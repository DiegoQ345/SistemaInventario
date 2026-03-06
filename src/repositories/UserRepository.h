#ifndef USERREPOSITORY_H
#define USERREPOSITORY_H

#include "../models/User.h"
#include <QObject>
#include <QString>
#include <QList>
#include <QSqlQuery>
#include <optional>

class QSqlDatabase;

/**
 * @brief Repositorio para acceso a datos de usuarios
 */
class UserRepository : public QObject
{
    Q_OBJECT
public:
    explicit UserRepository(QObject *parent = nullptr);

    // CRUD Operations
    std::optional<User> create(const User& user);
    std::optional<User> findById(int id);
    std::optional<User> findByUsername(const QString& username);
    QList<User> findAll();
    bool update(const User& user);
    bool deleteById(int id);
    
    // Authentication
    std::optional<User> authenticate(const QString& username, const QString& password);
    bool updateLastLogin(int userId);
    bool changePassword(int userId, const QString& newPassword);

    // Helpers
    QString hashPassword(const QString& password) const;
    bool verifyPassword(const QString& password, const QString& hash) const;

    QString lastError() const { return m_lastError; }

private:
    QString m_lastError;

    User mapFromQuery(const QSqlQuery& query) const;
};

#endif // USERREPOSITORY_H
