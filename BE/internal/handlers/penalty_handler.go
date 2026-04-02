// internal/handlers/penalty_handler.go

package handlers

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CreatePenalty - Admin creates a new penalty for an employee
func CreatePenalty(c *gin.Context) {
	userID := c.PostForm("user_id")
	title := c.PostForm("title")
	description := c.PostForm("description")
	amountStr := c.PostForm("amount")
	penaltyType := c.PostForm("type")
	dateStr := c.PostForm("date")

	if userID == "" || title == "" || amountStr == "" {
		utils.Error(c, "Data tidak lengkap")
		return
	}

	amount, err := strconv.ParseFloat(amountStr, 64)
	if err != nil || amount <= 0 {
		utils.Error(c, "Nominal denda tidak valid")
		return
	}

	if dateStr == "" {
		dateStr = time.Now().Format("2006-01-02")
	}

	// Handle optional attachment photo
	file, err := c.FormFile("attachment")
	var attachmentPath string
	if err == nil {
		// Ensure directory exists
		uploadDir := "uploads/penalties"
		if _, err := os.Stat(uploadDir); os.IsNotExist(err) {
			os.MkdirAll(uploadDir, 0755)
		}

		filename := uuid.New().String() + filepath.Ext(file.Filename)
		attachmentPath = "/" + uploadDir + "/" + filename
		if err := c.SaveUploadedFile(file, uploadDir+"/"+filename); err != nil {
			utils.Error(c, "Gagal menyimpan lampiran denda")
			return
		}
	}

	penalty := models.Penalty{
		ID:          uuid.New().String(),
		UserID:      userID,
		Title:       title,
		Description: description,
		Amount:      amount,
		Type:        penaltyType,
		Attachment:  attachmentPath,
		Date:        dateStr,
	}

	if err := database.DB.Create(&penalty).Error; err != nil {
		utils.Error(c, "Gagal membuat data denda: "+err.Error())
		return
	}

	// Trigger payroll recalculation for this month
	t, _ := time.Parse("2006-01-02", dateStr)
	generateSalary(userID, int(t.Month()), t.Year())

	utils.Success(c, "Denda berhasil dicatatkan", penalty)
}

// GetPenalties - List penalties (Admin: All / Filtered, Employee: Only theirs)
func GetPenalties(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	query := database.DB.Preload("User").Preload("User.Position")

	// If not admin, only show their own penalties
	if user.Role != "ADMIN" {
		query = query.Where("user_id = ?", user.ID)
	} else {
		// Admin filters
		filterUserID := c.Query("user_id")
		if filterUserID != "" {
			query = query.Where("user_id = ?", filterUserID)
		}
	}

	// Date filters
	month := c.Query("month")
	year := c.Query("year")
	if month != "" && year != "" {
		monthInt, _ := strconv.Atoi(month)
		// Simpler: filter by prefix
		query = query.Where("date LIKE ?", fmt.Sprintf("%s-%02d-%%", year, monthInt))
	} else if year != "" {
		query = query.Where("date LIKE ?", year+"-%%")
	}

	var penalties []models.Penalty
	if err := query.Order("created_at DESC").Find(&penalties).Error; err != nil {
		utils.Error(c, "Gagal mengambil data denda")
		return
	}

	utils.Success(c, "Berhasil mengambil data denda", penalties)
}

// DeletePenalty - Admin removes a penalty
func DeletePenalty(c *gin.Context) {
	id := c.Param("id")

	var penalty models.Penalty
	if err := database.DB.First(&penalty, "id = ?", id).Error; err != nil {
		utils.Error(c, "Data denda tidak ditemukan")
		return
	}

	// Store info for recalculation before deleting
	userID := penalty.UserID
	t, _ := time.Parse("2006-01-02", penalty.Date)

	if err := database.DB.Delete(&penalty).Error; err != nil {
		utils.Error(c, "Gagal menghapus data denda")
		return
	}

	// Trigger payroll recalculation
	generateSalary(userID, int(t.Month()), t.Year())

	utils.Success(c, "Denda berhasil dihapus", nil)
}
