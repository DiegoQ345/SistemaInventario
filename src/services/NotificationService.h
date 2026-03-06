#ifndef NOTIFICATIONSERVICE_H
#define NOTIFICATIONSERVICE_H

#include <QObject>
#include <QDateTime>
#include <QList>
#include <QVariantMap>

enum class NotificationType {
    Info,
    Warning,
    Error,
    Success
};

struct Notification {
    int id;
    QString title;
    QString message;
    NotificationType type;
    QDateTime timestamp;
    bool isRead;
    
    QVariantMap toVariantMap() const {
        QVariantMap map;
        map["id"] = id;
        map["title"] = title;
        map["message"] = message;
        map["type"] = static_cast<int>(type);
        map["timestamp"] = timestamp;
        map["isRead"] = isRead;
        return map;
    }
};

class NotificationService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int unreadCount READ unreadCount NOTIFY unreadCountChanged)
    Q_PROPERTY(QVariantList notifications READ notifications NOTIFY notificationsChanged)
    
public:
    static NotificationService& instance() {
        static NotificationService instance;
        return instance;
    }
    
    // Agregar notificación
    Q_INVOKABLE void addNotification(const QString& title, const QString& message, int type = 0);
    
    // Marcar como leída
    Q_INVOKABLE void markAsRead(int id);
    
    // Marcar todas como leídas
    Q_INVOKABLE void markAllAsRead();
    
    // Eliminar notificación
    Q_INVOKABLE void removeNotification(int id);
    
    // Limpiar todas
    Q_INVOKABLE void clearAll();
    
    // Getters
    int unreadCount() const;
    QVariantList notifications() const;
    
signals:
    void unreadCountChanged();
    void notificationsChanged();
    void notificationAdded(const QString& title, const QString& message);
    
private:
    explicit NotificationService(QObject *parent = nullptr);
    NotificationService(const NotificationService&) = delete;
    NotificationService& operator=(const NotificationService&) = delete;
    
    QList<Notification> m_notifications;
    int m_nextId = 1;
};

#endif // NOTIFICATIONSERVICE_H
