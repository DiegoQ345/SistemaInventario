#ifndef TICKETTEMPLATEREPOSITORY_H
#define TICKETTEMPLATEREPOSITORY_H

#include <QObject>
#include <QString>
#include <QJsonObject>
#include <QJsonArray>
#include <optional>

/**
 * @brief Estructura para almacenar un diseño de ticket
 */
struct TicketTemplate {
    int id;
    QString name;
    QString layoutJson;
    bool isActive;
    QString createdAt;
    QString updatedAt;
};

/**
 * @brief Repositorio para gestionar diseños de tickets
 */
class TicketTemplateRepository : public QObject
{
    Q_OBJECT

public:
    explicit TicketTemplateRepository(QObject *parent = nullptr);

    /**
     * @brief Guardar un nuevo diseño de ticket
     * @param name Nombre del diseño
     * @param layoutJson JSON con el diseño del ticket
     * @return ID del diseño guardado, o -1 si hay error
     */
    Q_INVOKABLE int saveTemplate(const QString& name, const QString& layoutJson);

    /**
     * @brief Actualizar un diseño existente
     * @param id ID del diseño
     * @param name Nuevo nombre
     * @param layoutJson Nuevo diseño
     * @return true si se actualizó correctamente
     */
    Q_INVOKABLE bool updateTemplate(int id, const QString& name, const QString& layoutJson);

    /**
     * @brief Obtener un diseño por ID
     * @param id ID del diseño
     * @return Diseño si existe
     */
    Q_INVOKABLE QVariantMap getTemplate(int id);

    /**
     * @brief Obtener el diseño activo
     * @return Diseño activo si existe
     */
    Q_INVOKABLE QVariantMap getActiveTemplate();

    /**
     * @brief Obtener todos los diseños
     * @return Lista de diseños
     */
    Q_INVOKABLE QVariantList getAllTemplates();

    /**
     * @brief Establecer un diseño como activo
     * @param id ID del diseño
     * @return true si se estableció correctamente
     */
    Q_INVOKABLE bool setActiveTemplate(int id);

    /**
     * @brief Eliminar un diseño
     * @param id ID del diseño
     * @return true si se eliminó correctamente
     */
    Q_INVOKABLE bool deleteTemplate(int id);

    /**
     * @brief Verificar si existe un diseño con el nombre dado
     * @param name Nombre del diseño
     * @param excludeId ID a excluir de la búsqueda (para actualizaciones)
     * @return true si existe
     */
    Q_INVOKABLE bool templateNameExists(const QString& name, int excludeId = -1);

private:
    QString m_lastError;

    // Método auxiliar para convertir TicketTemplate a QVariantMap
    QVariantMap templateToVariantMap(const TicketTemplate& tmpl);
};

#endif // TICKETTEMPLATEREPOSITORY_H
