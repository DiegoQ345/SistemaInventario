#ifndef PRINTSERVICE_H
#define PRINTSERVICE_H

#include "../models/Sale.h"
#include <QObject>
#include <QString>
#include <QPrinter>
#include <QPrintDialog>
#include <QPainter>
#include <QPageSize>
#include <QJsonObject>
#include <QJsonArray>
#include <QVariantMap>
#include <QVariantList>

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
                      const InvoiceData& invoiceData = InvoiceData{});

    /**
     * @brief Mostrar vista previa de impresión
     */
    bool showPrintPreview(const Sale& sale, VoucherType type,
                          const InvoiceData& invoiceData = InvoiceData{});

    /**
     * @brief Imprimir ticket (formato térmico pequeño)
     */
    bool printTicket(const Sale& sale, VoucherType type,
                     const InvoiceData& invoiceData = InvoiceData{});

    /**
     * @brief Imprimir ticket con diseño personalizado
     * @param sale Datos de la venta
     * @param type Tipo de comprobante
     * @param invoiceData Datos adicionales
     * @param layoutJson JSON con diseño personalizado
     * @return true si se imprimió correctamente
     */
    bool printCustomTicket(const Sale& sale, VoucherType type,
                          const InvoiceData& invoiceData,
                          const QString& layoutJson);

    /**
     * @brief Generar vista previa PDF del ticket personalizado
     * @param sale Datos de la venta
     * @param type Tipo de comprobante
     * @param invoiceData Datos adicionales
     * @param layoutJson JSON con diseño personalizado
     * @param outputPath Ruta donde guardar el PDF
     * @return true si se generó correctamente
     */
    Q_INVOKABLE bool generateCustomTicketPdf(const Sale& sale, VoucherType type,
                                              const InvoiceData& invoiceData,
                                              const QString& layoutJson,
                                              const QString& outputPath);

    /**
     * @brief Generar PDF de ticket personalizado (versión para QML)
     * @param saleData Mapa con datos de la venta (compatible con QML)
     * @param voucherType Tipo de comprobante (0=BOLETA, 1=FACTURA)
     * @param invoiceData Mapa con datos de facturación
     * @param layoutJson JSON con diseño personalizado
     * @param outputPath Ruta donde guardar el PDF
     * @return true si se generó correctamente
     */
    Q_INVOKABLE bool generateCustomTicketPdf(const QVariantMap& saleData,
                                              int voucherType,
                                              const QVariantMap& invoiceData,
                                              const QString& layoutJson,
                                              const QString& outputPath);

    /**
     * @brief Generar vista previa PDF con datos de ejemplo
     * @param layoutJson JSON con diseño personalizado
     * @param outputPath Ruta donde guardar el PDF
     * @return true si se generó correctamente
     */
    Q_INVOKABLE bool generatePreviewPdf(const QString& layoutJson,
                                         const QString& outputPath);

    /**
     * @brief Configurar impresora predeterminada
     */
    void setDefaultPrinter(const QString& printerName);

    /**
     * @brief Configurar información de la empresa
     * @param name Nombre de la empresa
     * @param ruc RUC de la empresa
     * @param address Dirección de la empresa
     * @param phone Teléfono de la empresa
     */
    void setCompanyInfo(const QString& name, const QString& ruc, const QString& address, const QString& phone = "");

    /**
     * @brief Obtener lista de impresoras disponibles
     */
    QStringList getAvailablePrinters();

signals:
    void printStarted();
    void printCompleted();
    void printFailed(const QString& error);

private:
    // Constantes para DPI estandarizado (300 DPI para consistencia)
    static constexpr double STANDARD_DPI = 300.0;
    static constexpr double STANDARD_PIXELS_PER_MM = STANDARD_DPI / 25.4;  // 11.811024
    
    QString m_defaultPrinter;
    QString m_companyName = "SISTEMA DE INVENTARIO";
    QString m_companyRuc = "20123456789";
    QString m_companyAddress = "Av. Principal 123, Lima, Perú";
    QString m_companyPhone = "(01) 234-5678";

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
     * @brief Dibujar ticket con diseño personalizado
     */
    void drawCustomTicket(QPainter& painter, const Sale& sale, VoucherType type,
                         const InvoiceData& invoiceData, const QString& layoutJson);

    /**
     * @brief Reemplazar variables en texto
     */
    QString replaceVariables(const QString& text, const Sale& sale, 
                            VoucherType type, const InvoiceData& invoiceData);

    /**
     * @brief Crear mapa de variables para reemplazo en renderizado
     */
    QMap<QString, QString> createVariablesMap(const Sale& sale, 
                                               VoucherType type, 
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
    
    /**
     * @brief Validar consistencia de DPI entre diseñador e impresión
     */
    void validateDpiConsistency(QPainter& painter, double expectedWidthMM, 
                               double expectedHeightMM) const;
    
    /**
     * @brief Convertir milímetros a píxeles usando DPI estándar
     */
    inline double mmToPixels(double mm) const {
        return mm * STANDARD_PIXELS_PER_MM;
    }
    
    /**
     * @brief Convertir píxeles a milímetros usando DPI estándar
     */
    inline double pixelsToMM(double pixels) const {
        return pixels / STANDARD_PIXELS_PER_MM;
    }
};

#endif // PRINTSERVICE_H
