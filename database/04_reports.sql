-- View for message statistics by user
CREATE OR REPLACE VIEW v_user_message_stats AS
SELECT 
    u.user_id,
    u.username,
    u.full_name,
    r.role_name,
    COUNT(DISTINCT m_sent.message_id) as messages_sent,
    COUNT(DISTINCT m_received.message_id) as messages_received,
    COUNT(DISTINCT CASE WHEN m_received.status = 'read' THEN m_received.message_id END) as messages_read,
    ROUND(AVG(CASE WHEN m_received.read_date IS NOT NULL 
              THEN (m_received.read_date - m_received.sent_date) * 24 * 60 END), 2) as avg_response_time_minutes
FROM users u
JOIN roles r ON u.role_id = r.role_id
LEFT JOIN messages m_sent ON u.user_id = m_sent.sender_id
LEFT JOIN messages m_received ON u.user_id = m_received.receiver_id
GROUP BY u.user_id, u.username, u.full_name, r.role_name;

-- View for daily message activity
CREATE OR REPLACE VIEW v_daily_message_activity AS
SELECT 
    TRUNC(sent_date) as message_date,
    COUNT(*) as total_messages,
    SUM(CASE WHEN priority = 'urgent' THEN 1 ELSE 0 END) as urgent_messages,
    SUM(CASE WHEN priority = 'high' THEN 1 ELSE 0 END) as high_priority_messages,
    SUM(CASE WHEN priority = 'normal' THEN 1 ELSE 0 END) as normal_messages,
    COUNT(DISTINCT sender_id) as unique_senders,
    COUNT(DISTINCT receiver_id) as unique_receivers
FROM messages
GROUP BY TRUNC(sent_date)
ORDER BY message_date DESC;

-- View for department communication analysis
CREATE OR REPLACE VIEW v_department_communication AS
SELECT 
    u_sender.department as sender_department,
    u_receiver.department as receiver_department,
    COUNT(*) as message_count,
    AVG(CASE WHEN m.read_date IS NOT NULL THEN 1 ELSE 0 END) * 100 as read_rate_percentage
FROM messages m
JOIN users u_sender ON m.sender_id = u_sender.user_id
JOIN users u_receiver ON m.receiver_id = u_receiver.user_id
GROUP BY u_sender.department, u_receiver.department;

-- Procedure to generate monthly report
CREATE OR REPLACE PROCEDURE sp_generate_monthly_report(
    p_month IN NUMBER,
    p_year IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
    SELECT 
        r.role_name,
        COUNT(DISTINCT m.message_id) as total_messages,
        COUNT(DISTINCT m.sender_id) as active_senders,
        COUNT(DISTINCT m.receiver_id) as active_receivers,
        SUM(CASE WHEN m.priority = 'urgent' THEN 1 ELSE 0 END) as urgent_messages,
        AVG(CASE WHEN m.read_date IS NOT NULL 
                 THEN EXTRACT(HOUR FROM (m.read_date - m.sent_date)) * 60 +
                      EXTRACT(MINUTE FROM (m.read_date - m.sent_date))
                 ELSE NULL END) as avg_read_time_minutes
    FROM messages m
    JOIN users u ON m.sender_id = u.user_id
    JOIN roles r ON u.role_id = r.role_id
    WHERE EXTRACT(MONTH FROM m.sent_date) = p_month
    AND EXTRACT(YEAR FROM m.sent_date) = p_year
    GROUP BY r.role_name;
END;
/