package complaint

import (
	"database/sql"
	"log"
	"net/http"
	"smart-city-backend/internal/db"
	"github.com/gin-gonic/gin"
)

type RaiseComplaintRequest struct {
	ModuleID    int     `json:"module_id" binding:"required"`
	Title       string  `json:"title" binding:"required"`
	Description string  `json:"description"`
	WardNo      int     `json:"ward_no" binding:"required"`
	Address     string  `json:"address"`
	Latitude    float64 `json:"latitude"`
	Longitude   float64 `json:"longitude"`
	Photo       string  `json:"photo"`
}

func RaiseComplaint(c *gin.Context) {
	var req RaiseComplaintRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		log.Printf("RaiseComplaint BindJSON Error: %v", err)
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userPhone := c.GetString("phone")
	log.Printf("Processing complaint for user: %s, Module: %d, Ward: %d", userPhone, req.ModuleID, req.WardNo)

	// 1. Automatically assign officer based on module and ward
	var officerID sql.NullInt64
	err := db.DB.QueryRow("SELECT officer_id FROM ward_mapping WHERE module_id = $1 AND ward_no = $2",
		req.ModuleID, req.WardNo).Scan(&officerID)

	if err != nil && err != sql.ErrNoRows {
		log.Printf("Ward mapping query error: %v", err)
	}

	// 2. Insert complaint
	_, err = db.DB.Exec(`INSERT INTO complaints
		(user_phone, module_id, ward_no, location, latitude, longitude, complaint_photo, reason, severity, assigned_officer_id)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
		userPhone, req.ModuleID, req.WardNo, req.Address, req.Latitude, req.Longitude, req.Photo, req.Title, "Medium", officerID)

	if err != nil {
		log.Printf("Database Insert Error: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to raise complaint: " + err.Error()})
		return
	}

	log.Println("Complaint raised successfully")
	c.JSON(http.StatusCreated, gin.H{"message": "complaint raised successfully"})
}

func GetMyComplaints(c *gin.Context) {
	userPhone := c.GetString("phone")

	rows, err := db.DB.Query("SELECT complaint_id, reason, ward_no, status, created_at, module_id FROM complaints WHERE user_phone = $1", userPhone)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch complaints"})
		return
	}
	defer rows.Close()

	var complaints []map[string]interface{}
	for rows.Next() {
		var id, status, createdAt, reason string
		var ward, moduleID int
		rows.Scan(&id, &reason, &ward, &status, &createdAt, &moduleID)
		complaints = append(complaints, map[string]interface{}{
			"id":         id,
			"title":      reason,
			"ward":       ward,
			"status":     status,
			"created_at": createdAt,
			"module_id":  moduleID,
		})
	}

	c.JSON(http.StatusOK, complaints)
}
