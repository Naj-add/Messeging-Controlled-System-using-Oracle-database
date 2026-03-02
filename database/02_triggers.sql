-- Trigger to enforce role-based communication rules
CREATE OR REPLACE TRIGGER trg_check_communication_rules
BEFORE INSERT ON messages
FOR EACH ROW
DECLARE
    v_sender_role VARCHAR2(50);
    v_receiver_role VARCHAR2(50);
    v_sender_dept VARCHAR2(100);
    v_receiver_dept VARCHAR2(100);
BEGIN
    -- Get sender and receiver roles
    SELECT r.role_name, u.department INTO v_sender_role, v_sender_dept
    FROM users u
    JOIN roles r ON u.role_id = r.role_id
    WHERE u.user_id = :NEW.sender_id;
    
    SELECT r.role_name, u.department INTO v_receiver_role, v_receiver_dept
    FROM users u
    JOIN roles r ON u.role_id = r.role_id
    WHERE u.user_id = :NEW.receiver_id;
    
    -- Enforce communication rules
    -- Students can only message teachers and admins
    IF v_sender_role = 'STUDENT' AND v_receiver_role NOT IN ('TEACHER', 'ADMIN') THEN
        RAISE_APPLICATION_ERROR(-20001, 'Students can only message teachers and administrators');
    END IF;
    
    -- Teachers can message students, admins, and other teachers
    IF v_sender_role = 'TEACHER' AND v_receiver_role = 'STUDENT' THEN
        -- Teachers can message students, but only in their department
        IF v_sender_dept != v_receiver_dept THEN
            RAISE_APPLICATION_ERROR(-20002, 'Teachers can only message students from their department');
        END IF;
    END IF;
    
    -- Admins can message everyone
    IF v_sender_role = 'ADMIN' THEN
        NULL; -- No restrictions for admins
    END IF;
    
    -- Log the action in audit table
    INSERT INTO message_audit (
        audit_id, message_id, action_type, performed_by, details
    ) VALUES (
        seq_message_audit.NEXTVAL, :NEW.message_id, 'SENT', 
        :NEW.sender_id, 'Message sent from ' || v_sender_role || ' to ' || v_receiver_role
    );
END;
/

-- Trigger to prevent self-messaging
CREATE OR REPLACE TRIGGER trg_prevent_self_message
BEFORE INSERT ON messages
FOR EACH ROW
BEGIN
    IF :NEW.sender_id = :NEW.receiver_id THEN
        RAISE_APPLICATION_ERROR(-20003, 'Users cannot send messages to themselves');
    END IF;
END;
/

-- Trigger to update read status
CREATE OR REPLACE TRIGGER trg_message_read
BEFORE UPDATE OF status ON messages
FOR EACH ROW
BEGIN
    IF :NEW.status = 'read' AND :OLD.status != 'read' THEN
        :NEW.read_date := SYSDATE;
        
        -- Log read action
        INSERT INTO message_audit (
            audit_id, message_id, action_type, performed_by, details
        ) VALUES (
            seq_message_audit.NEXTVAL, :OLD.message_id, 'READ', 
            :OLD.receiver_id, 'Message read by recipient'
        );
    END IF;
END;
/

-- Trigger to prevent sending messages to inactive users
CREATE OR REPLACE TRIGGER trg_check_receiver_active
BEFORE INSERT ON messages
FOR EACH ROW
DECLARE
    v_is_active NUMBER;
BEGIN
    SELECT is_active INTO v_is_active
    FROM users
    WHERE user_id = :NEW.receiver_id;
    
    IF v_is_active = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Cannot send messages to inactive users');
    END IF;
END;
/

-- Trigger to validate message content
CREATE OR REPLACE TRIGGER trg_validate_message_content
BEFORE INSERT ON messages
FOR EACH ROW
BEGIN
    -- Check for empty messages
    IF :NEW.message_body IS NULL OR LENGTH(TRIM(:NEW.message_body)) = 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Message body cannot be empty');
    END IF;
    
    -- Check subject length
    IF LENGTH(:NEW.subject) > 200 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Subject cannot exceed 200 characters');
    END IF;
    
    -- Check for prohibited content (basic example)
    IF INSTR(UPPER(:NEW.message_body), 'SPAM') > 0 THEN
        RAISE_APPLICATION_ERROR(-20007, 'Message contains prohibited content');
    END IF;
END;
/