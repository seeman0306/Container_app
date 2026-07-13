-- Automatic Field Officer Assignment
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

CREATE TRIGGER trg_assign_officer
BEFORE INSERT ON complaints
FOR EACH ROW
EXECUTE FUNCTION assign_field_officer();

-- Auto Create Work Order
CREATE OR REPLACE FUNCTION create_work_order()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO work_orders(complaint_id, officer_id)
    VALUES(NEW.complaint_id, NEW.assigned_officer_id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_create_workorder
AFTER INSERT ON complaints
FOR EACH ROW
EXECUTE FUNCTION create_work_order();
