#include "NotificationService.h"
#include <QDebug>

NotificationService::NotificationService(QObject *parent)
    : QObject(parent)
{
}

void NotificationService::addNotification(const QString& title, const QString& message, int type)
{
    Notification notification;
    notification.id = m_nextId++;
    notification.title = title;
    notification.message = message;
    notification.type = static_cast<NotificationType>(type);
    notification.timestamp = QDateTime::currentDateTime();
    notification.isRead = false;
    
    // Insertar al inicio (más reciente primero)
    m_notifications.prepend(notification);
    
    // Limitar a 50 notificaciones
    if (m_notifications.size() > 50) {
        m_notifications.removeLast();
    }
    
    qDebug() << "Nueva notificación:" << title << "-" << message;
    
    emit notificationsChanged();
    emit unreadCountChanged();
    emit notificationAdded(title, message);
}

void NotificationService::markAsRead(int id)
{
    for (auto& notification : m_notifications) {
        if (notification.id == id && !notification.isRead) {
            notification.isRead = true;
            emit notificationsChanged();
            emit unreadCountChanged();
            break;
        }
    }
}

void NotificationService::markAllAsRead()
{
    bool changed = false;
    for (auto& notification : m_notifications) {
        if (!notification.isRead) {
            notification.isRead = true;
            changed = true;
        }
    }
    
    if (changed) {
        emit notificationsChanged();
        emit unreadCountChanged();
    }
}

void NotificationService::removeNotification(int id)
{
    for (int i = 0; i < m_notifications.size(); ++i) {
        if (m_notifications[i].id == id) {
            m_notifications.removeAt(i);
            emit notificationsChanged();
            emit unreadCountChanged();
            break;
        }
    }
}

void NotificationService::clearAll()
{
    if (!m_notifications.isEmpty()) {
        m_notifications.clear();
        emit notificationsChanged();
        emit unreadCountChanged();
    }
}

int NotificationService::unreadCount() const
{
    int count = 0;
    for (const auto& notification : m_notifications) {
        if (!notification.isRead) {
            count++;
        }
    }
    return count;
}

QVariantList NotificationService::notifications() const
{
    QVariantList list;
    for (const auto& notification : m_notifications) {
        list.append(notification.toVariantMap());
    }
    return list;
}
