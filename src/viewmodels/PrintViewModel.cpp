#include "PrintViewModel.h"
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>
#include <QDesktopServices>
#include <QUrl>
#include <QDebug>

PrintViewModel::PrintViewModel(QObject *parent)
    : QObject(parent)
{
    // Cargar impresoras disponibles
    refreshPrinters();

    // Configurar información del negocio (valores por defecto)
    PdfGeneratorService::BusinessInfo businessInfo;
    businessInfo.name = "SISTEMA DE INVENTARIO";
    businessInfo.taxId = "20123456789";
    businessInfo.address = "Av. Principal 123, Lima, Perú";
    businessInfo.phone = "(01) 234-5678";
    businessInfo.email = "ventas@sistemainventario.com";
    m_pdfService.setBusinessInfo(businessInfo);

    // Conectar señales del servicio de PDF
    connect(&m_pdfService, &PdfGeneratorService::pdfGenerated,
            this, &PrintViewModel::pdfGenerated);

    // Conectar señales del servicio de impresión
    connect(&m_printService, &PrintService::printCompleted,
            this, [this]() {
                setIsPrinting(false);
                emit printCompleted();
            });

    connect(&m_printService, &PrintService::printFailed,
            this, [this](const QString& error) {
                setIsPrinting(false);
                setLastError(error);
                emit printFailed(error);
            });
}

void PrintViewModel::setDefaultPrinter(const QString& printer)
{
    if (m_defaultPrinter != printer) {
        m_defaultPrinter = printer;
        m_printService.setDefaultPrinter(printer);
        emit defaultPrinterChanged();
        emit defaultPrinterIndexChanged();
    }
}

int PrintViewModel::defaultPrinterIndex() const
{
    int index = m_availablePrinters.indexOf(m_defaultPrinter);
    return index >= 0 ? index : 0;
}

void PrintViewModel::setPaperSize(PaperSize size)
{
    if (m_paperSize != size) {
        m_paperSize = size;
        emit paperSizeChanged();
    }
}

QString PrintViewModel::generatePdf(const QString& invoiceNumber,
                                    const QString& customerName,
                                    const QVariantList& items,
                                    double subtotal,
                                    double discount,
                                    double total,
                                    VoucherType voucherType,
                                    const QString& ruc,
                                    const QString& businessName,
                                    const QString& address)
{
    qDebug() << "Generando PDF para" << invoiceNumber;

    // Crear directorio para PDFs si no existe
    QString pdfDir = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation) 
                     + "/SistemaInventario/Comprobantes";
    QDir dir;
    if (!dir.mkpath(pdfDir)) {
        setLastError("No se pudo crear el directorio de comprobantes");
        return QString();
    }

    // Generar nombre de archivo
    QString timestamp = QDateTime::currentDateTime().toString("yyyyMMdd_HHmmss");
    QString typeStr = (voucherType == Factura) ? "FACTURA" : "BOLETA";
    QString fileName = QString("%1_%2_%3.pdf")
                       .arg(typeStr)
                       .arg(invoiceNumber)
                       .arg(timestamp);
    QString filePath = pdfDir + "/" + fileName;

    // Crear objeto Sale
    Sale sale = createSaleFromData(invoiceNumber, customerName, items, 
                                   subtotal, discount, total);
    
    // Agregar datos de factura si aplica
    if (voucherType == Factura) {
        sale.notes = QString("RUC: %1 - %2 - %3")
                     .arg(ruc)
                     .arg(businessName)
                     .arg(address);
    }

    // Generar PDF según tamaño de papel
    bool success = false;
    if (m_paperSize == Thermal80mm) {
        success = m_pdfService.generateThermalReceipt(sale, filePath, 80);
    } else if (m_paperSize == Thermal58mm) {
        success = m_pdfService.generateThermalReceipt(sale, filePath, 58);
    } else {
        success = m_pdfService.generateSaleReceipt(sale, filePath);
    }

    if (success) {
        qDebug() << "PDF generado exitosamente:" << filePath;
        return filePath;
    } else {
        setLastError("Error al generar el PDF");
        return QString();
    }
}

bool PrintViewModel::printVoucher(const QString& invoiceNumber,
                                 const QString& customerName,
                                 const QVariantList& items,
                                 double subtotal,
                                 double discount,
                                 double total,
                                 VoucherType voucherType,
                                 const QString& ruc,
                                 const QString& businessName,
                                 const QString& address)
{
    qDebug() << "Imprimiendo comprobante:" << invoiceNumber;

    setIsPrinting(true);

    // Crear objeto Sale
    Sale sale = createSaleFromData(invoiceNumber, customerName, items, 
                                   subtotal, discount, total);

    // Configurar datos de factura
    PrintService::InvoiceData invoiceData;
    if (voucherType == Factura) {
        invoiceData.ruc = ruc;
        invoiceData.businessName = businessName;
        invoiceData.address = address;
    }

    // Seleccionar método de impresión según tamaño de papel
    bool success = false;
    PrintService::VoucherType type = (voucherType == Factura) 
                                     ? PrintService::FACTURA 
                                     : PrintService::BOLETA;

    if (m_paperSize == Thermal80mm || m_paperSize == Thermal58mm) {
        success = m_printService.printTicket(sale, type, invoiceData);
    } else {
        success = m_printService.printVoucher(sale, type, invoiceData);
    }

    if (!success) {
        setIsPrinting(false);
    }

    return success;
}

bool PrintViewModel::showPrinterSettings()
{
    // TODO: Mostrar diálogo personalizado de configuración
    return true;
}

QString PrintViewModel::previewPdf(const QString& invoiceNumber,
                                  const QString& customerName,
                                  const QVariantList& items,
                                  double subtotal,
                                  double discount,
                                  double total,
                                  VoucherType voucherType,
                                  const QString& ruc,
                                  const QString& businessName,
                                  const QString& address)
{
    // Generar PDF temporal
    QString pdfPath = generatePdf(invoiceNumber, customerName, items, 
                                 subtotal, discount, total, voucherType, 
                                 ruc, businessName, address);

    if (!pdfPath.isEmpty()) {
        // Abrir con visor de PDF predeterminado
        QDesktopServices::openUrl(QUrl::fromLocalFile(pdfPath));
    }

    return pdfPath;
}

void PrintViewModel::refreshPrinters()
{
    m_availablePrinters = m_printService.getAvailablePrinters();
    
    if (!m_availablePrinters.isEmpty() && m_defaultPrinter.isEmpty()) {
        setDefaultPrinter(m_availablePrinters.first());
    }
    
    emit availablePrintersChanged();
    emit defaultPrinterIndexChanged();
}

void PrintViewModel::setBusinessInfo(const QString& name,
                                     const QString& taxId,
                                     const QString& address,
                                     const QString& phone,
                                     const QString& email)
{
    PdfGeneratorService::BusinessInfo info;
    info.name = name;
    info.taxId = taxId;
    info.address = address;
    info.phone = phone;
    info.email = email;
    
    m_pdfService.setBusinessInfo(info);
}

Sale PrintViewModel::createSaleFromData(const QString& invoiceNumber,
                                       const QString& customerName,
                                       const QVariantList& items,
                                       double subtotal,
                                       double discount,
                                       double total)
{
    Sale sale;
    sale.invoiceNumber = invoiceNumber;
    sale.customerName = customerName;
    sale.subtotal = subtotal;
    sale.discount = discount;
    sale.total = total;
    sale.createdAt = QDateTime::currentDateTime();
    sale.status = "COMPLETED";

    // Convertir items de QVariantList a SaleItem
    for (const QVariant& itemVar : items) {
        QVariantMap itemMap = itemVar.toMap();
        
        SaleItem saleItem;
        saleItem.productName = itemMap.value("productName").toString();
        saleItem.quantity = itemMap.value("quantity").toDouble();
        saleItem.unitPrice = itemMap.value("unitPrice").toDouble();
        saleItem.subtotal = itemMap.value("subtotal").toDouble();
        
        sale.items.append(saleItem);
    }

    return sale;
}

void PrintViewModel::setIsPrinting(bool printing)
{
    if (m_isPrinting != printing) {
        m_isPrinting = printing;
        emit isPrintingChanged();
    }
}

void PrintViewModel::setLastError(const QString& error)
{
    if (m_lastError != error) {
        m_lastError = error;
        emit lastErrorChanged();
        qWarning() << "Print error:" << error;
    }
}
