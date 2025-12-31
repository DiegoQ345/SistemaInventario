#include "PrintService.h"
#include <QApplication>
#include <QFont>
#include <QFontMetrics>
#include <QDateTime>
#include <QPrinterInfo>
#include <QDebug>

PrintService::PrintService(QObject *parent)
    : QObject(parent)
{
}

bool PrintService::printVoucher(const Sale& sale, VoucherType type, const InvoiceData& invoiceData)
{
    emit printStarted();

    QPrinter printer(QPrinter::HighResolution);
    printer.setPageSize(QPageSize::A4);
    printer.setPageOrientation(QPageLayout::Portrait);

    if (!m_defaultPrinter.isEmpty()) {
        printer.setPrinterName(m_defaultPrinter);
    }

    QPrintDialog dialog(&printer);
    if (dialog.exec() != QDialog::Accepted) {
        emit printFailed("Impresión cancelada por el usuario");
        return false;
    }

    QPainter painter;
    if (!painter.begin(&printer)) {
        emit printFailed("Error iniciando impresión");
        return false;
    }

    drawVoucherA4(painter, sale, type, invoiceData);

    painter.end();
    emit printCompleted();
    return true;
}

bool PrintService::showPrintPreview(const Sale& sale, VoucherType type, const InvoiceData& invoiceData)
{
    // TODO: Implementar vista previa con QPrintPreviewDialog
    return printVoucher(sale, type, invoiceData);
}

bool PrintService::printTicket(const Sale& sale, VoucherType type, const InvoiceData& invoiceData)
{
    emit printStarted();

    QPrinter printer(QPrinter::HighResolution);
    
    // Configurar para impresora térmica (80mm)
    printer.setPageSize(QPageSize(QSizeF(80, 200), QPageSize::Millimeter));
    printer.setPageOrientation(QPageLayout::Portrait);
    printer.setPageMargins(QMarginsF(5, 5, 5, 5), QPageLayout::Millimeter);

    if (!m_defaultPrinter.isEmpty()) {
        printer.setPrinterName(m_defaultPrinter);
    }

    QPainter painter;
    if (!painter.begin(&printer)) {
        emit printFailed("Error iniciando impresión de ticket");
        return false;
    }

    drawTicket(painter, sale, type, invoiceData);

    painter.end();
    emit printCompleted();
    return true;
}

void PrintService::setDefaultPrinter(const QString& printerName)
{
    m_defaultPrinter = printerName;
}

QStringList PrintService::getAvailablePrinters()
{
    QStringList printers;
    for (const QPrinterInfo& info : QPrinterInfo::availablePrinters()) {
        printers.append(info.printerName());
    }
    return printers;
}

void PrintService::drawVoucherA4(QPainter& painter, const Sale& sale, VoucherType type, 
                                 const InvoiceData& invoiceData)
{
    int y = 50;
    int pageWidth = painter.device()->width();
    int margin = 100;

    // Configurar fuentes
    QFont titleFont("Arial", 16, QFont::Bold);
    QFont normalFont("Arial", 10);
    QFont boldFont("Arial", 10, QFont::Bold);
    QFont smallFont("Arial", 8);

    // Encabezado
    painter.setFont(titleFont);
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 30), 
                    Qt::AlignCenter, m_companyName);
    y += 35;

    painter.setFont(smallFont);
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 20), 
                    Qt::AlignCenter, m_companyAddress);
    y += 20;
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 20), 
                    Qt::AlignCenter, "RUC: " + m_companyRuc);
    y += 40;

    // Línea separadora
    painter.drawLine(margin, y, pageWidth - margin, y);
    y += 30;

    // Tipo de comprobante
    painter.setFont(titleFont);
    QString voucherTypeStr = (type == FACTURA) ? "FACTURA ELECTRÓNICA" : "BOLETA DE VENTA";
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 30), 
                    Qt::AlignCenter, voucherTypeStr);
    y += 35;

    painter.setFont(normalFont);
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 20), 
                    Qt::AlignCenter, "Nº " + sale.invoiceNumber);
    y += 40;

    // Datos del cliente
    painter.setFont(boldFont);
    painter.drawText(margin, y, "CLIENTE:");
    y += 20;

    painter.setFont(normalFont);
    painter.drawText(margin, y, sale.customerName);
    y += 20;

    if (type == FACTURA && !invoiceData.ruc.isEmpty()) {
        painter.drawText(margin, y, "RUC: " + invoiceData.ruc);
        y += 20;
        painter.drawText(margin, y, invoiceData.businessName);
        y += 20;
        painter.drawText(margin, y, "Dirección: " + invoiceData.address);
        y += 20;
    }

    painter.drawText(margin, y, "Fecha: " + sale.createdAt.toString("dd/MM/yyyy hh:mm"));
    y += 20;
    painter.drawText(margin, y, "Método de pago: " + sale.paymentMethodName);
    y += 40;

    // Tabla de items
    painter.drawLine(margin, y, pageWidth - margin, y);
    y += 10;

    painter.setFont(boldFont);
    painter.drawText(margin, y, "DESCRIPCIÓN");
    painter.drawText(pageWidth - margin - 300, y, "CANTIDAD");
    painter.drawText(pageWidth - margin - 200, y, "P. UNIT");
    painter.drawText(pageWidth - margin - 100, y, "SUBTOTAL");
    y += 20;

    painter.drawLine(margin, y, pageWidth - margin, y);
    y += 20;

    painter.setFont(normalFont);
    for (const auto& item : sale.items) {
        painter.drawText(margin, y, item.productName);
        painter.drawText(pageWidth - margin - 300, y, QString::number(item.quantity, 'f', 2));
        painter.drawText(pageWidth - margin - 200, y, "$" + QString::number(item.unitPrice, 'f', 2));
        painter.drawText(pageWidth - margin - 100, y, "$" + QString::number(item.subtotal, 'f', 2));
        y += 25;
    }

    y += 20;
    painter.drawLine(margin, y, pageWidth - margin, y);
    y += 30;

    // Totales
    painter.setFont(boldFont);
    painter.drawText(pageWidth - margin - 300, y, "SUBTOTAL:");
    painter.drawText(pageWidth - margin - 100, y, "$" + QString::number(sale.subtotal, 'f', 2));
    y += 25;

    if (sale.discount > 0) {
        painter.drawText(pageWidth - margin - 300, y, "DESCUENTO:");
        painter.drawText(pageWidth - margin - 100, y, "-$" + QString::number(sale.discount, 'f', 2));
        y += 25;
    }

    if (sale.tax > 0) {
        painter.drawText(pageWidth - margin - 300, y, "IGV (18%):");
        painter.drawText(pageWidth - margin - 100, y, "$" + QString::number(sale.tax, 'f', 2));
        y += 25;
    }

    painter.setFont(titleFont);
    painter.drawText(pageWidth - margin - 300, y, "TOTAL:");
    painter.drawText(pageWidth - margin - 100, y, "$" + QString::number(sale.total, 'f', 2));
    y += 60;

    // Footer
    painter.drawLine(margin, y, pageWidth - margin, y);
    y += 30;

    painter.setFont(smallFont);
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 20), 
                    Qt::AlignCenter, "¡Gracias por su compra!");
}

void PrintService::drawTicket(QPainter& painter, const Sale& sale, VoucherType type, 
                              const InvoiceData& invoiceData)
{
    int y = 10;
    int pageWidth = painter.device()->width();
    int margin = 20;

    QFont titleFont("Arial", 12, QFont::Bold);
    QFont normalFont("Arial", 8);
    QFont smallFont("Arial", 7);

    // Encabezado
    painter.setFont(titleFont);
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 20), 
                    Qt::AlignCenter, m_companyName);
    y += 25;

    painter.setFont(smallFont);
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 15), 
                    Qt::AlignCenter, "RUC: " + m_companyRuc);
    y += 15;

    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 15), 
                    Qt::AlignCenter, m_companyAddress);
    y += 25;

    // Tipo de comprobante
    QString voucherTypeStr = (type == FACTURA) ? "FACTURA" : "BOLETA";
    painter.setFont(titleFont);
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 20), 
                    Qt::AlignCenter, voucherTypeStr);
    y += 20;

    painter.setFont(normalFont);
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 15), 
                    Qt::AlignCenter, sale.invoiceNumber);
    y += 25;

    painter.drawLine(margin, y, pageWidth - margin, y);
    y += 15;

    // Cliente
    painter.setFont(smallFont);
    painter.drawText(margin, y, "CLIENTE: " + sale.customerName);
    y += 12;

    if (type == FACTURA && !invoiceData.ruc.isEmpty()) {
        painter.drawText(margin, y, "RUC: " + invoiceData.ruc);
        y += 12;
    }

    painter.drawText(margin, y, "FECHA: " + sale.createdAt.toString("dd/MM/yyyy hh:mm"));
    y += 20;

    painter.drawLine(margin, y, pageWidth - margin, y);
    y += 15;

    // Items
    for (const auto& item : sale.items) {
        painter.drawText(margin, y, item.productName);
        y += 12;
        
        QString itemDetail = QString("%1 x $%2 = $%3")
            .arg(item.quantity, 0, 'f', 2)
            .arg(item.unitPrice, 0, 'f', 2)
            .arg(item.subtotal, 0, 'f', 2);
        
        painter.drawText(margin + 10, y, itemDetail);
        y += 15;
    }

    painter.drawLine(margin, y, pageWidth - margin, y);
    y += 15;

    // Totales
    painter.setFont(normalFont);
    painter.drawText(margin, y, "SUBTOTAL:");
    painter.drawText(pageWidth - margin - 80, y, "$" + QString::number(sale.subtotal, 'f', 2));
    y += 15;

    if (sale.discount > 0) {
        painter.drawText(margin, y, "DESCUENTO:");
        painter.drawText(pageWidth - margin - 80, y, "-$" + QString::number(sale.discount, 'f', 2));
        y += 15;
    }

    painter.setFont(titleFont);
    painter.drawText(margin, y, "TOTAL:");
    painter.drawText(pageWidth - margin - 80, y, "$" + QString::number(sale.total, 'f', 2));
    y += 25;

    painter.drawLine(margin, y, pageWidth - margin, y);
    y += 20;

    painter.setFont(smallFont);
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 15), 
                    Qt::AlignCenter, "¡Gracias por su compra!");
}
