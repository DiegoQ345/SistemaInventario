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

    // Leer primera fila (encabezados) - TODAS las columnas hasta la última con datos
    int maxCol = xlsx.dimension().lastColumn();
    qDebug() << "[ExcelImportService] Leyendo columnas del Excel, total:" << maxCol;
    
    for (int col = 1; col <= maxCol; ++col) {
        QVariant cellValue = xlsx.read(1, col);
        QString columnName = cellValue.toString().trimmed();
        
        // Si la columna está vacía, usar un nombre genérico
        if (columnName.isEmpty()) {
            columnName = QString("Columna %1").arg(col);
        }
        
        columns.append(columnName);
        qDebug() << "  Columna" << col << ":" << columnName;
    }

    qDebug() << "[ExcelImportService] Total columnas detectadas:" << columns.size();
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

    qDebug() << "[ExcelImportService] Iniciando importación:";
    qDebug() << "  Total filas:" << totalRows;
    qDebug() << "  Fila inicial:" << startRow;
    qDebug() << "  Mapeos activos:" << columnMappings.size();
    for (const auto& m : columnMappings) {
        if (m.isMapped) {
            qDebug() << "    " << m.excelColumn << "(índice" << m.columnIndex << ") ->" << m.fieldName;
        }
    }
    
    for (int rowIndex = startRow; rowIndex <= totalRows; ++rowIndex) {
        // Actualizar progreso
        int progress = ((rowIndex - startRow + 1) * 100) / result.totalRows;
        emit importProgress(progress, QString("Procesando fila %1 de %2...")
                          .arg(rowIndex - startRow + 1).arg(result.totalRows));

        qDebug() << "\n=== FILA" << rowIndex << "===";
        
        // Leer fila
        QMap<QString, QVariant> rowData = readRow(xlsx, rowIndex, columnMappings);

        if (rowData.isEmpty()) {
            qWarning() << "Fila vacía, saltando...";
            continue;
        }

        // Validar
        QString errorMessage;
        if (!validateProductData(rowData, columnMappings, errorMessage)) {
            qWarning() << "Validación falló:" << errorMessage;
            result.failedRows++;
            result.errors.append(QString("Fila %1: %2").arg(rowIndex).arg(errorMessage));
            continue;
        }

        // Convertir a Product
        Product product = mapRowToProduct(rowData, columnMappings, errorMessage);
        if (!errorMessage.isEmpty()) {
            qWarning() << "Mapeo falló:" << errorMessage;
            result.failedRows++;
            result.errors.append(QString("Fila %1: %2").arg(rowIndex).arg(errorMessage));
            continue;
        }

        qDebug() << "Producto mapeado:" << product.name << "|" << product.sku;
        
        // Verificar si el SKU ya existe
        auto existingProduct = productService.getProductBySku(product.sku);
        
        if (existingProduct.has_value()) {
            // El producto ya existe, ACTUALIZAR en lugar de crear
            qDebug() << "  ⚠️ Producto existente encontrado (ID:" << existingProduct->id << "), actualizando...";
            
            // Mantener el ID del producto existente
            product.id = existingProduct->id;
            
            // Actualizar producto
            if (productService.updateProduct(product, errorMessage)) {
                qDebug() << "✓ Producto actualizado exitosamente";
                result.importedRows++;
            } else {
                qWarning() << "✗ Error actualizando:" << errorMessage;
                result.failedRows++;
                result.errors.append(QString("Fila %1: %2").arg(rowIndex).arg(errorMessage));
            }
        } else {
            // El producto no existe, CREAR nuevo
            qDebug() << "  ➕ Producto nuevo, creando...";
            
            if (productService.createProduct(product, errorMessage)) {
                qDebug() << "✓ Producto creado exitosamente";
                result.importedRows++;
            } else {
                qWarning() << "✗ Error creando:" << errorMessage;
                result.failedRows++;
                result.errors.append(QString("Fila %1: %2").arg(rowIndex).arg(errorMessage));
            }
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

    qDebug() << "[ExcelImportService] Mapeando fila a Product:";
    
    for (const auto& mapping : mappings) {
        if (!mapping.isMapped) continue;

        QVariant value = row.value(mapping.fieldName);
        qDebug() << "  " << mapping.fieldName << ":" << value;

        if (mapping.fieldName == "name") {
            product.name = value.toString().trimmed();
        } else if (mapping.fieldName == "sku") {
            product.sku = value.toString().trimmed();
        } else if (mapping.fieldName == "barcode") {
            product.barcode = value.toString().trimmed();
        } else if (mapping.fieldName == "currentStock") {
            product.currentStock = value.toDouble();
        } else if (mapping.fieldName == "minimumStock") {
            product.minimumStock = value.toDouble();
        } else if (mapping.fieldName == "purchasePrice") {
            product.purchasePrice = value.toDouble();
        } else if (mapping.fieldName == "salePrice") {
            product.salePrice = value.toDouble();
        } else if (mapping.fieldName == "description") {
            product.description = value.toString();
        }
    }

    qDebug() << "  Product creado:" << product.name << "|" << product.sku << "|" << product.salePrice;
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

    // Verificar que tenga SKU
    QString sku = row.value("sku").toString().trimmed();
    if (sku.isEmpty()) {
        errorMessage = "El SKU es obligatorio";
        return false;
    }

    // Verificar precio de venta si está presente
    if (row.contains("salePrice")) {
        double salePrice = row.value("salePrice").toDouble();
        if (salePrice < 0) {
            errorMessage = "El precio de venta no puede ser negativo";
            return false;
        }
    }

    return true;
}

QMap<QString, QVariant> ExcelImportService::readRow(const QXlsx::Document& xlsx,
                                                    int rowIndex,
                                                    const QList<ColumnMapping>& mappings)
{
    QMap<QString, QVariant> row;

    qDebug() << "[ExcelImportService] Leyendo fila" << rowIndex;
    
    for (const auto& mapping : mappings) {
        if (!mapping.isMapped || mapping.columnIndex < 0) continue;

        // QXlsx usa índices base 1, columnIndex ya está en base 0, así que sumamos 1
        int excelColIndex = mapping.columnIndex + 1;
        QVariant cellValue = xlsx.read(rowIndex, excelColIndex);
        
        qDebug() << "  Col" << excelColIndex << "(" << mapping.excelColumn << ") ->" 
                 << mapping.fieldName << ":" << cellValue;
        
        QVariant convertedValue = convertValue(mapping.fieldName, cellValue);
        row[mapping.fieldName] = convertedValue;
    }

    qDebug() << "  Datos leídos:" << row;
    return row;
}

QVariant ExcelImportService::convertValue(const QString& fieldName, const QVariant& value)
{
    if (value.isNull()) {
        return QVariant();
    }

    // Campos numéricos
    if (fieldName == "currentStock" || fieldName == "minimumStock" ||
        fieldName == "purchasePrice" || fieldName == "salePrice") {
        bool ok;
        double numValue = value.toDouble(&ok);
        if (!ok) {
            qWarning() << "[ExcelImportService] No se pudo convertir a número:" << fieldName << value;
            return 0.0;
        }
        return numValue;
    }

    // Campos de texto
    return value.toString().trimmed();
}
