#ifndef EXCELIMPORTVIEWMODEL_H
#define EXCELIMPORTVIEWMODEL_H

#include "../services/ExcelImportService.h"
#include <QObject>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

/**
 * @brief ViewModel para importación de Excel
 * 
 * Expone el servicio ExcelImportService a QML
 */
class ExcelImportViewModel : public QObject
{
    Q_OBJECT
    // Registrado manualmente en main.cpp

    Q_PROPERTY(QStringList excelColumns READ excelColumns NOTIFY excelColumnsChanged)
    Q_PROPERTY(QStringList availableFields READ availableFields CONSTANT)
    Q_PROPERTY(int totalRows READ totalRows NOTIFY totalRowsChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(QString errorMessage READ errorMessage NOTIFY errorMessageChanged)
    Q_PROPERTY(int importProgress READ importProgress NOTIFY importProgressChanged)
    Q_PROPERTY(QVariantList previewRows READ previewRows NOTIFY previewRowsChanged)
    Q_PROPERTY(bool hasFile READ hasFile NOTIFY hasFileChanged)

public:
    explicit ExcelImportViewModel(QObject *parent = nullptr);

    QStringList excelColumns() const { return m_excelColumns; }
    QStringList availableFields() const;
    int totalRows() const { return m_totalRows; }
    bool isLoading() const { return m_isLoading; }
    QString errorMessage() const { return m_errorMessage; }
    int importProgress() const { return m_importProgress; }
    QVariantList previewRows() const { return m_previewRows; }
    bool hasFile() const { return !m_currentFilePath.isEmpty(); }

public slots:
    /**
     * @brief Cargar archivo Excel
     * @param filePath Ruta del archivo
     */
    Q_INVOKABLE bool loadFile(const QString& filePath);

    /**
     * @brief Establecer mapeo de columna
     * @param excelColumnName Nombre de columna en Excel
     * @param fieldName Campo del sistema
     */
    Q_INVOKABLE void setColumnMapping(const QString& excelColumnName, const QString& fieldName);

    /**
     * @brief Obtener vista previa de datos
     * @param maxRows Cantidad máxima de filas
     */
    Q_INVOKABLE void loadPreview(int maxRows = 10);

    /**
     * @brief Iniciar importación
     */
    Q_INVOKABLE void startImport();

    /**
     * @brief Limpiar mapeo y datos
     */
    Q_INVOKABLE void clear();

    /**
     * @brief Resetear importación (limpiar archivo y preview)
     */
    Q_INVOKABLE void resetImport();

    /**
     * @brief Auto-mapear columna usando lógica inteligente
     * @param columnName Nombre de columna del Excel
     * @return Campo sugerido o "ninguno"
     */
    Q_INVOKABLE QString autoMapColumn(const QString& columnName);

    /**
     * @brief Obtener mapeo actual
     */
    Q_INVOKABLE QVariantMap getCurrentMapping() const;

signals:
    void excelColumnsChanged();
    void totalRowsChanged();
    void isLoadingChanged();
    void errorMessageChanged();
    void importProgressChanged();
    void importCompleted(int imported, int failed);
    void previewRowsChanged();
    void hasFileChanged();

private slots:
    void onImportProgress(int progress, const QString& message);
    void onImportCompleted(int imported, int failed);

private:
    void setIsLoading(bool loading);
    void setErrorMessage(const QString& message);
    void setHasFile(bool has);

    ExcelImportService m_service;
    QStringList m_excelColumns;
    QList<ExcelImportService::ColumnMapping> m_columnMappings;
    QString m_currentFilePath;
    int m_totalRows = 0;
    QVariantList m_previewRows;
    bool m_isLoading = false;
    QString m_errorMessage;
    int m_importProgress = 0;
};

#endif // EXCELIMPORTVIEWMODEL_H
