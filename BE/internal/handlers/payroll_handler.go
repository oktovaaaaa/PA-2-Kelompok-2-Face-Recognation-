// internal/handlers/payroll_handler.go

package handlers

import (
	"encoding/json"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"
)

type LateTier struct {
	Hours   int     `json:"hours"`
	Penalty float64 `json:"penalty"`
}

// GetMySalaries - Employee view (Only shows past months)
func GetMySalaries(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)
	userID := user.ID
	
	var salaries []models.Salary

	// Pastikan gaji bulan sebelumnya sudah terhitung
	ensureSalariesGenerated(userID)

	now := time.Now()
	currentMonth := int(now.Month())
	currentYear := now.Year()

	// Filter: Hanya tampilkan bulan yang sudah lewat (year < current OR (year == current AND month < current))
	database.DB.Where("user_id = ? AND (year < ? OR (year = ? AND month < ?))", 
		userID, currentYear, currentYear, currentMonth).
		Order("year desc, month desc").Find(&salaries)

	utils.Success(c, "Berhasil mengambil riwayat gaji", salaries)
}

// AdminGetSalaries - Admin view with filters
func AdminGetSalaries(c *gin.Context) {
	month, _ := strconv.Atoi(c.Query("month"))
	year, _ := strconv.Atoi(c.Query("year"))
	positionID := c.Query("position_id")
	search := c.Query("search")

	// Proactive Generation: Pastikan semua karyawan yang SUDAH BERGABUNG punya record gaji untuk periode ini
	if month > 0 && year > 0 {
		var employees []models.User
		// Kita batasi hanya karyawan yang dibuat SEBELUM atau PADA bulan yang diminta
		lastDayOfMonth := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.Local).AddDate(0, 1, 0)
		database.DB.Where("role = ? AND created_at < ?", "EMPLOYEE", lastDayOfMonth).Find(&employees)
		for _, emp := range employees {
			// Kita panggil generateSalary untuk memastikan data terbaru (termasuk denda) tercatat
			generateSalary(emp.ID, month, year)
		}
	}

	var salaries []models.Salary
	query := database.DB.Preload("User").Preload("User.Position").Joins("JOIN users ON users.id = salaries.user_id")

	if month > 0 && year > 0 {
		periodEnd := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.Local).AddDate(0, 1, 0)
		query = query.Where("salaries.month = ? AND salaries.year = ? AND users.created_at < ?", month, year, periodEnd)
	} else {
		if month > 0 {
			query = query.Where("salaries.month = ?", month)
		}
		if year > 0 {
			query = query.Where("salaries.year = ?", year)
		}
	}

	// Filter by User
	userSubQuery := database.DB.Model(&models.User{})
	if positionID != "" {
		userSubQuery = userSubQuery.Where("position_id = ?", positionID)
	}
	if search != "" {
		userSubQuery = userSubQuery.Where("name LIKE ?", "%"+search+"%")
	}
	
	var userIDs []string
	userSubQuery.Pluck("id", &userIDs)
	
	if len(userIDs) > 0 || (positionID == "" && search == "") {
		if positionID != "" || search != "" {
			query = query.Where("user_id IN ?", userIDs)
		}
		query.Order("year desc, month desc").Find(&salaries)
	} else {
		salaries = []models.Salary{}
	}

	utils.Success(c, "Berhasil mengambil data payroll", salaries)
}

// AdminPaySalary - Process payment
func AdminPaySalary(c *gin.Context) {
	salaryID := c.Param("id")
	
	var salary models.Salary
	if err := database.DB.First(&salary, "id = ?", salaryID).Error; err != nil {
		utils.Error(c, "Data gaji tidak ditemukan")
		return;
	}

	if salary.Status == "PAID" {
		utils.Error(c, "Gaji ini sudah dibayar sebelumnya")
		return;
	}

	// Handle optional payment proof photo
	photo, err := c.FormFile("proof")
	var photoPath string
	if err == nil {
		photoName := uuid.New().String() + ".jpg"
		photoPath = "/uploads/payments/" + photoName
		if err := c.SaveUploadedFile(photo, "uploads/payments/"+photoName); err != nil {
			utils.Error(c, "Gagal menyimpan bukti pembayaran")
			return
		}
	}

	now := time.Now()
	salary.Status = "PAID"
	salary.PaymentProof = photoPath
	salary.PaidAt = &now

	database.DB.Save(&salary)

	utils.Success(c, "Gaji berhasil ditandai sebagai dibayar", salary)
}

// UpdateBankInfo - Employee sets their own bank info
func UpdateBankInfo(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)
	userID := user.ID
	
	var input struct {
		BankName          string `json:"bank_name" binding:"required"`
		BankAccountNumber string `json:"bank_account_number" binding:"required"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		utils.Error(c, "Input tidak valid")
		return
	}

	if err := database.DB.Model(&models.User{}).Where("id = ?", userID).Updates(models.User{
		BankName:          input.BankName,
		BankAccountNumber: input.BankAccountNumber,
	}).Error; err != nil {
		utils.Error(c, "Gagal memperbarui info bank")
		return
	}

	utils.Success(c, "Info bank berhasil diperbarui", nil)
}

// Logic to ensure salaries are generated for specific user
func ensureSalariesGenerated(userID string) {
	now := time.Now()
	// Cek bulan ini dan bulan lalu
	monthsToCheck := []time.Time{now, now.AddDate(0, -1, 0)}

	for _, t := range monthsToCheck {
		month := int(t.Month())
		year := t.Year()

		var exist models.Salary
		err := database.DB.Where("user_id = ? AND month = ? AND year = ?", userID, month, year).First(&exist).Error
		if err != nil { // Not found
			generateSalary(userID, month, year)
		} else if exist.Status == "PENDING" {
			// Update rincian jika masih pending (karena denda bisa bertambah seiring hari berjalan)
			generateSalary(userID, month, year)
		}
	}
}

func generateSalary(userID string, month int, year int) {
	var user models.User
	if err := database.DB.Preload("Position").First(&user, "id = ?", userID).Error; err != nil {
		return
	}

	// Gaji dasar dari Position
	baseSalary := 0.0
	if user.PositionID != nil {
		baseSalary = user.Position.Salary
	}

	// Hitung Denda
	deductions := calculateDeductions(userID, month, year)

	// Update or Create
	var salary models.Salary
	database.DB.Where("user_id = ? AND month = ? AND year = ?", userID, month, year).First(&salary)
	
	if salary.ID == "" {
		salary.ID = uuid.New().String()
		salary.UserID = userID
		salary.Month = month
		salary.Year = year
		salary.Status = "PENDING"
	}
	
	salary.BaseSalary = baseSalary
	salary.Deductions = deductions
	salary.TotalSalary = baseSalary - deductions
	if salary.TotalSalary < 0 {
		salary.TotalSalary = 0
	}

	database.DB.Save(&salary)
}

func calculateDeductions(userID string, month int, year int) float64 {
	var settings models.AttendanceSettings
	database.DB.First(&settings) // Get first settings (assumed company wide for now)

	// Parse Tiers
	var tiers []LateTier
	if settings.LatePenaltyTiers != "" {
		json.Unmarshal([]byte(settings.LatePenaltyTiers), &tiers)
	}

	// Get Attendances for this month
	startDate := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.Local)
	endDate := startDate.AddDate(0, 1, 0)

	var attendances []models.Attendance
	database.DB.Where("user_id = ? AND date >= ? AND date < ?", userID, startDate.Format("2006-01-02"), endDate.Format("2006-01-02")).Find(&attendances)

	totalDeduction := 0.0
	for _, att := range attendances {
		if att.Status == "ABSENT" {
			totalDeduction += settings.AlphaPenalty
		} else if att.Status == "LATE" {
			// Hitung durasi terlambat
			if att.CheckInTime != nil {
				// Parse CheckInEnd for that day
				checkInEndStr := settings.CheckInEnd // Format "HH:MM"
				attDateStr := att.Date             // "YYYY-MM-DD"
				
				layout := "2006-01-02 15:04"
				deadline, _ := time.ParseInLocation(layout, attDateStr+" "+checkInEndStr, time.Local)
				
				lateDuration := att.CheckInTime.Sub(deadline)
				if lateDuration > 0 {
					lateHours := int(lateDuration.Hours())
					if lateDuration.Minutes() > float64(lateHours * 60) {
						lateHours++ // Pembulatan ke atas jam terlambat
					}

					// Cari Tier denda
					appliedPenalty := settings.LatePenalty // Default flat penalty
					maxTierHours := -1
					for _, tier := range tiers {
						if lateHours >= tier.Hours && tier.Hours > maxTierHours {
							appliedPenalty = tier.Penalty
							maxTierHours = tier.Hours
						}
					}
					totalDeduction += appliedPenalty
				}
			}
		}
	}

	return totalDeduction
}
