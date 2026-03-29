// internal/services/fcm_service.go
//
// Implementasi Firebase Cloud Messaging (FCM) HTTP v1 API.
// Saat ini menggunakan Legacy HTTP API sebagai fallback jika belum ada Service Account.
// Setelah google-services.json tersedia, ganti SERVER_KEY dengan key yang valid
// atau upgrade ke FCM HTTP v1 dengan service account credentials.

package services

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"employee-system/internal/database"
	"employee-system/internal/models"
)

const fcmLegacyURL = "https://fcm.googleapis.com/fcm/send"

type fcmPayload struct {
	To           string            `json:"to"`
	Notification fcmNotification   `json:"notification"`
	Data         map[string]string `json:"data,omitempty"`
}

type fcmNotification struct {
	Title string `json:"title"`
	Body  string `json:"body"`
	Sound string `json:"sound"`
}

// SendPushNotification mengirim push notification ke karyawan/admin berdasarkan userID.
// Mengambil FCM token dari database secara otomatis.
// Jika FCM_SERVER_KEY belum diset di .env, fungsi ini akan skip dengan aman.
func SendPushNotification(userID, title, body string) {
	serverKey := os.Getenv("FCM_SERVER_KEY")
	if serverKey == "" {
		// FCM belum dikonfigurasi, skip tanpa error
		fmt.Println("[FCM] FCM_SERVER_KEY belum diset, notifikasi push dilewati")
		return
	}

	// Ambil FCM token dari database
	var user models.User
	if err := database.DB.Select("fcm_token").Where("id = ?", userID).First(&user).Error; err != nil {
		fmt.Printf("[FCM] User %s tidak ditemukan\n", userID)
		return
	}
	if user.FcmToken == "" {
		fmt.Printf("[FCM] User %s tidak memiliki FCM token\n", userID)
		return
	}

	payload := fcmPayload{
		To: user.FcmToken,
		Notification: fcmNotification{
			Title: title,
			Body:  body,
			Sound: "default",
		},
		Data: map[string]string{
			"click_action": "FLUTTER_NOTIFICATION_CLICK",
		},
	}

	jsonData, err := json.Marshal(payload)
	if err != nil {
		fmt.Printf("[FCM] Gagal marshal payload: %v\n", err)
		return
	}

	req, err := http.NewRequest("POST", fcmLegacyURL, bytes.NewBuffer(jsonData))
	if err != nil {
		fmt.Printf("[FCM] Gagal membuat request: %v\n", err)
		return
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "key="+serverKey)

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		fmt.Printf("[FCM] Gagal mengirim notifikasi: %v\n", err)
		return
	}
	defer resp.Body.Close()

	fmt.Printf("[FCM] Notifikasi dikirim ke %s, status: %d\n", userID, resp.StatusCode)
}
