#include "UserListModel.h"
#include "../repositories/UserRepository.h"
#include <QDebug>

UserListModel::UserListModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_showInactive(false)
{
    loadUsers();
}

int UserListModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_filteredUsers.count();
}

QVariant UserListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_filteredUsers.count())
        return QVariant();
    
    const User& user = m_filteredUsers[index.row()];
    
    switch (role) {
    case IdRole:
        return user.id;
    case UsernameRole:
        return user.username;
    case FullNameRole:
        return user.fullName;
    case EmailRole:
        return user.email;
    case RoleRole:
        return user.roleToString();
    case RoleDisplayRole:
        return user.roleToString();
    case IsActiveRole:
        return user.isActive;
    case CreatedAtRole:
        return user.createdAt.isValid() ? user.createdAt.toString("dd/MM/yyyy") : "";
    case LastLoginRole:
        return user.lastLogin.isValid() ? user.lastLogin.toString("dd/MM/yyyy hh:mm") : "Nunca";
    case TotalSalesRole:
        return user.totalSales;
    case TotalRevenueRole:
        return user.totalRevenue;
    case CustomPermissionsRole: {
        QStringList perms;
        for (const QString& perm : user.customPermissions) {
            perms << perm;
        }
        return perms;
    }
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> UserListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "userId";
    roles[UsernameRole] = "username";
    roles[FullNameRole] = "fullName";
    roles[EmailRole] = "email";
    roles[RoleRole] = "role";
    roles[RoleDisplayRole] = "roleDisplay";
    roles[IsActiveRole] = "isActive";
    roles[CreatedAtRole] = "createdAt";
    roles[LastLoginRole] = "lastLogin";
    roles[TotalSalesRole] = "totalSales";
    roles[TotalRevenueRole] = "totalRevenue";
    roles[CustomPermissionsRole] = "customPermissions";
    return roles;
}

void UserListModel::setSearchText(const QString& text)
{
    if (m_searchText != text) {
        m_searchText = text;
        emit searchTextChanged();
        applyFilters();
    }
}

void UserListModel::setRoleFilter(const QString& role)
{
    if (m_roleFilter != role) {
        m_roleFilter = role;
        emit roleFilterChanged();
        applyFilters();
    }
}

void UserListModel::setShowInactive(bool show)
{
    if (m_showInactive != show) {
        m_showInactive = show;
        emit showInactiveChanged();
        applyFilters();
    }
}

void UserListModel::loadUsers()
{
    beginResetModel();
    
    UserRepository repo;
    m_users = repo.findAll();
    
    // Cargar estadísticas para cada usuario
    for (int i = 0; i < m_users.size(); ++i) {
        User userWithStats = repo.getUserWithStats(m_users[i].id);
        m_users[i].totalSales = userWithStats.totalSales;
        m_users[i].totalRevenue = userWithStats.totalRevenue;
    }
    
    applyFilters();
    endResetModel();
    
    emit countChanged();
}

bool UserListModel::createUser(const QString& username, const QString& password,
                               const QString& fullName, const QString& email,
                               const QString& role, const QStringList& permissions)
{
    if (username.isEmpty() || password.isEmpty() || fullName.isEmpty()) {
        emit errorOccurred("Todos los campos obligatorios deben estar llenos");
        return false;
    }
    
    User newUser;
    newUser.username = username;
    newUser.password = password;  // Se hasheará en el repositorio
    newUser.fullName = fullName;
    newUser.email = email;
    newUser.role = User::roleFromString(role);
    newUser.isActive = true;
    
    // Si es rol Custom, asignar permisos
    if (newUser.role == UserRole::Custom) {
        for (const QString& perm : permissions) {
            newUser.customPermissions.insert(perm);
        }
    }
    
    UserRepository repo;
    auto createdUser = repo.create(newUser);
    
    if (!createdUser) {
        emit errorOccurred("Error al crear usuario: " + repo.lastError());
        return false;
    }
    
    loadUsers();  // Recargar lista
    emit userCreated(createdUser->id);
    emit operationCompleted("Usuario creado exitosamente");
    return true;
}

bool UserListModel::updateUser(int userId, const QString& username, const QString& fullName,
                               const QString& email, const QString& role,
                               const QStringList& permissions, bool isActive)
{
    if (username.isEmpty() || fullName.isEmpty()) {
        emit errorOccurred("El nombre de usuario y nombre completo son obligatorios");
        return false;
    }
    
    UserRepository repo;
    auto userOpt = repo.findById(userId);
    
    if (!userOpt) {
        emit errorOccurred("Usuario no encontrado");
        return false;
    }
    
    User user = userOpt.value();
    user.username = username;
    user.fullName = fullName;
    user.email = email;
    user.role = User::roleFromString(role);
    user.isActive = isActive;
    
    // Actualizar permisos si es Custom
    user.customPermissions.clear();
    if (user.role == UserRole::Custom) {
        for (const QString& perm : permissions) {
            user.customPermissions.insert(perm);
        }
    }
    
    if (!repo.update(user)) {
        emit errorOccurred("Error al actualizar usuario: " + repo.lastError());
        return false;
    }
    
    loadUsers();  // Recargar lista
    emit userUpdated(userId);
    emit operationCompleted("Usuario actualizado exitosamente");
    return true;
}

bool UserListModel::deleteUser(int userId)
{
    // No permitir eliminar el usuario admin por seguridad
    if (userId == 1) {
        emit errorOccurred("No se puede eliminar el usuario administrador principal");
        return false;
    }
    
    UserRepository repo;
    if (!repo.deleteById(userId)) {
        emit errorOccurred("Error al eliminar usuario: " + repo.lastError());
        return false;
    }
    
    loadUsers();  // Recargar lista
    emit userDeleted(userId);
    emit operationCompleted("Usuario eliminado exitosamente");
    return true;
}

bool UserListModel::changePassword(int userId, const QString& newPassword)
{
    if (newPassword.length() < 6) {
        emit errorOccurred("La contraseña debe tener al menos 6 caracteres");
        return false;
    }
    
    UserRepository repo;
    if (!repo.changePassword(userId, newPassword)) {
        emit errorOccurred("Error al cambiar contraseña: " + repo.lastError());
        return false;
    }
    
    emit operationCompleted("Contraseña actualizada exitosamente");
    return true;
}

bool UserListModel::toggleUserActive(int userId)
{
    UserRepository repo;
    auto userOpt = repo.findById(userId);
    
    if (!userOpt) {
        emit errorOccurred("Usuario no encontrado");
        return false;
    }
    
    User user = userOpt.value();
    user.isActive = !user.isActive;
    
    if (!repo.update(user)) {
        emit errorOccurred("Error al cambiar estado: " + repo.lastError());
        return false;
    }
    
    loadUsers();
    emit operationCompleted(user.isActive ? "Usuario activado" : "Usuario desactivado");
    return true;
}

QVariantMap UserListModel::getUserData(int userId)
{
    QVariantMap data;
    
    UserRepository repo;
    auto userOpt = repo.findById(userId);
    
    if (!userOpt) {
        return data;
    }
    
    const User& user = userOpt.value();
    data["id"] = user.id;
    data["username"] = user.username;
    data["fullName"] = user.fullName;
    data["email"] = user.email;
    data["role"] = user.roleToString();
    data["isActive"] = user.isActive;
    data["createdAt"] = user.createdAt.toString("dd/MM/yyyy");
    data["lastLogin"] = user.lastLogin.isValid() ? user.lastLogin.toString("dd/MM/yyyy hh:mm") : "Nunca";
    
    // Permisos personalizados
    QStringList permsList;
    for (const QString& perm : user.customPermissions) {
        permsList << perm;
    }
    data["customPermissions"] = permsList;
    
    return data;
}

QVariantMap UserListModel::getUserStats(int userId, const QDate& startDate, const QDate& endDate)
{
    QVariantMap stats;
    
    UserRepository repo;
    User user = repo.getUserWithStats(userId, startDate, endDate);
    
    stats["userId"] = user.id;
    stats["username"] = user.username;
    stats["fullName"] = user.fullName;
    stats["totalSales"] = user.totalSales;
    stats["totalRevenue"] = user.totalRevenue;
    stats["averageTicket"] = user.totalSales > 0 ? user.totalRevenue / user.totalSales : 0.0;
    
    return stats;
}

bool UserListModel::userHasPermission(int userId, const QString& permission)
{
    UserRepository repo;
    auto userOpt = repo.findById(userId);
    
    if (!userOpt) {
        return false;
    }
    
    return userOpt->hasPermission(permission);
}

QStringList UserListModel::getAvailablePermissions()
{
    return QStringList() 
        << Permissions::DASHBOARD
        << Permissions::PRODUCTS
        << Permissions::SALES
        << Permissions::INVENTORY
        << Permissions::CUSTOMERS
        << Permissions::REPORTS
        << Permissions::TICKETS
        << Permissions::SETTINGS
        << Permissions::IMPORT
        << Permissions::CONSOLE
        << Permissions::USERS;
}

QStringList UserListModel::getAvailableRoles()
{
    return QStringList() << "Admin" << "Vendedor" << "Programador" << "Custom";
}

QString UserListModel::getPermissionDescription(const QString& permission)
{
    static QMap<QString, QString> descriptions = {
        {Permissions::DASHBOARD, "Acceso al panel principal y estadísticas"},
        {Permissions::PRODUCTS, "Gestión de productos y categorías"},
        {Permissions::SALES, "Realizar ventas y consultar historial"},
        {Permissions::INVENTORY, "Control de inventario y stock"},
        {Permissions::CUSTOMERS, "Gestión de clientes"},
        {Permissions::REPORTS, "Generar y consultar reportes"},
        {Permissions::TICKETS, "Diseñar y configurar tickets de venta"},
        {Permissions::SETTINGS, "Configuración del sistema"},
        {Permissions::IMPORT, "Importar datos desde Excel"},
        {Permissions::CONSOLE, "Consola de depuración (desarrolladores)"},
        {Permissions::USERS, "Gestión de usuarios y permisos"}
    };
    
    return descriptions.value(permission, "Sin descripción");
}

void UserListModel::applyFilters()
{
    beginResetModel();
    m_filteredUsers.clear();
    
    for (const User& user : m_users) {
        // Filtrar por estado activo
        if (!m_showInactive && !user.isActive) {
            continue;
        }
        
        // Filtrar por rol
        if (!m_roleFilter.isEmpty() && user.roleToString() != m_roleFilter) {
            continue;
        }
        
        // Filtrar por texto de búsqueda
        if (!m_searchText.isEmpty()) {
            QString searchLower = m_searchText.toLower();
            if (!user.username.toLower().contains(searchLower) &&
                !user.fullName.toLower().contains(searchLower) &&
                !user.email.toLower().contains(searchLower)) {
                continue;
            }
        }
        
        m_filteredUsers.append(user);
    }
    
    endResetModel();
    emit countChanged();
}

User* UserListModel::findUserById(int userId)
{
    for (int i = 0; i < m_users.size(); ++i) {
        if (m_users[i].id == userId) {
            return &m_users[i];
        }
    }
    return nullptr;
}
