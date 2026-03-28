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

	api := r.Group("/api")

	{
		api.GET("/health", func(c *gin.Context) {

			utils.Success(c, "Server berjalan", nil)

		})

		api.POST("/auth/register-admin", handlers.RegisterAdmin)
	}

	api.POST("/auth/send-otp", handlers.SendOTP)
	api.POST("/auth/verify-otp", handlers.VerifyOTP)
	api.POST("/auth/login", handlers.Login)
	api.POST("/auth/verify-login-otp", handlers.VerifyLoginOTP)
	api.POST("/auth/validate-invite", handlers.ValidateInvite)
	api.POST("/auth/google-login", handlers.GoogleLogin)
	api.POST("/auth/register-employee", handlers.RegisterEmployee)
	api.POST("/auth/login-pin", handlers.LoginPin)

	// Protected Admin Routes
	admin := api.Group("/admin")
	admin.Use(middleware.AuthMiddleware(), middleware.AdminOnlyMiddleware())
	{
		admin.POST("/generate-invite", handlers.GenerateInvite)
		admin.GET("/pending-employees", handlers.GetPendingEmployees)
		admin.POST("/approve-employee", handlers.ApproveEmployee)
		admin.POST("/reject-employee", handlers.RejectEmployee)
		admin.GET("/users", handlers.GetAllUsers)
		admin.POST("/reset-device", handlers.ResetDeviceBinding)

		admin.POST("/company", handlers.UpdateCompanySettings)
		admin.GET("/company", handlers.GetCompanySettings)
	}

	return r
}
