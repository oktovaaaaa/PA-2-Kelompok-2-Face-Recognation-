// internal/utils/response.go

package utils

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func Success(c *gin.Context, message string, data interface{}) {

	c.JSON(http.StatusOK, gin.H{
		"status":  true,
		"message": message,
		"data":    data,
	})
}

func Error(c *gin.Context, message string) {

	c.JSON(http.StatusBadRequest, gin.H{
		"status":  false,
		"message": message,
	})
}