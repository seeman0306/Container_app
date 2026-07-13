-- Alter complaints table to add new columns if they do not exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='complaints' AND column_name='user_phone') THEN
        ALTER TABLE complaints ADD COLUMN user_phone VARCHAR(15);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='complaints' AND column_name='category') THEN
        ALTER TABLE complaints ADD COLUMN category VARCHAR(50) DEFAULT 'Water Utility';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='complaints' AND column_name='reason') THEN
        ALTER TABLE complaints ADD COLUMN reason VARCHAR(50);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='complaints' AND column_name='severity') THEN
        ALTER TABLE complaints ADD COLUMN severity VARCHAR(20);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='complaints' AND column_name='ai_detected_issue') THEN
        ALTER TABLE complaints ADD COLUMN ai_detected_issue VARCHAR(50);
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='complaints' AND column_name='ai_confidence') THEN
        ALTER TABLE complaints ADD COLUMN ai_confidence DECIMAL(5,2);
    END IF;
END $$;

-- Insert module 'Water Utility' if it doesn't exist
INSERT INTO modules (module_name)
VALUES ('Water Utility')
ON CONFLICT (module_name) DO NOTHING;

-- Ensure mock users exist for field officers
INSERT INTO users (name, phone_number, role)
VALUES ('Officer One', '1111111111', 'FIELD_OFFICER')
ON CONFLICT (phone_number) DO NOTHING;

INSERT INTO users (name, phone_number, role)
VALUES ('Officer Two', '2222222222', 'FIELD_OFFICER')
ON CONFLICT (phone_number) DO NOTHING;

INSERT INTO users (name, phone_number, role)
VALUES ('Officer Three', '3333333333', 'FIELD_OFFICER')
ON CONFLICT (phone_number) DO NOTHING;

INSERT INTO users (name, phone_number, role)
VALUES ('Officer Four', '4444444444', 'FIELD_OFFICER')
ON CONFLICT (phone_number) DO NOTHING;

-- Seed mock field officers matching IDs 1, 2, 3, 4 referenced by the triggers
INSERT INTO field_officers (officer_id, user_id, officer_name, phone, ward_from, ward_to)
VALUES
(1, (SELECT user_id FROM users WHERE phone_number='1111111111'), 'Officer One', '1111111111', 1, 10)
ON CONFLICT (officer_id) DO NOTHING;

INSERT INTO field_officers (officer_id, user_id, officer_name, phone, ward_from, ward_to)
VALUES
(2, (SELECT user_id FROM users WHERE phone_number='2222222222'), 'Officer Two', '2222222222', 11, 20)
ON CONFLICT (officer_id) DO NOTHING;

INSERT INTO field_officers (officer_id, user_id, officer_name, phone, ward_from, ward_to)
VALUES
(3, (SELECT user_id FROM users WHERE phone_number='3333333333'), 'Officer Three', '3333333333', 21, 30)
ON CONFLICT (officer_id) DO NOTHING;

INSERT INTO field_officers (officer_id, user_id, officer_name, phone, ward_from, ward_to)
VALUES
(4, (SELECT user_id FROM users WHERE phone_number='4444444444'), 'Officer Four', '4444444444', 31, 42)
ON CONFLICT (officer_id) DO NOTHING;

-- Update the sequence so that subsequent auto-increments for field_officers start after 4
SELECT setval(pg_get_serial_sequence('field_officers', 'officer_id'), COALESCE(MAX(officer_id), 1)) FROM field_officers;
