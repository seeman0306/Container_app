package complaint

import (
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
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	userID := c.GetInt("user_id")

	// Insert complaint. Triggers in DB will handle assignment and work order creation.
	_, err := db.DB.Exec(`INSERT INTO complaints
		(user_id, module_id, complaint_title, complaint_description, ward_no, complaint_address, latitude, longitude, complaint_photo)
		VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
		userID, req.ModuleID, req.Title, req.Description, req.WardNo, req.Address, req.Latitude, req.Longitude, req.Photo)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to raise complaint: " + err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"message": "complaint raised successfully"})
}

func GetMyComplaints(c *gin.Context) {
	userID := c.GetInt("user_id")

	rows, err := db.DB.Query("SELECT complaint_id, complaint_title, ward_no, status, created_at FROM complaints WHERE user_id = $1", userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch complaints"})
		return
	}
	defer rows.Close()

	var complaints []map[string]interface{}
	for rows.Next() {
		var id, ward int
		var title, status, createdAt string
		rows.Scan(&id, &title, &ward, &status, &createdAt)
		complaints = append(complaints, map[string]interface{}{
			"id":         id,
			"title":      title,
			"ward":       ward,
			"status":     status,
			"created_at": createdAt,
		})
	}

	c.JSON(http.StatusOK, complaints)
}
