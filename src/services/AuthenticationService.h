#ifndef AUTHENTICATIONSERVICE_H
#define AUTHENTICATIONSERVICE_H

#include <QObject>
#include "../models/User.h"
#include <optional>

class UserRepository;

/**
 * @brief Servicio de autenticación y gestión de sesión
 */
class AuthenticationService : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isAuthenticated READ isAuthenticated NOTIFY authenticationChanged)
    Q_PROPERTY(QString currentUsername READ currentUsername NOTIFY authenticationChanged)
    Q_PROPERTY(QString currentUserFullName READ currentUserFullName NOTIFY authenticationChanged)
    Q_PROPERTY(QString currentUserRole READ currentUserRole NOTIFY authenticationChanged)
    
    // Permisos para UI
    Q_PROPERTY(bool canAccessDashboard READ canAccessDashboard NOTIFY authenticationChanged)
    Q_PROPERTY(bool canAccessProducts READ canAccessProducts NOTIFY authenticationChanged)
    Q_PROPERTY(bool canAccessSales READ canAccessSales NOTIFY authenticationChanged)
    Q_PROPERTY(bool canAccessInventory READ canAccessInventory NOTIFY authenticationChanged)
    Q_PROPERTY(bool canAccessCustomers READ canAccessCustomers NOTIFY authenticationChanged)
    Q_PROPERTY(bool canAccessReports READ canAccessReports NOTIFY authenticationChanged)
    Q_PROPERTY(bool canAccessSettings READ canAccessSettings NOTIFY authenticationChanged)
    Q_PROPERTY(bool canAccessImport READ canAccessImport NOTIFY authenticationChanged)
    Q_PROPERTY(bool canAccessConsole READ canAccessConsole NOTIFY authenticationChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY authenticationChanged)

public:
    explicit AuthenticationService(QObject *parent = nullptr);
    ~AuthenticationService() override;

    // Singleton
    static AuthenticationService& instance();

    bool isAuthenticated() const { return m_currentUser.has_value(); }
    QString currentUsername() const;
    QString currentUserFullName() const;
    QString currentUserRole() const;
    int currentUserId() const;

    // Permisos
    bool canAccessDashboard() const;
    bool canAccessProducts() const;
    bool canAccessSales() const;
    bool canAccessInventory() const;
    bool canAccessCustomers() const;
    bool canAccessReports() const;
    bool canAccessSettings() const;
    bool canAccessImport() const;
    bool canAccessConsole() const;

    Q_INVOKABLE bool login(const QString& username, const QString& password);
    Q_INVOKABLE void logout();
    Q_INVOKABLE bool changePassword(const QString& oldPassword, const QString& newPassword);

    QString lastError() const { return m_lastError; }

signals:
    void authenticationChanged();
    void loginSucceeded();
    void loginFailed(const QString& error);
    void logoutCompleted();

private:
    UserRepository* m_userRepository;
    std::optional<User> m_currentUser;
    QString m_lastError;
};

#endif // AUTHENTICATIONSERVICE_H
