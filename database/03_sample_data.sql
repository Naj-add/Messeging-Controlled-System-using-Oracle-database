-- Insert roles
INSERT INTO roles (role_id, role_name, description) VALUES (seq_roles.NEXTVAL, 'ADMIN', 'System Administrator');
INSERT INTO roles (role_id, role_name, description) VALUES (seq_roles.NEXTVAL, 'TEACHER', 'Faculty Member');
INSERT INTO roles (role_id, role_name, description) VALUES (seq_roles.NEXTVAL, 'STUDENT', 'Student');

-- Insert users (password hashes would be properly hashed in production)
INSERT INTO users (user_id, username, email, password_hash, role_id, full_name, department) 
VALUES (seq_users.NEXTVAL, 'admin1', 'admin@university.edu', 'hash_admin123', 1, 'Admin User', 'Administration');

INSERT INTO users (user_id, username, email, password_hash, role_id, full_name, department) 
VALUES (seq_users.NEXTVAL, 'teacher1', 'teacher1@university.edu', 'hash_teacher123', 2, 'John Smith', 'Computer Science');

INSERT INTO users (user_id, username, email, password_hash, role_id, full_name, department) 
VALUES (seq_users.NEXTVAL, 'teacher2', 'teacher2@university.edu', 'hash_teacher456', 2, 'Jane Doe', 'Mathematics');

INSERT INTO users (user_id, username, email, password_hash, role_id, full_name, department) 
VALUES (seq_users.NEXTVAL, 'student1', 'student1@university.edu', 'hash_student123', 3, 'Bob Johnson', 'Computer Science');

INSERT INTO users (user_id, username, email, password_hash, role_id, full_name, department) 
VALUES (seq_users.NEXTVAL, 'student2', 'student2@university.edu', 'hash_student456', 3, 'Alice Brown', 'Mathematics');

INSERT INTO users (user_id, username, email, password_hash, role_id, full_name, department) 
VALUES (seq_users.NEXTVAL, 'student3', 'student3@university.edu', 'hash_student789', 3, 'Charlie Wilson', 'Computer Science');

-- Insert sample messages
INSERT INTO messages (message_id, sender_id, receiver_id, subject, message_body, status, priority)
VALUES (seq_messages.NEXTVAL, 2, 4, 'Welcome to CS101', 'Welcome to Computer Science 101. Please check the syllabus.', 'sent', 'normal');

INSERT INTO messages (message_id, sender_id, receiver_id, subject, message_body, status, priority)
VALUES (seq_messages.NEXTVAL, 3, 5, 'Math Homework', 'Please complete chapter 3 exercises by Friday.', 'sent', 'high');

INSERT INTO messages (message_id, sender_id, receiver_id, subject, message_body, status, priority)
VALUES (seq_messages.NEXTVAL, 4, 2, 'Question about assignment', 'I have a question about the programming assignment.', 'read', 'normal');

INSERT INTO messages (message_id, sender_id, receiver_id, subject, message_body, status, priority)
VALUES (seq_messages.NEXTVAL, 1, 2, 'Faculty Meeting', 'Reminder: Faculty meeting tomorrow at 2 PM.', 'sent', 'urgent');