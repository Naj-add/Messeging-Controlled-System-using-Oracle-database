from flask import Flask, render_template, request, redirect, url_for, session, jsonify
import oracledb
import hashlib
from datetime import datetime
import os

app = Flask(__name__)
app.secret_key = 'your-secret-key-change-in-production'

# Database configuration
DB_CONFIG = {
    'user': 'SYSTEM',
    'password': 'SYSTEMNAJ2026',
    'dsn': 'localhost:1521/ORCL'  # Update with your Oracle connection string
}

def get_db_connection():
    """Create and return a database connection"""
    try:
        connection = oracledb.connect(**DB_CONFIG)
        return connection
    except oracledb.Error as e:
        print(f"Database connection error: {e}")
        return None

def hash_password(password):
    """Hash password using SHA-256"""
    return hashlib.sha256(password.encode()).hexdigest()

@app.route('/')
def index():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return render_template('index.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form['username']
        password = request.form['password']  # No hashing
        
        print(f"1. Login attempt - Username: {username}")
        print(f"2. Password entered: {password}")
        
        conn = get_db_connection()
        if conn:
            cursor = conn.cursor()
            
            # First, check if user exists at all
            cursor.execute("""
                SELECT user_id, username, password_hash, is_active 
                FROM users 
                WHERE username = :1
            """, (username,))
            
            user_check = cursor.fetchone()
            if user_check:
                print(f"3. User found in DB: {user_check[1]}")
                print(f"4. DB password hash: {user_check[2]}")
                print(f"5. Password entered: {password}")
                print(f"6. Do they match? {user_check[2] == password}")
                print(f"7. Is active? {user_check[3]}")
            else:
                print("3. User NOT found in database!")
            
            # Now try the full login query
            cursor.execute("""
                SELECT u.user_id, u.username, u.full_name, r.role_name 
                FROM users u
                JOIN roles r ON u.role_id = r.role_id
                WHERE u.username = :1 AND u.password_hash = :2 AND u.is_active = 1
            """, (username, password))
            
            user = cursor.fetchone()
            print(f"8. Login query result: {user}")
            
            cursor.close()
            conn.close()
            
            if user:
                print("9. Login successful!")
                session['user_id'] = user[0]
                session['username'] = user[1]
                session['full_name'] = user[2]
                session['role'] = user[3]
                return redirect(url_for('dashboard'))
            else:
                print("9. Login failed!")
                return render_template('login.html', error='Invalid credentials')
    
    return render_template('login.html')

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('index'))

@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Get unread messages count
    cursor.execute("""
        SELECT COUNT(*) FROM messages 
        WHERE receiver_id = :1 AND status = 'sent'
    """, (session['user_id'],))
    unread_count = cursor.fetchone()[0]
    
    # Get recent messages
    cursor.execute("""
        SELECT m.message_id, m.subject, u.full_name as sender_name,
               m.sent_date, m.status, m.priority
        FROM messages m
        JOIN users u ON m.sender_id = u.user_id
        WHERE m.receiver_id = :1
        ORDER BY m.sent_date DESC
        FETCH FIRST 5 ROWS ONLY
    """, (session['user_id'],))
    recent_messages = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('dashboard.html', 
                         unread_count=unread_count,
                         recent_messages=recent_messages,
                         user=session)

@app.route('/send_message', methods=['GET', 'POST'])
def send_message():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    if request.method == 'POST':
        receiver_id = request.form['receiver_id']
        subject = request.form['subject']
        message_body = request.form['message_body']
        priority = request.form.get('priority', 'normal')
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        try:
            # Get next message ID
            cursor.execute("SELECT seq_messages.NEXTVAL FROM DUAL")
            message_id = cursor.fetchone()[0]
            
            # Insert message
            cursor.execute("""
                INSERT INTO messages (message_id, sender_id, receiver_id, subject, 
                                    message_body, priority, sent_date, status)
                VALUES (:1, :2, :3, :4, :5, :6, SYSDATE, 'sent')
            """, (message_id, session['user_id'], receiver_id, subject, 
                  message_body, priority))
            
            conn.commit()
            return redirect(url_for('inbox'))
            
        except oracledb.Error as e:
            error_msg = str(e)
            conn.rollback()
            return render_template('send_message.html', 
                                 error=f"Error sending message: {error_msg}")
        finally:
            cursor.close()
            conn.close()
    
    # GET request - show form
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Get eligible receivers based on role
    if session['role'] == 'ADMIN':
        cursor.execute("""
            SELECT user_id, full_name, role_name, department 
            FROM users u
            JOIN roles r ON u.role_id = r.role_id
            WHERE u.is_active = 1 AND u.user_id != :1
            ORDER BY r.role_name, u.full_name
        """, (session['user_id'],))
    elif session['role'] == 'TEACHER':
        cursor.execute("""
            SELECT u.user_id, u.full_name, r.role_name, u.department
            FROM users u
            JOIN roles r ON u.role_id = r.role_id
            WHERE u.is_active = 1 AND u.user_id != :1
            AND (
                r.role_name IN ('ADMIN', 'TEACHER')
                OR (r.role_name = 'STUDENT' AND u.department = (
                    SELECT department FROM users WHERE user_id = :1
                ))
            )
            ORDER BY r.role_name, u.full_name
        """, (session['user_id'], session['user_id']))
    else:  # STUDENT
        cursor.execute("""
            SELECT u.user_id, u.full_name, r.role_name, u.department
            FROM users u
            JOIN roles r ON u.role_id = r.role_id
            WHERE u.is_active = 1 AND u.user_id != :1
            AND r.role_name IN ('TEACHER', 'ADMIN')
            ORDER BY r.role_name, u.full_name
        """, (session['user_id'],))
    
    receivers = cursor.fetchall()
    cursor.close()
    conn.close()
    
    return render_template('send_message.html', receivers=receivers)

@app.route('/inbox')
def inbox():
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Get all messages for user
    cursor.execute("""
        SELECT m.message_id, m.subject, u.full_name as sender_name,
               m.sent_date, m.read_date, m.status, m.priority,
               u.department as sender_department
        FROM messages m
        JOIN users u ON m.sender_id = u.user_id
        WHERE m.receiver_id = :1
        ORDER BY 
            CASE m.priority 
                WHEN 'urgent' THEN 1
                WHEN 'high' THEN 2
                WHEN 'normal' THEN 3
                ELSE 4
            END,
            m.sent_date DESC
    """, (session['user_id'],))
    
    messages = cursor.fetchall()
    cursor.close()
    conn.close()
    
    return render_template('inbox.html', messages=messages)

@app.route('/view_message/<int:message_id>')
def view_message(message_id):
    if 'user_id' not in session:
        return redirect(url_for('login'))
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Get message details
    cursor.execute("""
        SELECT m.message_id, m.subject, m.message_body,
               s.full_name as sender_name, s.department as sender_dept,
               r.full_name as receiver_name, r.department as receiver_dept,
               m.sent_date, m.read_date, m.status, m.priority,
               m.receiver_id, m.sender_id
        FROM messages m
        JOIN users s ON m.sender_id = s.user_id
        JOIN users r ON m.receiver_id = r.user_id
        WHERE m.message_id = :1 
        AND (m.receiver_id = :2 OR m.sender_id = :3)
    """, (message_id, session['user_id'], session['user_id']))
    
    row = cursor.fetchone()
    
    if not row:
        cursor.close()
        conn.close()
        return "Message not found", 404
    
    # Convert to dictionary with meaningful keys
    message = {
        'id': row[0],
        'subject': row[1],
        'body': row[2].read() if row[2] else '',  # Read CLOB here
        'sender_name': row[3],
        'sender_dept': row[4],
        'receiver_name': row[5],
        'receiver_dept': row[6],
        'sent_date': row[7],
        'read_date': row[8],
        'status': row[9],
        'priority': row[10],
        'receiver_id': row[11],
        'sender_id': row[12]
    }
    
    # Mark as read if user is receiver and message is unread
    if message['status'] == 'sent' and message['receiver_id'] == session['user_id']:
        cursor.execute("""
            UPDATE messages SET status = 'read', read_date = SYSDATE
            WHERE message_id = :1 AND receiver_id = :2 AND status = 'sent'
        """, (message_id, session['user_id']))
        conn.commit()
    
    cursor.close()
    conn.close()
    
    return render_template('view_message.html', message=message)

@app.route('/reports')
def reports():
    if 'user_id' not in session or session['role'] != 'ADMIN':
        return redirect(url_for('dashboard'))
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    # Get user statistics
    cursor.execute("SELECT * FROM v_user_message_stats")
    user_stats = cursor.fetchall()
    
    # Get daily activity
    cursor.execute("SELECT * FROM v_daily_message_activity WHERE ROWNUM <= 30")
    daily_activity = cursor.fetchall()
    
    # Get department communication
    cursor.execute("SELECT * FROM v_department_communication")
    dept_comm = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('reports.html', 
                         user_stats=user_stats,
                         daily_activity=daily_activity,
                         dept_comm=dept_comm)

@app.route('/api/unread_count')
def api_unread_count():
    if 'user_id' not in session:
        return jsonify({'error': 'Not authenticated'}), 401
    
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT COUNT(*) FROM messages 
        WHERE receiver_id = :1 AND status = 'sent'
    """, (session['user_id'],))
    count = cursor.fetchone()[0]
    cursor.close()
    conn.close()
    
    return jsonify({'unread_count': count})

@app.route('/archive_message/<int:message_id>', methods=['POST'])
def archive_message(message_id):
    if 'user_id' not in session:
        return jsonify({'error': 'Not authenticated'}), 401
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        cursor.execute("""
            UPDATE messages SET status = 'archived'
            WHERE message_id = :1 AND receiver_id = :2
        """, (message_id, session['user_id']))
        conn.commit()
        return jsonify({'success': True})
    except oracledb.Error as e:
        conn.rollback()
        return jsonify({'error': str(e)}), 500
    finally:
        cursor.close()
        conn.close()

if __name__ == '__main__':
    app.run(debug=True)