// internal /services/ qrcode_service.go
package services

import (
	"encoding/base64"

	"github.com/skip2/go-qrcode"
)

func GenerateQRCode(data string) (string, error) {

	png, err := qrcode.Encode(data, qrcode.Medium, 256)

	if err != nil {
		return "", err
	}

	base64Image := base64.StdEncoding.EncodeToString(png)

	return base64Image, nil
}