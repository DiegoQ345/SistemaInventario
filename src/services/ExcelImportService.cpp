#include "ExcelImportService.h"
#include "ProductService.h"
#include "../database/DatabaseManager.h"
#include <xlsxdocument.h>
#include <xlsxcellrange.h>
#include <QSqlQuery>
#include <QSqlError>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

ExcelImportService::ExcelImportService(QObject *parent)
    : QObject(parent)
{
}

QStringList ExcelImportService::loadExcelFile(const QString& filePath)
{
    QStringList columns;
    
    QXlsx::Document xlsx(filePath);
    if (!xlsx.load()) {
        qCritical() << "Error cargando archivo Excel:" << filePath;
        return columns;
    }

    m_currentFilePath = filePath;

    // Leer primera fila (encabezados)
    int maxCol = xlsx.dimension().lastColumn();
    for (int col = 1; col <= maxCol; ++col) {
        QVariant cellValue = xlsx.read(1, col);
        if (!cellValue.isNull() && !cellValue.toString().isEmpty()) {
            columns.append(cellValue.toString().trimmed());
        }
    }

    return columns;
}

ExcelImportService::PreviewData ExcelImportService::getPreview(
    const QString& filePath,
    const QList<ColumnMapping>& columnMappings,
    int maxRows)
{
    PreviewData preview;
    preview.columnMappings = columnMappings;

    QXlsx::Document xlsx(filePath);
    if (!xlsx.load()) {
        preview.hasErrors = true;
        preview.errorMessage = "Error cargando archivo Excel";
        return preview;
    }

    int totalRows = xlsx.dimension().lastRow();
    preview.totalRows = totalRows - 1;  // Menos la fila de encabezados

    // Leer primeras N filas
    int rowsToRead = qMin(maxRows, totalRows - 1);
    for (int i = 0; i < rowsToRead; ++i) {
        int rowIndex = i + 2;  // Saltar encabezados
        QMap<QString, QVariant> row = readRow(xlsx, rowIndex, columnMappings);
        preview.rows.append(row);
    }

    return preview;
}

ExcelImportService::ImportResult ExcelImportService::importProducts(
    const QString& filePath,
    const QList<ColumnMapping>& columnMappings,
    bool skipFirstRow)
{
    ImportResult result;

    QXlsx::Document xlsx(filePath);
    if (!xlsx.load()) {
        result.success = false;
        result.errors.append("Error cargando archivo Excel");
        return result;
    }

    ProductService productService;

    int totalRows = xlsx.dimension().lastRow();
    int startRow = skipFirstRow ? 2 : 1;
    result.totalRows = totalRows - startRow + 1;

    emit importProgress(0, "Iniciando importación...");

    for (int rowIndex = startRow; rowIndex <= totalRows; ++rowIndex) {
        // Actualizar progreso
        int progress = ((rowIndex - startRow + 1) * 100) / result.totalRows;
        emit importProgress(progress, QString("Procesando fila %1 de %2...")
                          .arg(rowIndex - startRow + 1).arg(result.totalRows));

        // Leer fila
        QMap<QString, QVariant> rowData = readRow(xlsx, rowIndex, columnMappings);

        // Validar
        QString errorMessage;
        if (!validateProductData(rowData, columnMappings, errorMessage)) {
            result.failedRows++;
            result.errors.append(QString("Fila %1: %2").arg(rowIndex).arg(errorMessage));
            continue;
        }

        // Convertir a Product
        Product product = mapRowToProduct(rowData, columnMappings, errorMessage);
        if (!errorMessage.isEmpty()) {
            result.failedRows++;
            result.errors.append(QString("Fila %1: %2").arg(rowIndex).arg(errorMessage));
            continue;
        }

        // Guardar producto
        if (productService.createProduct(product, errorMessage)) {
            result.importedRows++;
        } else {
            result.failedRows++;
            result.errors.append(QString("Fila %1: %2").arg(rowIndex).arg(errorMessage));
        }
    }

    result.success = (result.importedRows > 0);
    emit importProgress(100, "Importación completada");
    emit importCompleted(result.importedRows, result.failedRows);

    return result;
}

bool ExcelImportService::saveTemplate(const QString& templateName,
                                     const QList<ColumnMapping>& columnMappings,
                                     QString& errorMessage)
{
    // Convertir mapeo a JSON
    QJsonArray mappingsArray;
    for (const auto& mapping : columnMappings) {
        QJsonObject mappingObj;
        mappingObj["excelColumn"] = mapping.excelColumn;
        mappingObj["fieldName"] = mapping.fieldName;
        mappingObj["columnIndex"] = mapping.columnIndex;
        mappingObj["isMapped"] = mapping.isMapped;
        mappingsArray.append(mappingObj);
    }

    QJsonDocument doc(mappingsArray);
    QString jsonStr = doc.toJson(QJsonDocument::Compact);

    // Guardar en base de datos
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare(
        "INSERT OR REPLACE INTO import_templates (name, column_mapping, updated_at) "
        "VALUES (:name, :mapping, datetime('now'))"
    );
    query.bindValue(":name", templateName);
    query.bindValue(":mapping", jsonStr);

    if (!query.exec()) {
        errorMessage = query.lastError().text();
        qCritical() << "Error guardando plantilla:" << errorMessage;
        return false;
    }

    return true;
}

QList<ExcelImportService::ColumnMapping> ExcelImportService::loadTemplate(const QString& templateName)
{
    QList<ColumnMapping> mappings;

    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("SELECT column_mapping FROM import_templates WHERE name = :name");
    query.bindValue(":name", templateName);

    if (!query.exec() || !query.next()) {
        return mappings;
    }

    QString jsonStr = query.value(0).toString();
    QJsonDocument doc = QJsonDocument::fromJson(jsonStr.toUtf8());
    QJsonArray mappingsArray = doc.array();

    for (const auto& value : mappingsArray) {
        QJsonObject obj = value.toObject();
        ColumnMapping mapping;
        mapping.excelColumn = obj["excelColumn"].toString();
        mapping.fieldName = obj["fieldName"].toString();
        mapping.columnIndex = obj["columnIndex"].toInt();
        mapping.isMapped = obj["isMapped"].toBool();
        mappings.append(mapping);
    }

    return mappings;
}

QStringList ExcelImportService::getTemplates()
{
    QStringList templates;
    QSqlQuery query(DatabaseManager::instance().database());
    
    if (!query.exec("SELECT name FROM import_templates ORDER BY name")) {
        return templates;
    }

    while (query.next()) {
        templates.append(query.value(0).toString());
    }

    return templates;
}

bool ExcelImportService::deleteTemplate(const QString& templateName)
{
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare("DELETE FROM import_templates WHERE name = :name");
    query.bindValue(":name", templateName);
    return query.exec();
}

QStringList ExcelImportService::getAvailableFields()
{
    return {
        "name",           // Nombre del producto
        "sku",            // SKU
        "barcode",        // Código de barras
        "category",       // Categoría
        "stock",          // Stock actual
        "minimum_stock",  // Stock mínimo
        "purchase_price", // Precio de compra
        "sale_price",     // Precio de venta
        "description"     // Descripción
    };
}

QString ExcelImportService::getFieldDisplayName(const QString& fieldName)
{
    static QMap<QString, QString> displayNames = {
        {"name", "Nombre"},
        {"sku", "SKU"},
        {"barcode", "Código de Barras"},
        {"category", "Categoría"},
        {"stock", "Stock Actual"},
        {"minimum_stock", "Stock Mínimo"},
        {"purchase_price", "Precio de Compra"},
        {"sale_price", "Precio de Venta"},
        {"description", "Descripción"}
    };

    return displayNames.value(fieldName, fieldName);
}

Product ExcelImportService::mapRowToProduct(const QMap<QString, QVariant>& row,
                                           const QList<ColumnMapping>& mappings,
                                           QString& errorMessage)
{
    Product product;
    product.active = true;

    for (const auto& mapping : mappings) {
        if (!mapping.isMapped) continue;

        QVariant value = row.value(mapping.fieldName);

        if (mapping.fieldName == "name") {
            product.name = value.toString().trimmed();
        } else if (mapping.fieldName == "sku") {
            product.sku = value.toString().trimmed();
        } else if (mapping.fieldName == "barcode") {
            product.barcode = value.toString().trimmed();
        } else if (mapping.fieldName == "category") {
            // TODO: Buscar o crear categoría
            // Por ahora solo guardamos el nombre
        } else if (mapping.fieldName == "stock") {
            product.currentStock = value.toDouble();
        } else if (mapping.fieldName == "minimum_stock") {
            product.minimumStock = value.toDouble();
        } else if (mapping.fieldName == "purchase_price") {
            product.purchasePrice = value.toDouble();
        } else if (mapping.fieldName == "sale_price") {
            product.salePrice = value.toDouble();
        } else if (mapping.fieldName == "description") {
            product.description = value.toString();
        }
    }

    return product;
}

bool ExcelImportService::validateProductData(const QMap<QString, QVariant>& row,
                                            const QList<ColumnMapping>& mappings,
                                            QString& errorMessage)
{
    // Verificar que tenga nombre
    QString name = row.value("name").toString().trimmed();
    if (name.isEmpty()) {
        errorMessage = "El nombre del producto es obligatorio";
        return false;
    }

    // Verificar precio de venta
    double salePrice = row.value("sale_price").toDouble();
    if (salePrice < 0) {
        errorMessage = "El precio de venta no puede ser negativo";
        return false;
    }

    return true;
}

QMap<QString, QVariant> ExcelImportService::readRow(const QXlsx::Document& xlsx,
                                                    int rowIndex,
                                                    const QList<ColumnMapping>& mappings)
{
    QMap<QString, QVariant> row;

    for (const auto& mapping : mappings) {
        if (!mapping.isMapped || mapping.columnIndex < 0) continue;

        QVariant cellValue = xlsx.read(rowIndex, mapping.columnIndex + 1);  // QXlsx usa índice 1
        QVariant convertedValue = convertValue(mapping.fieldName, cellValue);
        row[mapping.fieldName] = convertedValue;
    }

    return row;
}

QVariant ExcelImportService::convertValue(const QString& fieldName, const QVariant& value)
{
    if (value.isNull()) {
        return QVariant();
    }

    // Campos numéricos
    if (fieldName == "stock" || fieldName == "minimum_stock" ||
        fieldName == "purchase_price" || fieldName == "sale_price") {
        return value.toDouble();
    }

    // Campos de texto
    return value.toString().trimmed();
}
