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

	// Validasi waktu check-in
	if !isTimeInRange(now, settings.CheckInStart, settings.CheckInEnd) {
		utils.Error(c, fmt.Sprintf("Check-in hanya diperbolehkan antara %s - %s", settings.CheckInStart, settings.CheckInEnd))
		return
	}

	// Cek apakah sudah check-in hari ini
	var existing models.Attendance
	if err := database.DB.Where("user_id = ? AND date = ?", emp.ID, today).First(&existing).Error; err == nil {
		if existing.CheckInTime != nil {
			utils.Error(c, "Kamu sudah melakukan check-in hari ini")
			return
		}
	}

	upsertCheckIn(emp.ID, emp.CompanyID, today, now)
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

	utils.Success(c, "Status absensi hari ini", gin.H{
		"date":            today,
		"attendance":      att,
		"has_record":      err == nil,
		"settings":        settings,
		"current_time":    time.Now().Format("15:04:05"),
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

	database.DB.Save(&settings)
	utils.Success(c, "Pengaturan absensi berhasil diperbarui", settings)
}

// ===== HELPER FUNCTIONS =====

// isTimeInRange mengecek apakah waktu now berada di antara start dan end (format "HH:MM")
func isTimeInRange(now time.Time, start, end string) bool {
	loc := now.Location()
	todayStr := now.Format("2006-01-02")

	parseT := func(t string) time.Time {
		parsed, _ := time.ParseInLocation("2006-01-02 15:04", todayStr+" "+t, loc)
		return parsed
	}

	s := parseT(start)
	e := parseT(end)
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
func upsertCheckIn(userID, companyID, date string, checkInTime time.Time) {
	var att models.Attendance
	err := database.DB.Where("user_id = ? AND date = ?", userID, date).First(&att).Error
	if err != nil {
		att = models.Attendance{
			ID:          uuid.New().String(),
			UserID:      userID,
			CompanyID:   companyID,
			Date:        date,
			CheckInTime: &checkInTime,
			Status:      "PRESENT",
		}
		database.DB.Create(&att)
	} else {
		att.CheckInTime = &checkInTime
		att.Status = "PRESENT"
		database.DB.Save(&att)
	}
}
