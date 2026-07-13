package main

import (
	"log"
	"net/http"
	"os"
	"strings"

	"smart-city-backend/internal/auth"
	"smart-city-backend/internal/complaint"
	"smart-city-backend/internal/db"
	"smart-city-backend/internal/staff"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/joho/godotenv"
)

func main() {
	if err := godotenv.Load("../../.env"); err != nil {
		log.Println("No .env file found, using defaults")
	}

	db.InitDB()
	staff.StartEscalationJob()

	r := gin.Default()

	// Public routes
	r.GET("/api/auth/captcha", auth.GetCaptcha)
	r.POST("/api/auth/send-otp", auth.SendOTP)
	r.POST("/api/auth/verify-otp", auth.VerifyOTP)

	// Protected routes
	api := r.Group("/api")
	api.Use(AuthMiddleware())

	// Citizen routes
	api.POST("/citizen/complaints", complaint.RaiseComplaint)
	api.GET("/citizen/my-complaints", complaint.GetMyComplaints)

	// Staff routes
	api.GET("/field-officer/work-orders", staff.GetWorkOrders)
	api.POST("/field-officer/work-order/:id/action", staff.ActionWorkOrder)
	api.GET("/field-officer/todo", staff.GetTodoList)
	api.POST("/field-officer/todo/:id/complete", staff.CompleteTask)
	api.POST("/field-officer/work-order/:id/navigate", staff.TrackNavigation)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server starting on port %s", port)
	r.Run(":" + port)
}

func AuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Authorization header required"})
			c.Abort()
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || parts[0] != "Bearer" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid authorization format"})
			c.Abort()
			return
		}

		tokenString := parts[1]
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			return []byte(os.Getenv("JWT_SECRET")), nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired token"})
			c.Abort()
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid token claims"})
			c.Abort()
			return
		}

		userID := int(claims["user_id"].(float64))
		role := claims["role"].(string)

		c.Set("user_id", userID)
		c.Set("role", role)
		c.Next()
	}
}
