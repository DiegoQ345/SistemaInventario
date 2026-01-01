#include "ExcelImportViewModel.h"
#include <QDebug>

ExcelImportViewModel::ExcelImportViewModel(QObject *parent)
    : QObject(parent)
{
    connect(&m_service, &ExcelImportService::importProgress,
            this, &ExcelImportViewModel::onImportProgress);
    connect(&m_service, &ExcelImportService::importCompleted,
            this, &ExcelImportViewModel::onImportCompleted);
}

QStringList ExcelImportViewModel::availableFields() const
{
    return {
        "name",           // Nombre
        "sku",            // SKU
        "barcode",        // Código de barras
        "currentStock",   // Stock actual
        "minimumStock",   // Stock mínimo
        "purchasePrice",  // Precio de compra
        "salePrice",      // Precio de venta
        "description"     // Descripción
    };
}

bool ExcelImportViewModel::loadFile(const QString& filePath)
{
    setIsLoading(true);
    setErrorMessage("");

    qDebug() << "[ExcelImportViewModel] Cargando archivo:" << filePath;

    // Convertir file:// URL a path local
    QString localPath = filePath;
    if (localPath.startsWith("file:///")) {
        localPath = localPath.mid(8);  // Remover file:///
    }

    m_currentFilePath = localPath;
    m_excelColumns = m_service.loadExcelFile(localPath);

    if (m_excelColumns.isEmpty()) {
        setErrorMessage("No se pudieron leer las columnas del archivo Excel");
        setIsLoading(false);
        return false;
    }

    qDebug() << "[ExcelImportViewModel] Columnas detectadas:" << m_excelColumns;

    // Inicializar mapeos vacíos
    m_columnMappings.clear();
    for (int i = 0; i < m_excelColumns.size(); ++i) {
        ExcelImportService::ColumnMapping mapping;
        mapping.excelColumn = m_excelColumns[i];
        mapping.columnIndex = i;  // Mantener el orden original del Excel
        mapping.isMapped = false;
        
        // Auto-mapear si se detecta el campo
        QString suggestedField = autoMapColumn(m_excelColumns[i]);
        if (suggestedField != "ninguno") {
            mapping.fieldName = suggestedField;
            mapping.isMapped = true;
            qDebug() << "  Auto-mapeado:" << m_excelColumns[i] << "->" << suggestedField;
        }
        
        m_columnMappings.append(mapping);
    }

    qDebug() << "[ExcelImportViewModel] Total mapeos creados:" << m_columnMappings.size();
    
    emit excelColumnsChanged();
    setHasFile(true);
    setIsLoading(false);
    return true;
}

void ExcelImportViewModel::setColumnMapping(const QString& excelColumnName, const QString& fieldName)
{
    qDebug() << "[ExcelImportViewModel] Mapeando:" << excelColumnName << "→" << fieldName;

    // Encontrar el mapeo correspondiente
    for (auto& mapping : m_columnMappings) {
        if (mapping.excelColumn == excelColumnName) {
            if (fieldName.isEmpty() || fieldName == "ninguno") {
                mapping.fieldName = "";
                mapping.isMapped = false;
            } else {
                mapping.fieldName = fieldName;
                mapping.isMapped = true;
            }
            break;
        }
    }
}

void ExcelImportViewModel::loadPreview(int maxRows)
{
    qDebug() << "[ExcelImportViewModel] loadPreview llamado, maxRows:" << maxRows;
    
    // Limpiar estado previo
    m_previewRows.clear();
    emit previewRowsChanged();

    if (m_currentFilePath.isEmpty()) {
        setErrorMessage("No hay archivo cargado");
        return;
    }

    setIsLoading(true);
    setErrorMessage("");  // Limpiar errores previos

    qDebug() << "[ExcelImportViewModel] Solicitando preview con" << m_columnMappings.size() << "mapeos";
    
    auto preview = m_service.getPreview(m_currentFilePath, m_columnMappings, maxRows);

    if (preview.hasErrors) {
        setErrorMessage(preview.errorMessage);
        setIsLoading(false);
        return;
    }

    m_totalRows = preview.totalRows;
    emit totalRowsChanged();

    qDebug() << "[ExcelImportViewModel] Preview obtenido:" << preview.rows.size() << "filas de" << m_totalRows << "total";

    // Convertir a QVariantList para QML
    for (const auto& row : preview.rows) {
        QVariantMap rowMap;
        for (auto it = row.begin(); it != row.end(); ++it) {
            rowMap[it.key()] = it.value();
            qDebug() << "    " << it.key() << ":" << it.value();
        }
        m_previewRows.append(rowMap);
    }

    qDebug() << "[ExcelImportViewModel] m_previewRows tiene" << m_previewRows.size() << "elementos";

    setIsLoading(false);
    emit previewRowsChanged();
}

void ExcelImportViewModel::startImport()
{
    if (m_currentFilePath.isEmpty()) {
        setErrorMessage("No hay archivo cargado");
        return;
    }

    // Validar que al menos los campos obligatorios estén mapeados
    bool hasName = false, hasSku = false;
    for (const auto& mapping : m_columnMappings) {
        if (mapping.isMapped) {
            if (mapping.fieldName == "name") hasName = true;
            if (mapping.fieldName == "sku") hasSku = true;
        }
    }

    if (!hasName || !hasSku) {
        setErrorMessage("Debes mapear al menos: Nombre y SKU (campos obligatorios)");
        return;
    }

    setIsLoading(true);
    m_importProgress = 0;
    emit importProgressChanged();

    qDebug() << "[ExcelImportViewModel] Iniciando importación con" << m_columnMappings.size() << "mapeos...";
    for (const auto& mapping : m_columnMappings) {
        if (mapping.isMapped) {
            qDebug() << "  " << mapping.excelColumn << "(col" << mapping.columnIndex << ") ->" << mapping.fieldName;
        }
    }

    auto result = m_service.importProducts(m_currentFilePath, m_columnMappings, true);

    if (!result.success && result.importedRows == 0) {
        QString errorMsg = "Error en la importación:\n";
        int maxErrors = qMin(5, result.errors.size());
        for (int i = 0; i < maxErrors; ++i) {
            errorMsg += "\n• " + result.errors[i];
        }
        if (result.errors.size() > 5) {
            errorMsg += QString("\n... y %1 errores más").arg(result.errors.size() - 5);
        }
        setErrorMessage(errorMsg);
    } else {
        qDebug() << "[ExcelImportViewModel] Importación completada:" << result.importedRows << "productos";
    }

    setIsLoading(false);
}

void ExcelImportViewModel::clear()
{
    m_currentFilePath.clear();
    m_excelColumns.clear();
    m_columnMappings.clear();
    m_totalRows = 0;
    m_importProgress = 0;
    setErrorMessage("");

    emit excelColumnsChanged();
    emit totalRowsChanged();
    emit importProgressChanged();
}

void ExcelImportViewModel::resetImport()
{
    m_currentFilePath.clear();
    m_excelColumns.clear();
    m_columnMappings.clear();
    m_previewRows.clear();
    m_totalRows = 0;
    m_importProgress = 0;
    setErrorMessage("");
    
    emit excelColumnsChanged();
    emit previewRowsChanged();
    emit totalRowsChanged();
    emit importProgressChanged();
    emit hasFileChanged();
}

QString ExcelImportViewModel::autoMapColumn(const QString& columnName)
{
    QString columnLower = columnName.toLower();
    
    // Lógica de auto-mapeo inteligente
    if (columnLower.contains("nombre") || columnLower.contains("name") || columnLower.contains("producto")) {
        return "name";
    } else if (columnLower.contains("sku") || columnLower.contains("codigo")) {
        return "sku";
    } else if (columnLower.contains("barr") || columnLower.contains("ean") || columnLower.contains("upc")) {
        return "barcode";
    } else if (columnLower.contains("mín") || columnLower.contains("min") && (columnLower.contains("stock") || columnLower.contains("existencia"))) {
        return "minimumStock";
    } else if (columnLower.contains("stock") || columnLower.contains("existencia") || columnLower.contains("cantidad")) {
        return "currentStock";
    } else if (columnLower.contains("compra") || columnLower.contains("costo")) {
        return "purchasePrice";
    } else if (columnLower.contains("venta") || columnLower.contains("precio") || columnLower.contains("pvp")) {
        return "salePrice";
    } else if (columnLower.contains("desc") || columnLower.contains("detalle")) {
        return "description";
    }
    
    return "ninguno";
}

QVariantMap ExcelImportViewModel::getCurrentMapping() const
{
    QVariantMap mapping;
    for (const auto& m : m_columnMappings) {
        if (m.isMapped) {
            mapping[m.excelColumn] = m.fieldName;
        }
    }
    return mapping;
}

void ExcelImportViewModel::onImportProgress(int progress, const QString& message)
{
    m_importProgress = progress;
    emit importProgressChanged();
    qDebug() << "[ExcelImportViewModel]" << progress << "%" << message;
}

void ExcelImportViewModel::onImportCompleted(int imported, int failed)
{
    qDebug() << "[ExcelImportViewModel] Completado - Importados:" << imported << "Fallidos:" << failed;
    emit importCompleted(imported, failed);
}

void ExcelImportViewModel::setIsLoading(bool loading)
{
    if (m_isLoading != loading) {
        m_isLoading = loading;
        emit isLoadingChanged();
    }
}

void ExcelImportViewModel::setErrorMessage(const QString& message)
{
    if (m_errorMessage != message) {
        m_errorMessage = message;
        emit errorMessageChanged();
    }
}

void ExcelImportViewModel::setHasFile(bool has)
{
    emit hasFileChanged();
}
