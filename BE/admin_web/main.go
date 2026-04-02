package main

import (
	"fmt"
	"os"

	"employee-system/internal/config"
	"employee-system/internal/database"
	"employee-system/routes"

	"github.com/gin-gonic/gin"
)

func main() {
	// 1. Load config & koneksi database
	config.LoadEnv()
	database.ConnectDatabase()

	// 2. Gunakan SetupRouter yang sudah ada agar semua API otomatis terbawa
	app := routes.SetupRouter()

	// 3. Konfigurasi Statis & Template (Relatif terhadap folder BE)
	app.Static("/static", "admin_web/static")
	app.LoadHTMLGlob("admin_web/templates/**/*.html")

	// 4. Redirect root ke login
	app.GET("/", func(c *gin.Context) {
		c.Redirect(302, "/admin-web/login")
	})

	// 5. Grup Rute Web Admin
	web := app.Group("/admin-web")
	{
		web.GET("/login", func(c *gin.Context) {
			c.HTML(200, "login.html", gin.H{"title": "Login Admin"})
		})
		web.GET("/dashboard", func(c *gin.Context) {
			c.HTML(200, "dashboard.html", gin.H{"title": "Beranda", "active": "dashboard"})
		})
		web.GET("/leaves", func(c *gin.Context) {
			c.HTML(200, "leaves.html", gin.H{"title": "Perizinan", "active": "leaves"})
		})
		web.GET("/employees", func(c *gin.Context) {
			c.HTML(200, "employees.html", gin.H{"title": "Daftar Karyawan", "active": "employees"})
		})
		web.GET("/employees/pending", func(c *gin.Context) {
			c.HTML(200, "pending_employees.html", gin.H{"title": "Karyawan Pending", "active": "employees"})
		})
		web.GET("/payroll", func(c *gin.Context) {
			c.HTML(200, "payroll.html", gin.H{"title": "Manajemen Gaji", "active": "payroll"})
		})
		web.GET("/positions", func(c *gin.Context) {
			c.HTML(200, "positions.html", gin.H{"title": "Manajemen Jabatan", "active": "positions"})
		})
		web.GET("/holidays", func(c *gin.Context) {
			c.HTML(200, "holidays.html", gin.H{"title": "Hari Libur", "active": "holidays"})
		})
		web.GET("/penalties", func(c *gin.Context) {
			c.HTML(200, "penalties.html", gin.H{"title": "Denda", "active": "penalties"})
		})
		web.GET("/attendance-report", func(c *gin.Context) {
			c.HTML(200, "attendance_report.html", gin.H{"title": "Laporan Absensi", "active": "attendance"})
		})
		web.GET("/settings", func(c *gin.Context) {
			c.HTML(200, "settings.html", gin.H{"title": "Pengaturan", "active": "settings"})
		})
	}

	// 6. Jalankan server
	port := os.Getenv("APP_PORT")
	if port == "" {
		port = "8080"
	}

	fmt.Println("Admin Web Dashboard aktif di: http://localhost:" + port + "/admin-web/login")
	app.Run(":" + port)
}
