#include "AuthenticationService.h"
#include "../repositories/UserRepository.h"
#include "../database/DatabaseManager.h"
#include <QDebug>
#include <QCryptographicHash>
#include <QSqlQuery>
#include <QSqlError>

AuthenticationService::AuthenticationService(QObject *parent)
    : QObject(parent)
{
    m_userRepository = new UserRepository(this);
}

AuthenticationService::~AuthenticationService()
{
}

AuthenticationService& AuthenticationService::instance()
{
    static AuthenticationService instance;
    return instance;
}

QString AuthenticationService::currentUsername() const
{
    return m_currentUser ? m_currentUser->username : QString();
}

QString AuthenticationService::currentUserFullName() const
{
    return m_currentUser ? m_currentUser->fullName : QString();
}

QString AuthenticationService::currentUserRole() const
{
    return m_currentUser ? m_currentUser->roleToString() : QString();
}

int AuthenticationService::currentUserId() const
{
    return m_currentUser ? m_currentUser->id : 0;
}

bool AuthenticationService::canAccessDashboard() const
{
    return m_currentUser && m_currentUser->canAccessDashboard();
}

bool AuthenticationService::canAccessProducts() const
{
    return m_currentUser && m_currentUser->canAccessProducts();
}

bool AuthenticationService::canAccessSales() const
{
    return m_currentUser && m_currentUser->canAccessSales();
}

bool AuthenticationService::canAccessInventory() const
{
    return m_currentUser && m_currentUser->canAccessInventory();
}

bool AuthenticationService::canAccessCustomers() const
{
    return m_currentUser && m_currentUser->canAccessCustomers();
}

bool AuthenticationService::canAccessReports() const
{
    return m_currentUser && m_currentUser->canAccessReports();
}

bool AuthenticationService::canAccessSettings() const
{
    return m_currentUser && m_currentUser->canAccessSettings();
}

bool AuthenticationService::canAccessImport() const
{
    return m_currentUser && m_currentUser->canAccessImport();
}

bool AuthenticationService::canAccessConsole() const
{
    return m_currentUser && m_currentUser->canAccessConsole();
}

bool AuthenticationService::login(const QString& username, const QString& password)
{
    qDebug() << "Attempting login for user:" << username;
    
    // Debug: Verificar base de datos
    QSqlQuery debugQuery(DatabaseManager::instance().database());
    if (debugQuery.exec("SELECT COUNT(*) FROM users")) {
        if (debugQuery.next()) {
            qDebug() << "Total usuarios en BD:" << debugQuery.value(0).toInt();
        }
    } else {
        qWarning() << "Error verificando usuarios:" << debugQuery.lastError().text();
    }
    
    // Listar usuarios con más detalle
    if (debugQuery.exec("SELECT username, role, is_active, LENGTH(password) as pwd_len FROM users")) {
        qDebug() << "=== Usuarios disponibles ===";
        while (debugQuery.next()) {
            qDebug() << "  - Usuario:" << debugQuery.value(0).toString() 
                     << "| Rol:" << debugQuery.value(1).toString()
                     << "| Activo:" << debugQuery.value(2).toInt()
                     << "| Password length:" << debugQuery.value(3).toInt();
        }
    }
    
    // Calcular hash de la contraseña ingresada
    QString passwordHash = QString(QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256).toHex());
    qDebug() << "Hash de contraseña ingresada:" << passwordHash;

    auto user = m_userRepository->authenticate(username, password);
    
    if (user) {
        m_currentUser = user;
        qDebug() << "Login successful for:" << username << "Role:" << user->roleToString();
        emit authenticationChanged();
        emit loginSucceeded();
        return true;
    }

    m_lastError = m_userRepository->lastError();
    qWarning() << "Login failed:" << m_lastError;
    emit loginFailed(m_lastError);
    return false;
}

void AuthenticationService::logout()
{
    qDebug() << "Logging out user:" << currentUsername();
    m_currentUser.reset();
    emit authenticationChanged();
    emit logoutCompleted();
}

bool AuthenticationService::changePassword(const QString& oldPassword, const QString& newPassword)
{
    if (!m_currentUser) {
        m_lastError = "No hay usuario autenticado";
        return false;
    }

    if (!m_userRepository->verifyPassword(oldPassword, m_currentUser->password)) {
        m_lastError = "Contraseña actual incorrecta";
        return false;
    }

    if (m_userRepository->changePassword(m_currentUser->id, newPassword)) {
        // Actualizar el usuario actual
        auto updatedUser = m_userRepository->findById(m_currentUser->id);
        if (updatedUser) {
            m_currentUser = updatedUser;
        }
        return true;
    }

    m_lastError = m_userRepository->lastError();
    return false;
}
