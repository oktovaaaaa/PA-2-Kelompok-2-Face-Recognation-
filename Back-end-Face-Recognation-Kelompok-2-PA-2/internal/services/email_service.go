// internal/services/email_service.go

package services

import (
	"fmt"
	"os"

	gomail "gopkg.in/gomail.v2"
)

func SendOTPEmail(email string, otp string) error {

	m := gomail.NewMessage()

	m.SetHeader("From", os.Getenv("SMTP_EMAIL"))
	m.SetHeader("To", email)
	m.SetHeader("Subject", "Kode OTP Aplikasi")

	body := fmt.Sprintf(
		"Kode OTP Anda adalah %s\nKode berlaku selama 5 menit.",
		otp,
	)

	m.SetBody("text/plain", body)

	d := gomail.NewDialer(
		os.Getenv("SMTP_HOST"),
		587,
		os.Getenv("SMTP_EMAIL"),
		os.Getenv("SMTP_PASSWORD"),
	)

	return d.DialAndSend(m)
}