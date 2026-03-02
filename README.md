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
