// Main JavaScript file for the messaging system

// Check for unread messages periodically
function checkUnreadMessages() {
    fetch('/api/unread_count')
        .then(response => response.json())
        .then(data => {
            const unreadCount = data.unread_count;
            updateUnreadBadge(unreadCount);
            
            if (unreadCount > 0) {
                showNotification(`You have ${unreadCount} unread message(s)`);
            }
        })
        .catch(error => console.error('Error checking unread messages:', error));
}

// Update unread message badge
function updateUnreadBadge(count) {
    const badge = document.querySelector('.badge');
    if (badge) {
        if (count > 0) {
            badge.textContent = count;
            badge.style.display = 'inline';
        } else {
            badge.style.display = 'none';
        }
    }
}

// Archive message
function archiveMessage(messageId) {
    if (!confirm('Are you sure you want to archive this message?')) {
        return;
    }
    
    fetch(`/archive_message/${messageId}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
        }
    })
    .then(response => response.json())
    .then(data => {
        if (data.success) {
            showNotification('Message archived successfully', 'success');
            // Remove the message row or update UI
            const messageRow = document.querySelector(`tr[data-message-id="${messageId}"]`);
            if (messageRow) {
                messageRow.remove();
            }
        } else {
            showNotification('Error archiving message: ' + data.error, 'error');
        }
    })
    .catch(error => {
        console.error('Error:', error);
        showNotification('Error archiving message', 'error');
    });
}

// Show notification
function showNotification(message, type = 'info') {
    // Create notification element
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    
    // Add close button
    const closeBtn = document.createElement('button');
    closeBtn.innerHTML = '×';
    closeBtn.className = 'notification-close';
    closeBtn.onclick = function() {
        notification.remove();
    };
    notification.appendChild(closeBtn);
    
    // Add to page
    document.body.appendChild(notification);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.remove();
        }
    }, 5000);
}

// Refresh inbox
function refreshInbox() {
    showNotification('Refreshing inbox...', 'info');
    location.reload();
}

// Validate message form
function validateMessageForm() {
    const subject = document.getElementById('subject');
    const messageBody = document.getElementById('message_body');
    
    if (subject.value.trim() === '') {
        showNotification('Subject cannot be empty', 'error');
        subject.focus();
        return false;
    }
    
    if (messageBody.value.trim() === '') {
        showNotification('Message body cannot be empty', 'error');
        messageBody.focus();
        return false;
    }
    
    if (messageBody.value.length > 4000) {
        showNotification('Message body is too long (max 4000 characters)', 'error');
        messageBody.focus();
        return false;
    }
    
    return true;
}

// Auto-resize textarea
function autoResizeTextarea(textarea) {
    textarea.style.height = 'auto';
    textarea.style.height = (textarea.scrollHeight) + 'px';
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    // Check for unread messages every 30 seconds
    checkUnreadMessages();
    setInterval(checkUnreadMessages, 30000);
    
    // Initialize textarea auto-resize
    const textareas = document.querySelectorAll('textarea');
    textareas.forEach(textarea => {
        textarea.addEventListener('input', function() {
            autoResizeTextarea(this);
        });
    });
    
    // Add form validation to message form
    const messageForm = document.querySelector('.message-form');
    if (messageForm) {
        messageForm.addEventListener('submit', function(e) {
            if (!validateMessageForm()) {
                e.preventDefault();
            }
        });
    }
    
    // Add keyboard shortcuts
    document.addEventListener('keydown', function(e) {
        // Ctrl+Shift+I for inbox
        if (e.ctrlKey && e.shiftKey && e.key === 'I') {
            e.preventDefault();
            window.location.href = '/inbox';
        }
        
        // Ctrl+Shift+M for new message
        if (e.ctrlKey && e.shiftKey && e.key === 'M') {
            e.preventDefault();
            window.location.href = '/send_message';
        }
        
        // Ctrl+Shift+D for dashboard
        if (e.ctrlKey && e.shiftKey && e.key === 'D') {
            e.preventDefault();
            window.location.href = '/dashboard';
        }
    });
});

// Add notification styles dynamically
const style = document.createElement('style');
style.textContent = `
    .notification {
        position: fixed;
        top: 20px;
        right: 20px;
        padding: 15px 20px;
        background: white;
        border-radius: 8px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
        z-index: 9999;
        min-width: 300px;
        animation: slideIn 0.3s ease;
        border-left: 4px solid var(--primary-color);
    }
    
    .notification-info {
        border-left-color: var(--primary-color);
    }
    
    .notification-success {
        border-left-color: var(--success-color);
    }
    
    .notification-error {
        border-left-color: var(--danger-color);
    }
    
    .notification-close {
        float: right;
        border: none;
        background: none;
        font-size: 20px;
        cursor: pointer;
        color: var(--secondary-color);
        padding: 0 5px;
    }
    
    .notification-close:hover {
        color: var(--dark-text);
    }
    
    @keyframes slideIn {
        from {
            transform: translateX(100%);
            opacity: 0;
        }
        to {
            transform: translateX(0);
            opacity: 1;
        }
    }
    
    .btn-back {
        display: inline-block;
        padding: 8px 16px;
        background-color: var(--light-bg);
        color: var(--dark-text);
        text-decoration: none;
        border-radius: 4px;
        border: 1px solid var(--border-color);
    }
    
    .btn-back:hover {
        background-color: var(--border-color);
    }
    
    .subject-cell a {
        color: var(--dark-text);
        text-decoration: none;
        font-weight: 500;
    }
    
    .subject-cell a:hover {
        color: var(--primary-color);
        text-decoration: underline;
    }
    
    tr.priority-urgent {
        border-left: 4px solid var(--danger-color);
    }
    
    tr.priority-high {
        border-left: 4px solid #f97316;
    }
    
    .form-actions {
        display: flex;
        gap: 10px;
        margin-top: 20px;
    }
`;

document.head.appendChild(style);