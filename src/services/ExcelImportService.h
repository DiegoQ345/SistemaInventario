#ifndef EXCELIMPORTSERVICE_H
#define EXCELIMPORTSERVICE_H

#include "../models/Product.h"
#include <QObject>
#include <QString>
#include <QVariant>
#include <QMap>
#include <QList>

// Forward declaration para QXlsx
namespace QXlsx {
    class Document;
}

/**
 * @brief Servicio para importación de productos desde Excel
 * 
 * REQUISITO CRÍTICO: Importación flexible desde Excel
 * 
 * Características:
 * - El orden de las columnas NO importa
 * - Mapeo visual de columnas
 * - Guardar/cargar plantillas de mapeo
 * - Vista previa antes de importar
 * - Validación de datos
 * 
 * Usa QXlsx para leer archivos .xlsx
 */
class ExcelImportService : public QObject
{
    Q_OBJECT

public:
    explicit ExcelImportService(QObject *parent = nullptr);

    /**
     * @brief Estructura para mapeo de columnas
     */
    struct ColumnMapping {
        QString excelColumn;      // Nombre de la columna en Excel
        QString fieldName;        // Campo del sistema (name, sku, barcode, etc.)
        int columnIndex = -1;     // Índice de la columna en Excel
        bool isMapped = false;    // Si está mapeada
    };

    /**
     * @brief Datos de vista previa
     */
    struct PreviewData {
        QList<ColumnMapping> columnMappings;
        QList<QMap<QString, QVariant>> rows;  // Primeras N filas
        int totalRows = 0;
        bool hasErrors = false;
        QString errorMessage;
    };

    /**
     * @brief Resultado de importación
     */
    struct ImportResult {
        int totalRows = 0;
        int importedRows = 0;
        int failedRows = 0;
        QStringList errors;
        bool success = false;
    };

    /**
     * @brief Cargar archivo Excel y detectar columnas
     * @param filePath Ruta al archivo .xlsx
     * @return Lista de nombres de columnas detectadas
     */
    QStringList loadExcelFile(const QString& filePath);

    /**
     * @brief Obtener vista previa con mapeo de columnas
     * @param filePath Ruta al archivo Excel
     * @param columnMappings Mapeo de columnas configurado
     * @param maxRows Cantidad máxima de filas a previsualizar (default: 10)
     */
    PreviewData getPreview(const QString& filePath, 
                          const QList<ColumnMapping>& columnMappings,
                          int maxRows = 10);

    /**
     * @brief Importar productos desde Excel
     * @param filePath Ruta al archivo Excel
     * @param columnMappings Mapeo de columnas
     * @param skipFirstRow Si debe saltar la primera fila (encabezados)
     */
    ImportResult importProducts(const QString& filePath,
                                const QList<ColumnMapping>& columnMappings,
                                bool skipFirstRow = true);

    /**
     * @brief Guardar plantilla de mapeo
     */
    bool saveTemplate(const QString& templateName, 
                     const QList<ColumnMapping>& columnMappings,
                     QString& errorMessage);

    /**
     * @brief Cargar plantilla de mapeo guardada
     */
    QList<ColumnMapping> loadTemplate(const QString& templateName);

    /**
     * @brief Obtener lista de plantillas guardadas
     */
    QStringList getTemplates();

    /**
     * @brief Eliminar plantilla
     */
    bool deleteTemplate(const QString& templateName);

    /**
     * @brief Obtener lista de campos disponibles del sistema
     */
    static QStringList getAvailableFields();

    /**
     * @brief Obtener nombre amigable de un campo
     */
    static QString getFieldDisplayName(const QString& fieldName);

signals:
    /**
     * @brief Progreso de importación (0-100)
     */
    void importProgress(int percentage, const QString& message);

    /**
     * @brief Importación completada
     */
    void importCompleted(int importedRows, int failedRows);

private:
    QString m_currentFilePath;

    /**
     * @brief Convertir fila de Excel a Product
     */
    Product mapRowToProduct(const QMap<QString, QVariant>& row, 
                           const QList<ColumnMapping>& mappings,
                           QString& errorMessage);

    /**
     * @brief Validar datos de producto antes de importar
     */
    bool validateProductData(const QMap<QString, QVariant>& row,
                            const QList<ColumnMapping>& mappings,
                            QString& errorMessage);

    /**
     * @brief Leer fila de Excel según el mapeo
     */
    QMap<QString, QVariant> readRow(const QXlsx::Document& xlsx,
                                    int rowIndex,
                                    const QList<ColumnMapping>& mappings);

    /**
     * @brief Convertir valor de Excel al tipo correcto
     */
    QVariant convertValue(const QString& fieldName, const QVariant& value);
};

#endif // EXCELIMPORTSERVICE_H
