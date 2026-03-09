#include "PdfGeneratorService.h"
#include <QPrinter>
#include <QPainter>
#include <QTextDocument>
#include <QPageSize>
#include <QPageLayout>
#include <QPrintDialog>
#include <QFile>
#include <QDateTime>
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

bool PdfGeneratorService::generateCustomerPurchaseHistory(const Customer& customer, 
                                                          const QList<Sale>& sales, 
                                                          const QString& outputPath)
{
    emit generationProgress(10);

    QPrinter printer(QPrinter::HighResolution);
    printer.setOutputFormat(QPrinter::PdfFormat);
    printer.setOutputFileName(outputPath);
    printer.setPageSize(QPageSize(QPageSize::A4));
    printer.setPageMargins(QMarginsF(6, 6, 6, 6), QPageLayout::Millimeter);

    emit generationProgress(30);

    // Generar HTML del historial
    QString html = generatePurchaseHistoryHtml(customer, sales);

    emit generationProgress(60);

    // Renderizar HTML a PDF
    QTextDocument document;
    document.setHtml(html);
    document.setPageSize(printer.pageRect(QPrinter::Point).size());

    emit generationProgress(80);

    document.print(&printer);

    emit generationProgress(100);
    emit pdfGenerated(outputPath);

    qDebug() << "PDF de historial de compras generado:" << outputPath;
    return true;
}

QString PdfGeneratorService::generatePurchaseHistoryHtml(const Customer& customer, const QList<Sale>& sales)
{
    QString html = R"(
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <style>
                body {
                    font-family: Arial, sans-serif;
                    margin: 8px;
                    font-size: 7pt;
                }
                .header {
                    text-align: center;
                    margin-bottom: 10px;
                    border-bottom: 2px solid #2196F3;
                    padding-bottom: 6px;
                }
                .header h1 {
                    color: #2196F3;
                    margin: 0;
                    font-size: 14pt;
                }
                .header h2 {
                    color: #666;
                    margin: 3px 0 0 0;
                    font-size: 10pt;
                    font-weight: normal;
                }
                .header .report-date {
                    color: #999;
                    font-size: 7pt;
                    margin: 4px 0 0 0;
                    font-style: italic;
                }
                .customer-info {
                    background-color: #f5f5f5;
                    padding: 6px 10px;
                    border-radius: 3px;
                    margin-bottom: 10px;
                    border-left: 3px solid #2196F3;
                }
                .customer-info h3 {
                    margin: 0 0 5px 0;
                    color: #2196F3;
                    font-size: 9pt;
                }
                .customer-info p {
                    margin: 2px 0;
                    font-size: 7pt;
                    line-height: 1.3;
                }
                .stats-box {
                    margin-bottom: 10px;
                    border: 1px solid #e0e0e0;
                    border-radius: 3px;
                    overflow: hidden;
                }
                .stats-table {
                    width: 100%;
                    border-collapse: collapse;
                }
                .stats-table td {
                    padding: 5px 7px;
                    text-align: left;
                    border-bottom: 1px solid #e0e0e0;
                    border-right: 1px solid #e0e0e0;
                    font-size: 6pt;
                    background-color: #f5f5f5;
                }
                .stats-table td:last-child {
                    border-right: none;
                }
                .stats-table .label {
                    font-weight: 600;
                    color: #000000;
                }
                .stats-table .value {
                    font-weight: bold;
                    font-size: 9pt;
                    color: #1976D2;
                }
                .credit-box {
                    background-color: #fff3e0;
                    padding: 6px 10px;
                    border-radius: 3px;
                    margin-bottom: 10px;
                    border-left: 3px solid #ff9800;
                }
                .credit-box h3 {
                    margin: 0 0 5px 0;
                    color: #ff9800;
                    font-size: 9pt;
                }
                .credit-stats {
                    display: flex;
                    justify-content: space-around;
                }
                .credit-stats > div {
                    text-align: center;
                }
                .credit-stats p {
                    margin: 0;
                    font-size: 6pt;
                    color: #000000;
                }
                .credit-stats .value {
                    margin: 2px 0;
                    font-size: 10pt;
                    font-weight: bold;
                }
                h3.section-title {
                    color: #2196F3;
                    margin: 10px 0 5px 0;
                    font-size: 9pt;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    font-size: 6pt;
                }
                thead {
                    background-color: #1976D2;
                }
                th {
                    padding: 5px 6px;
                    text-align: left;
                    font-weight: 600;
                    font-size: 7pt;
                    color: #FFFFFF;
                    background-color: #1976D2;
                }
                td {
                    padding: 4px 6px;
                    border-bottom: 1px solid #e0e0e0;
                    font-size: 6pt;
                    line-height: 1.2;
                }
                tbody tr:nth-child(even) {
                    background-color: #f9f9f9;
                }
                .total-row {
                    font-weight: bold;
                    background-color: #e3f2fd !important;
                    font-size: 7pt;
                }
                .pending-row {
                    background-color: #ffebee !important;
                    font-weight: bold;
                    font-size: 6pt;
                }
                .footer {
                    text-align: center;
                    margin-top: 12px;
                    padding-top: 6px;
                    border-top: 1px solid #e0e0e0;
                    color: #666;
                    font-size: 6pt;
                }
                .footer p {
                    margin: 2px 0;
                }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>)" + m_businessInfo.name + R"(</h1>)";
    
    if (!m_businessInfo.taxId.isEmpty()) {
        html += R"(
                <p style="margin: 0; font-size: 7pt; color: #666;">RUC: )" + m_businessInfo.taxId + R"(</p>)";
    }
    if (!m_businessInfo.address.isEmpty()) {
        html += R"(
                <p style="margin: 0; font-size: 6pt; color: #666;">)" + m_businessInfo.address + R"(</p>)";
    }
    if (!m_businessInfo.phone.isEmpty()) {
        html += R"(
                <p style="margin: 0; font-size: 6pt; color: #666;">Tel: )" + m_businessInfo.phone + R"(</p>)";
    }
    if (!m_businessInfo.email.isEmpty()) {
        html += R"(
                <p style="margin: 0; font-size: 6pt; color: #666;">)" + m_businessInfo.email + R"(</p>)";
    }
    
    html += R"(
                <h2>Historial de Compras del Cliente</h2>
                <p class="report-date">Reporte generado el )" + QDateTime::currentDateTime().toString("dd/MM/yyyy hh:mm") + R"(</p>
            </div>
            
            <div class="customer-info">
                <h3>Información del Cliente</h3>
                <p><strong>Nombre:</strong> )" + customer.name + R"(</p>
                <p><strong>Documento:</strong> )" + customer.documentType + " " + customer.documentNumber + R"(</p>)";
    
    if (!customer.phone.isEmpty()) {
        html += R"(<p><strong>Teléfono:</strong> )" + customer.phone + R"(</p>)";
    }
    
    if (!customer.email.isEmpty()) {
        html += R"(<p><strong>Email:</strong> )" + customer.email + R"(</p>)";
    }
    
    if (!customer.address.isEmpty()) {
        html += R"(<p><strong>Dirección:</strong> )" + customer.address + R"(</p>)";
    }
    
    html += R"(
            </div>
            
            <div class="stats-box">
                <table class="stats-table">
                    <tr>
                        <td class="label">Total de Compras:</td>
                        <td class="label">Monto Total:</td>
                        <td class="label">Ticket Promedio:</td>
                    </tr>
                    <tr>
                        <td class="value">)" + QString::number(customer.totalPurchases) + R"(</td>
                        <td class="value">S/ )" + QString::number(customer.totalSpent, 'f', 2) + R"(</td>
                        <td class="value">S/ )" + QString::number(customer.totalPurchases > 0 ? customer.totalSpent / customer.totalPurchases : 0.0, 'f', 2) + R"(</td>
                    </tr>
                </table>
            </div>)";
    
    // Agregar información de crédito si el cliente tiene límite configurado
    if (customer.creditLimit > 0.0) {
        double availableCredit = customer.creditLimit - customer.currentDebt;
        QString debtColor = customer.currentDebt > 0 ? "#f44336" : "#4CAF50";
        QString creditColor = availableCredit > 0 ? "#4CAF50" : "#f44336";
        
        html += R"(
            <div class="credit-box">
                <h3>Estado de Crédito</h3>
                <div class="credit-stats">
                    <div>
                        <p>Límite de Crédito</p>
                        <p class="value" style="color: #ff9800;">S/ )" + QString::number(customer.creditLimit, 'f', 2) + R"(</p>
                    </div>
                    <div>
                        <p>Deuda Actual</p>
                        <p class="value" style="color: )" + debtColor + R"(;">S/ )" + QString::number(customer.currentDebt, 'f', 2) + R"(</p>
                    </div>
                    <div>
                        <p>Crédito Disponible</p>
                        <p class="value" style="color: )" + creditColor + R"(;">S/ )" + QString::number(availableCredit, 'f', 2) + R"(</p>
                    </div>
                </div>
            </div>)";
    }
    
    html += R"(
            
            <h3 class="section-title">Detalle de Compras</h3>
            <table>
                <thead>
                    <tr>
                        <th>Fecha</th>
                        <th>Factura</th>
                        <th>Tipo</th>
                        <th>Items</th>
                        <th>Pago</th>
                        <th>Estado</th>
                        <th style="text-align: right;">Total</th>
                    </tr>
                </thead>
                <tbody>)";
    
    // Agregar cada venta con detalle de productos
    double totalGeneral = 0.0;
    double totalPendiente = 0.0;
    for (const Sale& sale : sales) {
        QString fecha = sale.createdAt.toString("dd/MM/yyyy hh:mm");
        QString voucherType = sale.voucherType.isEmpty() ? "TICKET" : sale.voucherType;
        int itemCount = sale.items.size();
        
        // Tipo de pago y estado
        QString paymentType = sale.paymentType.isEmpty() ? "CONTADO" : sale.paymentType;
        QString paymentStatus = sale.paymentStatus.isEmpty() ? "PAID" : sale.paymentStatus;
        QString paymentTypeDisplay = paymentType;
        
        // Estado con color
        QString statusDisplay = "";
        QString statusColor = "#4CAF50";  // Verde por defecto (PAID)
        if (paymentStatus == "PENDING") {
            statusDisplay = "Pendiente";
            statusColor = "#f44336";  // Rojo
            totalPendiente += sale.total;
        } else if (paymentStatus == "PARTIAL") {
            statusDisplay = "Parcial";
            statusColor = "#ff9800";  // Naranja
            totalPendiente += sale.total;
        } else {
            statusDisplay = "Pagado";
            statusColor = "#4CAF50";  // Verde
        }
        
        html += R"(
                    <tr>
                        <td>)" + fecha + R"(</td>
                        <td>)" + sale.invoiceNumber + R"(</td>
                        <td>)" + voucherType + R"(</td>
                        <td>)" + QString::number(itemCount) + " producto" + (itemCount != 1 ? "s" : "") + R"(</td>
                        <td>)" + paymentTypeDisplay + R"(</td>
                        <td><span style="color: )" + statusColor + R"(; font-weight: bold;">)" + statusDisplay + R"(</span></td>
                        <td style="text-align: right;">S/ )" + QString::number(sale.total, 'f', 2) + R"(</td>
                    </tr>)";
        
        // Agregar fila de detalle de productos
        if (!sale.items.isEmpty()) {
            html += R"(
                    <tr style="background-color: #f5f5f5;">
                        <td colspan="7" style="padding: 6px 16px;">
                            <div style="font-size: 5.5pt; color: #555;">
                                <strong style="color: #1976D2;">Productos:</strong> )";
            
            for (int i = 0; i < sale.items.size(); ++i) {
                const SaleItem& item = sale.items[i];
                html += R"(<span style="display: inline-block; margin-right: 12px;">• <strong>)" 
                        + QString::number(item.quantity, 'f', 0)
                        + R"(</strong> )" 
                        + item.productName 
                        + R"( - S/ )" + QString::number(item.subtotal, 'f', 2) 
                        + R"(</span>)";
                
                // Agregar salto de línea cada 3 productos para mejor lectura
                if ((i + 1) % 3 == 0 && i + 1 < sale.items.size()) {
                    html += R"(<br/>                                )";
                }
            }
            
            html += R"(
                            </div>
                        </td>
                    </tr>)";
        }
        
        totalGeneral += sale.total;
    }
    
    // Fila de total pendiente si hay deudas
    if (totalPendiente > 0.0) {
        html += R"(
                    <tr class="pending-row">
                        <td colspan="6" style="text-align: right; color: #f44336;">TOTAL PENDIENTE:</td>
                        <td style="text-align: right; color: #f44336;">S/ )" + QString::number(totalPendiente, 'f', 2) + R"(</td>
                    </tr>)";
    }
    
    // Fila de total
    html += R"(
                    <tr class="total-row">
                        <td colspan="6" style="text-align: right;">TOTAL GENERAL:</td>
                        <td style="text-align: right;">S/ )" + QString::number(totalGeneral, 'f', 2) + R"(</td>
                    </tr>
                </tbody>
            </table>
            
            <div class="footer">
                <p>)" + m_businessInfo.name + R"(</p>)";
    
    // Agregar RUC si está disponible
    if (!m_businessInfo.taxId.isEmpty()) {
        html += R"(<p>RUC: )" + m_businessInfo.taxId + R"(</p>)";
    }
    
    html += R"(<p>)" + m_businessInfo.address + R"( | )" + m_businessInfo.phone + R"(</p>)";
    
    // Agregar email si está disponible
    if (!m_businessInfo.email.isEmpty()) {
        html += R"(<p>)" + m_businessInfo.email + R"(</p>)";
    }
    
    html += R"(<p>Reporte generado el )" + QDateTime::currentDateTime().toString("dd/MM/yyyy hh:mm") + R"(</p>
            </div>
        </body>
        </html>
    )";
    
    return html;
}

