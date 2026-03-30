// internal/handlers/profile_handler.go

package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
)

// GetMyProfile — mendapatkan profil diri sendiri (admin & karyawan)
func GetMyProfile(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	type ProfileResponse struct {
		ID           string  `json:"id"`
		Name         string  `json:"name"`
		Email        string  `json:"email"`
		Phone        string  `json:"phone"`
		BirthPlace   string  `json:"birth_place"`
		BirthDate    string  `json:"birth_date"`
		Address      string  `json:"address"`
		PhotoURL     string  `json:"photo_url"`
		Role         string  `json:"role"`
		Status       string  `json:"status"`
		PositionID   string  `json:"position_id"`
		PositionName string  `json:"position_name"`
		Salary       float64 `json:"salary"`
		CompanyID    string  `json:"company_id"`
	}

	resp := ProfileResponse{
		ID:         user.ID,
		Name:       user.Name,
		Email:      user.Email,
		Phone:      user.Phone,
		BirthPlace: user.BirthPlace,
		BirthDate:  user.BirthDate,
		Address:    user.Address,
		PhotoURL:   user.PhotoURL,
		Role:       user.Role,
		Status:     user.Status,
		PositionID: user.PositionID,
		CompanyID:  user.CompanyID,
	}

	if user.PositionID != "" {
		var pos models.Position
		if err := database.DB.Where("id = ?", user.PositionID).First(&pos).Error; err == nil {
			resp.PositionName = pos.Name
			resp.Salary = pos.Salary
		}
	}

	utils.Success(c, "Profil berhasil dimuat", resp)
}

// UpdateMyProfile — edit data diri sendiri (admin & karyawan, wajib isi semua field)
func UpdateMyProfile(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	var body struct {
		Name       string `json:"name"`
		Phone      string `json:"phone"`
		BirthPlace string `json:"birth_place"`
		BirthDate  string `json:"birth_date"`
		Address    string `json:"address"`
		PhotoURL   string `json:"photo_url"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}
	if body.Name == "" || body.Phone == "" || body.Address == "" {
		utils.Error(c, "Nama, nomor telepon, dan alamat wajib diisi")
		return
	}

	var dbUser models.User
	database.DB.Where("id = ?", user.ID).First(&dbUser)

	dbUser.Name = body.Name
	dbUser.Phone = body.Phone
	dbUser.BirthPlace = body.BirthPlace
	dbUser.BirthDate = body.BirthDate
	dbUser.Address = body.Address
	if body.PhotoURL != "" {
		dbUser.PhotoURL = body.PhotoURL
	}

	database.DB.Save(&dbUser)
	utils.Success(c, "Profil berhasil diperbarui", gin.H{
		"name":        dbUser.Name,
		"phone":       dbUser.Phone,
		"birth_place": dbUser.BirthPlace,
		"birth_date":  dbUser.BirthDate,
		"address":     dbUser.Address,
		"photo_url":   dbUser.PhotoURL,
	})
}

// UpdateFcmToken — simpan FCM token karyawan/admin agar bisa terima push notification
func UpdateFcmToken(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	var body struct {
		FcmToken string `json:"fcm_token"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.FcmToken == "" {
		utils.Error(c, "FCM token tidak valid")
		return
	}

	database.DB.Model(&models.User{}).Where("id = ?", user.ID).Update("fcm_token", body.FcmToken)
	utils.Success(c, "FCM token berhasil disimpan", nil)
}
