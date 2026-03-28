// internal/models/user.go

package models

import "time"

type User struct {
	ID        string `gorm:"primaryKey"`

	CompanyID string
	Company   Company `gorm:"foreignKey:CompanyID"`

	Name     string
	Email    string `gorm:"unique"`
	Password string

	Pin string

	Phone string

	BirthPlace string
	BirthDate  string
	Address    string

	Role   string
	Status string

	GoogleID string

	DeviceID string

	// For PIN lockout system
	InvalidPinAttempts int
	PinLockedUntil     *time.Time

	CreatedAt time.Time
	UpdatedAt time.Time
}