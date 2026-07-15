-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    role VARCHAR(20) DEFAULT 'CITIZEN', -- CITIZEN, FIELD_OFFICER, JUNIOR_ENGINEER
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. CAPTCHA TABLE
CREATE TABLE IF NOT EXISTS captcha (
    captcha_id SERIAL PRIMARY KEY,
    captcha_code VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- 3. OTP TABLE
CREATE TABLE IF NOT EXISTS otp_verification (
    otp_id SERIAL PRIMARY KEY,
    phone_number VARCHAR(15),
    otp_code VARCHAR(6),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- 4. MODULES TABLE
CREATE TABLE IF NOT EXISTS modules (
    module_id SERIAL PRIMARY KEY,
    module_name VARCHAR(100) UNIQUE
);

-- Sample Data for Modules
INSERT INTO modules(module_name)
VALUES
('UGSS'),
('Water Supply'),
('Road Damage'),
('Street Light'),
('Drainage'),
('Solid Waste'),
('Park Maintenance'),
('Public Toilet'),
('Other Complaints')
ON CONFLICT (module_name) DO NOTHING;

-- 5. FIELD OFFICERS
CREATE TABLE IF NOT EXISTS field_officers (
    officer_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    officer_name VARCHAR(100),
    phone VARCHAR(15),
    ward_from INT,
    ward_to INT
);

-- 6. JUNIOR ENGINEERS
CREATE TABLE IF NOT EXISTS junior_engineers (
    engineer_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    engineer_name VARCHAR(100),
    phone VARCHAR(15)
);

-- 7. COMPLAINTS TABLE
CREATE TABLE IF NOT EXISTS complaints (
    complaint_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    module_id INT REFERENCES modules(module_id),
    complaint_title VARCHAR(255),
    complaint_description TEXT,
    ward_no INT NOT NULL,
    complaint_address TEXT,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    complaint_photo TEXT,
    assigned_officer_id INT REFERENCES field_officers(officer_id),
    status VARCHAR(30) DEFAULT 'Pending',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 8. WORK ORDERS TABLE
CREATE TABLE IF NOT EXISTS work_orders (
    work_order_id SERIAL PRIMARY KEY,
    complaint_id INT REFERENCES complaints(complaint_id),
    officer_id INT REFERENCES field_officers(officer_id),
    assigned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    work_order_status VARCHAR(30) DEFAULT 'Pending'
);

-- 9. WORK ORDER REJECTION TABLE
CREATE TABLE IF NOT EXISTS work_order_rejections (
    rejection_id SERIAL PRIMARY KEY,
    work_order_id INT REFERENCES work_orders(work_order_id),
    rejected_by INT REFERENCES field_officers(officer_id),
    rejection_reason TEXT,
    rejected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. TODO LIST TABLE
CREATE TABLE IF NOT EXISTS todo_list (
    todo_id SERIAL PRIMARY KEY,
    work_order_id INT REFERENCES work_orders(work_order_id),
    task_name VARCHAR(255),
    navigation_link TEXT,
    start_time TIMESTAMP,
    completion_status VARCHAR(20) DEFAULT 'Pending',
    completed_at TIMESTAMP
);

-- 11. ESCALATION TABLE
CREATE TABLE IF NOT EXISTS escalations (
    escalation_id SERIAL PRIMARY KEY,
    complaint_id INT REFERENCES complaints(complaint_id),
    work_order_id INT REFERENCES work_orders(work_order_id),
    officer_id INT REFERENCES field_officers(officer_id),
    engineer_id INT REFERENCES junior_engineers(engineer_id),
    escalation_reason TEXT,
    escalated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. NAVIGATION TRACKING
CREATE TABLE IF NOT EXISTS navigation_tracking (
    navigation_id SERIAL PRIMARY KEY,
    work_order_id INT REFERENCES work_orders(work_order_id),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    tracked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 13. COMPLETED PROJECTS
CREATE TABLE IF NOT EXISTS completed_projects (
    completed_id SERIAL PRIMARY KEY,
    complaint_id INT REFERENCES complaints(complaint_id),
    work_order_id INT REFERENCES work_orders(work_order_id),
    officer_id INT REFERENCES field_officers(officer_id),
    completion_remarks TEXT,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 14. REJECTED PROJECTS
CREATE TABLE IF NOT EXISTS rejected_projects (
    rejected_project_id SERIAL PRIMARY KEY,
    complaint_id INT REFERENCES complaints(complaint_id),
    work_order_id INT REFERENCES work_orders(work_order_id),
    officer_id INT REFERENCES field_officers(officer_id),
    rejection_reason TEXT,
    rejected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- TRIGGERS FOR AUTOMATION

-- 1. Automatic Field Officer Assignment based on Ward
CREATE OR REPLACE FUNCTION assign_field_officer()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.ward_no BETWEEN 1 AND 10 THEN
        NEW.assigned_officer_id := 1;
    ELSIF NEW.ward_no BETWEEN 11 AND 20 THEN
        NEW.assigned_officer_id := 2;
    ELSIF NEW.ward_no BETWEEN 21 AND 30 THEN
        NEW.assigned_officer_id := 3;
    ELSIF NEW.ward_no BETWEEN 31 AND 42 THEN
        NEW.assigned_officer_id := 4;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_assign_officer ON complaints;
CREATE TRIGGER trg_assign_officer
BEFORE INSERT ON complaints
FOR EACH ROW
EXECUTE FUNCTION assign_field_officer();

-- 2. Auto Create Work Order when a complaint is inserted
CREATE OR REPLACE FUNCTION create_work_order()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO work_orders(complaint_id, officer_id)
    VALUES(NEW.complaint_id, NEW.assigned_officer_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_create_workorder ON complaints;
CREATE TRIGGER trg_create_workorder
AFTER INSERT ON complaints
FOR EACH ROW
EXECUTE FUNCTION create_work_order();

-- SAMPLE STAFF DATA
-- Create staff users first
INSERT INTO users (phone_number, role, name) VALUES ('1111111111', 'FIELD_OFFICER', 'Officer One') ON CONFLICT DO NOTHING;
INSERT INTO users (phone_number, role, name) VALUES ('2222222222', 'FIELD_OFFICER', 'Officer Two') ON CONFLICT DO NOTHING;
INSERT INTO users (phone_number, role, name) VALUES ('3333333333', 'FIELD_OFFICER', 'Officer Three') ON CONFLICT DO NOTHING;
INSERT INTO users (phone_number, role, name) VALUES ('4444444444', 'FIELD_OFFICER', 'Officer Four') ON CONFLICT DO NOTHING;

-- Insert into field_officers table
INSERT INTO field_officers (officer_id, user_id, officer_name, phone, ward_from, ward_to)
VALUES
(1, (SELECT user_id FROM users WHERE phone_number='1111111111'), 'Officer One', '1111111111', 1, 10),
(2, (SELECT user_id FROM users WHERE phone_number='2222222222'), 'Officer Two', '2222222222', 11, 20),
(3, (SELECT user_id FROM users WHERE phone_number='3333333333'), 'Officer Three', '3333333333', 21, 30),
(4, (SELECT user_id FROM users WHERE phone_number='4444444444'), 'Officer Four', '4444444444', 31, 42)
ON CONFLICT (officer_id) DO NOTHING;
