#ifndef USERLISTMODEL_H
#define USERLISTMODEL_H

#include "../models/User.h"
#include <QAbstractListModel>
#include <QList>
#include <QString>
#include <QDate>

/**
 * @brief ViewModel para gestión de usuarios del sistema
 * 
 * Proporciona funcionalidad CRUD y gestión de permisos para usuarios
 */
class UserListModel : public QAbstractListModel
{
    Q_OBJECT
    
    Q_PROPERTY(int count READ count NOTIFY countChanged)
    Q_PROPERTY(QString searchText READ searchText WRITE setSearchText NOTIFY searchTextChanged)
    Q_PROPERTY(QString roleFilter READ roleFilter WRITE setRoleFilter NOTIFY roleFilterChanged)
    Q_PROPERTY(bool showInactive READ showInactive WRITE setShowInactive NOTIFY showInactiveChanged)

public:
    enum UserRoles {
        IdRole = Qt::UserRole + 1,
        UsernameRole,
        FullNameRole,
        EmailRole,
        RoleRole,
        RoleDisplayRole,
        IsActiveRole,
        CreatedAtRole,
        LastLoginRole,
        TotalSalesRole,
        TotalRevenueRole,
        HasPermissionRole,
        CustomPermissionsRole
    };

    explicit UserListModel(QObject *parent = nullptr);
    
    // QAbstractListModel interface
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;
    
    // Properties
    int count() const { return m_users.count(); }
    QString searchText() const { return m_searchText; }
    QString roleFilter() const { return m_roleFilter; }
    bool showInactive() const { return m_showInactive; }
    
    void setSearchText(const QString& text);
    void setRoleFilter(const QString& role);
    void setShowInactive(bool show);

public slots:
    /**
     * @brief Cargar todos los usuarios desde la base de datos
     */
    Q_INVOKABLE void loadUsers();
    
    /**
     * @brief Crear nuevo usuario
     */
    Q_INVOKABLE bool createUser(const QString& username, const QString& password, 
                                const QString& fullName, const QString& email,
                                const QString& role, const QStringList& permissions);
    
    /**
     * @brief Actualizar usuario existente
     */
    Q_INVOKABLE bool updateUser(int userId, const QString& username, const QString& fullName,
                                const QString& email, const QString& role,
                                const QStringList& permissions, bool isActive);
    
    /**
     * @brief Eliminar usuario
     */
    Q_INVOKABLE bool deleteUser(int userId);
    
    /**
     * @brief Cambiar contraseña de un usuario
     */
    Q_INVOKABLE bool changePassword(int userId, const QString& newPassword);
    
    /**
     * @brief Activar/desactivar usuario
     */
    Q_INVOKABLE bool toggleUserActive(int userId);
    
    /**
     * @brief Obtener datos completos de un usuario
     */
    Q_INVOKABLE QVariantMap getUserData(int userId);
    
    /**
     * @brief Obtener estadísticas de un usuario
     */
    Q_INVOKABLE QVariantMap getUserStats(int userId, const QDate& startDate = QDate(), 
                                         const QDate& endDate = QDate());
    
    /**
     * @brief Verificar si un usuario tiene un permiso específico
     */
    Q_INVOKABLE bool userHasPermission(int userId, const QString& permission);
    
    /**
     * @brief Obtener lista de todos los permisos disponibles
     */
    Q_INVOKABLE QStringList getAvailablePermissions();
    
    /**
     * @brief Obtener roles predefinidos disponibles
     */
    Q_INVOKABLE QStringList getAvailableRoles();
    
    /**
     * @brief Obtener descripción de un permiso
     */
    Q_INVOKABLE QString getPermissionDescription(const QString& permission);

signals:
    void countChanged();
    void searchTextChanged();
    void roleFilterChanged();
    void showInactiveChanged();
    void userCreated(int userId);
    void userUpdated(int userId);
    void userDeleted(int userId);
    void errorOccurred(const QString& message);
    void operationCompleted(const QString& message);

private:
    QList<User> m_users;
    QList<User> m_filteredUsers;
    QString m_searchText;
    QString m_roleFilter;
    bool m_showInactive;
    
    void applyFilters();
    User* findUserById(int userId);
};

#endif // USERLISTMODEL_H
