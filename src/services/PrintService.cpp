#include "PrintService.h"
#include "../printing/TicketLayout.h"
#include "../printing/TicketRenderer.h"
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

    // Usar impresora predeterminada configurada
    if (!m_defaultPrinter.isEmpty()) {
        printer.setPrinterName(m_defaultPrinter);
    }
    // Si no hay impresora configurada, usar la predeterminada del sistema
    else {
        QPrinterInfo defaultPrinter = QPrinterInfo::defaultPrinter();
        if (defaultPrinter.isNull()) {
            emit printFailed("No hay impresora configurada");
            return false;
        }
        printer.setPrinterName(defaultPrinter.printerName());
    }

    QPainter painter;
    if (!painter.begin(&printer)) {
        emit printFailed("Error iniciando impresion");
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
    
    // Configurar para impresora termica (80mm)
    printer.setPageSize(QPageSize(QSizeF(80, 200), QPageSize::Millimeter));
    printer.setPageOrientation(QPageLayout::Portrait);
    printer.setPageMargins(QMarginsF(5, 5, 5, 5), QPageLayout::Millimeter);

    if (!m_defaultPrinter.isEmpty()) {
        printer.setPrinterName(m_defaultPrinter);
    }

    QPainter painter;
    if (!painter.begin(&printer)) {
        emit printFailed("Error iniciando impresion de ticket");
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

void PrintService::setCompanyInfo(const QString& name, const QString& ruc, const QString& address, const QString& phone)
{
    m_companyName = name;
    m_companyRuc = ruc;
    m_companyAddress = address;
    if (!phone.isEmpty()) {
        m_companyPhone = phone;
    }
    qDebug() << "PrintService: Información de empresa actualizada -" << name << ruc << address << phone;
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

    // Linea separadora
    painter.drawLine(margin, y, pageWidth - margin, y);
    y += 30;

    // Tipo de comprobante
    painter.setFont(titleFont);
    QString voucherTypeStr = (type == FACTURA) ? "FACTURA ELECTRONICA" : "BOLETA DE VENTA";
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 30), 
                    Qt::AlignCenter, voucherTypeStr);
    y += 35;

    painter.setFont(normalFont);
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 20), 
                    Qt::AlignCenter, "NÂº " + sale.invoiceNumber);
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
        painter.drawText(margin, y, "Direccion: " + invoiceData.address);
        y += 20;
    }

    painter.drawText(margin, y, "Fecha: " + sale.createdAt.toString("dd/MM/yyyy hh:mm"));
    y += 20;
    painter.drawText(margin, y, "Metodo de pago: " + sale.paymentMethodName);
    y += 40;

    // Tabla de items
    painter.drawLine(margin, y, pageWidth - margin, y);
    y += 10;

    painter.setFont(boldFont);
    painter.drawText(margin, y, "DESCRIPCION");
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
    y += 40;

    // Monto pagado y vuelto
    if (sale.amountPaid > 0) {
        painter.setFont(boldFont);
        painter.drawText(pageWidth - margin - 300, y, "PAGADO:");
        painter.drawText(pageWidth - margin - 100, y, "$" + QString::number(sale.amountPaid, 'f', 2));
        y += 25;
        
        if (sale.changeGiven > 0) {
            painter.drawText(pageWidth - margin - 300, y, "VUELTO:");
            painter.drawText(pageWidth - margin - 100, y, "$" + QString::number(sale.changeGiven, 'f', 2));
            y += 25;
        }
    }
    
    y += 20;

    // Footer
    painter.drawLine(margin, y, pageWidth - margin, y);
    y += 30;

    painter.setFont(smallFont);
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 20), 
                    Qt::AlignCenter, "Gracias por su compra!");
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
    y += 20;

    // Monto pagado y vuelto
    if (sale.amountPaid > 0) {
        painter.setFont(normalFont);
        painter.drawText(margin, y, "PAGADO:");
        painter.drawText(pageWidth - margin - 80, y, "$" + QString::number(sale.amountPaid, 'f', 2));
        y += 15;
        
        if (sale.changeGiven > 0) {
            painter.drawText(margin, y, "VUELTO:");
            painter.drawText(pageWidth - margin - 80, y, "$" + QString::number(sale.changeGiven, 'f', 2));
            y += 15;
        }
    }
    
    y += 10;

    painter.drawLine(margin, y, pageWidth - margin, y);
    y += 20;

    painter.setFont(smallFont);
    painter.drawText(QRect(margin, y, pageWidth - 2*margin, 15), 
                    Qt::AlignCenter, "Gracias por su compra!");
}

bool PrintService::printCustomTicket(const Sale& sale, VoucherType type,
                                     const InvoiceData& invoiceData,
                                     const QString& layoutJson)
{
    emit printStarted();
    
    QJsonDocument doc = QJsonDocument::fromJson(layoutJson.toUtf8());
    double ticketWidth = 80;
    double ticketHeight = 200;
    
    if (doc.isObject()) {
        QJsonObject layoutObj = doc.object();
        if (layoutObj.contains("size")) {
            QJsonObject sizeObj = layoutObj["size"].toObject();
            ticketWidth = sizeObj["width"].toDouble(80);
            ticketHeight = sizeObj["height"].toDouble(200);
        }
    }
    
    QPrinter printer(QPrinter::HighResolution);
    
    // Configurar tamano de pagina personalizado
    printer.setPageSize(QPageSize(QSizeF(ticketWidth, ticketHeight), QPageSize::Millimeter));
    printer.setPageOrientation(QPageLayout::Portrait);
    
    // CONFIGURACION CRITICA: Usar pagina completa sin margenes
    printer.setFullPage(true);
    
    // Configurar layout con margenes en 0 y modo FullPage
    QPageLayout layout = printer.pageLayout();
    layout.setMargins(QMarginsF(0, 0, 0, 0));
    layout.setMode(QPageLayout::FullPageMode);
    printer.setPageLayout(layout);
    
    qDebug() << "=== CONFIGURACION DE IMPRESORA ===";
    qDebug() << "Tamano ticket:" << ticketWidth << "x" << ticketHeight << "mm";
    qDebug() << "Full page mode:" << printer.fullPage();
    qDebug() << "Page layout mode:" << layout.mode();
    qDebug() << "Margenes:" << layout.margins();
    
    if (!m_defaultPrinter.isEmpty()) {
        printer.setPrinterName(m_defaultPrinter);
        qDebug() << "Usando impresora:" << m_defaultPrinter;
    } else {
        qDebug() << "Usando impresora predeterminada del sistema";
    }
    
    QPainter painter;
    if (!painter.begin(&printer)) {
        emit printFailed("Error iniciando impresion de ticket personalizado");
        return false;
    }
    
    drawCustomTicket(painter, sale, type, invoiceData, layoutJson);
    
    painter.end();
    emit printCompleted();
    return true;
}

void PrintService::drawCustomTicket(QPainter& painter, const Sale& sale, VoucherType type,
                                    const InvoiceData& invoiceData, const QString& layoutJson)
{
    qDebug() << "=== RENDERIZANDO TICKET CON ARQUITECTURA MODULAR ===";
    
    // 1. Crear TicketLayout y parsear JSON
    TicketLayout layout;
    if (!layout.loadFromJson(layoutJson)) {
        qDebug() << "ERROR:" << layout.getError();
        return;
    }
    
    qDebug() << "Layout cargado exitosamente";
    qDebug() << "Dimensiones:" << layout.getWidthMM() << "x" << layout.getInitialHeightMM() << "mm";
    qDebug() << "Elementos:" << layout.getElements().size();
    
    // 2. Configurar hints de renderizado
    painter.setRenderHint(QPainter::Antialiasing, false);
    painter.setRenderHint(QPainter::TextAntialiasing, true);
    painter.setRenderHint(QPainter::SmoothPixmapTransform, true);
    
    // 3. Crear mapa de variables
    QMap<QString, QString> variables = createVariablesMap(sale, type, invoiceData);
    
    // 4. Convertir tipos de PrintService a tipos de TicketRenderer
    ::VoucherType rendererType = (type == FACTURA) ? ::VoucherType::FACTURA : ::VoucherType::BOLETA;
    
    ::InvoiceData rendererInvoiceData;
    rendererInvoiceData.ruc = invoiceData.ruc;
    rendererInvoiceData.businessName = invoiceData.businessName;
    rendererInvoiceData.address = invoiceData.address;
    
    // 5. Crear renderer y renderizar
    TicketRenderer renderer;
    renderer.render(painter, layout, sale, rendererType, rendererInvoiceData, variables);
    
    qDebug() << "=== RENDERIZADO COMPLETADO ===";
}

QString PrintService::replaceVariables(const QString& text, const Sale& sale,
                                       VoucherType type, const InvoiceData& invoiceData)
{
    QString result = text;
    
    result.replace("{{businessName}}", m_companyName);
    result.replace("{{companyName}}", m_companyName);
    result.replace("{{ruc}}", m_companyRuc);
    result.replace("{{companyRuc}}", m_companyRuc);
    result.replace("{{address}}", m_companyAddress);
    result.replace("{{companyAddress}}", m_companyAddress);
    
    QString voucherTypeStr = (type == FACTURA) ? "FACTURA" : "BOLETA";
    result.replace("{{voucherType}}", voucherTypeStr);
    result.replace("{{invoiceNumber}}", sale.invoiceNumber);
    
    result.replace("{{date}}", sale.createdAt.toString("dd/MM/yyyy"));
    result.replace("{{datetime}}", sale.createdAt.toString("dd/MM/yyyy hh:mm"));
    result.replace("{{time}}", sale.createdAt.toString("hh:mm"));
    
    result.replace("{{customerName}}", sale.customerName);
    result.replace("{{customerRuc}}", invoiceData.ruc);
    
    result.replace("{{subtotal}}", QString::number(sale.subtotal, 'f', 2));
    result.replace("{{discount}}", QString::number(sale.discount, 'f', 2));
    result.replace("{{tax}}", QString::number(sale.tax, 'f', 2));
    result.replace("{{total}}", QString::number(sale.total, 'f', 2));
    
    // Información de pago (monto pagado y vuelto)
    result.replace("{{amountPaid}}", QString::number(sale.amountPaid, 'f', 2));
    result.replace("{{changeGiven}}", QString::number(sale.changeGiven, 'f', 2));
    
    return result;
}

QMap<QString, QString> PrintService::createVariablesMap(const Sale& sale, 
                                                         VoucherType type, 
                                                         const InvoiceData& invoiceData)
{
    QMap<QString, QString> vars;
    
    // Datos de la empresa
    vars["{{businessName}}"] = m_companyName;
    vars["{{companyName}}"] = m_companyName;
    vars["{{ruc}}"] = m_companyRuc;
    vars["{{companyRuc}}"] = m_companyRuc;
    vars["{{address}}"] = m_companyAddress;
    vars["{{companyAddress}}"] = m_companyAddress;
    vars["{{phone}}"] = m_companyPhone;
    vars["{{companyPhone}}"] = m_companyPhone;
    
    // Tipo de comprobante
    QString voucherTypeStr = (type == FACTURA) ? "FACTURA" : "BOLETA";
    vars["{{voucherType}}"] = voucherTypeStr;
    vars["{{invoiceNumber}}"] = sale.invoiceNumber;
    
    // Fechas
    vars["{{date}}"] = sale.createdAt.toString("dd/MM/yyyy");
    vars["{{datetime}}"] = sale.createdAt.toString("dd/MM/yyyy hh:mm");
    vars["{{time}}"] = sale.createdAt.toString("hh:mm");
    
    // Cliente
    vars["{{customerName}}"] = sale.customerName;
    vars["{{customerRuc}}"] = invoiceData.ruc;
    
    // Totales
    vars["{{subtotal}}"] = QString::number(sale.subtotal, 'f', 2);
    vars["{{discount}}"] = QString::number(sale.discount, 'f', 2);
    vars["{{tax}}"] = QString::number(sale.tax, 'f', 2);
    vars["{{total}}"] = QString::number(sale.total, 'f', 2);
    
    // Información de pago (monto pagado y vuelto)
    vars["{{amountPaid}}"] = QString::number(sale.amountPaid, 'f', 2);
    vars["{{changeGiven}}"] = QString::number(sale.changeGiven, 'f', 2);
    
    return vars;
}

bool PrintService::generateCustomTicketPdf(const Sale& sale, VoucherType type,
                                            const InvoiceData& invoiceData,
                                            const QString& layoutJson,
                                            const QString& outputPath)
{
    QJsonDocument doc = QJsonDocument::fromJson(layoutJson.toUtf8());
    double ticketWidth = 80;
    double ticketHeight = 200;
    
    if (doc.isObject()) {
        QJsonObject layoutObj = doc.object();
        if (layoutObj.contains("size")) {
            QJsonObject sizeObj = layoutObj["size"].toObject();
            ticketWidth = sizeObj["width"].toDouble(80);
            ticketHeight = sizeObj["height"].toDouble(200);
        }
    }
    
    QPrinter printer(QPrinter::HighResolution);
    printer.setOutputFormat(QPrinter::PdfFormat);
    printer.setOutputFileName(outputPath);
    
    // Configurar tamano de pagina personalizado
    printer.setPageSize(QPageSize(QSizeF(ticketWidth, ticketHeight), QPageSize::Millimeter));
    printer.setPageOrientation(QPageLayout::Portrait);
    
    // CONFIGURACION CRITICA: Usar pagina completa sin margenes
    printer.setFullPage(true);
    
    // Configurar layout con margenes en 0 y modo FullPage
    QPageLayout layout = printer.pageLayout();
    layout.setMargins(QMarginsF(0, 0, 0, 0));
    layout.setMode(QPageLayout::FullPageMode);
    printer.setPageLayout(layout);
    
    QPainter painter;
    if (!painter.begin(&printer)) {
        qDebug() << "Error iniciando generacion de PDF";
        return false;
    }
    
    drawCustomTicket(painter, sale, type, invoiceData, layoutJson);
    
    painter.end();
    
    qDebug() << "PDF generado exitosamente:" << outputPath;
    return true;
}


bool PrintService::generateCustomTicketPdf(const QVariantMap& saleData,
                                            int voucherType,
                                            const QVariantMap& invoiceData,
                                            const QString& layoutJson,
                                            const QString& outputPath)
{
    Sale sale;
    sale.id = saleData["id"].toInt();
    sale.invoiceNumber = saleData["invoiceNumber"].toString();
    sale.customerName = saleData["customerName"].toString();
    sale.subtotal = saleData["subtotal"].toDouble();
    sale.discount = saleData["discount"].toDouble();
    sale.tax = saleData["tax"].toDouble();
    sale.total = saleData["total"].toDouble();
    sale.paymentMethodId = saleData["paymentMethodId"].toInt();
    sale.createdAt = saleData["createdAt"].toDateTime();
    
    QVariantList itemsList = saleData["items"].toList();
    for (const QVariant& itemVar : itemsList) {
        QVariantMap itemMap = itemVar.toMap();
        SaleItem item;
        item.productName = itemMap["productName"].toString();
        item.quantity = itemMap["quantity"].toDouble();
        item.unitPrice = itemMap["unitPrice"].toDouble();
        item.subtotal = itemMap["subtotal"].toDouble();
        sale.items.append(item);
    }
    
    InvoiceData invoice;
    invoice.ruc = invoiceData["ruc"].toString();
    invoice.businessName = invoiceData["businessName"].toString();
    invoice.address = invoiceData["address"].toString();
    
    VoucherType type = (voucherType == 0) ? BOLETA : FACTURA;
    
    return generateCustomTicketPdf(sale, type, invoice, layoutJson, outputPath);
}

bool PrintService::generatePreviewPdf(const QString& layoutJson,
                                       const QString& outputPath)
{
    Sale sampleSale;
    sampleSale.id = 1;
    sampleSale.invoiceNumber = "B001-00000001";
    sampleSale.customerName = "Cliente de Ejemplo";
    sampleSale.subtotal = 100.00;
    sampleSale.discount = 0.00;
    sampleSale.tax = 18.00;
    sampleSale.total = 118.00;
    sampleSale.amountPaid = 150.00;   // Monto pagado de ejemplo
    sampleSale.changeGiven = 32.00;   // Vuelto calculado (150 - 118)
    sampleSale.paymentMethodId = 1;
    sampleSale.createdAt = QDateTime::currentDateTime();
    
    SaleItem item1;
    item1.productName = "Producto de ejemplo 1";
    item1.quantity = 2.0;
    item1.unitPrice = 25.00;
    item1.subtotal = 50.00;
    sampleSale.items.append(item1);
    
    SaleItem item2;
    item2.productName = "Producto de ejemplo 2";
    item2.quantity = 1.0;
    item2.unitPrice = 50.00;
    item2.subtotal = 50.00;
    sampleSale.items.append(item2);
    
    InvoiceData sampleInvoice;
    sampleInvoice.ruc = "20123456789";
    sampleInvoice.businessName = "Empresa de Ejemplo S.A.C.";
    sampleInvoice.address = "Av. Ejemplo 123, Lima";
    
    return generateCustomTicketPdf(sampleSale, BOLETA, sampleInvoice, layoutJson, outputPath);
}
