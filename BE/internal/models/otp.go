// internal / models / otp.go
package models

import "time"

type OTP struct {
	ID        string `gorm:"primaryKey"`
	Email     string
	Code      string
	Type      string
	Used      bool
	ExpiresAt time.Time
	CreatedAt time.Time
}