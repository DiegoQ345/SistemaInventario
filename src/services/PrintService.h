#ifndef PRINTSERVICE_H
#define PRINTSERVICE_H

#include "../models/Sale.h"
#include <QObject>
#include <QString>
#include <QPrinter>
#include <QPrintDialog>
#include <QPainter>
#include <QPageSize>

/**
 * @brief Servicio para impresión de comprobantes
 * 
 * Maneja la generación e impresión de boletas y facturas
 */
class PrintService : public QObject
{
    Q_OBJECT

public:
    explicit PrintService(QObject *parent = nullptr);

    /**
     * @brief Tipos de comprobante
     */
    enum VoucherType {
        BOLETA,
        FACTURA
    };
    Q_ENUM(VoucherType)

    /**
     * @brief Datos adicionales para factura
     */
    struct InvoiceData {
        QString ruc;
        QString businessName;
        QString address;
    };

public slots:
    /**
     * @brief Imprimir comprobante
     * @param sale Datos de la venta
     * @param type Tipo de comprobante (BOLETA o FACTURA)
     * @param invoiceData Datos adicionales si es factura
     * @return true si se imprimió correctamente
     */
    bool printVoucher(const Sale& sale, VoucherType type, 
                      const InvoiceData& invoiceData = InvoiceData());

    /**
     * @brief Mostrar vista previa de impresión
     */
    bool showPrintPreview(const Sale& sale, VoucherType type,
                          const InvoiceData& invoiceData = InvoiceData());

    /**
     * @brief Imprimir ticket (formato térmico pequeño)
     */
    bool printTicket(const Sale& sale, VoucherType type,
                     const InvoiceData& invoiceData = InvoiceData());

    /**
     * @brief Configurar impresora predeterminada
     */
    void setDefaultPrinter(const QString& printerName);

    /**
     * @brief Obtener lista de impresoras disponibles
     */
    QStringList getAvailablePrinters();

signals:
    void printStarted();
    void printCompleted();
    void printFailed(const QString& error);

private:
    QString m_defaultPrinter;
    QString m_companyName = "SISTEMA DE INVENTARIO";
    QString m_companyRuc = "20123456789";
    QString m_companyAddress = "Av. Principal 123, Lima, Perú";

    /**
     * @brief Dibujar comprobante A4
     */
    void drawVoucherA4(QPainter& painter, const Sale& sale, VoucherType type,
                       const InvoiceData& invoiceData);

    /**
     * @brief Dibujar ticket térmico (80mm)
     */
    void drawTicket(QPainter& painter, const Sale& sale, VoucherType type,
                    const InvoiceData& invoiceData);

    /**
     * @brief Dibujar encabezado
     */
    void drawHeader(QPainter& painter, int& y, VoucherType type,
                    const QString& invoiceNumber);

    /**
     * @brief Dibujar datos del cliente
     */
    void drawCustomerData(QPainter& painter, int& y, const Sale& sale,
                          VoucherType type, const InvoiceData& invoiceData);

    /**
     * @brief Dibujar tabla de items
     */
    void drawItemsTable(QPainter& painter, int& y, const Sale& sale);

    /**
     * @brief Dibujar totales
     */
    void drawTotals(QPainter& painter, int& y, const Sale& sale);

    /**
     * @brief Dibujar pie de página
     */
    void drawFooter(QPainter& painter, int y);
};

#endif // PRINTSERVICE_H
