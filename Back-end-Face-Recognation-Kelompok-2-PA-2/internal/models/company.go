// internal/models/company.go

package models

import "time"

type Company struct {
	ID        string    `gorm:"primaryKey"`
	Name      string
	Address   string
	Email     string
	Phone     string
	CreatedAt time.Time
}