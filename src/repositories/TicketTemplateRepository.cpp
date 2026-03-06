#include "TicketTemplateRepository.h"
#include "../database/DatabaseManager.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>

TicketTemplateRepository::TicketTemplateRepository(QObject *parent)
    : QObject(parent)
{
}

int TicketTemplateRepository::saveTemplate(const QString& name, const QString& layoutJson)
{
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare("INSERT INTO ticket_templates (name, layout_json, is_active) "
                 "VALUES (:name, :layout_json, 0)");
    
    query.bindValue(":name", name);
    query.bindValue(":layout_json", layoutJson);
    
    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qCritical() << "Error guardando diseño de ticket:" << m_lastError;
        return -1;
    }
    
    return query.lastInsertId().toInt();
}

bool TicketTemplateRepository::updateTemplate(int id, const QString& name, const QString& layoutJson)
{
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare("UPDATE ticket_templates SET "
                 "name = :name, "
                 "layout_json = :layout_json, "
                 "updated_at = datetime('now') "
                 "WHERE id = :id");
    
    query.bindValue(":id", id);
    query.bindValue(":name", name);
    query.bindValue(":layout_json", layoutJson);
    
    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qCritical() << "Error actualizando diseño de ticket:" << m_lastError;
        return false;
    }
    
    return query.numRowsAffected() > 0;
}

QVariantMap TicketTemplateRepository::getTemplate(int id)
{
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare("SELECT id, name, layout_json, is_active, created_at, updated_at "
                 "FROM ticket_templates WHERE id = :id");
    
    query.bindValue(":id", id);
    
    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qCritical() << "Error obteniendo diseño de ticket:" << m_lastError;
        return QVariantMap();
    }
    
    if (query.next()) {
        TicketTemplate tmpl;
        tmpl.id = query.value("id").toInt();
        tmpl.name = query.value("name").toString();
        tmpl.layoutJson = query.value("layout_json").toString();
        tmpl.isActive = query.value("is_active").toBool();
        tmpl.createdAt = query.value("created_at").toString();
        tmpl.updatedAt = query.value("updated_at").toString();
        
        return templateToVariantMap(tmpl);
    }
    
    return QVariantMap();
}

QVariantMap TicketTemplateRepository::getActiveTemplate()
{
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare("SELECT id, name, layout_json, is_active, created_at, updated_at "
                 "FROM ticket_templates WHERE is_active = 1 LIMIT 1");
    
    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qCritical() << "Error obteniendo diseño activo:" << m_lastError;
        return QVariantMap();
    }
    
    if (query.next()) {
        TicketTemplate tmpl;
        tmpl.id = query.value("id").toInt();
        tmpl.name = query.value("name").toString();
        tmpl.layoutJson = query.value("layout_json").toString();
        tmpl.isActive = query.value("is_active").toBool();
        tmpl.createdAt = query.value("created_at").toString();
        tmpl.updatedAt = query.value("updated_at").toString();
        
        return templateToVariantMap(tmpl);
    }
    
    return QVariantMap();
}

QVariantList TicketTemplateRepository::getAllTemplates()
{
    QVariantList templates;
    
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare("SELECT id, name, layout_json, is_active, created_at, updated_at "
                 "FROM ticket_templates ORDER BY created_at DESC");
    
    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qCritical() << "Error obteniendo diseños:" << m_lastError;
        return templates;
    }
    
    while (query.next()) {
        TicketTemplate tmpl;
        tmpl.id = query.value("id").toInt();
        tmpl.name = query.value("name").toString();
        tmpl.layoutJson = query.value("layout_json").toString();
        tmpl.isActive = query.value("is_active").toBool();
        tmpl.createdAt = query.value("created_at").toString();
        tmpl.updatedAt = query.value("updated_at").toString();
        
        templates.append(templateToVariantMap(tmpl));
    }
    
    return templates;
}

bool TicketTemplateRepository::setActiveTemplate(int id)
{
    QSqlDatabase& db = DatabaseManager::instance().database();
    
    // Iniciar transacción
    if (!db.transaction()) {
        m_lastError = "Error iniciando transacción";
        return false;
    }
    
    QSqlQuery query(db);
    
    // Desactivar todos los diseños
    if (!query.exec("UPDATE ticket_templates SET is_active = 0")) {
        m_lastError = query.lastError().text();
        db.rollback();
        return false;
    }
    
    // Activar el diseño seleccionado
    query.prepare("UPDATE ticket_templates SET is_active = 1 WHERE id = :id");
    query.bindValue(":id", id);
    
    if (!query.exec()) {
        m_lastError = query.lastError().text();
        db.rollback();
        return false;
    }
    
    if (!db.commit()) {
        m_lastError = "Error confirmando transacción";
        return false;
    }
    
    return true;
}

bool TicketTemplateRepository::deleteTemplate(int id)
{
    QSqlQuery query(DatabaseManager::instance().database());
    
    query.prepare("DELETE FROM ticket_templates WHERE id = :id");
    query.bindValue(":id", id);
    
    if (!query.exec()) {
        m_lastError = query.lastError().text();
        qCritical() << "Error eliminando diseño de ticket:" << m_lastError;
        return false;
    }
    
    return query.numRowsAffected() > 0;
}

bool TicketTemplateRepository::templateNameExists(const QString& name, int excludeId)
{
    QSqlQuery query(DatabaseManager::instance().database());
    
    if (excludeId == -1) {
        query.prepare("SELECT COUNT(*) FROM ticket_templates WHERE name = :name");
        query.bindValue(":name", name);
    } else {
        query.prepare("SELECT COUNT(*) FROM ticket_templates WHERE name = :name AND id != :id");
        query.bindValue(":name", name);
        query.bindValue(":id", excludeId);
    }
    
    if (!query.exec()) {
        return false;
    }
    
    if (query.next()) {
        return query.value(0).toInt() > 0;
    }
    
    return false;
}

QVariantMap TicketTemplateRepository::templateToVariantMap(const TicketTemplate& tmpl)
{
    QVariantMap map;
    map["id"] = tmpl.id;
    map["name"] = tmpl.name;
    map["layoutJson"] = tmpl.layoutJson;
    map["isActive"] = tmpl.isActive;
    map["createdAt"] = tmpl.createdAt;
    map["updatedAt"] = tmpl.updatedAt;
    return map;
}
