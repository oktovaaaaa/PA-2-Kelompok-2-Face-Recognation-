// internal/config/config.go

package config

import (
	"log"

	"github.com/joho/godotenv"
)

func LoadEnv() {

	err := godotenv.Load()

	if err != nil {
		log.Println("File .env tidak ditemukan, menggunakan environment sistem")
	}
}