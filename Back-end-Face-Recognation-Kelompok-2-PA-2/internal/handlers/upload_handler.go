// internal/handlers/upload_handler.go

package handlers

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strings"
	"time"

	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// UploadFile — upload foto (profil/izin/logo perusahaan)
// Form field: "file"
// Returns: { "url": "/uploads/xxx.jpg" }
func UploadFile(c *gin.Context) {
	file, header, err := c.Request.FormFile("file")
	if err != nil {
		utils.Error(c, "File tidak ditemukan dalam request")
		return
	}
	defer file.Close()

	// Validasi ekstensi
	ext := strings.ToLower(filepath.Ext(header.Filename))
	allowed := map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".webp": true}
	if !allowed[ext] {
		utils.Error(c, "Hanya file gambar yang diizinkan (jpg, jpeg, png, webp)")
		return
	}

	// Validasi ukuran (maks 5MB)
	if header.Size > 5*1024*1024 {
		utils.Error(c, "Ukuran file maksimal 5MB")
		return
	}

	// Buat folder uploads jika belum ada
	uploadDir := "./uploads"
	if err := os.MkdirAll(uploadDir, 0755); err != nil {
		utils.Error(c, "Gagal membuat direktori upload")
		return
	}

	// Generate nama file unik
	filename := fmt.Sprintf("%s_%d%s", uuid.New().String(), time.Now().UnixMilli(), ext)
	savePath := filepath.Join(uploadDir, filename)

	// Simpan file
	if err := c.SaveUploadedFile(header, savePath); err != nil {
		utils.Error(c, "Gagal menyimpan file")
		return
	}

	// URL yang bisa diakses client
	fileURL := "/uploads/" + filename
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"message": "File berhasil diupload",
		"data": gin.H{
			"url": fileURL,
		},
	})
}
