package middleware

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

func SessionTimeout() gin.HandlerFunc {

	return func(c *gin.Context) {

		lastActivity := time.Now()

		if time.Since(lastActivity) > 5*time.Minute {

			c.JSON(http.StatusUnauthorized, gin.H{
				"status": false,
				"message": "Session habis",
			})

			c.Abort()
			return
		}

		c.Next()
	}
}