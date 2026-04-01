// internal/handlers/attendance_handler.go

package handlers

import (
	"fmt"
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CheckIn — karyawan melakukan absensi masuk
func CheckIn(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	now := time.Now()
	today := now.Format("2006-01-02")

	// Ambil pengaturan jam absensi
	var settings models.AttendanceSettings
	if err := database.DB.Where("company_id = ?", emp.CompanyID).First(&settings).Error; err != nil {
		utils.Error(c, "Pengaturan absensi belum dikonfigurasi oleh admin")
		return
	}

	// Validasi waktu check-in: Mulai setelah CheckInStart dan sebelum CheckOutStart dimulai
	if now.Before(parseT(today, settings.CheckInStart, now.Location())) {
		utils.Error(c, fmt.Sprintf("Absensi masuk belum dibuka. Mulai jam %s", settings.CheckInStart))
		return
	}
	if now.Equal(parseT(today, settings.CheckOutStart, now.Location())) || now.After(parseT(today, settings.CheckOutStart, now.Location())) {
		utils.Error(c, "Batas waktu check-in sudah habis (sudah masuk jam pulang)")
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

	// Ambil pengaturan jam absensi
	var settings models.AttendanceSettings
	if err := database.DB.Where("company_id = ?", emp.CompanyID).First(&settings).Error; err != nil {
		utils.Error(c, "Pengaturan absensi belum dikonfigurasi")
		return
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
	att.Status = "PRESENT"
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

	var settings models.AttendanceSettings
	database.DB.Where("company_id = ?", emp.CompanyID).First(&settings)

	// Hitung status tampilan dinamis
	displayStatus := att.Status
	now := time.Now()
	loc := now.Location()
	
	if err != nil { // Belum ada record absensi hari ini
		if now.Before(parseT(today, settings.CheckInStart, loc)) {
			displayStatus = "NOT_STARTED" // Label: Belum Mulai
		} else if now.After(parseT(today, settings.CheckInEnd, loc)) {
			displayStatus = "ABSENT" // Label: Alpha
		} else {
			displayStatus = "READY" // Sesuai jam tapi belum klik
		}
	} else if att.CheckOutTime == nil { // Sudah check-in tapi belum check-out
		if now.After(parseT(today, settings.CheckOutEnd, loc)) {
			displayStatus = "EARLY_LEAVE" // Label: Pulang di jam kerja
		}
	}

	utils.Success(c, "Status absensi hari ini", gin.H{
		"date":           today,
		"attendance":     att,
		"has_record":     err == nil,
		"settings":       settings,
		"current_time":   now.Format("15:04:05"),
		"display_status": displayStatus,
	})
}

// GetMyAttendanceHistory — riwayat absensi karyawan sendiri
// Query params: filter=week|month|year
func GetMyAttendanceHistory(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	filter := c.DefaultQuery("filter", "month")
	start := getFilterStart(filter)

	var records []models.Attendance
	database.DB.Where("user_id = ? AND date >= ?", emp.ID, start).
		Order("date desc").Find(&records)

	// Hitung statistik
	var present, absent, leave, sick int
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
		}
	}

	utils.Success(c, "Riwayat kehadiran", gin.H{
		"records": records,
		"stats": gin.H{
			"present": present,
			"absent":  absent,
			"leave":   leave,
			"sick":    sick,
			"total":   len(records),
		},
	})
}

// AdminGetAttendanceHistory — admin melihat riwayat semua karyawan
// Query params: filter=week|month|year, user_id (opsional)
func AdminGetAttendanceHistory(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	startDate := c.Query("start_date")
	endDate := c.Query("end_date")
	filter := c.DefaultQuery("filter", "month")
	userID := c.Query("user_id")

	query := database.DB.Where("company_id = ?", adminUser.CompanyID)

	if startDate != "" && endDate != "" {
		query = query.Where("date >= ? AND date <= ?", startDate, endDate)
	} else {
		start := getFilterStart(filter)
		query = query.Where("date >= ?", start)
	}

	if userID != "" {
		query = query.Where("user_id = ?", userID)
	}

	var records []models.Attendance
	query.Order("date desc").Find(&records)

	// Attach user info ke setiap record
	type AttendanceWithUser struct {
		models.Attendance
		UserName  string `json:"user_name"`
		UserEmail string `json:"user_email"`
	}

	var result []AttendanceWithUser
	userCache := map[string]models.User{}
	for _, r := range records {
		u, ok := userCache[r.UserID]
		if !ok {
			database.DB.Select("name, email").Where("id = ?", r.UserID).First(&u)
			userCache[r.UserID] = u
		}
		result = append(result, AttendanceWithUser{
			Attendance: r,
			UserName:   u.Name,
			UserEmail:  u.Email,
		})
	}

	utils.Success(c, "Riwayat kehadiran karyawan", result)
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

// UpdateAttendanceSettings — admin mengubah pengaturan jam absensi & denda alpha
func UpdateAttendanceSettings(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var body struct {
		CheckInStart  string  `json:"check_in_start"`
		CheckInEnd    string  `json:"check_in_end"`
		CheckOutStart string  `json:"check_out_start"`
		CheckOutEnd   string  `json:"check_out_end"`
		AlphaPenalty  float64 `json:"alpha_penalty"`
		LatePenalty   float64 `json:"late_penalty"`
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

	database.DB.Save(&settings)
	utils.Success(c, "Pengaturan absensi berhasil diperbarui", settings)
}

// AdminGetDashboardSummary — ringkasan status absensi hari ini untuk dashboard admin
func AdminGetDashboardSummary(c *gin.Context) {
	userCtx, _ := c.Get("user")
	admin := userCtx.(models.User)
	today := time.Now().Format("2006-01-02")

	var present, late, leave, sick int64

	// Hitung semua status dari Tabel Attendance hari ini
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ?", admin.CompanyID, today, "PRESENT").Count(&present)
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ?", admin.CompanyID, today, "LATE").Count(&late)
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ?", admin.CompanyID, today, "LEAVE").Count(&leave)
	database.DB.Model(&models.Attendance{}).Where("company_id = ? AND date = ? AND status = ?", admin.CompanyID, today, "SICK").Count(&sick)

	// Hitung Total Karyawan Aktif
	var totalEmployees int64
	database.DB.Model(&models.User{}).Where("company_id = ? AND status = ? AND role = ?", admin.CompanyID, "ACTIVE", "EMPLOYEE").Count(&totalEmployees)

	// Hitung Alpha (Sisa karyawan yang belum absen sama sekali)
	// Jika sebelum jam masuk, Alpha diset 0 agar dashboard tidak merah sebelum waktunya
	var absentCount int64
	var settings models.AttendanceSettings
	database.DB.Where("company_id = ?", admin.CompanyID).First(&settings)

	if time.Now().Before(parseT(today, settings.CheckInStart, time.Now().Location())) {
		absentCount = 0
	} else {
		absentCount = totalEmployees - (present + late + leave + sick)
	}

	if absentCount < 0 {
		absentCount = 0
	}

	utils.Success(c, "Dashboard summary", gin.H{
		"present": present,
		"late":    late,
		"absent":  absentCount,
		"leave":   leave,
		"sick":    sick,
		"total":   totalEmployees,
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
