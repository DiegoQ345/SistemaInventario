#ifndef PDFGENERATORSERVICE_H
#define PDFGENERATORSERVICE_H

#include "../models/Sale.h"
#include <QObject>
#include <QString>

/**
 * @brief Servicio para generación de comprobantes en PDF
 * 
 * Genera boletas/facturas de venta en formato PDF.
 * Compatible con impresión estándar e impresoras térmicas.
 */
class PdfGeneratorService : public QObject
{
    Q_OBJECT

public:
    explicit PdfGeneratorService(QObject *parent = nullptr);

    /**
     * @brief Configuración del negocio para el comprobante
     */
    struct BusinessInfo {
        QString name;
        QString address;
        QString phone;
        QString email;
        QString taxId;  // RUC, NIT, etc.
        QString logoPath;
    };

    /**
     * @brief Configurar información del negocio
     */
    void setBusinessInfo(const BusinessInfo& info);

    /**
     * @brief Generar comprobante de venta en PDF
     * @param sale Venta a imprimir
     * @param outputPath Ruta donde guardar el PDF
     * @return true si se generó correctamente
     */
    bool generateSaleReceipt(const Sale& sale, const QString& outputPath);

    /**
     * @brief Generar comprobante para impresora térmica (58mm o 80mm)
     * @param sale Venta a imprimir
     * @param outputPath Ruta donde guardar el PDF
     * @param paperWidth Ancho del papel (58 o 80 mm)
     * @return true si se generó correctamente
     */
    bool generateThermalReceipt(const Sale& sale, const QString& outputPath, int paperWidth = 80);

    /**
     * @brief Enviar comprobante directamente a impresora
     * @param sale Venta a imprimir
     * @param printerName Nombre de la impresora
     * @return true si se imprimió correctamente
     */
    bool printReceipt(const Sale& sale, const QString& printerName = "");

signals:
    /**
     * @brief Progreso de generación del PDF
     */
    void generationProgress(int percentage);

    /**
     * @brief PDF generado exitosamente
     */
    void pdfGenerated(const QString& filePath);

private:
    BusinessInfo m_businessInfo;

    /**
     * @brief Generar HTML para el comprobante
     */
    QString generateReceiptHtml(const Sale& sale, bool isThermal = false);

    /**
     * @brief Aplicar estilos CSS al HTML
     */
    QString getReceiptStyles(bool isThermal = false);
};

#endif // PDFGENERATORSERVICE_H
