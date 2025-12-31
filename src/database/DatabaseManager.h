#ifndef DATABASEMANAGER_H
#define DATABASEMANAGER_H

#include <QObject>
#include <QSqlDatabase>
#include <QSqlError>
#include <QMutex>
#include <memory>

/**
 * @brief Gestor centralizado de base de datos (Singleton, thread-safe)
 * 
 * Responsabilidades:
 * - Gestionar conexión única a la base de datos SQLite
 * - Ejecutar migraciones automáticas
 * - Proporcionar transacciones seguras
 * - Logging de errores SQL
 * 
 * Arquitectura: Singleton para garantizar una única instancia
 */
class DatabaseManager : public QObject
{
    Q_OBJECT

public:
    /**
     * @brief Obtener instancia única del gestor
     */
    static DatabaseManager& instance();

    /**
     * @brief Inicializar base de datos y ejecutar migraciones
     * @param dbPath Ruta al archivo de base de datos (por defecto: data/inventory.db)
     * @return true si la inicialización fue exitosa
     */
    bool initialize(const QString& dbPath = "");

    /**
     * @brief Obtener referencia a la base de datos
     * @return QSqlDatabase& conexión activa
     */
    QSqlDatabase& database();

    /**
     * @brief Comenzar transacción
     */
    bool beginTransaction();

    /**
     * @brief Confirmar transacción
     */
    bool commit();

    /**
     * @brief Revertir transacción
     */
    bool rollback();

    /**
     * @brief Verificar si la base de datos está conectada
     */
    bool isConnected() const;

    /**
     * @brief Obtener último error SQL
     */
    QString lastError() const;

signals:
    /**
     * @brief Señal emitida cuando ocurre un error de base de datos
     */
    void databaseError(const QString& error);

    /**
     * @brief Señal emitida cuando la base de datos está lista
     */
    void databaseReady();

private:
    // Constructor privado (Singleton)
    explicit DatabaseManager(QObject *parent = nullptr);
    ~DatabaseManager();

    // Deshabilitar copia y asignación
    DatabaseManager(const DatabaseManager&) = delete;
    DatabaseManager& operator=(const DatabaseManager&) = delete;

    /**
     * @brief Ejecutar migraciones de esquema
     */
    bool runMigrations();

    /**
     * @brief Crear tablas iniciales
     */
    bool createTables();

    /**
     * @brief Verificar y actualizar versión del esquema
     */
    int getCurrentSchemaVersion();
    bool setSchemaVersion(int version);

    QSqlDatabase m_database;
    QString m_lastError;
    mutable QMutex m_mutex;  // Para thread-safety
    bool m_initialized;
};

#endif // DATABASEMANAGER_H
