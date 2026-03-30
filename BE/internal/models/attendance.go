// internal/models/attendance.go

package models

import "time"

// Attendance menyimpan data kehadiran harian karyawan.
// SalaryDeduction menyimpan potongan gaji per individu saat alpha — tidak mengubah gaji pokok jabatan.
type Attendance struct {
	ID        string `gorm:"primaryKey" json:"id"`
	UserID    string `gorm:"index" json:"user_id"`
	CompanyID string `gorm:"index" json:"company_id"`

	Date string `json:"date"` // format "YYYY-MM-DD"

	CheckInTime  *time.Time `json:"check_in_time"`
	CheckOutTime *time.Time `json:"check_out_time"`

	// PRESENT | ABSENT | LEAVE | SICK
	Status string `json:"status"`

	// Potongan gaji untuk karyawan ini pada hari ini (jika alpha)
	SalaryDeduction float64 `json:"salary_deduction"`

	Notes string `json:"notes"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

