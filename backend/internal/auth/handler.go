package auth

import (
	"net/http"
	"time"
	"math/rand"
	"fmt"

	"smart-city-backend/internal/db"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"os"
)

type OTPRequest struct {
	Phone        string `json:"phone" binding:"required"`
	CaptchaID    int    `json:"captcha_id"`
	CaptchaValue string `json:"captcha_value"`
}

type OTPVerifyRequest struct {
	Phone string `json:"phone" binding:"required"`
	Code  string `json:"code" binding:"required"`
}

func SendOTP(c *gin.Context) {
	var req OTPRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "phone is required"})
		return
	}

	// Basic Captcha Verification (if provided)
	if req.CaptchaID > 0 {
		var validCode string
		err := db.DB.QueryRow("SELECT captcha_code FROM captcha WHERE captcha_id = $1 AND expires_at > $2",
			req.CaptchaID, time.Now()).Scan(&validCode)
		if err == nil && validCode != req.CaptchaValue {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invalid captcha"})
			return
		}
	}

	// Generate 6-digit OTP
	rand.Seed(time.Now().UnixNano())
	code := fmt.Sprintf("%06d", rand.Intn(1000000))

	// Store OTP in database with 5-min expiry
	_, err := db.DB.Exec("INSERT INTO otp_verification (phone_number, otp_code, expires_at) VALUES ($1, $2, NOW() + INTERVAL '5 minutes')",
		req.Phone, code)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to store OTP"})
		return
	}

	fmt.Printf("\n--- GENERATED OTP FOR %s: %s ---\n", req.Phone, code)

	// In a real app, you would send this via SMS API. For now, we return it in response for testing.
	c.JSON(http.StatusOK, gin.H{"message": "OTP sent successfully", "code": code})
}

func GetCaptcha(c *gin.Context) {
	// Simple Captcha Generator
	rand.Seed(time.Now().UnixNano())
	code := fmt.Sprintf("%04d", rand.Intn(10000))
	expiry := time.Now().Add(5 * time.Minute)

	var id int
	err := db.DB.QueryRow("INSERT INTO captcha (captcha_code, expires_at) VALUES ($1, $2) RETURNING captcha_id",
		code, expiry).Scan(&id)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate captcha"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"captcha_id": id, "captcha_code": code})
}

func VerifyOTP(c *gin.Context) {
	var req OTPVerifyRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "phone and code are required"})
		return
	}

	var otpID int
	err := db.DB.QueryRow("SELECT otp_id FROM otp_verification WHERE phone_number = $1 AND otp_code = $2 AND is_verified = FALSE AND expires_at > NOW()",
		req.Phone, req.Code).Scan(&otpID)

	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid or expired OTP"})
		return
	}

	// Mark OTP as verified
	db.DB.Exec("UPDATE otp_verification SET is_verified = TRUE WHERE otp_id = $1", otpID)

	// Get or Create User
	var userID int
	var role string
	err = db.DB.QueryRow("SELECT user_id, role FROM users WHERE phone_number = $1", req.Phone).Scan(&userID, &role)
	if err != nil {
		// Create new user
		err = db.DB.QueryRow("INSERT INTO users (phone_number) VALUES ($1) RETURNING user_id, role", req.Phone).Scan(&userID, &role)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to create user"})
			return
		}
	}

	// Generate JWT
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": userID,
		"role":    role,
		"exp":     time.Now().Add(24 * time.Hour).Unix(),
	})

	tokenString, err := token.SignedString([]byte(os.Getenv("JWT_SECRET")))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to generate token"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"token":   tokenString,
		"user_id": userID,
		"role":    role,
	})
}
