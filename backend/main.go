package main

import (
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"time"
)

func main() {
	// Seed random number generator
	rand.Seed(time.Now().UnixNano())

	mux := http.NewServeMux()

	mux.HandleFunc("/api/auth/citizen/captcha", handleCaptcha)
	mux.HandleFunc("/api/auth/citizen/send-otp", handleSendOTP)
	mux.HandleFunc("/api/auth/citizen/verify-otp", handleVerifyOTP)

	handler := corsMiddleware(mux)

	fmt.Println("Backend server starting on http://localhost:8080...")
	log.Fatal(http.ListenAndServe(":8080", handler))
}

func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")

		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func handleCaptcha(w http.ResponseWriter, r *http.Request) {
	resp := map[string]string{"captchaID": "test-id"}
	json.NewEncoder(w).Encode(resp)
}

func handleSendOTP(w http.ResponseWriter, r *http.Request) {
	var body map[string]interface{}
	json.NewDecoder(r.Body).Decode(&body)

	phone := body["phone"]
	// Generate a random 6-digit OTP
	otp := rand.Intn(900000) + 100000

	fmt.Printf("\n--- NEW OTP REQUEST ---")
	fmt.Printf("\nPhone: %v", phone)
	fmt.Printf("\nOTP Code: %d", otp)
	fmt.Printf("\n-----------------------\n")

	resp := map[string]interface{}{"is_officer": false}
	json.NewEncoder(w).Encode(resp)
}

func handleVerifyOTP(w http.ResponseWriter, r *http.Request) {
	fmt.Println("POST /api/auth/citizen/verify-otp - Success")
	resp := map[string]string{
		"token":         "mock-access-token",
		"refresh_token": "mock-refresh-token",
		"role":          "CITIZEN",
	}
	json.NewEncoder(w).Encode(resp)
}
