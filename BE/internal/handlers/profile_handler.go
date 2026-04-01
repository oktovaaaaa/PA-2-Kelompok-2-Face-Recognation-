// internal/handlers/profile_handler.go

package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
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
		Salary            float64 `json:"salary"`
		CompanyID         string  `json:"company_id"`
		BankName          string  `json:"bank_name"`
		BankAccountNumber string  `json:"bank_account_number"`
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
		PositionID:         "",
		CompanyID:          user.CompanyID,
		BankName:           user.BankName,
		BankAccountNumber:  user.BankAccountNumber,
	}

	if user.PositionID != nil {
		resp.PositionID = *user.PositionID
		var pos models.Position
		if err := database.DB.Where("id = ?", *user.PositionID).First(&pos).Error; err == nil {
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
		Address           string `json:"address"`
		PhotoURL          string `json:"photo_url"`
		BankName          string `json:"bank_name"`
		BankAccountNumber string `json:"bank_account_number"`
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
	dbUser.BankName = body.BankName
	dbUser.BankAccountNumber = body.BankAccountNumber

	database.DB.Save(&dbUser)
	utils.Success(c, "Profil berhasil diperbarui", gin.H{
		"name":        dbUser.Name,
		"phone":       dbUser.Phone,
		"birth_place": dbUser.BirthPlace,
		"birth_date":  dbUser.BirthDate,
		"address":             dbUser.Address,
		"photo_url":           dbUser.PhotoURL,
		"bank_name":           dbUser.BankName,
		"bank_account_number": dbUser.BankAccountNumber,
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

// RequestProfileOTP — kirim OTP ke email user yang sedang login untuk verifikasi ubah password/pin
func RequestProfileOTP(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	code, err := services.GenerateOTP(user.Email)
	if err != nil {
		utils.Error(c, "Gagal membuat OTP: "+err.Error())
		return
	}

	services.SendOTPEmail(user.Email, code)
	utils.Success(c, "OTP berhasil dikirim ke email Anda", nil)
}

// ChangePassword — ubah password sendiri (verifikasi Password Lama ATAU OTP)
func ChangePassword(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	var body struct {
		OldPassword string `json:"old_password"`
		OtpCode     string `json:"otp_code"`
		NewPassword string `json:"new_password"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	if body.NewPassword == "" {
		utils.Error(c, "Password baru wajib diisi")
		return
	}

	// 1. Verifikasi Identitas
	verified := false

	// Cek Password Lama (jika diisi)
	if body.OldPassword != "" {
		if utils.CheckPassword(user.Password, body.OldPassword) {
			verified = true
		} else {
			utils.Error(c, "Password lama salah")
			return
		}
	}

	// Cek OTP (jika diisi dan belum terverifikasi lewat password lama)
	if !verified && body.OtpCode != "" {
		if err := services.VerifyOTP(user.Email, body.OtpCode); err == nil {
			verified = true
		} else {
			utils.Error(c, "Kode OTP tidak valid atau kedaluwarsa")
			return
		}
	}

	if !verified {
		utils.Error(c, "Harap masukkan password lama atau kode OTP untuk verifikasi")
		return
	}

	// 2. Update Password Baru
	hash, _ := utils.HashPassword(body.NewPassword)
	if err := database.DB.Model(&models.User{}).Where("id = ?", user.ID).Update("password", hash).Error; err != nil {
		utils.Error(c, "Gagal memperbarui password")
		return
	}

	utils.Success(c, "Password berhasil diperbarui", nil)
}

// ChangePin — ubah PIN sendiri (verifikasi PIN Lama ATAU OTP)
func ChangePin(c *gin.Context) {
	userCtx, _ := c.Get("user")
	user := userCtx.(models.User)

	var body struct {
		OldPin  string `json:"old_pin"`
		OtpCode string `json:"otp_code"`
		NewPin  string `json:"new_pin"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	if body.NewPin == "" || len(body.NewPin) != 6 {
		utils.Error(c, "PIN baru harus 6 digit angka")
		return
	}

	// 1. Verifikasi Identitas
	verified := false

	// Cek PIN Lama (jika diisi)
	if body.OldPin != "" {
		if utils.CheckPin(user.Pin, body.OldPin) {
			verified = true
		} else {
			utils.Error(c, "PIN lama salah")
			return
		}
	}

	// Cek OTP (jika diisi dan belum terverifikasi lewat PIN lama)
	if !verified && body.OtpCode != "" {
		if err := services.VerifyOTP(user.Email, body.OtpCode); err == nil {
			verified = true
		} else {
			utils.Error(c, "Kode OTP tidak valid atau kedaluwarsa")
			return
		}
	}

	if !verified {
		utils.Error(c, "Harap masukkan PIN lama atau kode OTP untuk verifikasi")
		return
	}

	// 2. Update PIN Baru
	hash, _ := utils.HashPin(body.NewPin)
	if err := database.DB.Model(&models.User{}).Where("id = ?", user.ID).Update("pin", hash).Error; err != nil {
		utils.Error(c, "Gagal memperbarui PIN")
		return
	}

	utils.Success(c, "PIN berhasil diperbarui", nil)
}
