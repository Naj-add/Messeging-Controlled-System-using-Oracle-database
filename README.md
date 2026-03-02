# 📧 Controlled Internal Messaging System

A secure, role-based internal messaging system for academic institutions built with Flask and Oracle Database.

## 🚀 Features

- **Role-Based Access**: Students, Teachers, and Admins with different permissions
- **Secure Messaging**: Complete audit trail with trigger-based validation
- **Status Tracking**: Sent, read, and archived message states
- **Real-time Updates**: Unread count badges and read receipts
- **Analytics**: Comprehensive reports and communication insights

## 🛠️ Tech Stack

- **Backend**: Python 3.11, Flask 2.3.3
- **Database**: Oracle Database with PL/SQL triggers
- **Frontend**: HTML5, CSS3, JavaScript
- **ORM**: python-oracledb 2.0.1

## 📋 Prerequisites

- Python 3.11+
- Oracle Database (XE recommended)
- Git

## ⚡ Quick Installation

```bash
# Clone repository
git clone https://github.com/yourusername/controlled-messaging-system.git
cd controlled-messaging-system

# Set up virtual environment
python -m venv venv
# Windows: venv\Scripts\activate
# Mac/Linux: source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```
🗄️ Database Setup
Run these SQL scripts in order using SQL Developer or SQL*Plus:

```bash
sqlplus system/your_password@localhost:1521/ORCL @database/01_schema.sql
sqlplus system/your_password@localhost:1521/ORCL @database/02_triggers.sql
sqlplus system/your_password@localhost:1521/ORCL @database/03_sample_data.sql
sqlplus system/your_password@localhost:1521/ORCL @database/04_reports.sql
```
⚙️ Configuration
Update app.py with your database credentials:

```python
DB_CONFIG = {
    'user': 'system',
    'password': 'your_password',
    'dsn': 'localhost:1521/ORCL'
}
```
🏃 Running the App
```bash
python app.py
```
Access at: http://localhost:5000
```table
🔑 Default Users
Role	Username	Password
Admin	admin1	hash_admin123
Teacher	teacher1	hash_teacher123
Student	student1	hash_student123
```
📁 Project Structure
```text
controlled-messaging-system/
├── app.py                 # Main Flask application
├── requirements.txt       # Python dependencies
├── database/              # SQL scripts
│   ├── 01_schema.sql      # Table creation
│   ├── 02_triggers.sql    # Database triggers
│   ├── 03_sample_data.sql # Sample data
│   └── 04_reports.sql     # Views and procedures
├── templates/             # HTML templates
└── static/                # CSS and JS files
```
