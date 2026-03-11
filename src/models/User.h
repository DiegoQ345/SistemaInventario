#ifndef USER_H
#define USER_H

#include <QString>
#include <QDateTime>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSet>

/**
 * @brief Roles de usuario en el sistema
 */
enum class UserRole {
    Admin,        // Acceso completo
    Vendedor,     // Solo ventas y clientes
    Programador,  // Acceso completo + consola de debug
    Custom        // Permisos personalizados
};

/**
 * @brief Permisos disponibles en el sistema
 */
namespace Permissions {
    const QString DASHBOARD = "dashboard";
    const QString PRODUCTS = "products";
    const QString SALES = "sales";
    const QString INVENTORY = "inventory";
    const QString CUSTOMERS = "customers";
    const QString REPORTS = "reports";
    const QString TICKETS = "tickets";
    const QString SETTINGS = "settings";
    const QString IMPORT = "import";
    const QString CONSOLE = "console";
    const QString USERS = "users";
}

/**
 * @brief Modelo de dominio para Usuario
 */
struct User
{
    int id = 0;
    QString username;
    QString password;  // Almacenado con hash
    QString fullName;
    QString email;
    UserRole role = UserRole::Vendedor;
    QSet<QString> customPermissions;  // Permisos personalizados cuando role == Custom
    bool isActive = true;
    QDateTime createdAt;
    QDateTime lastLogin;
    
    // Estadísticas del usuario
    int totalSales = 0;
    double totalRevenue = 0.0;

    bool isValid() const {
        return !username.isEmpty() && !password.isEmpty();
    }

    QString roleToString() const {
        switch (role) {
            case UserRole::Admin: return "Admin";
            case UserRole::Vendedor: return "Vendedor";
            case UserRole::Programador: return "Programador";
            case UserRole::Custom: return "Custom";
            default: return "Desconocido";
        }
    }

    static UserRole roleFromString(const QString& roleStr) {
        if (roleStr == "Admin") return UserRole::Admin;
        if (roleStr == "Vendedor") return UserRole::Vendedor;
        if (roleStr == "Programador") return UserRole::Programador;
        if (roleStr == "Custom") return UserRole::Custom;
        return UserRole::Vendedor;
    }
    
    // Serialización de permisos personalizados
    QString permissionsToJson() const {
        QJsonArray jsonArray;
        for (const QString& perm : customPermissions) {
            jsonArray.append(perm);
        }
        QJsonObject obj;
        obj["permissions"] = jsonArray;
        return QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Compact));
    }
    
    void permissionsFromJson(const QString& json) {
        customPermissions.clear();
        QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8());
        if (doc.isObject()) {
            QJsonArray array = doc.object()["permissions"].toArray();
            for (const QJsonValue& val : array) {
                customPermissions.insert(val.toString());
            }
        }
    }
    
    // Verificación de permisos con soporte para roles y permisos personalizados
    bool hasPermission(const QString& permission) const {
        // Admin tiene todos los permisos
        if (role == UserRole::Admin) return true;
        
        // Si tiene rol Custom, usar permisos personalizados
        if (role == UserRole::Custom) {
            return customPermissions.contains(permission);
        }
        
        // Roles predefinidos (legacy)
        if (role == UserRole::Programador) {
            return permission != Permissions::USERS; // Todos excepto gestión de usuarios
        }
        
        if (role == UserRole::Vendedor) {
            return permission == Permissions::DASHBOARD ||
                   permission == Permissions::SALES ||
                   permission == Permissions::CUSTOMERS;
        }
        
        return false;
    }

    // Métodos de compatibilidad (legacy)
    bool canAccessDashboard() const { return hasPermission(Permissions::DASHBOARD); }
    bool canAccessProducts() const { return hasPermission(Permissions::PRODUCTS); }
    bool canAccessSales() const { return hasPermission(Permissions::SALES); }
    bool canAccessInventory() const { return hasPermission(Permissions::INVENTORY); }
    bool canAccessCustomers() const { return hasPermission(Permissions::CUSTOMERS); }
    bool canAccessReports() const { return hasPermission(Permissions::REPORTS); }
    bool canAccessSettings() const { return hasPermission(Permissions::SETTINGS); }
    bool canAccessImport() const { return hasPermission(Permissions::IMPORT); }
    bool canAccessConsole() const { return hasPermission(Permissions::CONSOLE); }
    bool canAccessUsers() const { return hasPermission(Permissions::USERS); }
    bool canAccessTickets() const { return hasPermission(Permissions::TICKETS); }
};

#endif // USER_H
