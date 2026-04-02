// internal/handlers/attendance_handler.go

package handlers

import (
	"fmt"
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"strconv"
	"strings"

	"encoding/json"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"sort"
)

// isHoliday mengecek apakah tanggal tertentu adalah hari libur (manual atau akhir pekan)
func isHoliday(companyID string, t time.Time) (bool, string) {
	var settings models.AttendanceSettings
	database.DB.Where("company_id = ?", companyID).First(&settings)

	// Cek Hari Kerja (WorkDays)
	// Format: "Monday,Tuesday,Wednesday,Thursday,Friday"
	dayName := t.Weekday().String()
	workDays := settings.WorkDays
	if workDays == "" {
		// Default: Senin - Jumat
		workDays = "Monday,Tuesday,Wednesday,Thursday,Friday"
	}

	if !strings.Contains(workDays, dayName) {
		return true, fmt.Sprintf("%s (Bukan Hari Kerja)", dayName)
	}

	// Cek Tabel Hari Libur
	var holiday models.Holiday
	// Cari libur yang mencakup tanggal t (Start <= t <= End)
	err := database.DB.Where("company_id = ? AND ? >= start_date AND ? <= end_date",
		companyID, t.Format("2006-01-02"), t.Format("2006-01-02")).First(&holiday).Error

	if err == nil {
		return true, holiday.Name
	}

	return false, ""
}

// CheckIn — karyawan melakukan absensi masuk
func CheckIn(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	// Cek Hari Libur
	if holiday, msg := isHoliday(emp.CompanyID, time.Now()); holiday {
		utils.Error(c, "Hari ini libur: "+msg)
		return
	}

	now := time.Now()
	today := now.Format("2006-01-02")

	// Ambil pengaturan jam absensi
	var settings models.AttendanceSettings
	if err := database.DB.Where("company_id = ?", emp.CompanyID).First(&settings).Error; err != nil {
		utils.Error(c, "Pengaturan absensi belum dikonfigurasi oleh admin")
		return
	}

	// Validasi waktu check-in: Mulai setelah CheckInStart dan sebelum jam pulang berakhir (CheckOutEnd)
	if now.Before(parseT(today, settings.CheckInStart, now.Location())) {
		utils.Error(c, fmt.Sprintf("Absensi masuk belum dibuka. Mulai jam %s", settings.CheckInStart))
		return
	}
	if now.After(parseT(today, settings.CheckOutEnd, now.Location())) {
		utils.Error(c, "Batas waktu absensi untuk hari ini sudah berakhir (Alpha)")
		return
	}

	// Tentukan Status: LATE jika lewat dari CheckInEnd
	status := "PRESENT"
	var deduction float64 = 0
	if now.After(parseT(today, settings.CheckInEnd, now.Location())) {
		status = "LATE"
		deduction = settings.LatePenalty
	}

	// Cek apakah sudah check-in hari ini
	var existing models.Attendance
	if err := database.DB.Where("user_id = ? AND date = ?", emp.ID, today).First(&existing).Error; err == nil {
		if existing.CheckInTime != nil {
			utils.Error(c, "Kamu sudah melakukan check-in hari ini")
			return
		}
	}

	upsertCheckIn(emp.ID, emp.CompanyID, today, now, status, deduction)
	utils.Success(c, "Check-in berhasil", gin.H{
		"check_in_time": now.Format("15:04:05"),
		"date":          today,
	})
}

// CheckOut — karyawan melakukan absensi pulang
func CheckOut(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	now := time.Now()
	today := now.Format("2006-01-02")

	// Cek Hari Libur
	if holiday, msg := isHoliday(emp.CompanyID, now); holiday {
		utils.Error(c, "Hari ini libur: "+msg)
		return
	}

	// Ambil pengaturan jam absensi
	var settings models.AttendanceSettings
	if err := database.DB.Where("company_id = ?", emp.CompanyID).First(&settings).Error; err != nil {
		settings = models.AttendanceSettings{
			CheckInStart:  "07:00",
			CheckInEnd:    "09:00",
			CheckOutStart: "16:00",
			CheckOutEnd:   "18:00",
		}
	}

	// Validasi waktu check-out
	if !isTimeInRange(now, settings.CheckOutStart, settings.CheckOutEnd) {
		utils.Error(c, fmt.Sprintf("Check-out hanya diperbolehkan antara %s - %s", settings.CheckOutStart, settings.CheckOutEnd))
		return
	}

	// Pastikan sudah check-in
	var att models.Attendance
	if err := database.DB.Where("user_id = ? AND date = ?", emp.ID, today).First(&att).Error; err != nil {
		utils.Error(c, "Kamu belum melakukan check-in hari ini")
		return
	}
	if att.CheckInTime == nil {
		utils.Error(c, "Kamu belum melakukan check-in hari ini")
		return
	}
	if att.CheckOutTime != nil {
		utils.Error(c, "Kamu sudah melakukan check-out hari ini")
		return
	}

	att.CheckOutTime = &now
	database.DB.Save(&att)

	utils.Success(c, "Check-out berhasil", gin.H{
		"check_out_time": now.Format("15:04:05"),
		"date":           today,
	})
}

// GetTodayAttendance — status absensi karyawan hari ini
func GetTodayAttendance(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	today := time.Now().Format("2006-01-02")
	var att models.Attendance
	err := database.DB.Where("user_id = ? AND date = ?", emp.ID, today).First(&att).Error

	// Ambil pengaturan jam absensi (dengan fallback)
	var settings models.AttendanceSettings
	if err := database.DB.Where("company_id = ?", emp.CompanyID).First(&settings).Error; err != nil {
		settings = models.AttendanceSettings{
			CheckInStart:  "07:00",
			CheckInEnd:    "09:00",
			CheckOutStart: "16:00",
			CheckOutEnd:   "18:00",
		}
	}

	// Hitung status tampilan dinamis
	displayStatus := att.Status
	now := time.Now()
	loc := now.Location()

	// Cek Hari Libur
	if holiday, msg := isHoliday(emp.CompanyID, now); holiday {
		utils.Success(c, "Hari ini libur", gin.H{
			"status":       "HOLIDAY",
			"holiday_name": msg,
		})
		return
	}

	if err != nil { // Belum ada record absensi hari ini
		if now.Before(parseT(today, settings.CheckInStart, loc)) {
			displayStatus = "NOT_STARTED" // Label: Belum Mulai
		} else if now.After(parseT(today, settings.CheckOutEnd, loc)) {
			displayStatus = "ABSENT" // Label: Alpha (Hanya jika benar-benar lewat hari/jam pulang)
		} else if now.After(parseT(today, settings.CheckInEnd, loc)) {
			displayStatus = "LATE" // Label: Terlambat
		} else {
			displayStatus = "READY" // Siap Absen
		}
	} else if att.CheckOutTime == nil { // Sudah check-in tapi belum check-out
		if now.After(parseT(today, settings.CheckOutEnd, loc)) {
			displayStatus = "EARLY_LEAVE" // Label: Pulang di jam kerja
		}
	}

	// Hitung total denda bulan ini untuk estimasi gaji
	var totalDeductionMonth float64
	
	// Gunakan logika bersama agar sinkron dengan tab Gaji
	// Ini akan menghitung semua denda absensi + denda manual + denda Alpha otomatis
	totalDeductionMonth, _ = CalculateDeductions(emp.ID, int(now.Month()), now.Year())

	utils.Success(c, "Status absensi hari ini", gin.H{
		"date":                  today,
		"attendance":            att,
		"has_record":            err == nil,
		"settings":              settings,
		"current_time":          now.Format("15:04:05"),
		"display_status":        displayStatus,
		"total_deduction_month": totalDeductionMonth,
	})
}

// GetMyAttendanceHistory — riwayat absensi karyawan sendiri
// Query params: filter=week|month|year
func GetMyAttendanceHistory(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)
	// Refresh from DB agar data CreatedAt 100% akurat
	database.DB.First(&emp, "id = ?", emp.ID)

	filter := c.Query("filter")
	month := c.Query("month")
	year := c.Query("year")

	query := database.DB.Where("user_id = ?", emp.ID)

	if year != "" {
		if month != "" {
			mInt, _ := strconv.Atoi(month)
			pattern := fmt.Sprintf("%s-%02d%%", year, mInt)
			query = query.Where("date LIKE ?", pattern)
		} else {
			pattern := fmt.Sprintf("%s-%%", year)
			query = query.Where("date LIKE ?", pattern)
		}
	} else {
		if filter == "" {
			filter = "month"
		}
		start := getFilterStart(filter)
		query = query.Where("date >= ?", start)
	}

	var records []models.Attendance
	query.Order("date desc").Find(&records)

	// --- Dinamis: Tambahkan record ALPHA untuk hari kerja yang terlewat ---
	// 1. Tentukan tanggal awal & akhir untuk pengecekan
	var startT, endT time.Time
	now := time.Now()
	
	if year != "" {
		yInt, _ := strconv.Atoi(year)
		if month != "" {
			mInt, _ := strconv.Atoi(month)
			startT = time.Date(yInt, time.Month(mInt), 1, 0, 0, 0, 0, time.Local)
			endT = startT.AddDate(0, 1, -1)
		} else {
			startT = time.Date(yInt, 1, 1, 0, 0, 0, 0, time.Local)
			endT = time.Date(yInt, 12, 31, 0, 0, 0, 0, time.Local)
		}
	} else {
		startS := getFilterStart(filter)
		startT, _ = time.Parse("2006-01-02", startS)
		endT = now
	}

	if endT.After(now) {
		endT = now // Jangan cek masa depan
	}

	// 2. Map record yang ada untuk lookup cepat
	existingDates := make(map[string]bool)
	for _, r := range records {
		existingDates[r.Date] = true
	}

	// 3. Ambil pengaturan untuk denda Alpha
	var settings models.AttendanceSettings
	database.DB.Where("company_id = ?", emp.CompanyID).First(&settings)

	// 4. Loop setiap tanggal dalam range
	for d := startT; !d.After(endT); d = d.AddDate(0, 0, 1) {
		dateStr := d.Format("2006-01-02")
		
		// Jangan denda Alpha jika tanggalnya sebelum user bergabung/dibuat
		if dateStr < emp.CreatedAt.Format("2006-01-02") {
			continue
		}

		// Jika belum ada record dan bukan hari ini yang belum selesai
		if !existingDates[dateStr] {
			// Cek apakah hari libur/akhir pekan
			holiday, _ := isHoliday(emp.CompanyID, d)
			if !holiday {
				// Cek jam operasional jika itu hari ini
				if dateStr == now.Format("2006-01-02") {
					loc := now.Location()
					checkOutEnd := parseT(dateStr, settings.CheckOutEnd, loc)
					if now.Before(checkOutEnd) {
						continue // Masih bisa absen, jangan dianggap alpha dulu
					}
				}

				// Tambahkan record Alpha virtual
				records = append(records, models.Attendance{
					Date:            dateStr,
					Status:          "ABSENT",
					SalaryDeduction: settings.AlphaPenalty,
				})
			}
		}
	}

	// Urutkan kembali berdasarkan tanggal terbaru (descending)
	sort.Slice(records, func(i, j int) bool {
		return records[i].Date > records[j].Date
	})

	// Hitung statistik
	var present, absent, leave, sick, late int
	for _, r := range records {
		switch r.Status {
		case "PRESENT":
			present++
		case "ABSENT":
			absent++
		case "LEAVE":
			leave++
		case "SICK":
			sick++
		case "LATE":
			late++
		}
	}

	utils.Success(c, "Riwayat kehadiran", gin.H{
		"records": records,
		"stats": gin.H{
			"present": present,
			"absent":  absent,
			"leave":   leave,
			"sick":    sick,
			"late":    late,
			"total":   len(records),
		},
	})
}

// AdminGetAttendanceHistory — admin melihat riwayat semua karyawan
func AdminGetAttendanceHistory(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	startDate := c.Query("start_date")
	endDate := c.Query("end_date")
	filter := c.DefaultQuery("filter", "month")
	userID := c.Query("user_id")
	statusFilter := c.Query("status") // Misal: PRESENT, LATE, ABSENT, LEAVE, SICK

	now := time.Now()
	loc := now.Location()
	today := now.Format("2006-01-02")

	// Ambil Pengaturan (dengan fallback default agar tidak Alpha prematur)
	var settings models.AttendanceSettings
	if err := database.DB.Where("company_id = ?", adminUser.CompanyID).First(&settings).Error; err != nil {
		settings = models.AttendanceSettings{
			CheckInStart:  "07:00",
			CheckInEnd:    "09:00",
			CheckOutStart: "16:00",
			CheckOutEnd:   "18:00",
		}
	}
	checkOutEndT := parseT(today, settings.CheckOutEnd, loc)

	// Cari tanggal absensi pertama kali di perusahaan ini sebagai batas awal "System Active"
	var firstRecordDate string
	database.DB.Model(&models.Attendance{}).Where("company_id = ?", adminUser.CompanyID).Order("date asc").Limit(1).Select("date").Scan(&firstRecordDate)

	// 1. Ambil Semua Karyawan Aktif Perusahaan ini
	var employees []models.User
	empQuery := database.DB.Where("company_id = ? AND role = ? AND status = ?", adminUser.CompanyID, "EMPLOYEE", "ACTIVE")
	if userID != "" {
		empQuery = empQuery.Where("id = ?", userID)
	}
	empQuery.Find(&employees)

	// 2. Tentukan Rentang Tanggal
	var start, end string
	specificMonth := c.Query("month") // 1-12
	specificYear := c.Query("year")   // e.g. 2024

	if startDate != "" && endDate != "" {
		start = startDate
		end = endDate
	} else if filter == "year" && specificYear != "" {
		start = fmt.Sprintf("%s-01-01", specificYear)
		end = fmt.Sprintf("%s-12-31", specificYear)
	} else if filter == "month" && specificMonth != "" {
		yearStr := specificYear
		if yearStr == "" {
			yearStr = fmt.Sprintf("%d", now.Year())
		}
		monthInt, _ := strconv.Atoi(specificMonth)
		// Cari tanggal terakhir dari bulan tersebut
		firstDay := time.Date(now.Year(), time.Month(monthInt), 1, 0, 0, 0, 0, loc)
		if specificYear != "" {
			y, _ := strconv.Atoi(specificYear)
			firstDay = time.Date(y, time.Month(monthInt), 1, 0, 0, 0, 0, loc)
		}
		lastDay := firstDay.AddDate(0, 1, -1)

		start = firstDay.Format("2006-01-02")
		end = lastDay.Format("2006-01-02")
	} else {
		start = getFilterStart(filter)
		end = today
	}

	// 3. Ambil Data Absensi yang Ada dari DB
	query := database.DB.Where("company_id = ? AND date >= ? AND date <= ?", adminUser.CompanyID, start, end)
	if userID != "" {
		query = query.Where("user_id = ?", userID)
	}
	var records []models.Attendance
	query.Order("date desc").Find(&records)

	// Buat map untuk memudahkan pengecekan: date -> user_id -> record
	recordMap := make(map[string]map[string]models.Attendance)
	for _, r := range records {
		if recordMap[r.Date] == nil {
			recordMap[r.Date] = make(map[string]models.Attendance)
		}
		recordMap[r.Date][r.UserID] = r
	}

	// 4. Struktur Hasil
	type AttendanceResult struct {
		models.Attendance
		UserName  string `json:"user_name"`
		UserEmail string `json:"user_email"`
		IsVirtual bool   `json:"is_virtual"` // Penanda data ini Alpha otomatis
	}
	var finalResult []AttendanceResult

	// Iterasi Hari dari 'end' ke 'start' (Terbaru ke Terlama)
	curr, _ := time.ParseInLocation("2006-01-02", end, loc)
	limit, _ := time.ParseInLocation("2006-01-02", start, loc)

	for !curr.Before(limit) {
		dateStr := curr.Format("2006-01-02")

		// Lewati jika sebelum sistem aktif (absen pertama perusahaan)
		if firstRecordDate != "" && dateStr < firstRecordDate {
			curr = curr.AddDate(0, 0, -1)
			continue
		}

		for _, emp := range employees {
			att, exists := recordMap[dateStr][emp.ID]

			if exists {
				// Deteksi status dinamis untuk riwayat (WORKING / EARLY_LEAVE)
				displayStatus := att.Status
				isPastTime := dateStr < today || (dateStr == today && now.After(checkOutEndT))

				if att.CheckInTime != nil && att.CheckOutTime == nil {
					if isPastTime {
						displayStatus = "EARLY_LEAVE"
					} else {
						displayStatus = "WORKING"
					}
				}

				if statusFilter == "" || displayStatus == statusFilter {
					// Copy record agar tidak merubah data asli di Map
					newAtt := att
					newAtt.Status = displayStatus

					finalResult = append(finalResult, AttendanceResult{
						Attendance: newAtt,
						UserName:   emp.Name,
						UserEmail:  emp.Email,
						IsVirtual:  false,
					})
				}
			} else {
				// Cegah Alpha untuk tanggal sebelum karyawan didaftarkan (Gunakan Zona Waktu Lokal)
				registrationDate := emp.CreatedAt.In(loc).Format("2006-01-02")
				if dateStr < registrationDate {
					continue
				}

				// Cek apakah hari ini Alpha (Sudah lewat jam pulang / Hari sudah lewat)
				isAlpha := false
				if dateStr < today {
					isAlpha = true
				} else if dateStr == today && now.After(checkOutEndT) {
					isAlpha = true
				}

				if isAlpha && (statusFilter == "" || statusFilter == "ABSENT") {
					finalResult = append(finalResult, AttendanceResult{
						Attendance: models.Attendance{
							ID:        "virtual-" + emp.ID + "-" + dateStr,
							UserID:    emp.ID,
							CompanyID: emp.CompanyID,
							Date:      dateStr,
							Status:    "ABSENT",
						},
						UserName:  emp.Name,
						UserEmail: emp.Email,
						IsVirtual: true,
					})
				} else if !isAlpha && dateStr == today && (statusFilter == "" || statusFilter == "ALL") {
					// Tambahkan entri "Belum Absen" untuk hari ini
					finalResult = append(finalResult, AttendanceResult{
						Attendance: models.Attendance{
							ID:        "yet-" + emp.ID + "-" + dateStr,
							UserID:    emp.ID,
							CompanyID: emp.CompanyID,
							Date:      dateStr,
							Status:    "NOT_YET",
						},
						UserName:  emp.Name,
						UserEmail: emp.Email,
						IsVirtual: true,
					})
				}
			}
		}
		curr = curr.AddDate(0, 0, -1)
	}

	utils.Success(c, "Riwayat kehadiran karyawan", finalResult)
}

// GetAttendanceSettings — admin mendapatkan pengaturan jam absensi
func GetAttendanceSettings(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var settings models.AttendanceSettings
	if err := database.DB.Where("company_id = ?", adminUser.CompanyID).First(&settings).Error; err != nil {
		// Kembalikan default jika belum ada
		utils.Success(c, "Pengaturan absensi (default)", models.AttendanceSettings{
			CheckInStart:  "07:00",
			CheckInEnd:    "09:00",
			CheckOutStart: "16:00",
			CheckOutEnd:   "18:00",
			AlphaPenalty:  0,
			LatePenalty:   0,
		})
		return
	}
	utils.Success(c, "Pengaturan absensi", settings)
}

// AdminBulkDeleteAttendance — admin menghapus riwayat absensi massal berdasarkan filter
func AdminBulkDeleteAttendance(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	filter := c.Query("filter")
	year := c.Query("year")
	month := c.Query("month")
	startDate := c.Query("start_date")
	endDate := c.Query("end_date")

	query := database.DB.Where("company_id = ?", adminUser.CompanyID)

	switch filter {
	case "month":
		if month != "" && year != "" {
			query = query.Where("date LIKE ?", year+"-"+fmt.Sprintf("%02s", month)+"-%")
		}
	case "year":
		if year != "" {
			query = query.Where("date LIKE ?", year+"-%")
		}
	case "custom":
		if startDate != "" && endDate != "" {
			query = query.Where("date BETWEEN ? AND ?", startDate, endDate)
		}
	}

	if err := query.Delete(&models.Attendance{}).Error; err != nil {
		utils.Error(c, "Gagal menghapus riwayat kehadiran")
		return
	}

	utils.Success(c, "Riwayat kehadiran berhasil dihapus", nil)
}

// UpdateAttendanceSettings — admin mengubah pengaturan jam absensi & denda alpha
func UpdateAttendanceSettings(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var body struct {
		CheckInStart      string                   `json:"check_in_start"`
		CheckInEnd        string                   `json:"check_in_end"`
		CheckOutStart     string                   `json:"check_out_start"`
		CheckOutEnd       string                   `json:"check_out_end"`
		AlphaPenalty      float64                  `json:"alpha_penalty"`
		LatePenalty       float64                  `json:"late_penalty"`
		LatePenaltyTiers  []map[string]interface{} `json:"late_penalty_tiers"`
		WorkDays          string                   `json:"work_days"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	var settings models.AttendanceSettings
	database.DB.Where("company_id = ?", adminUser.CompanyID).First(&settings)

	if settings.ID == "" {
		settings.ID = uuid.New().String()
		settings.CompanyID = adminUser.CompanyID
	}
	settings.CheckInStart = body.CheckInStart
	settings.CheckInEnd = body.CheckInEnd
	settings.CheckOutStart = body.CheckOutStart
	settings.CheckOutEnd = body.CheckOutEnd
	settings.AlphaPenalty = body.AlphaPenalty
	settings.LatePenalty = body.LatePenalty
	settings.WorkDays = body.WorkDays

	// Marshal tiers to string for DB storage
	tiersJSON, _ := json.Marshal(body.LatePenaltyTiers)
	settings.LatePenaltyTiers = string(tiersJSON)

	database.DB.Save(&settings)
	utils.Success(c, "Pengaturan absensi berhasil diperbarui", settings)
}

// AdminGetDashboardSummary — ringkasan status absensi hari ini untuk dashboard admin
func AdminGetDashboardSummary(c *gin.Context) {
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)
	now := time.Now()
	loc := now.Location()
	today := now.Format("2006-01-02")

	// Cek Hari Libur
	isHold, holdName := isHoliday(admin.CompanyID, now)

	// Ambil pengaturan jam absensi (dengan fallback default)
	var settings models.AttendanceSettings
	if err := database.DB.Where("company_id = ?", admin.CompanyID).First(&settings).Error; err != nil {
		settings = models.AttendanceSettings{
			CheckInStart:  "07:00",
			CheckInEnd:    "09:00",
			CheckOutStart: "16:00",
			CheckOutEnd:   "18:00",
		}
	}
	checkOutEndT := parseT(today, settings.CheckOutEnd, loc)

	var present, late, leave, sick, working int64

	// 1. Hitung yang sudah SELESAI (sudah check-out)
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ? AND check_out_time IS NOT NULL", admin.CompanyID, today, "PRESENT").Count(&present)
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ? AND check_out_time IS NOT NULL", admin.CompanyID, today, "LATE").Count(&late)

	// 2. Hitung yang SEDANG BEKERJA (sudah check-in tapi belum check-out)
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND (status = ? OR status = ?) AND check_out_time IS NULL", admin.CompanyID, today, "PRESENT", "LATE").Count(&working)

	// 3. Izin & Sakit
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ?", admin.CompanyID, today, "LEAVE").Count(&leave)
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ?", admin.CompanyID, today, "SICK").Count(&sick)

	// 4. Total Karyawan Aktif
	var totalEmployees int64
	database.DB.Model(&models.User{}).Where("company_id = ? AND status = ? AND role = ?", admin.CompanyID, "ACTIVE", "EMPLOYEE").Count(&totalEmployees)

	// 5. Logika Alpha vs Belum Absen vs Pulang di Jam Kerja
	var absentCount, notYetCount, earlyLeaveCount, displayWorking int64
	totalCheckedIn := present + late + working + leave + sick
	notCheckedInYet := totalEmployees - totalCheckedIn
	if notCheckedInYet < 0 {
		notCheckedInYet = 0
	}

	if now.After(checkOutEndT) {
		// Jika sudah lewat jam pulang:
		// Yang tidak absen sama sekali = ALPHA
		// Yang check-in tapi tidak check-out = Pulang di jam kerja (early_leave)
		absentCount = notCheckedInYet
		earlyLeaveCount = working
		displayWorking = 0
		notYetCount = 0
	} else {
		// Jika masih dalam jam kerja:
		// Alpha diset 0 agar dashboard tidak merah prematur
		// Yang tidak absen = Belum Absen (not_yet)
		absentCount = 0
		earlyLeaveCount = 0
		displayWorking = working
		notYetCount = notCheckedInYet
	}

	utils.Success(c, "Dashboard summary", gin.H{
		"present":            present,
		"late":               late,
		"absent":             absentCount,
		"leave":              leave,
		"sick":               sick,
		"working":            displayWorking,
		"not_yet":            notYetCount,
		"early_leave":        earlyLeaveCount,
		"total":              totalEmployees,
		"is_after_work_hour": now.After(checkOutEndT),
		"is_holiday":         isHold,
		"holiday_name":       holdName,
	})
}

// ===== HELPER FUNCTIONS =====

// isTimeInRange mengecek apakah waktu now berada di antara start dan end (format "HH:MM")
func isTimeInRange(now time.Time, start, end string) bool {
	loc := now.Location()
	todayStr := now.Format("2006-01-02")

	s := parseT(todayStr, start, loc)
	e := parseT(todayStr, end, loc)
	return (now.Equal(s) || now.After(s)) && (now.Equal(e) || now.Before(e))
}

// getFilterStart mengembalikan tanggal awal berdasarkan filter
func getFilterStart(filter string) string {
	now := time.Now()
	switch filter {
	case "week":
		weekday := int(now.Weekday())
		if weekday == 0 {
			weekday = 7
		}
		start := now.AddDate(0, 0, -(weekday - 1))
		return start.Format("2006-01-02")
	case "year":
		return fmt.Sprintf("%d-01-01", now.Year())
	default: // month
		return fmt.Sprintf("%d-%02d-01", now.Year(), now.Month())
	}
}

// upsertCheckIn membuat atau update record check-in
func upsertCheckIn(userID, companyID, date string, checkInTime time.Time, status string, deduction float64) {
	var att models.Attendance
	err := database.DB.Where("user_id = ? AND date = ?", userID, date).First(&att).Error
	if err != nil {
		att = models.Attendance{
			ID:              uuid.New().String(),
			UserID:          userID,
			CompanyID:       companyID,
			Date:            date,
			CheckInTime:     &checkInTime,
			Status:          status,
			SalaryDeduction: deduction,
		}
		database.DB.Create(&att)
	} else {
		att.CheckInTime = &checkInTime
		att.Status = status
		att.SalaryDeduction = deduction
		database.DB.Save(&att)
	}
}

// helper parseT (pindah keluar untuk dipakai di CheckIn)
func parseT(dateStr, t string, loc *time.Location) time.Time {
	parsed, _ := time.ParseInLocation("2006-01-02 15:04", dateStr+" "+t, loc)
	return parsed
}
