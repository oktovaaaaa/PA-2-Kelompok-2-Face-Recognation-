package middleware

import (
	"strings"

	"employee-system/internal/database"
	"employee-system/internal/models"
	"employee-system/internal/services"
	"employee-system/internal/utils"

	"github.com/gin-gonic/gin"
)

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			utils.Error(c, "Unauthorized")
			c.Abort()
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		claims, err := services.ParseToken(tokenString)
		if err != nil {
			utils.Error(c, "Invalid token")
			c.Abort()
			return
		}

		userID, ok := claims["user_id"].(string)
		if !ok {
			utils.Error(c, "Invalid token claims")
			c.Abort()
			return
		}

		var user models.User
		if err := database.DB.Where("id = ?", userID).First(&user).Error; err != nil {
			utils.Error(c, "User not found")
			c.Abort()
			return
		}

		if user.Status != "ACTIVE" {
			utils.Error(c, "Account inactive")
			c.Abort()
			return
		}

		c.Set("user", user)
		c.Next()
	}
}

func AdminOnlyMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		user, exists := c.Get("user")
		if !exists {
			utils.Error(c, "Unauthorized")
			c.Abort()
			return
		}

		u := user.(models.User)
		if u.Role != "ADMIN" && u.Role != "OWNER" {
			utils.Error(c, "Access denied: Admin only")
			c.Abort()
			return
		}

		c.Next()
	}
}
