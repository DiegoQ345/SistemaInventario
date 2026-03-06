#ifndef USER_H
#define USER_H

#include <QString>
#include <QDateTime>

/**
 * @brief Roles de usuario en el sistema
 */
enum class UserRole {
    Admin,        // Acceso completo
    Vendedor,     // Solo ventas y clientes
    Programador   // Acceso completo + consola de debug
};

/**
 * @brief Modelo de dominio para Usuario
 */
struct User
{
    int id = 0;
    QString username;
    QString password;  // Almacenado con hash
    QString fullName;
    UserRole role = UserRole::Vendedor;
    bool isActive = true;
    QDateTime createdAt;
    QDateTime lastLogin;

    bool isValid() const {
        return !username.isEmpty() && !password.isEmpty();
    }

    QString roleToString() const {
        switch (role) {
            case UserRole::Admin: return "Admin";
            case UserRole::Vendedor: return "Vendedor";
            case UserRole::Programador: return "Programador";
            default: return "Desconocido";
        }
    }

    static UserRole roleFromString(const QString& roleStr) {
        if (roleStr == "Admin") return UserRole::Admin;
        if (roleStr == "Vendedor") return UserRole::Vendedor;
        if (roleStr == "Programador") return UserRole::Programador;
        return UserRole::Vendedor;
    }

    bool canAccessDashboard() const {
        return true; // Todos los usuarios pueden ver el dashboard (con datos filtrados según rol)
    }

    bool canAccessProducts() const {
        return role == UserRole::Admin;
    }

    bool canAccessSales() const {
        return true; // Todos pueden acceder
    }

    bool canAccessInventory() const {
        return role == UserRole::Admin;
    }

    bool canAccessCustomers() const {
        return role == UserRole::Admin || role == UserRole::Vendedor;
    }

    bool canAccessReports() const {
        return role == UserRole::Admin || role == UserRole::Programador;
    }

    bool canAccessSettings() const {
        return role == UserRole::Admin || role == UserRole::Programador;
    }

    bool canAccessImport() const {
        return role == UserRole::Admin;
    }

    bool canAccessConsole() const {
        return role == UserRole::Programador;
    }
};

#endif // USER_H
