package staff

import (
	"log"
	"smart-city-backend/internal/db"
	"time"
)

func StartEscalationJob() {
	ticker := time.NewTicker(1 * time.Hour) // Check every hour
	go func() {
		for range ticker.C {
			EscalatePendingWorkOrders()
		}
	}()
}

func EscalatePendingWorkOrders() {
	// Find work orders older than 3 days that are still 'Pending'
	rows, err := db.DB.Query(`SELECT work_order_id, complaint_id, officer_id
		FROM work_orders
		WHERE work_order_status = 'Pending'
		AND assigned_date <= NOW() - INTERVAL '3 days'`)

	if err != nil {
		log.Println("Error fetching pending work orders for escalation:", err)
		return
	}
	defer rows.Close()

	for rows.Next() {
		var woID, complaintID, officerID int
		rows.Scan(&woID, &complaintID, &officerID)

		// Assign to first junior engineer as a default escalation
		var engineerID int
		err := db.DB.QueryRow("SELECT engineer_id FROM junior_engineers LIMIT 1").Scan(&engineerID)
		if err != nil {
			log.Println("No junior engineers available for escalation")
			continue
		}

		// Insert into escalations
		_, err = db.DB.Exec(`INSERT INTO escalations (complaint_id, work_order_id, officer_id, engineer_id, escalation_reason)
			VALUES ($1, $2, $3, $4, 'No response for 3 days')`,
			complaintID, woID, officerID, engineerID)

		if err == nil {
			// Update work order status
			db.DB.Exec("UPDATE work_orders SET work_order_status = 'Escalated' WHERE work_order_id = $1", woID)
			log.Printf("Escalated work order %d to engineer %d\n", woID, engineerID)
		} else {
			log.Println("Error escalating work order:", err)
		}
	}
}
