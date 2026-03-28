package services

import (
	"errors"
	"fmt"
	"math/rand"
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"github.com/google/uuid"
)

func RegisterAdmin(user models.User, company models.Company) error {
	var existing models.User

	database.DB.Where("email = ?", user.Email).First(&existing)
	if existing.ID != "" {
		return errors.New("EMAIL_ALREADY_REGISTERED")
	}

	hashPassword, _ := utils.HashPassword(user.Password)
	hashPin, _ := utils.HashPin(user.Pin)

	company.ID = uuid.New().String()
	if err := database.DB.Create(&company).Error; err != nil {
		return err
	}

	user.ID = uuid.New().String()
	user.CompanyID = company.ID
	user.Password = hashPassword
	user.Pin = hashPin
	user.Role = "ADMIN"
	user.Status = "ACTIVE"

	if err := database.DB.Create(&user).Error; err != nil {
		return err
	}

	return nil
}

func Login(email string, password string) error {
	var user models.User

	err := database.DB.Where("email = ?", email).First(&user).Error
	if err != nil {
		return errors.New("Email tidak ditemukan")
	}

	if user.Status != "ACTIVE" {
		return errors.New("Akun belum aktif")
	}

	if !utils.CheckPassword(user.Password, password) {
		return errors.New("Password salah")
	}

	return nil
}

func GenerateLoginOTP(email string) (string, error) {
	code := fmt.Sprintf("%06d", rand.Intn(999999))

	otp := models.OTP{
		ID:        uuid.New().String(),
		Email:     email,
		Code:      code,
		Type:      "LOGIN",
		Used:      false,
		ExpiresAt: time.Now().Add(5 * time.Minute),
	}

	err := database.DB.Create(&otp).Error
	return code, err
}

func GoogleAuth(email string, name string, googleID string) (models.User, error) {
	var user models.User

	err := database.DB.Where("email = ?", email).First(&user).Error
	if err == nil {
		return user, nil
	}

	user = models.User{
		ID:       uuid.New().String(),
		Name:     name,
		Email:    email,
		GoogleID: googleID,
		Status:   "ACTIVE",
		Role:     "EMPLOYEE",
	}

	err = database.DB.Create(&user).Error
	return user, err
}

func LoginWithDevice(email string, password string, deviceID string) (models.User, error) {
	var user models.User

	err := database.DB.Where("email = ?", email).First(&user).Error
	if err != nil {
		return user, errors.New("User tidak ditemukan")
	}

	if user.Status != "ACTIVE" {
		return user, errors.New("Akun belum aktif")
	}

	if !utils.CheckPassword(user.Password, password) {
		return user, errors.New("Password salah")
	}

	if user.DeviceID != "" && user.DeviceID != deviceID {
		return user, errors.New("ACCOUNT_ALREADY_ACTIVE_ON_ANOTHER_DEVICE")
	}

	if user.DeviceID == "" {
		user.DeviceID = deviceID
		database.DB.Save(&user)
	}

	return user, nil
}
