// internal/handlers/leave_handler.go

package handlers

import (
	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

// ===== ADMIN HANDLERS =====

// AdminGetLeaveRequests — admin melihat semua izin karyawan perusahaannya
// Query params: status=PENDING|APPROVED|REJECTED (opsional)
func AdminGetLeaveRequests(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	status := c.Query("status")

	var leaves []models.LeaveRequest
	query := database.DB.Where("company_id = ? AND is_deleted_by_admin = ?", adminUser.CompanyID, false)
	if status != "" {
		query = query.Where("status = ?", status)
	}
	query.Order("created_at desc").Find(&leaves)

	// Attach user info
	type LeaveWithUser struct {
		models.LeaveRequest
		UserName  string `json:"user_name"`
		UserEmail string `json:"user_email"`
		UserPhoto string `json:"user_photo"`
	}
	var result []LeaveWithUser
	for _, l := range leaves {
		var user models.User
		database.DB.Select("name, email, photo_url").Where("id = ?", l.UserID).First(&user)
		result = append(result, LeaveWithUser{
			LeaveRequest: l,
			UserName:     user.Name,
			UserEmail:    user.Email,
			UserPhoto:    user.PhotoURL,
		})
	}

	utils.Success(c, "Daftar izin karyawan", result)
}

// ApproveLeave — admin menyetujui izin karyawan
func ApproveLeave(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	id := c.Param("id")
	var body struct {
		Note string `json:"note"`
	}
	c.ShouldBindJSON(&body)

	var leave models.LeaveRequest
	if err := database.DB.Where("id = ? AND company_id = ?", id, adminUser.CompanyID).First(&leave).Error; err != nil {
		utils.Error(c, "Izin tidak ditemukan")
		return
	}
	if leave.Status != "PENDING" {
		utils.Error(c, "Izin sudah diproses sebelumnya")
		return
	}

	leave.Status = "APPROVED"
	leave.AdminNote = body.Note
	database.DB.Save(&leave)

	// Tandai hari kehadiran dengan status LEAVE/SICK
	attendanceStatus := "LEAVE"
	if leave.Type == "SAKIT" {
		attendanceStatus = "SICK"
	}
	upsertAttendance(leave.UserID, adminUser.CompanyID, leave.CreatedAt.Format("2006-01-02"), attendanceStatus)

	// Kirim notifikasi ke karyawan
	services.CreateNotification(leave.UserID, adminUser.CompanyID, "Izin Disetujui",
		"Izin kamu telah disetujui oleh admin.", "LEAVE_APPROVED", leave.ID)
	services.SendPushNotification(leave.UserID, "Izin Disetujui", "Izin kamu telah disetujui oleh admin.")

	utils.Success(c, "Izin berhasil disetujui", nil)
}

// RejectLeave — admin menolak izin karyawan
func RejectLeave(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	id := c.Param("id")
	var body struct {
		Note string `json:"note"`
	}
	c.ShouldBindJSON(&body)

	var leave models.LeaveRequest
	if err := database.DB.Where("id = ? AND company_id = ?", id, adminUser.CompanyID).First(&leave).Error; err != nil {
		utils.Error(c, "Izin tidak ditemukan")
		return
	}
	if leave.Status != "PENDING" {
		utils.Error(c, "Izin sudah diproses sebelumnya")
		return
	}

	leave.Status = "REJECTED"
	leave.AdminNote = body.Note
	database.DB.Save(&leave)

	// Kirim notifikasi ke karyawan
	services.CreateNotification(leave.UserID, adminUser.CompanyID, "Izin Ditolak",
		"Izin kamu ditolak oleh admin. "+body.Note, "LEAVE_REJECTED", leave.ID)
	services.SendPushNotification(leave.UserID, "Izin Ditolak", "Izin kamu ditolak oleh admin.")

	utils.Success(c, "Izin berhasil ditolak", nil)
}

// AdminDeleteLeave — admin menghapus izin (soft-delete sisi admin)
func AdminDeleteLeave(c *gin.Context) {
	userCtx, _ := c.Get("user")
	adminUser := userCtx.(models.User)

	id := c.Param("id")
	var leave models.LeaveRequest
	if err := database.DB.Where("id = ? AND company_id = ?", id, adminUser.CompanyID).First(&leave).Error; err != nil {
		utils.Error(c, "Izin tidak ditemukan")
		return
	}

	leave.IsDeletedByAdmin = true
	database.DB.Save(&leave)

	// Hapus permanen jika kedua pihak sudah menghapus
	if leave.IsDeletedByEmployee {
		database.DB.Delete(&leave)
	}

	utils.Success(c, "Izin dihapus", nil)
}

// ===== EMPLOYEE HANDLERS =====

// EmployeeCreateLeave — karyawan mengajukan izin/sakit
func EmployeeCreateLeave(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	var body struct {
		Type            string `json:"type"`
		Title           string `json:"title"`
		Description     string `json:"description"`
		PhotoURL        string `json:"photo_url"`
		ConfirmedHonest bool   `json:"confirmed_honest"`
	}
	if err := c.ShouldBindJSON(&body); err != nil || body.Title == "" || body.Type == "" {
		utils.Error(c, "Data izin tidak lengkap")
		return
	}
	if !body.ConfirmedHonest {
		utils.Error(c, "Kamu harus mengkonfirmasi kejujuran data izin")
		return
	}
	if body.Type != "IZIN" && body.Type != "SAKIT" {
		utils.Error(c, "Tipe izin tidak valid (IZIN / SAKIT)")
		return
	}

	leave := models.LeaveRequest{
		ID:              uuid.New().String(),
		UserID:          emp.ID,
		CompanyID:       emp.CompanyID,
		Type:            body.Type,
		Title:           body.Title,
		Description:     body.Description,
		PhotoURL:        body.PhotoURL,
		Status:          "PENDING",
		ConfirmedHonest: body.ConfirmedHonest,
	}
	if err := database.DB.Create(&leave).Error; err != nil {
		utils.Error(c, "Gagal membuat izin")
		return
	}

	// Cari admin perusahaan ini untuk kirim notifikasi
	var admin models.User
	if err := database.DB.Where("company_id = ? AND role = ?", emp.CompanyID, "admin").First(&admin).Error; err == nil {
		services.CreateNotification(admin.ID, emp.CompanyID, "Pengajuan Izin Baru",
			emp.Name+" mengajukan "+body.Type+": "+body.Title, "LEAVE_REQUEST", leave.ID)
		services.SendPushNotification(admin.ID, "Pengajuan Izin Baru",
			emp.Name+" mengajukan "+body.Type+": "+body.Title)
	}

	utils.Success(c, "Izin berhasil diajukan", leave)
}

// EmployeeUpdateLeave — edit izin (hanya jika masih PENDING)
func EmployeeUpdateLeave(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	id := c.Param("id")
	var body struct {
		Title       string `json:"title"`
		Description string `json:"description"`
		PhotoURL    string `json:"photo_url"`
	}
	if err := c.ShouldBindJSON(&body); err != nil {
		utils.Error(c, "Data tidak valid")
		return
	}

	var leave models.LeaveRequest
	if err := database.DB.Where("id = ? AND user_id = ?", id, emp.ID).First(&leave).Error; err != nil {
		utils.Error(c, "Izin tidak ditemukan")
		return
	}
	if leave.Status != "PENDING" {
		utils.Error(c, "Izin yang sudah diproses tidak bisa diedit")
		return
	}

	leave.Title = body.Title
	leave.Description = body.Description
	if body.PhotoURL != "" {
		leave.PhotoURL = body.PhotoURL
	}
	database.DB.Save(&leave)
	utils.Success(c, "Izin berhasil diperbarui", leave)
}

// EmployeeDeleteLeave — soft-delete dari sisi karyawan
func EmployeeDeleteLeave(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	id := c.Param("id")
	var leave models.LeaveRequest
	if err := database.DB.Where("id = ? AND user_id = ?", id, emp.ID).First(&leave).Error; err != nil {
		utils.Error(c, "Izin tidak ditemukan")
		return
	}

	leave.IsDeletedByEmployee = true
	database.DB.Save(&leave)

	// Hapus permanen jika kedua pihak sudah menghapus
	if leave.IsDeletedByAdmin {
		database.DB.Delete(&leave)
	}
	utils.Success(c, "Izin dihapus dari riwayat kamu", nil)
}

// EmployeeGetLeaves — list izin milik karyawan sendiri
func EmployeeGetLeaves(c *gin.Context) {
	userCtx, _ := c.Get("user")
	emp := userCtx.(models.User)

	var leaves []models.LeaveRequest
	database.DB.Where("user_id = ? AND is_deleted_by_employee = ?", emp.ID, false).
		Order("created_at desc").Find(&leaves)
	utils.Success(c, "Daftar izin kamu", leaves)
}

// helper: buat atau update record attendance untuk karyawan pada tanggal tertentu
func upsertAttendance(userID, companyID, date, status string) {
	var att models.Attendance
	err := database.DB.Where("user_id = ? AND date = ?", userID, date).First(&att).Error
	if err != nil {
		// Buat baru
		att = models.Attendance{
			ID:        uuid.New().String(),
			UserID:    userID,
			CompanyID: companyID,
			Date:      date,
			Status:    status,
		}
		database.DB.Create(&att)
	} else {
		att.Status = status
		database.DB.Save(&att)
	}
}
