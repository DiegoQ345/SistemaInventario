#ifndef PRINTVIEWMODEL_H
#define PRINTVIEWMODEL_H

#include "../models/Sale.h"
#include "../services/PrintService.h"
#include "../services/PdfGeneratorService.h"
#include <QObject>

/**
 * @brief ViewModel para impresión de comprobantes desde QML
 * 
 * Expone funcionalidad de impresión al frontend.
 */
class PrintViewModel : public QObject
{
    Q_OBJECT
    
    Q_PROPERTY(bool isPrinting READ isPrinting NOTIFY isPrintingChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QStringList availablePrinters READ availablePrinters NOTIFY availablePrintersChanged)
    Q_PROPERTY(QString defaultPrinter READ defaultPrinter WRITE setDefaultPrinter NOTIFY defaultPrinterChanged)
    Q_PROPERTY(int defaultPrinterIndex READ defaultPrinterIndex NOTIFY defaultPrinterIndexChanged)
    Q_PROPERTY(PaperSize paperSize READ paperSize WRITE setPaperSize NOTIFY paperSizeChanged)

public:
    explicit PrintViewModel(QObject *parent = nullptr);

    /**
     * @brief Tamaños de papel soportados
     */
    enum PaperSize {
        A4,              // 210 x 297 mm
        Letter,          // 216 x 279 mm
        Thermal80mm,     // 80 x continuo mm (impresora térmica)
        Thermal58mm,     // 58 x continuo mm (impresora térmica pequeña)
        Custom
    };
    Q_ENUM(PaperSize)

    /**
     * @brief Tipo de comprobante
     */
    enum VoucherType {
        Boleta,
        Factura
    };
    Q_ENUM(VoucherType)

    // Getters
    bool isPrinting() const { return m_isPrinting; }
    QString lastError() const { return m_lastError; }
    QStringList availablePrinters() const { return m_availablePrinters; }
    QString defaultPrinter() const { return m_defaultPrinter; }
    int defaultPrinterIndex() const;
    PaperSize paperSize() const { return m_paperSize; }

    // Setters
    void setDefaultPrinter(const QString& printer);
    void setPaperSize(PaperSize size);

public slots:
    /**
     * @brief Generar PDF del comprobante
     * @param invoiceNumber Número de factura/boleta
     * @param customerName Nombre del cliente
     * @param items Array de items [{ productName, quantity, unitPrice, subtotal }]
     * @param subtotal Subtotal de la venta
     * @param discount Descuento aplicado
     * @param total Total de la venta
     * @param voucherType Tipo de comprobante (Boleta/Factura)
     * @param ruc RUC (solo para facturas)
     * @param businessName Razón social (solo para facturas)
     * @param address Dirección (solo para facturas)
     * @return Ruta del PDF generado
     */
    QString generatePdf(const QString& invoiceNumber,
                       const QString& customerName,
                       const QVariantList& items,
                       double subtotal,
                       double discount,
                       double total,
                       VoucherType voucherType,
                       const QString& ruc = "",
                       const QString& businessName = "",
                       const QString& address = "");

    /**
     * @brief Imprimir comprobante directamente
     */
    bool printVoucher(const QString& invoiceNumber,
                     const QString& customerName,
                     const QVariantList& items,
                     double subtotal,
                     double discount,
                     double total,
                     VoucherType voucherType,
                     const QString& ruc = "",
                     const QString& businessName = "",
                     const QString& address = "");

    /**
     * @brief Mostrar diálogo de configuración de impresora
     */
    bool showPrinterSettings();

    /**
     * @brief Vista previa del PDF
     */
    QString previewPdf(const QString& invoiceNumber,
                      const QString& customerName,
                      const QVariantList& items,
                      double subtotal,
                      double discount,
                      double total,
                      VoucherType voucherType,
                      const QString& ruc = "",
                      const QString& businessName = "",
                      const QString& address = "");

    /**
     * @brief Refrescar lista de impresoras
     */
    void refreshPrinters();

    /**
     * @brief Configurar información del negocio
     */
    void setBusinessInfo(const QString& name,
                        const QString& taxId,
                        const QString& address,
                        const QString& phone,
                        const QString& email);

signals:
    void isPrintingChanged();
    void lastErrorChanged();
    void availablePrintersChanged();
    void defaultPrinterChanged();
    void defaultPrinterIndexChanged();
    void paperSizeChanged();
    void pdfGenerated(const QString& filePath);
    void printCompleted();
    void printFailed(const QString& error);

private:
    PrintService m_printService;
    PdfGeneratorService m_pdfService;
    bool m_isPrinting = false;
    QString m_lastError;
    QStringList m_availablePrinters;
    QString m_defaultPrinter;
    PaperSize m_paperSize = A4;

    /**
     * @brief Convertir datos QML a modelo Sale
     */
    Sale createSaleFromData(const QString& invoiceNumber,
                           const QString& customerName,
                           const QVariantList& items,
                           double subtotal,
                           double discount,
                           double total);

    void setIsPrinting(bool printing);
    void setLastError(const QString& error);
};

#endif // PRINTVIEWMODEL_H
