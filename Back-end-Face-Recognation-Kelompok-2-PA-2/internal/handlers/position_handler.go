// internal/handlers/position_handler.go

package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// CreatePosition — admin membuat jabatan baru
func CreatePosition(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var body struct {
		Name   string  `json:"name"`
		Salary float64 `json:"salary"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.Name == "" {
		utils.Error(c, "Data jabatan tidak valid")
		return
	}

	position := models.Position{
		ID:        uuid.New().String(),
		CompanyID: adminUser.CompanyID,
		Name:      body.Name,
		Salary:    body.Salary,
	}
	if err := database.DB.Create(&position).Error; err != nil {
		utils.Error(c, "Gagal membuat jabatan")
		return
	}
	utils.Success(c, "Jabatan berhasil dibuat", position)
}

// GetPositions — list semua jabatan perusahaan
func GetPositions(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var positions []models.Position
	database.DB.Where("company_id = ?", adminUser.CompanyID).Find(&positions)
	utils.Success(c, "Daftar jabatan", positions)
}

// UpdatePosition — edit nama/gaji jabatan
func UpdatePosition(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	id := c.Param("id")
	var body struct {
		Name   string  `json:"name"`
		Salary float64 `json:"salary"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	var position models.Position
	if err := database.DB.Where("id = ? AND company_id = ?", id, adminUser.CompanyID).First(&position).Error; err != nil {
		utils.Error(c, "Jabatan tidak ditemukan")
		return
	}

	position.Name = body.Name
	position.Salary = body.Salary
	database.DB.Save(&position)
	utils.Success(c, "Jabatan berhasil diperbarui", position)
}

// DeletePosition — hapus jabatan (hanya jika tidak ada karyawan di jabatan ini)
func DeletePosition(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	id := c.Param("id")

	var position models.Position
	if err := database.DB.Where("id = ? AND company_id = ?", id, adminUser.CompanyID).First(&position).Error; err != nil {
		utils.Error(c, "Jabatan tidak ditemukan")
		return
	}

	// Cek apakah ada karyawan dengan jabatan ini
	var count int64
	database.DB.Model(&models.User{}).Where("position_id = ? AND company_id = ?", id, adminUser.CompanyID).Count(&count)
	if count > 0 {
		utils.Error(c, "Jabatan masih digunakan oleh karyawan, tidak dapat dihapus")
		return
	}

	database.DB.Delete(&position)
	utils.Success(c, "Jabatan berhasil dihapus", nil)
}

// AssignPosition — assign jabatan ke karyawan
func AssignPosition(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	var body struct {
		UserID     string `json:"user_id"`
		PositionID string `json:"position_id"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	// Validasi karyawan milik perusahaan ini
	var employee models.User
	if err := database.DB.Where("id = ? AND company_id = ?", body.UserID, adminUser.CompanyID).First(&employee).Error; err != nil {
		utils.Error(c, "Karyawan tidak ditemukan")
		return
	}

	// Validasi jabatan milik perusahaan ini (boleh kosong untuk unassign)
	if body.PositionID != "" {
		var position models.Position
		if err := database.DB.Where("id = ? AND company_id = ?", body.PositionID, adminUser.CompanyID).First(&position).Error; err != nil {
			utils.Error(c, "Jabatan tidak ditemukan")
			return
		}
	}

	employee.PositionID = body.PositionID
	database.DB.Save(&employee)
	utils.Success(c, "Jabatan karyawan berhasil diperbarui", nil)
}
