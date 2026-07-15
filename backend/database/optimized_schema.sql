-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    phone_number VARCHAR(15) PRIMARY KEY,
    name VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. MODULES TABLE
CREATE TABLE IF NOT EXISTS modules (
    module_id SERIAL PRIMARY KEY,
    module_name VARCHAR(100) UNIQUE NOT NULL
);

-- Insert 9 Modules
INSERT INTO modules(module_name)
VALUES
('Water Utility'),
('Solar Power'),
('Pollution Monitoring'),
('Vehicle Tracking'),
('Water Body Levels'),
('Garbage Monitoring'),
('Smart Lighting'),
('Weather Sensors'),
('Health Management')
ON CONFLICT (module_name) DO NOTHING;

-- 3. FIELD OFFICERS TABLE
CREATE TABLE IF NOT EXISTS field_officers (
    officer_id SERIAL PRIMARY KEY,
    module_id INT NOT NULL REFERENCES modules(module_id),
    officer_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(15) UNIQUE NOT NULL,
    ward_from INT NOT NULL,
    ward_to INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. WARD MAPPING TABLE
CREATE TABLE IF NOT EXISTS ward_mapping (
    mapping_id SERIAL PRIMARY KEY,
    module_id INT NOT NULL REFERENCES modules(module_id),
    ward_no INT NOT NULL,
    officer_id INT NOT NULL REFERENCES field_officers(officer_id),
    UNIQUE(module_id, ward_no)
);

-- 5. COMPLAINTS TABLE
CREATE TABLE IF NOT EXISTS complaints (
    complaint_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_phone VARCHAR(15) REFERENCES users(phone_number),
    module_id INT NOT NULL REFERENCES modules(module_id),
    ward_no INT NOT NULL,
    assigned_officer_id INT REFERENCES field_officers(officer_id),
    location TEXT NOT NULL,
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    complaint_photo TEXT,
    reason VARCHAR(150),
    severity VARCHAR(20),
    ai_detected_issue VARCHAR(150),
    ai_confidence DECIMAL(5,2),
    status VARCHAR(30) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. COMPLAINT STATUS HISTORY
CREATE TABLE IF NOT EXISTS complaint_updates (
    update_id SERIAL PRIMARY KEY,
    complaint_id UUID REFERENCES complaints(complaint_id),
    officer_id INT REFERENCES field_officers(officer_id),
    old_status VARCHAR(30),
    new_status VARCHAR(30),
    remarks TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- POPULATE DATA HELPER FUNCTION
CREATE OR REPLACE FUNCTION populate_officers_and_wards()
RETURNS VOID AS $$
DECLARE
    m_id INT;
BEGIN
    -- For each module
    FOR m_id IN SELECT module_id FROM modules LOOP

        -- Insert 4 officers for this module
        INSERT INTO field_officers (module_id, officer_name, phone_number, ward_from, ward_to)
        VALUES
        (m_id, (SELECT module_name FROM modules WHERE module_id=m_id) || ' Officer 1', '900' || LPAD(m_id::text, 2, '0') || '00001', 1, 10),
        (m_id, (SELECT module_name FROM modules WHERE module_id=m_id) || ' Officer 2', '900' || LPAD(m_id::text, 2, '0') || '00002', 11, 20),
        (m_id, (SELECT module_name FROM modules WHERE module_id=m_id) || ' Officer 3', '900' || LPAD(m_id::text, 2, '0') || '00003', 21, 30),
        (m_id, (SELECT module_name FROM modules WHERE module_id=m_id) || ' Officer 4', '900' || LPAD(m_id::text, 2, '0') || '00004', 31, 42)
        ON CONFLICT DO NOTHING;

        -- Map Wards to Officers for this module
        INSERT INTO ward_mapping(module_id, ward_no, officer_id)
        SELECT m_id, generate_series(1,10), (SELECT officer_id FROM field_officers WHERE module_id=m_id AND ward_from=1)
        ON CONFLICT DO NOTHING;

        INSERT INTO ward_mapping(module_id, ward_no, officer_id)
        SELECT m_id, generate_series(11,20), (SELECT officer_id FROM field_officers WHERE module_id=m_id AND ward_from=11)
        ON CONFLICT DO NOTHING;

        INSERT INTO ward_mapping(module_id, ward_no, officer_id)
        SELECT m_id, generate_series(21,30), (SELECT officer_id FROM field_officers WHERE module_id=m_id AND ward_from=21)
        ON CONFLICT DO NOTHING;

        INSERT INTO ward_mapping(module_id, ward_no, officer_id)
        SELECT m_id, generate_series(31,42), (SELECT officer_id FROM field_officers WHERE module_id=m_id AND ward_from=31)
        ON CONFLICT DO NOTHING;

    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Run the population
SELECT populate_officers_and_wards();
