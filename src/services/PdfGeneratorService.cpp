#include "PdfGeneratorService.h"
#include <QPrinter>
#include <QPainter>
#include <QTextDocument>
#include <QPageSize>
#include <QPageLayout>
#include <QPrintDialog>
#include <QFile>
#include <QDebug>

PdfGeneratorService::PdfGeneratorService(QObject *parent)
    : QObject(parent)
{
    // Configuración por defecto
    m_businessInfo.name = "Mi Negocio";
    m_businessInfo.address = "Dirección del negocio";
    m_businessInfo.phone = "(000) 000-0000";
    m_businessInfo.email = "info@minegocio.com";
}

void PdfGeneratorService::setBusinessInfo(const BusinessInfo& info)
{
    m_businessInfo = info;
}

bool PdfGeneratorService::generateSaleReceipt(const Sale& sale, const QString& outputPath)
{
    emit generationProgress(10);

    QPrinter printer(QPrinter::HighResolution);
    printer.setOutputFormat(QPrinter::PdfFormat);
    printer.setOutputFileName(outputPath);
    printer.setPageSize(QPageSize(QPageSize::A4));
    printer.setPageMargins(QMarginsF(10, 10, 10, 10), QPageLayout::Millimeter);

    emit generationProgress(30);

    // Generar HTML del comprobante
    QString html = generateReceiptHtml(sale, false);

    emit generationProgress(50);

    // Renderizar HTML a PDF
    QTextDocument document;
    document.setHtml(html);
    document.setPageSize(printer.pageRect(QPrinter::Point).size());

    emit generationProgress(70);

    // Imprimir a PDF
    document.print(&printer);

    emit generationProgress(100);
    emit pdfGenerated(outputPath);

    qDebug() << "Comprobante PDF generado:" << outputPath;
    return QFile::exists(outputPath);
}

bool PdfGeneratorService::generateThermalReceipt(const Sale& sale, const QString& outputPath, int paperWidth)
{
    emit generationProgress(10);

    QPrinter printer(QPrinter::HighResolution);
    printer.setOutputFormat(QPrinter::PdfFormat);
    printer.setOutputFileName(outputPath);

    // Configurar tamaño personalizado para papel térmico
    QSizeF paperSize;
    if (paperWidth == 58) {
        paperSize = QSizeF(58, 297);  // 58mm x altura variable
    } else {
        paperSize = QSizeF(80, 297);  // 80mm x altura variable
    }
    
    printer.setPageSize(QPageSize(paperSize, QPageSize::Millimeter));
    printer.setPageMargins(QMarginsF(2, 2, 2, 2), QPageLayout::Millimeter);

    emit generationProgress(30);

    // Generar HTML para impresora térmica
    QString html = generateReceiptHtml(sale, true);

    emit generationProgress(50);

    // Renderizar
    QTextDocument document;
    document.setHtml(html);
    document.setPageSize(printer.pageRect(QPrinter::Point).size());

    emit generationProgress(70);

    document.print(&printer);

    emit generationProgress(100);
    emit pdfGenerated(outputPath);

    qDebug() << "Comprobante térmico generado:" << outputPath;
    return QFile::exists(outputPath);
}

bool PdfGeneratorService::printReceipt(const Sale& sale, const QString& printerName)
{
    QPrinter printer(QPrinter::HighResolution);

    if (!printerName.isEmpty()) {
        printer.setPrinterName(printerName);
    }

    // Mostrar diálogo de impresión
    QPrintDialog printDialog(&printer);
    if (printDialog.exec() != QDialog::Accepted) {
        return false;
    }

    // Generar HTML
    QString html = generateReceiptHtml(sale, false);

    // Renderizar e imprimir
    QTextDocument document;
    document.setHtml(html);
    document.print(&printer);

    qDebug() << "Comprobante enviado a impresora";
    return true;
}

QString PdfGeneratorService::generateReceiptHtml(const Sale& sale, bool isThermal)
{
    QString html;
    html += "<!DOCTYPE html><html><head><meta charset='UTF-8'>";
    html += "<style>" + getReceiptStyles(isThermal) + "</style>";
    html += "</head><body>";

    // Encabezado del negocio
    html += "<div class='header'>";
    html += QString("<h1>%1</h1>").arg(m_businessInfo.name);
    html += QString("<p>%1</p>").arg(m_businessInfo.address);
    if (!m_businessInfo.taxId.isEmpty()) {
        html += QString("<p>RUC/NIT: %1</p>").arg(m_businessInfo.taxId);
    }
    html += QString("<p>Tel: %1</p>").arg(m_businessInfo.phone);
    html += "</div>";

    html += "<hr>";

    // Información de la venta
    html += "<div class='sale-info'>";
    html += QString("<p><strong>COMPROBANTE DE VENTA</strong></p>");
    html += QString("<p>Nº: %1</p>").arg(sale.invoiceNumber);
    html += QString("<p>Fecha: %1</p>").arg(sale.createdAt.toString("dd/MM/yyyy hh:mm"));
    
    if (!sale.customerName.isEmpty()) {
        html += QString("<p>Cliente: %1</p>").arg(sale.customerName);
    }
    
    if (!sale.paymentMethodName.isEmpty()) {
        html += QString("<p>Pago: %1</p>").arg(sale.paymentMethodName);
    }
    html += "</div>";

    html += "<hr>";

    // Tabla de productos
    html += "<table>";
    html += "<thead><tr>";
    html += "<th>Producto</th>";
    html += "<th>Cant.</th>";
    html += "<th>P.Unit</th>";
    html += "<th>Subtotal</th>";
    html += "</tr></thead>";
    html += "<tbody>";

    for (const auto& item : sale.items) {
        html += "<tr>";
        html += QString("<td>%1</td>").arg(item.productName);
        html += QString("<td>%1</td>").arg(item.quantity, 0, 'f', 2);
        html += QString("<td>$%1</td>").arg(item.unitPrice, 0, 'f', 2);
        html += QString("<td>$%1</td>").arg(item.subtotal, 0, 'f', 2);
        html += "</tr>";
    }

    html += "</tbody></table>";

    html += "<hr>";

    // Totales
    html += "<div class='totals'>";
    html += QString("<p>Subtotal: <span>$%1</span></p>").arg(sale.subtotal, 0, 'f', 2);
    
    if (sale.tax > 0) {
        html += QString("<p>Impuesto: <span>$%1</span></p>").arg(sale.tax, 0, 'f', 2);
    }
    
    if (sale.discount > 0) {
        html += QString("<p>Descuento: <span>-$%1</span></p>").arg(sale.discount, 0, 'f', 2);
    }
    
    html += QString("<p class='total'><strong>TOTAL: <span>$%1</span></strong></p>")
               .arg(sale.total, 0, 'f', 2);
    html += "</div>";

    html += "<hr>";

    // Pie de página
    html += "<div class='footer'>";
    html += "<p>¡Gracias por su compra!</p>";
    html += QString("<p>%1</p>").arg(m_businessInfo.email);
    html += "</div>";

    html += "</body></html>";

    return html;
}

QString PdfGeneratorService::getReceiptStyles(bool isThermal)
{
    QString styles;

    if (isThermal) {
        // Estilos para impresora térmica (más compacto)
        styles = R"(
            body {
                font-family: 'Courier New', monospace;
                font-size: 10pt;
                margin: 0;
                padding: 5px;
            }
            .header {
                text-align: center;
                margin-bottom: 10px;
            }
            .header h1 {
                font-size: 14pt;
                margin: 5px 0;
            }
            .header p {
                font-size: 9pt;
                margin: 2px 0;
            }
            .sale-info {
                margin: 10px 0;
                font-size: 9pt;
            }
            .sale-info p {
                margin: 3px 0;
            }
            hr {
                border: none;
                border-top: 1px dashed #000;
                margin: 5px 0;
            }
            table {
                width: 100%;
                border-collapse: collapse;
                font-size: 9pt;
            }
            th, td {
                padding: 3px 2px;
                text-align: left;
            }
            th {
                border-bottom: 1px solid #000;
            }
            .totals {
                margin-top: 10px;
                font-size: 10pt;
            }
            .totals p {
                margin: 3px 0;
                display: flex;
                justify-content: space-between;
            }
            .totals .total {
                font-size: 12pt;
                margin-top: 5px;
            }
            .footer {
                text-align: center;
                margin-top: 10px;
                font-size: 9pt;
            }
        )";
    } else {
        // Estilos para hoja A4 estándar
        styles = R"(
            body {
                font-family: Arial, sans-serif;
                font-size: 12pt;
                margin: 20px;
            }
            .header {
                text-align: center;
                margin-bottom: 20px;
            }
            .header h1 {
                font-size: 24pt;
                margin: 10px 0;
                color: #333;
            }
            .header p {
                margin: 5px 0;
                color: #666;
            }
            .sale-info {
                margin: 20px 0;
                background-color: #f5f5f5;
                padding: 15px;
                border-radius: 5px;
            }
            .sale-info p {
                margin: 5px 0;
            }
            hr {
                border: none;
                border-top: 2px solid #333;
                margin: 15px 0;
            }
            table {
                width: 100%;
                border-collapse: collapse;
                margin: 20px 0;
            }
            th, td {
                padding: 10px;
                text-align: left;
                border-bottom: 1px solid #ddd;
            }
            th {
                background-color: #333;
                color: white;
                font-weight: bold;
            }
            tr:hover {
                background-color: #f5f5f5;
            }
            .totals {
                margin-top: 20px;
                text-align: right;
            }
            .totals p {
                margin: 8px 0;
                font-size: 14pt;
            }
            .totals .total {
                font-size: 18pt;
                color: #333;
                margin-top: 15px;
                padding-top: 10px;
                border-top: 2px solid #333;
            }
            .footer {
                text-align: center;
                margin-top: 30px;
                color: #666;
                font-style: italic;
            }
        )";
    }

    return styles;
}
