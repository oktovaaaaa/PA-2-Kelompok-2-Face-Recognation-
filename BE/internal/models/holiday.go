// internal/models/holiday.go

package models

import "time"

type Holiday struct {
	ID          string    `gorm:"primaryKey" json:"id"`
	CompanyID   string    `gorm:"index" json:"company_id"`
	Name        string    `json:"name"`
	Description string    `json:"description"`
	StartDate   time.Time `json:"start_date"`
	EndDate     time.Time `json:"end_date"`
	CreatedAt   time.Time `json:"created_at"`
}
