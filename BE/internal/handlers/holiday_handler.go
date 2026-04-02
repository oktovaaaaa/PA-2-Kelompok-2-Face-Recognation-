// internal/handlers/holiday_handler.go

package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CreateHoliday — admin membuat hari libur (bisa range)
func CreateHoliday(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var body struct {
		Name        string `json:"name"`
		Description string `json:"description"`
		StartDate   string `json:"start_date"` // format: YYYY-MM-DD
		EndDate     string `json:"end_date"`   // format: YYYY-MM-DD
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	start, err := time.Parse("2006-01-02", body.StartDate)
	if err != nil {
		utils.Error(c, "Format tanggal mulai tidak valid (YYYY-MM-DD)")
		return
	}

	end, err := time.Parse("2006-01-02", body.EndDate)
	if err != nil {
		utils.Error(c, "Format tanggal selesai tidak valid (YYYY-MM-DD)")
		return
	}

	if end.Before(start) {
		utils.Error(c, "Tanggal selesai tidak boleh sebelum tanggal mulai")
		return
	}

	holiday := models.Holiday{
		ID:          uuid.New().String(),
		CompanyID:   adminUser.CompanyID,
		Name:        body.Name,
		Description: body.Description,
		StartDate:   start,
		EndDate:     end,
		CreatedAt:   time.Now(),
	}

	if err := database.DB.Create(&holiday).Error; err != nil {
		utils.Error(c, "Gagal menyimpan hari libur")
		return
	}

	utils.Success(c, "Hari libur berhasil dibuat", holiday)
}

// GetHolidays — list semua hari libur perusahaan
func GetHolidays(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var holidays []models.Holiday
	database.DB.Where("company_id = ?", adminUser.CompanyID).Order("start_date DESC").Find(&holidays)

	utils.Success(c, "Daftar hari libur", holidays)
}

// UpdateHoliday — edit hari libur
func UpdateHoliday(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	id := c.Param("id")
	var body struct {
		Name        string `json:"name"`
		Description string `json:"description"`
		StartDate   string `json:"start_date"`
		EndDate     string `json:"end_date"`
	}

	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	var holiday models.Holiday
	if err := database.DB.Where("id = ? AND company_id = ?", id, adminUser.CompanyID).First(&holiday).Error; err != nil {
		utils.Error(c, "Hari libur tidak ditemukan")
		return
	}

	start, _ := time.Parse("2006-01-02", body.StartDate)
	end, _ := time.Parse("2006-01-02", body.EndDate)

	holiday.Name = body.Name
	holiday.Description = body.Description
	holiday.StartDate = start
	holiday.EndDate = end

	database.DB.Save(&holiday)
	utils.Success(c, "Hari libur berhasil diperbarui", holiday)
}

// DeletePastHolidays — hapus semua hari libur yang sudah lewat (EndDate < today)
func DeletePastHolidays(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	today := time.Now().Format("2006-01-02")
	if err := database.DB.Where("company_id = ? AND end_date < ?", adminUser.CompanyID, today).Delete(&models.Holiday{}).Error; err != nil {
		utils.Error(c, "Gagal menghapus riwayat hari libur")
		return
	}

	utils.Success(c, "Semua riwayat hari libur berhasil dihapus", nil)
}

// DeleteHoliday — hapus/cancel hari libur
func DeleteHoliday(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	id := c.Param("id")
	if err := database.DB.Where("id = ? AND company_id = ?", id, adminUser.CompanyID).Delete(&models.Holiday{}).Error; err != nil {
		utils.Error(c, "Gagal menghapus hari libur")
		return
	}

	utils.Success(c, "Hari libur berhasil dihapus", nil)
}
