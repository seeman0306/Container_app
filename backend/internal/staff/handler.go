package staff

import (
	"net/http"
	"smart-city-backend/internal/db"
	"github.com/gin-gonic/gin"
	"time"
)

func GetWorkOrders(c *gin.Context) {
	phone := c.GetString("phone")
	var officerID int
	err := db.DB.QueryRow("SELECT officer_id FROM field_officers WHERE phone_number = $1", phone).Scan(&officerID)
	if err != nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "not a field officer"})
		return
	}

	rows, err := db.DB.Query(`SELECT w.work_order_id, c.reason, c.ward_no, w.assigned_date, w.work_order_status
		FROM work_orders w
		JOIN complaints c ON w.complaint_id = c.complaint_id
		WHERE w.officer_id = $1`, officerID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch work orders: " + err.Error()})
		return
	}
	defer rows.Close()

	var orders []map[string]interface{}
	for rows.Next() {
		var id, ward int
		var title, status, assignedDate string
		rows.Scan(&id, &title, &ward, &assignedDate, &status)
		orders = append(orders, map[string]interface{}{
			"work_order_id": id,
			"title":         title,
			"ward":          ward,
			"assigned_date": assignedDate,
			"status":        status,
		})
	}

	c.JSON(http.StatusOK, orders)
}

func ActionWorkOrder(c *gin.Context) {
	workOrderID := c.Param("id")
	var req struct {
		Action string `json:"action"` // "Accept" or "Reject"
		Reason string `json:"reason"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	status := "Accepted"
	if req.Action == "Reject" {
		status = "Rejected"
	}

	_, err := db.DB.Exec("UPDATE work_orders SET work_order_status = $1 WHERE work_order_id = $2", status, workOrderID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update status"})
		return
	}

	if status == "Rejected" {
		db.DB.Exec("INSERT INTO work_order_rejections (work_order_id, rejection_reason) VALUES ($1, $2)", workOrderID, req.Reason)
	} else {
		// If accepted, add to TODO LIST
		db.DB.Exec("INSERT INTO todo_list (work_order_id, task_name) VALUES ($1, 'Pending Completion')", workOrderID)
	}

	c.JSON(http.StatusOK, gin.H{"message": "work order " + status})
}

func GetTodoList(c *gin.Context) {
	phone := c.GetString("phone")
	var officerID int
	db.DB.QueryRow("SELECT officer_id FROM field_officers WHERE phone_number = $1", phone).Scan(&officerID)

	rows, err := db.DB.Query(`SELECT t.todo_id, c.reason, t.completion_status
		FROM todo_list t
		JOIN work_orders w ON t.work_order_id = w.work_order_id
		JOIN complaints c ON w.complaint_id = c.complaint_id
		WHERE w.officer_id = $1 AND t.completion_status != 'Completed'`, officerID)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch todo list"})
		return
	}
	defer rows.Close()

	var todos []map[string]interface{}
	for rows.Next() {
		var id int
		var title, status string
		rows.Scan(&id, &title, &status)
		todos = append(todos, map[string]interface{}{
			"todo_id": id,
			"title":   title,
			"status":  status,
		})
	}

	c.JSON(http.StatusOK, todos)
}

func CompleteTask(c *gin.Context) {
	todoID := c.Param("id")
	_, err := db.DB.Exec("UPDATE todo_list SET completion_status = 'Completed', completed_at = $1 WHERE todo_id = $2", time.Now(), todoID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to complete task"})
		return
	}

	// Update work order status as well
	var woID int
	db.DB.QueryRow("SELECT work_order_id FROM todo_list WHERE todo_id = $1", todoID).Scan(&woID)
	db.DB.Exec("UPDATE work_orders SET work_order_status = 'Completed' WHERE work_order_id = $1", woID)

	c.JSON(http.StatusOK, gin.H{"message": "task completed successfully"})
}

func TrackNavigation(c *gin.Context) {
	workOrderID := c.Param("id")
	var req struct {
		Lat float64 `json:"latitude"`
		Lng float64 `json:"longitude"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid coordinates"})
		return
	}

	_, err := db.DB.Exec("INSERT INTO navigation_tracking (work_order_id, latitude, longitude) VALUES ($1, $2, $3)",
		workOrderID, req.Lat, req.Lng)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to track location"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "location tracked"})
}
