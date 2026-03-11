#include "UserRepository.h"
#include "../database/DatabaseManager.h"
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDebug>
#include <QCryptographicHash>

UserRepository::UserRepository(QObject *parent)
    : QObject(parent)
{
}

std::optional<User> UserRepository::create(const User& user)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare(
        "INSERT INTO users (username, password, full_name, email, role, custom_permissions, is_active) "
        "VALUES (:username, :password, :full_name, :email, :role, :custom_permissions, :is_active)"
    );
    
    query.bindValue(":username", user.username);
    query.bindValue(":password", hashPassword(user.password));
    query.bindValue(":full_name", user.fullName);
    query.bindValue(":email", user.email);
    query.bindValue(":role", user.roleToString());
    query.bindValue(":custom_permissions", user.role == UserRole::Custom ? user.permissionsToJson() : QString());
    query.bindValue(":is_active", user.isActive);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qWarning() << "Error creating user:" << m_lastError;
        return std::nullopt;
    }

    int newId = query.lastInsertId().toInt();
    return findById(newId);
}

std::optional<User> UserRepository::findById(int id)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("SELECT * FROM users WHERE id = :id");
    query.bindValue(":id", id);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        return std::nullopt;
    }

    if (query.next()) {
        return mapFromQuery(query);
    }

    return std::nullopt;
}

std::optional<User> UserRepository::findByUsername(const QString& username)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("SELECT * FROM users WHERE username = :username");
    query.bindValue(":username", username);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qWarning() << "Error ejecutando query:" << m_lastError;
        return std::nullopt;
    }

    if (query.next()) {
        return mapFromQuery(query);
    }

    return std::nullopt;
}

QList<User> UserRepository::findAll()
{
    QList<User> users;
    QSqlQuery query(DatabaseManager::instance().database());

    if (!query.exec("SELECT * FROM users ORDER BY username ASC")) {
        m_lastError = query.lastError().text();
        return users;
    }

    while (query.next()) {
        users.append(mapFromQuery(query));
    }

    return users;
}

bool UserRepository::update(const User& user)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare(
        "UPDATE users SET "
        "username = :username, "
        "full_name = :full_name, "
        "email = :email, "
        "role = :role, "
        "custom_permissions = :custom_permissions, "
        "is_active = :is_active "
        "WHERE id = :id"
    );

    query.bindValue(":id", user.id);
    query.bindValue(":username", user.username);
    query.bindValue(":full_name", user.fullName);
    query.bindValue(":email", user.email);
    query.bindValue(":role", user.roleToString());
    query.bindValue(":custom_permissions", user.role == UserRole::Custom ? user.permissionsToJson() : QString());
    query.bindValue(":is_active", user.isActive);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qWarning() << "Error updating user:" << m_lastError;
        return false;
    }

    return query.numRowsAffected() > 0;
}

bool UserRepository::deleteById(int id)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("DELETE FROM users WHERE id = :id");
    query.bindValue(":id", id);

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qWarning() << "Error deleting user:" << m_lastError;
        return false;
    }

    return query.numRowsAffected() > 0;
}

std::optional<User> UserRepository::authenticate(const QString& username, const QString& password)
{
    auto user = findByUsername(username);
    
    if (!user) {
        m_lastError = "Usuario no encontrado";
        return std::nullopt;
    }

    if (!user->isActive) {
        m_lastError = "Usuario inactivo";
        return std::nullopt;
    }

    if (!verifyPassword(password, user->password)) {
        m_lastError = "Contraseña incorrecta";
        return std::nullopt;
    }

    updateLastLogin(user->id);
    return user;
}

bool UserRepository::updateLastLogin(int userId)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("UPDATE users SET last_login = datetime('now') WHERE id = :id");
    query.bindValue(":id", userId);
    return query.exec();
}

bool UserRepository::changePassword(int userId, const QString& newPassword)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("UPDATE users SET password = :password WHERE id = :id");
    query.bindValue(":id", userId);
    query.bindValue(":password", hashPassword(newPassword));

    if (!query.exec()) {
        m_lastError = query.lastError().text();
        return false;
    }

    return query.numRowsAffected() > 0;
}

QString UserRepository::hashPassword(const QString& password) const
{
    // Simple SHA-256 hash (en producción usar bcrypt o similar)
    return QString(QCryptographicHash::hash(password.toUtf8(), QCryptographicHash::Sha256).toHex());
}

bool UserRepository::verifyPassword(const QString& password, const QString& hash) const
{
    return hashPassword(password) == hash;
}

User UserRepository::mapFromQuery(const QSqlQuery& query) const
{
    User user;
    user.id = query.value("id").toInt();
    user.username = query.value("username").toString();
    user.password = query.value("password").toString();
    user.fullName = query.value("full_name").toString();
    user.email = query.value("email").toString();
    user.role = User::roleFromString(query.value("role").toString());
    user.isActive = query.value("is_active").toBool();
    user.createdAt = QDateTime::fromString(query.value("created_at").toString(), Qt::ISODate);
    user.lastLogin = QDateTime::fromString(query.value("last_login").toString(), Qt::ISODate);
    
    // Cargar permisos personalizados si el rol es Custom
    if (user.role == UserRole::Custom) {
        QString permissionsJson = query.value("custom_permissions").toString();
        if (!permissionsJson.isEmpty()) {
            user.permissionsFromJson(permissionsJson);
        }
    }
    
    return user;
}

User UserRepository::getUserWithStats(int userId, const QDate& startDate, const QDate& endDate)
{
    auto userOpt = findById(userId);
    if (!userOpt) {
        return User();
    }
    
    User user = userOpt.value();
    
    // Construir query para estadísticas
    QString queryStr = "SELECT COUNT(*) as total_sales, COALESCE(SUM(total), 0) as total_revenue "
                       "FROM sales WHERE user_id = :user_id AND status = 'COMPLETED'";
    
    if (startDate.isValid() && endDate.isValid()) {
        queryStr += " AND date(created_at) BETWEEN :start_date AND :end_date";
    }
    
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare(queryStr);
    query.bindValue(":user_id", userId);
    
    if (startDate.isValid() && endDate.isValid()) {
        query.bindValue(":start_date", startDate.toString(Qt::ISODate));
        query.bindValue(":end_date", endDate.toString(Qt::ISODate));
    }
    
    if (query.exec() && query.next()) {
        user.totalSales = query.value("total_sales").toInt();
        user.totalRevenue = query.value("total_revenue").toDouble();
    }
    
    return user;
}
