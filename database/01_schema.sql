-- Drop existing tables if they exist
DROP TABLE message_audit CASCADE CONSTRAINTS;
DROP TABLE messages CASCADE CONSTRAINTS;
DROP TABLE users CASCADE CONSTRAINTS;
DROP TABLE roles CASCADE CONSTRAINTS;

-- Create roles table
CREATE TABLE roles (
    role_id NUMBER PRIMARY KEY,
    role_name VARCHAR2(50) NOT NULL UNIQUE,
    description VARCHAR2(200),
    created_date DATE DEFAULT SYSDATE
);

-- Create users table
CREATE TABLE users (
    user_id NUMBER PRIMARY KEY,
    username VARCHAR2(50) NOT NULL UNIQUE,
    email VARCHAR2(100) NOT NULL UNIQUE,
    password_hash VARCHAR2(255) NOT NULL,
    role_id NUMBER NOT NULL,
    full_name VARCHAR2(100),
    department VARCHAR2(100),
    is_active NUMBER(1) DEFAULT 1,
    created_date DATE DEFAULT SYSDATE,
    last_login DATE,
    CONSTRAINT fk_user_role FOREIGN KEY (role_id) REFERENCES roles(role_id)
);

-- Create messages table
CREATE TABLE messages (
    message_id NUMBER PRIMARY KEY,
    sender_id NUMBER NOT NULL,
    receiver_id NUMBER NOT NULL,
    subject VARCHAR2(200) NOT NULL,
    message_body CLOB NOT NULL,
    sent_date DATE DEFAULT SYSDATE,
    read_date DATE,
    status VARCHAR2(20) DEFAULT 'sent',
    priority VARCHAR2(20) DEFAULT 'normal',
    parent_message_id NUMBER,
    CONSTRAINT fk_message_sender FOREIGN KEY (sender_id) REFERENCES users(user_id),
    CONSTRAINT fk_message_receiver FOREIGN KEY (receiver_id) REFERENCES users(user_id),
    CONSTRAINT fk_message_parent FOREIGN KEY (parent_message_id) REFERENCES messages(message_id),
    CONSTRAINT chk_message_status CHECK (status IN ('sent', 'read', 'archived', 'deleted')),
    CONSTRAINT chk_message_priority CHECK (priority IN ('low', 'normal', 'high', 'urgent'))
);

-- Create message audit table for traceability
CREATE TABLE message_audit (
    audit_id NUMBER PRIMARY KEY,
    message_id NUMBER NOT NULL,
    action_type VARCHAR2(20) NOT NULL,
    action_date DATE DEFAULT SYSDATE,
    performed_by NUMBER NOT NULL,
    ip_address VARCHAR2(45),
    details VARCHAR2(500),
    CONSTRAINT fk_audit_message FOREIGN KEY (message_id) REFERENCES messages(message_id),
    CONSTRAINT fk_audit_user FOREIGN KEY (performed_by) REFERENCES users(user_id)
);

-- Create sequences
CREATE SEQUENCE seq_roles START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_users START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_messages START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_message_audit START WITH 1 INCREMENT BY 1;

-- Create indexes for performance
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);
CREATE INDEX idx_messages_status ON messages(status);
CREATE INDEX idx_messages_sent_date ON messages(sent_date);
CREATE INDEX idx_audit_message ON message_audit(message_id);