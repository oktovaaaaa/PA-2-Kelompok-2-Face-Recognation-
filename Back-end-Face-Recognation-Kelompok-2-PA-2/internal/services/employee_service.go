package services

import (
	"errors"
	"time"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/utils"

	"github.com/google/uuid"
)

func RegisterEmployee(user models.User, inviteToken string) error {

	var invite models.InviteToken

	err := database.DB.Where("token = ?", inviteToken).First(&invite).Error

	if err != nil {
		return errors.New("INVALID_BARCODE")
	}

	if invite.Status == "USED" {
		return errors.New("BARCODE_ALREADY_USED")
	}

	if time.Now().After(invite.ExpiresAt) {
		invite.Status = "EXPIRED"
		database.DB.Save(&invite)
		return errors.New("BARCODE_EXPIRED")
	}

	var existing models.User
	database.DB.Where("email = ?", user.Email).First(&existing)
	if existing.ID != "" {
		return errors.New("EMAIL_ALREADY_REGISTERED")
	}

	hashPassword, _ := utils.HashPassword(user.Password)
	hashPin, _ := utils.HashPin(user.Pin)

	user.ID = uuid.New().String()
	user.CompanyID = invite.CompanyID
	user.Password = hashPassword
	user.Pin = hashPin
	user.Status = "PENDING"
	user.Role = "EMPLOYEE"

	err = database.DB.Create(&user).Error

	if err != nil {
		return err
	}

	invite.Status = "USED"
	database.DB.Save(&invite)

	return nil
}
