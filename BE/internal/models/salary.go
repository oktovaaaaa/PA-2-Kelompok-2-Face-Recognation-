// internal/models/salary.go

package models

import "time"

type Salary struct {
	ID        string    `gorm:"primaryKey" json:"id"`
	UserID    string    `gorm:"index" json:"user_id"`
	User      User      `gorm:"foreignKey:UserID" json:"user"`
	
	Month     int       `json:"month"` // 1-12
	Year      int       `json:"year"`
	
	BaseSalary   float64 `json:"base_salary"`
	Deductions   float64 `json:"deductions"`
	TotalSalary  float64 `json:"total_salary"`
	
	Status       string    `json:"status"` // PENDING | PAID
	PaymentProof string    `json:"payment_proof"` // URL/Path foto bukti
	PaidAt       *time.Time `json:"paid_at"`
	
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
