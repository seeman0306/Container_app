-- 1. USERS TABLE
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100),
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    role VARCHAR(20) DEFAULT 'CITIZEN', -- CITIZEN, FIELD_OFFICER, JUNIOR_ENGINEER
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. CAPTCHA TABLE
CREATE TABLE captcha (
    captcha_id SERIAL PRIMARY KEY,
    captcha_code VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- 3. OTP TABLE
CREATE TABLE otp_verification (
    otp_id SERIAL PRIMARY KEY,
    phone_number VARCHAR(15),
    otp_code VARCHAR(6),
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- 4. MODULES TABLE
CREATE TABLE modules (
    module_id SERIAL PRIMARY KEY,
    module_name VARCHAR(100) UNIQUE
);

-- Sample Data
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
CREATE TABLE field_officers (
    officer_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    officer_name VARCHAR(100),
    phone VARCHAR(15),
    ward_from INT,
    ward_to INT
);

-- 6. JUNIOR ENGINEERS
CREATE TABLE junior_engineers (
    engineer_id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    engineer_name VARCHAR(100),
    phone VARCHAR(15)
);

-- 7. COMPLAINTS TABLE
CREATE TABLE complaints (
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
CREATE TABLE work_orders (
    work_order_id SERIAL PRIMARY KEY,
    complaint_id INT REFERENCES complaints(complaint_id),
    officer_id INT REFERENCES field_officers(officer_id),
    assigned_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    work_order_status VARCHAR(30) DEFAULT 'Pending'
);

-- 9. WORK ORDER REJECTION TABLE
CREATE TABLE work_order_rejections (
    rejection_id SERIAL PRIMARY KEY,
    work_order_id INT REFERENCES work_orders(work_order_id),
    rejected_by INT REFERENCES field_officers(officer_id),
    rejection_reason TEXT,
    rejected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. TODO LIST TABLE
CREATE TABLE todo_list (
    todo_id SERIAL PRIMARY KEY,
    work_order_id INT REFERENCES work_orders(work_order_id),
    task_name VARCHAR(255),
    navigation_link TEXT,
    start_time TIMESTAMP,
    completion_status VARCHAR(20) DEFAULT 'Pending',
    completed_at TIMESTAMP
);

-- 11. ESCALATION TABLE
CREATE TABLE escalations (
    escalation_id SERIAL PRIMARY KEY,
    complaint_id INT REFERENCES complaints(complaint_id),
    work_order_id INT REFERENCES work_orders(work_order_id),
    officer_id INT REFERENCES field_officers(officer_id),
    engineer_id INT REFERENCES junior_engineers(engineer_id),
    escalation_reason TEXT,
    escalated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 12. NAVIGATION TRACKING
CREATE TABLE navigation_tracking (
    navigation_id SERIAL PRIMARY KEY,
    work_order_id INT REFERENCES work_orders(work_order_id),
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    tracked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 13. COMPLETED PROJECTS (VIEW/TABLE)
CREATE TABLE completed_projects (
    completed_id SERIAL PRIMARY KEY,
    complaint_id INT REFERENCES complaints(complaint_id),
    work_order_id INT REFERENCES work_orders(work_order_id),
    officer_id INT REFERENCES field_officers(officer_id),
    completion_remarks TEXT,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 14. REJECTED PROJECTS (VIEW/TABLE)
CREATE TABLE rejected_projects (
    rejected_project_id SERIAL PRIMARY KEY,
    complaint_id INT REFERENCES complaints(complaint_id),
    work_order_id INT REFERENCES work_orders(work_order_id),
    officer_id INT REFERENCES field_officers(officer_id),
    rejection_reason TEXT,
    rejected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
