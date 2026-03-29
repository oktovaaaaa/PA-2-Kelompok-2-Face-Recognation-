// routes/routes.go

package routes

import (
	"employee-system/internal/handlers"
	"employee-system/internal/middleware"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
)

func SetupRouter() *gin.Engine {

	r := gin.Default()

	// Serve file upload statis
	r.Static("/uploads", "./uploads")

	api := r.Group("/api")

	{
		api.GET("/health", func(c *gin.Context) {
			utils.Success(c, "Server berjalan", nil)
		})

		api.POST("/auth/register-admin", handlers.RegisterAdmin)
	}

	// Auth routes (public)
	api.POST("/auth/send-otp", handlers.SendOTP)
	api.POST("/auth/verify-otp", handlers.VerifyOTP)
	api.POST("/auth/login", handlers.Login)
	api.POST("/auth/verify-login-otp", handlers.VerifyLoginOTP)
	api.POST("/auth/validate-invite", handlers.ValidateInvite)
	api.POST("/auth/google-login", handlers.GoogleLogin)
	api.POST("/auth/register-employee", handlers.RegisterEmployee)
	api.POST("/auth/login-pin", handlers.LoginPin)

	// Protected routes (semua user yang sudah login)
	protected := api.Group("/")
	protected.Use(middleware.AuthMiddleware())
	{
		// Upload file (gambar profil, foto izin, logo perusahaan)
		protected.POST("/upload", handlers.UploadFile)

		// Profil (admin & karyawan)
		protected.GET("/profile", handlers.GetMyProfile)
		protected.PUT("/profile", handlers.UpdateMyProfile)
		protected.PUT("/profile/fcm-token", handlers.UpdateFcmToken)

		// Notifikasi (admin & karyawan)
		protected.GET("/notifications", handlers.GetNotifications)
		protected.PUT("/notifications/:id/read", handlers.MarkNotificationRead)
		protected.PUT("/notifications/read-all", handlers.MarkAllNotificationsRead)
	}

	// Protected Admin Routes
	admin := api.Group("/admin")
	admin.Use(middleware.AuthMiddleware(), middleware.AdminOnlyMiddleware())
	{
		// Undangan karyawan
		admin.POST("/generate-invite", handlers.GenerateInvite)
		admin.GET("/pending-employees", handlers.GetPendingEmployees)
		admin.POST("/approve-employee", handlers.ApproveEmployee)
		admin.POST("/reject-employee", handlers.RejectEmployee)
		admin.POST("/reset-device", handlers.ResetDeviceBinding)

		// Data perusahaan
		admin.POST("/company", handlers.UpdateCompanySettings)
		admin.GET("/company", handlers.GetCompanySettings)

		// Jabatan
		admin.POST("/positions", handlers.CreatePosition)
		admin.GET("/positions", handlers.GetPositions)
		admin.PUT("/positions/:id", handlers.UpdatePosition)
		admin.DELETE("/positions/:id", handlers.DeletePosition)
		admin.POST("/positions/assign", handlers.AssignPosition)

		// Kelola karyawan
		admin.GET("/employees", handlers.GetEmployees)
		admin.POST("/employees/fire", handlers.FireEmployee)
		admin.POST("/employees/reactivate", handlers.ReactivateEmployee)

		// Perizinan karyawan
		admin.GET("/leaves", handlers.AdminGetLeaveRequests)
		admin.PUT("/leaves/:id/approve", handlers.ApproveLeave)
		admin.PUT("/leaves/:id/reject", handlers.RejectLeave)
		admin.DELETE("/leaves/:id", handlers.AdminDeleteLeave)

		// Riwayat absensi semua karyawan
		admin.GET("/attendance", handlers.AdminGetAttendanceHistory)

		// Pengaturan absensi
		admin.GET("/attendance-settings", handlers.GetAttendanceSettings)
		admin.PUT("/attendance-settings", handlers.UpdateAttendanceSettings)
	}

	// Protected Employee Routes
	employee := api.Group("/employee")
	employee.Use(middleware.AuthMiddleware())
	{
		// Absensi
		employee.POST("/attendance/checkin", handlers.CheckIn)
		employee.POST("/attendance/checkout", handlers.CheckOut)
		employee.GET("/attendance/today", handlers.GetTodayAttendance)
		employee.GET("/attendance/history", handlers.GetMyAttendanceHistory)

		// Pengajuan izin / sakit
		employee.POST("/leaves", handlers.EmployeeCreateLeave)
		employee.GET("/leaves", handlers.EmployeeGetLeaves)
		employee.PUT("/leaves/:id", handlers.EmployeeUpdateLeave)
		employee.DELETE("/leaves/:id", handlers.EmployeeDeleteLeave)
	}

	return r
}

