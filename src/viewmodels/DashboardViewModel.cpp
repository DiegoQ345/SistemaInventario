#include "DashboardViewModel.h"
#include "../services/SalesService.h"
#include "../services/AuthenticationService.h"
#include "../database/DatabaseManager.h"
#include "xlsxdocument.h"
#include "xlsxformat.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>
#include <QSqlQuery>
#include <QSqlError>
#include <QFileDialog>
#include <QStandardPaths>
#include <QDesktopServices>
#include <QUrl>
#include <QSettings>
#include <QPrinter>
#include <QTextDocument>
#include <QPageSize>
#include <QPageLayout>
#include <QDir>
#include <QFileInfo>
#include <QRegularExpression>

DashboardViewModel::DashboardViewModel(QObject *parent)
    : QObject(parent)
{
    // Cargar usuarios según el rol del usuario actual
    loadAvailableCashiers();
    
    // Refrescar al iniciar
    refresh();
}

void DashboardViewModel::refresh()
{
    setIsLoading(true);

    SalesService salesService;
    auto stats = salesService.getDashboardStats();

    m_todaySales = stats.todaySales;
    m_todayTransactions = stats.todayTransactions;
    m_monthSales = stats.monthSales;
    m_averageTicket = stats.averageTicket;
    m_lowStockProducts = stats.lowStockProducts;
    m_totalProducts = stats.totalProducts;

    emit todaySalesChanged();
    emit todayTransactionsChanged();
    emit monthSalesChanged();
    emit averageTicketChanged();
    emit lowStockProductsChanged();
    emit totalProductsChanged();
    
    // Cargar estadísticas de cajero actual
    loadCashierStats();

    setIsLoading(false);
}

void DashboardViewModel::setIsLoading(bool loading)
{
    if (m_isLoading != loading) {
        m_isLoading = loading;
        emit isLoadingChanged();
    }
}

void DashboardViewModel::setCurrentCashier(const QString& cashier)
{
    if (m_currentCashier != cashier) {
        m_currentCashier = cashier;
        emit currentCashierChanged();
        loadCashierStats();
    }
}

void DashboardViewModel::loadCashierStats()
{
    if (m_currentCashier.isEmpty()) {
        m_todayTransactionsByCashier = 0;
        m_todaySalesByCashier = 0.0;
        emit todayTransactionsByCashierChanged();
        emit todaySalesByCashierChanged();
        return;
    }
    
    // TODO: Implementar filtro por cajero en SalesRepository
    // Por ahora, mostrar estadísticas generales
    m_todayTransactionsByCashier = m_todayTransactions;
    m_todaySalesByCashier = m_todaySales;
    
    emit todayTransactionsByCashierChanged();
    emit todaySalesByCashierChanged();
}

QString DashboardViewModel::closeDayShift()
{
    qDebug() << "=== Cierre de día ===";
    
    SalesService salesService;
    auto todaySales = salesService.getTodaySales();
    
    QJsonObject report;
    report["date"] = QDate::currentDate().toString(Qt::ISODate);
    report["closeTime"] = QDateTime::currentDateTime().toString(Qt::ISODate);
    report["cashier"] = m_currentCashier.isEmpty() ? "No especificado" : m_currentCashier;
    
    // Estadísticas generales
    QJsonObject generalStats;
    generalStats["totalSales"] = m_todaySales;
    generalStats["totalTransactions"] = m_todayTransactions;
    generalStats["averageTicket"] = m_averageTicket;
    report["generalStats"] = generalStats;
    
    // Ventas por tipo de comprobante
    QJsonObject byVoucherType;
    double boletas = 0.0, facturas = 0.0, tickets = 0.0;
    int boletasCount = 0, facturasCount = 0, ticketsCount = 0;
    
    for (const auto& sale : todaySales) {
        if (sale.voucherType == "BOLETA") {
            boletas += sale.total;
            boletasCount++;
        } else if (sale.voucherType == "FACTURA") {
            facturas += sale.total;
            facturasCount++;
        } else {
            tickets += sale.total;
            ticketsCount++;
        }
    }
    
    QJsonObject boletasObj;
    boletasObj["total"] = boletas;
    boletasObj["count"] = boletasCount;
    byVoucherType["boletas"] = boletasObj;
    
    QJsonObject facturasObj;
    facturasObj["total"] = facturas;
    facturasObj["count"] = facturasCount;
    byVoucherType["facturas"] = facturasObj;
    
    QJsonObject ticketsObj;
    ticketsObj["total"] = tickets;
    ticketsObj["count"] = ticketsCount;
    byVoucherType["tickets"] = ticketsObj;
    
    report["byVoucherType"] = byVoucherType;
    
    // Productos más vendidos (top 5)
    QMap<QString, int> productQuantities;
    for (const auto& sale : todaySales) {
        for (const auto& item : sale.items) {
            productQuantities[item.productName] += item.quantity;
        }
    }
    
    QJsonArray topProducts;
    auto sortedProducts = productQuantities.toStdMap();
    QList<QPair<QString, int>> productList;
    for (auto it = sortedProducts.begin(); it != sortedProducts.end(); ++it) {
        productList.append(qMakePair(it->first, it->second));
    }
    std::sort(productList.begin(), productList.end(), 
              [](const QPair<QString, int>& a, const QPair<QString, int>& b) {
                  return a.second > b.second;
              });
    
    for (int i = 0; i < qMin(5, productList.size()); ++i) {
        QJsonObject prod;
        prod["name"] = productList[i].first;
        prod["quantity"] = productList[i].second;
        topProducts.append(prod);
    }
    report["topProducts"] = topProducts;
    
    // Lista de todas las ventas con sus items
    QJsonArray salesArray;
    for (const auto& sale : todaySales) {
        QJsonObject saleObj;
        saleObj["id"] = sale.id;
        saleObj["invoiceNumber"] = sale.invoiceNumber;
        saleObj["voucherType"] = sale.voucherType.isEmpty() ? "TICKET" : sale.voucherType;
        saleObj["paymentType"] = sale.paymentType;
        saleObj["total"] = sale.total;
        saleObj["createdAt"] = sale.createdAt.toString("dd/MM/yyyy hh:mm");
        saleObj["itemCount"] = sale.items.size();
        
        // Agregar items de la venta
        QJsonArray itemsArray;
        for (const auto& item : sale.items) {
            QJsonObject itemObj;
            itemObj["productName"] = item.productName;
            itemObj["quantity"] = item.quantity;
            itemObj["unitPrice"] = item.unitPrice;
            itemObj["subtotal"] = item.subtotal;
            itemsArray.append(itemObj);
        }
        saleObj["items"] = itemsArray;
        
        salesArray.append(saleObj);
    }
    report["sales"] = salesArray;
    
    QJsonDocument doc(report);
    QString jsonString = doc.toJson(QJsonDocument::Indented);
    
    qDebug() << "Reporte de cierre generado:" << jsonString;
    emit dayClosingCompleted(jsonString);
    
    return jsonString;
}

QString DashboardViewModel::getDailyReport()
{
    // Similar a closeDayShift pero sin marcar como cerrado
    return closeDayShift();
}

void DashboardViewModel::generateDailyReportPDF()
{
    // Obtener información del negocio
    QSettings settings("SistemaInventario", "Config");
    QString businessName = settings.value("businessName", "Mi Negocio").toString();
    QString businessRuc = settings.value("businessRuc", "").toString();
    QString businessAddress = settings.value("businessAddress", "").toString();
    QString businessPhone = settings.value("businessPhone", "").toString();
    
    // Sanitizar nombre del negocio para carpetas
    QString sanitizedBusinessName = businessName;
    sanitizedBusinessName.replace(QRegularExpression("[^a-zA-Z0-9_]"), "_");
    sanitizedBusinessName.replace(QRegularExpression("_+"), "_");
    
    // Construir estructura de carpetas: C:/Reportes_{NombreNegocio}/Reportes_Diarios/
    QString baseDir = "C:/Reportes_" + sanitizedBusinessName;
    QString reportsDir = baseDir + "/Reportes_Diarios";
    
    // Crear directorios si no existen
    QDir dir;
    if (!dir.exists(reportsDir)) {
        qDebug() << "Creando estructura de directorios:" << reportsDir;
        if (!dir.mkpath(reportsDir)) {
            qCritical() << "Error al crear directorio de reportes:" << reportsDir;
            return;
        }
    }
    
    // Generar nombre de archivo
    QString dateStr = QDate::currentDate().toString("yyyy-MM-dd");
    QString fileName = "Reporte_" + dateStr + ".pdf";
    QString outputPath = reportsDir + "/" + fileName;
    
    qDebug() << "Generando PDF del reporte diario en:" << outputPath;
    
    // Obtener datos de ventas
    SalesService salesService;
    auto todaySales = salesService.getTodaySales();
    
    if (todaySales.isEmpty()) {
        qDebug() << "No hay ventas para generar reporte hoy";
        return;
    }
    
    // Calcular estadísticas
    double boletas = 0.0, facturas = 0.0, tickets = 0.0;
    int boletasCount = 0, facturasCount = 0, ticketsCount = 0;
    
    for (const auto& sale : todaySales) {
        if (sale.voucherType == "BOLETA") {
            boletas += sale.total;
            boletasCount++;
        } else if (sale.voucherType == "FACTURA") {
            facturas += sale.total;
            facturasCount++;
        } else {
            tickets += sale.total;
            ticketsCount++;
        }
    }
    
    // Crear HTML del reporte siguiendo el patrón de PdfGeneratorService
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
                    color: #000000;
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
                .header p {
                    margin: 0;
                    font-size: 6pt;
                    color: #666;
                }
                .header .report-date {
                    color: #999;
                    font-size: 7pt;
                    margin: 4px 0 0 0;
                    font-style: italic;
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
                    text-align: center;
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
                h3.section-title {
                    color: #2196F3;
                    margin: 10px 0 5px 0;
                    font-size: 9pt;
                    border-bottom: 1px solid #2196F3;
                    padding-bottom: 3px;
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
                    color: #000000;
                }
                tbody tr:nth-child(even) {
                    background-color: #f9f9f9;
                }
                .total-row {
                    font-weight: bold;
                    background-color: #e3f2fd !important;
                    font-size: 7pt;
                }
                .money {
                    text-align: right;
                }
                .sale-header {
                    background-color: #f5f5f5;
                    font-weight: bold;
                }
                .products-row {
                    background-color: #fafafa !important;
                }
                .products-table {
                    width: 100%;
                    margin: 5px 0;
                    border-collapse: collapse;
                    font-size: 6pt;
                }
                .products-table th {
                    background-color: #e0e0e0;
                    padding: 3px 5px;
                    font-size: 6pt;
                    color: #000000;
                }
                .products-table td {
                    padding: 2px 5px;
                    border-bottom: 1px solid #f0f0f0;
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
            </style>
        </head>
        <body>
            <div class="header">
                <h1>)" + businessName + R"(</h1>)";
    
    if (!businessRuc.isEmpty()) {
        html += R"(
                <p>RUC: )" + businessRuc + R"(</p>)";
    }
    if (!businessAddress.isEmpty()) {
        html += R"(
                <p>)" + businessAddress + R"(</p>)";
    }
    if (!businessPhone.isEmpty()) {
        html += R"(
                <p>Tel: )" + businessPhone + R"(</p>)";
    }
    
    html += R"(
                <h2>REPORTE DE VENTAS DEL DÍA</h2>
                <p class="report-date">)" + QDate::currentDate().toString("dddd, dd 'de' MMMM 'de' yyyy") + R"(</p>
                <p class="report-date">Generado: )" + QDateTime::currentDateTime().toString("dd/MM/yyyy hh:mm") + R"(</p>)";
    
    QString cashierName = m_currentCashier.isEmpty() ? "Todos los cajeros" : m_currentCashier;
    html += R"(
                <p class="report-date">Cajero: )" + cashierName + R"(</p>
            </div>
            
            <div class="stats-box">
                <table class="stats-table">
                    <tr>
                        <td class="label">Total Ventas:</td>
                        <td class="label">Total Transacciones:</td>
                        <td class="label">Ticket Promedio:</td>
                    </tr>
                    <tr>
                        <td class="value">S/ )" + QString::number(m_todaySales, 'f', 2) + R"(</td>
                        <td class="value">)" + QString::number(m_todayTransactions) + R"(</td>
                        <td class="value">S/ )" + QString::number(m_averageTicket, 'f', 2) + R"(</td>
                    </tr>
                </table>
            </div>
            
            <h3 class="section-title">VENTAS POR TIPO DE COMPROBANTE</h3>
            <table>
                <thead>
                    <tr>
                        <th>Tipo</th>
                        <th style="text-align: right;">Cantidad</th>
                        <th style="text-align: right;">Total</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>Boletas</td>
                        <td class="money">)" + QString::number(boletasCount) + R"(</td>
                        <td class="money">S/ )" + QString::number(boletas, 'f', 2) + R"(</td>
                    </tr>
                    <tr>
                        <td>Facturas</td>
                        <td class="money">)" + QString::number(facturasCount) + R"(</td>
                        <td class="money">S/ )" + QString::number(facturas, 'f', 2) + R"(</td>
                    </tr>
                    <tr>
                        <td>Tickets</td>
                        <td class="money">)" + QString::number(ticketsCount) + R"(</td>
                        <td class="money">S/ )" + QString::number(tickets, 'f', 2) + R"(</td>
                    </tr>
                    <tr class="total-row">
                        <td>TOTAL</td>
                        <td class="money">)" + QString::number(m_todayTransactions) + R"(</td>
                        <td class="money">S/ )" + QString::number(m_todaySales, 'f', 2) + R"(</td>
                    </tr>
                </tbody>
            </table>
            
            <h3 class="section-title">DETALLE DE VENTAS)";
    
    int maxSales = qMin(50, todaySales.size());
    if (todaySales.size() > 50) {
        html += " (Mostrando primeras 50 de " + QString::number(todaySales.size()) + ")";
    }
    
    html += R"(</h3>)";
    
    // Generar detalle de cada venta con sus productos
    for (int i = 0; i < maxSales; ++i) {
        const auto& sale = todaySales[i];
        
        // Encabezado de la venta
        html += R"(
            <table style="margin-bottom: 15px;">
                <thead>
                    <tr class="sale-header">
                        <th style="width: 8%;">Hora</th>
                        <th style="width: 15%;">Factura</th>
                        <th style="width: 12%;">Tipo</th>
                        <th style="width: 25%;">Cliente</th>
                        <th style="width: 12%;">Pago</th>
                        <th style="width: 8%;">Items</th>
                        <th style="text-align: right; width: 20%;">Total</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>)" + sale.createdAt.toString("hh:mm") + R"(</td>
                        <td>)" + sale.invoiceNumber + R"(</td>
                        <td>)" + (sale.voucherType.isEmpty() ? "TICKET" : sale.voucherType) + R"(</td>
                        <td>)" + (sale.customerName.isEmpty() ? "-" : sale.customerName) + R"(</td>
                        <td>)" + (sale.paymentType.isEmpty() ? "CONTADO" : sale.paymentType) + R"(</td>
                        <td>)" + QString::number(sale.items.size()) + R"(</td>
                        <td class="money">S/ )" + QString::number(sale.total, 'f', 2) + R"(</td>
                    </tr>)";
        
        // Productos de la venta
        if (!sale.items.isEmpty()) {
            html += R"(
                    <tr class="products-row">
                        <td colspan="7" style="padding: 5px 10px;">
                            <table class="products-table">
                                <thead>
                                    <tr>
                                        <th style="text-align: left;">Producto</th>
                                        <th style="text-align: right; width: 10%;">Cant.</th>
                                        <th style="text-align: right; width: 15%;">P. Unit.</th>
                                        <th style="text-align: right; width: 15%;">Subtotal</th>
                                    </tr>
                                </thead>
                                <tbody>)";
            
            for (const auto& item : sale.items) {
                html += R"(
                                    <tr>
                                        <td>)" + item.productName + R"(</td>
                                        <td class="money">)" + QString::number(item.quantity) + R"(</td>
                                        <td class="money">S/ )" + QString::number(item.unitPrice, 'f', 2) + R"(</td>
                                        <td class="money">S/ )" + QString::number(item.subtotal, 'f', 2) + R"(</td>
                                    </tr>)";
            }
            
            html += R"(
                                </tbody>
                            </table>
                        </td>
                    </tr>)";
        }
        
        html += R"(
                </tbody>
            </table>)";
    }
    
    html += R"(
            <div class="footer">
                <p>Sistema de Inventario - Reporte Generado Automáticamente</p>
            </div>
        </body>
        </html>)";
    
    // Generar PDF usando el mismo patrón que PdfGeneratorService
    QPrinter printer(QPrinter::HighResolution);
    printer.setOutputFormat(QPrinter::PdfFormat);
    printer.setOutputFileName(outputPath);
    printer.setPageSize(QPageSize(QPageSize::A4));
    printer.setPageMargins(QMarginsF(6, 6, 6, 6), QPageLayout::Millimeter);
    
    // Renderizar HTML a PDF
    QTextDocument document;
    document.setHtml(html);
    document.setPageSize(printer.pageRect(QPrinter::Point).size());
    
    // Imprimir a PDF
    document.print(&printer);
    
    // Verificar que el archivo se creó
    QFileInfo fileInfo(outputPath);
    if (!fileInfo.exists() || fileInfo.size() == 0) {
        qCritical() << "Error: El PDF no se generó correctamente";
        return;
    }
    
    qDebug() << "PDF generado exitosamente:" << outputPath;
    qDebug() << "  Tamaño:" << fileInfo.size() << "bytes";
    
    // Abrir el PDF automáticamente
    if (!QDesktopServices::openUrl(QUrl::fromLocalFile(outputPath))) {
        qWarning() << "No se pudo abrir el PDF automáticamente";
    }
}

void DashboardViewModel::generateDailyReportExcel()
{
    using namespace QXlsx;
    
    // Obtener información del negocio
    QSettings settings("SistemaInventario", "Config");
    QString businessName = settings.value("businessName", "Mi Negocio").toString();
    
    // Sanitizar nombre del negocio para carpetas
    QString sanitizedBusinessName = businessName;
    sanitizedBusinessName.replace(QRegularExpression("[^a-zA-Z0-9_]"), "_");
    sanitizedBusinessName.replace(QRegularExpression("_+"), "_");
    
    // Construir estructura de carpetas: C:/Reportes_{NombreNegocio}/Reportes_Diarios/
    QString baseDir = "C:/Reportes_" + sanitizedBusinessName;
    QString reportsDir = baseDir + "/Reportes_Diarios";
    
    // Crear directorios si no existen
    QDir dir;
    if (!dir.exists(reportsDir)) {
        qDebug() << "Creando estructura de directorios:" << reportsDir;
        if (!dir.mkpath(reportsDir)) {
            qCritical() << "Error al crear directorio de reportes:" << reportsDir;
            return;
        }
    }
    
    // Obtener datos de ventas
    SalesService salesService;
    auto todaySales = salesService.getTodaySales();
    
    if (todaySales.isEmpty()) {
        qDebug() << "No hay ventas para exportar hoy";
        return;
    }
    
    // Generar nombre de archivo
    QString dateStr = QDate::currentDate().toString("yyyy-MM-dd");
    QString fileName = "Reporte_" + dateStr + ".xlsx";
    QString defaultPath = reportsDir + "/" + fileName;
    
    // Crear documento Excel
    Document xlsx;
    
    // Configurar formatos
    Format headerFormat;
    headerFormat.setFontBold(true);
    headerFormat.setFontSize(12);
    headerFormat.setFontColor(Qt::white);
    headerFormat.setPatternBackgroundColor(QColor(25, 118, 210));
    headerFormat.setHorizontalAlignment(Format::AlignHCenter);
    headerFormat.setVerticalAlignment(Format::AlignVCenter);
    
    Format titleFormat;
    titleFormat.setFontBold(true);
    titleFormat.setFontSize(16);
    titleFormat.setFontColor(QColor(33, 150, 243));
    
    Format subtitleFormat;
    subtitleFormat.setFontBold(true);
    subtitleFormat.setFontSize(11);
    
    Format moneyFormat;
    moneyFormat.setNumberFormat("S/ #,##0.00");
    
    Format moneyBoldFormat;
    moneyBoldFormat.setNumberFormat("S/ #,##0.00");
    moneyBoldFormat.setFontBold(true);
    moneyBoldFormat.setFontSize(11);
    
    Format detailFormat;
    detailFormat.setFontSize(9);
    detailFormat.setFontColor(QColor(85, 85, 85));
    detailFormat.setVerticalAlignment(Format::AlignTop);
    
    // Título del reporte
    int row = 1;
    xlsx.write(row, 1, businessName, titleFormat);
    row++;
    
    xlsx.write(row, 1, "REPORTE DE VENTAS DEL DÍA", subtitleFormat);
    row++;
    
    xlsx.write(row, 1, QDate::currentDate().toString("dd/MM/yyyy"));
    row++;
    
    QString cashierName = m_currentCashier.isEmpty() ? "Todos los cajeros" : m_currentCashier;
    xlsx.write(row, 1, "Cajero: " + cashierName);
    row++;
    
    xlsx.write(row, 1, "Fecha de generación:", subtitleFormat);
    xlsx.write(row, 2, QDateTime::currentDateTime().toString("dd/MM/yyyy hh:mm"));
    row += 2;
    
    // Estadísticas generales
    xlsx.write(row, 1, "RESUMEN", subtitleFormat);
    row++;
    
    xlsx.write(row, 1, "Total Ventas:");
    xlsx.write(row, 2, m_todaySales, moneyBoldFormat);
    row++;
    
    xlsx.write(row, 1, "Total Transacciones:");
    xlsx.write(row, 2, m_todayTransactions);
    row++;
    
    xlsx.write(row, 1, "Ticket Promedio:");
    xlsx.write(row, 2, m_averageTicket, moneyFormat);
    row += 2;
    
    // Ventas por tipo de comprobante
    xlsx.write(row, 1, "VENTAS POR TIPO DE COMPROBANTE", subtitleFormat);
    row++;
    
    double boletas = 0.0, facturas = 0.0, tickets = 0.0;
    int boletasCount = 0, facturasCount = 0, ticketsCount = 0;
    
    for (const auto& sale : todaySales) {
        if (sale.voucherType == "BOLETA") {
            boletas += sale.total;
            boletasCount++;
        } else if (sale.voucherType == "FACTURA") {
            facturas += sale.total;
            facturasCount++;
        } else {
            tickets += sale.total;
            ticketsCount++;
        }
    }
    
    xlsx.write(row, 1, "Tipo", headerFormat);
    xlsx.write(row, 2, "Cantidad", headerFormat);
    xlsx.write(row, 3, "Total", headerFormat);
    row++;
    
    xlsx.write(row, 1, "Boletas");
    xlsx.write(row, 2, boletasCount);
    xlsx.write(row, 3, boletas, moneyFormat);
    row++;
    
    xlsx.write(row, 1, "Facturas");
    xlsx.write(row, 2, facturasCount);
    xlsx.write(row, 3, facturas, moneyFormat);
    row++;
    
    xlsx.write(row, 1, "Tickets");
    xlsx.write(row, 2, ticketsCount);
    xlsx.write(row, 3, tickets, moneyFormat);
    row += 2;
    
    // Productos más vendidos
    QMap<QString, QPair<int, double>> productStats; // nombre -> (cantidad, revenue)
    for (const auto& sale : todaySales) {
        for (const auto& item : sale.items) {
            auto& stats = productStats[item.productName];
            stats.first += item.quantity;
            stats.second += item.subtotal;
        }
    }
    
    QList<QPair<QString, QPair<int, double>>> productList;
    for (auto it = productStats.begin(); it != productStats.end(); ++it) {
        productList.append(qMakePair(it.key(), it.value()));
    }
    std::sort(productList.begin(), productList.end(), 
              [](const QPair<QString, QPair<int, double>>& a, 
                 const QPair<QString, QPair<int, double>>& b) {
                  return a.second.first > b.second.first; // Ordenar por cantidad
              });
    
    xlsx.write(row, 1, "PRODUCTOS MÁS VENDIDOS", subtitleFormat);
    row++;
    
    xlsx.write(row, 1, "#", headerFormat);
    xlsx.write(row, 2, "Producto", headerFormat);
    xlsx.write(row, 3, "Cantidad", headerFormat);
    xlsx.write(row, 4, "Total Vendido", headerFormat);
    row++;
    
    int maxProducts = qMin(10, productList.size());
    for (int i = 0; i < maxProducts; ++i) {
        xlsx.write(row, 1, i + 1);
        xlsx.write(row, 2, productList[i].first);
        xlsx.write(row, 3, productList[i].second.first);
        xlsx.write(row, 4, productList[i].second.second, moneyFormat);
        row++;
    }
    row += 2;
    
    // Detalle de ventas
    xlsx.write(row, 1, "DETALLE DE VENTAS", subtitleFormat);
    row++;
    
    xlsx.write(row, 1, "Hora", headerFormat);
    xlsx.write(row, 2, "Factura", headerFormat);
    xlsx.write(row, 3, "Tipo", headerFormat);
    xlsx.write(row, 4, "Items", headerFormat);
    xlsx.write(row, 5, "Productos", headerFormat);
    xlsx.write(row, 6, "Pago", headerFormat);
    xlsx.write(row, 7, "Total", headerFormat);
    row++;
    
    for (const auto& sale : todaySales) {
        xlsx.write(row, 1, sale.createdAt.toString("hh:mm"));
        xlsx.write(row, 2, sale.invoiceNumber);
        xlsx.write(row, 3, sale.voucherType.isEmpty() ? "TICKET" : sale.voucherType);
        xlsx.write(row, 4, sale.items.size());
        xlsx.write(row, 5, sale.productNames.isEmpty() ? 
            QString("%1 productos").arg(sale.items.size()) : sale.productNames);
        xlsx.write(row, 6, sale.paymentType.isEmpty() ? "CONTADO" : sale.paymentType);
        xlsx.write(row, 7, sale.total, moneyFormat);
        row++;
        
        // Detalle de productos
        if (!sale.items.isEmpty()) {
            QString productsDetail = "  Productos:\n";
            for (const SaleItem& item : sale.items) {
                productsDetail += QString("    • %1 %2 - S/ %3\n")
                    .arg(QString::number(item.quantity, 'f', 0))
                    .arg(item.productName)
                    .arg(QString::number(item.subtotal, 'f', 2));
            }
            
            xlsx.mergeCells(CellRange(row, 2, row, 7));
            xlsx.write(row, 2, productsDetail, detailFormat);
            xlsx.setRowHeight(row, 15.0 * (sale.items.size() + 1));
            
            row++;
        }
    }
    
    // Ajustar anchos de columna
    xlsx.setColumnWidth(1, 12);  // Hora
    xlsx.setColumnWidth(2, 20);  // Factura/Producto
    xlsx.setColumnWidth(3, 12);  // Tipo
    xlsx.setColumnWidth(4, 10);  // Items/Cantidad
    xlsx.setColumnWidth(5, 35);  // Productos
    xlsx.setColumnWidth(6, 12);  // Pago
    xlsx.setColumnWidth(7, 15);  // Total
    
    // Guardar archivo
    if (xlsx.saveAs(defaultPath)) {
        qDebug() << "Reporte Excel guardado en:" << defaultPath;
        
        // Abrir el archivo automáticamente
        QDesktopServices::openUrl(QUrl::fromLocalFile(defaultPath));
    } else {
        qWarning() << "Error al guardar reporte Excel en:" << defaultPath;
    }
}

void DashboardViewModel::loadAvailableCashiers()
{
    m_availableCashiers.clear();
    
    // Obtener usuario actual
    auto& authService = AuthenticationService::instance();
    QString currentUserRole = authService.currentUserRole();
    QString currentUsername = authService.currentUsername();
    
    if (currentUserRole == "Admin" || currentUserRole == "Programador") {
        // Si es administrador o programador, cargar todos los usuarios
        DatabaseManager& db = DatabaseManager::instance();
        QSqlQuery query(db.database());
        
        query.prepare("SELECT username FROM users WHERE active = 1 ORDER BY username");
        
        if (query.exec()) {
            while (query.next()) {
                m_availableCashiers << query.value(0).toString();
            }
        } else {
            qWarning() << "Error loading users:" << query.lastError().text();
            // Fallback: solo usuario actual
            m_availableCashiers << currentUsername;
        }
    } else {
        // Si es vendedor, solo mostrar su nombre
        m_availableCashiers << currentUsername;
    }
    
    // Establecer el usuario actual como cajero seleccionado
    if (!m_availableCashiers.isEmpty()) {
        m_currentCashier = currentUsername;
    }
    
    emit availableCashiersChanged();
    emit currentCashierChanged();
}

QVariantList DashboardViewModel::getSalesByVoucherType()
{
    QVariantList result;
    
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare(R"(
        SELECT voucher_type, COUNT(*) as count, SUM(total) as total
        FROM sales
        WHERE DATE(created_at) = DATE('now', 'localtime')
        AND status != 'CANCELLED'
        GROUP BY voucher_type
    )");
    
    if (query.exec()) {
        while (query.next()) {
            QVariantMap item;
            item["label"] = query.value(0).toString();
            item["count"] = query.value(1).toInt();
            item["value"] = query.value(2).toDouble();
            result.append(item);
        }
    } else {
        qWarning() << "Error getting sales by voucher type:" << query.lastError().text();
    }
    
    return result;
}

QVariantList DashboardViewModel::getTopCategories(int limit)
{
    QVariantList result;
    
    qDebug() << "=== getTopCategories called with limit:" << limit;
    
    QSqlQuery query(DatabaseManager::instance().database());
    // SQLite no acepta bind en LIMIT, usar QString directamente
    QString queryStr = QString(R"(
        SELECT c.name, SUM(si.quantity) as total_qty, SUM(si.subtotal) as revenue
        FROM sale_items si
        INNER JOIN sales s ON si.sale_id = s.id
        INNER JOIN products p ON si.product_id = p.id
        LEFT JOIN categories c ON p.category_id = c.id
        WHERE DATE(s.created_at) = DATE('now', 'localtime')
        AND s.status != 'CANCELLED'
        GROUP BY p.category_id
        ORDER BY total_qty DESC
        LIMIT %1
    )").arg(limit);
    
    qDebug() << "Executing query:" << queryStr;
    
    if (query.exec(queryStr)) {
        int count = 0;
        while (query.next()) {
            QVariantMap item;
            QString name = query.value(0).toString();
            if (name.isEmpty()) {
                name = "Sin categoría";
            }
            double quantity = query.value(1).toDouble();
            double revenue = query.value(2).toDouble();
            
            item["name"] = name;
            item["quantity"] = quantity;
            item["revenue"] = revenue;
            
            result.append(item);
            count++;
            
            qDebug() << "  Category" << count << ":" << name 
                     << "| Quantity:" << quantity
                     << "| Revenue: S/" << revenue;
        }
        qDebug() << "=== Total categories returned:" << result.size();
    } else {
        qWarning() << "❌ Error getting top categories:" << query.lastError().text();
    }
    
    return result;
}

QVariantList DashboardViewModel::getTopProducts(int limit)
{
    QVariantList result;
    
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare(R"(
        SELECT p.name, SUM(si.quantity) as total_qty, SUM(si.subtotal) as revenue
        FROM sale_items si
        INNER JOIN sales s ON si.sale_id = s.id
        INNER JOIN products p ON si.product_id = p.id
        WHERE DATE(s.created_at) = DATE('now', 'localtime')
        AND s.status != 'CANCELLED'
        GROUP BY si.product_id
        ORDER BY total_qty DESC
        LIMIT :limit
    )");
    query.bindValue(":limit", limit);
    
    if (query.exec()) {
        while (query.next()) {
            QVariantMap item;
            item["name"] = query.value(0).toString();
            item["quantity"] = query.value(1).toDouble();
            item["revenue"] = query.value(2).toDouble();
            result.append(item);
        }
    } else {
        qWarning() << "Error getting top products:" << query.lastError().text();
    }
    
    return result;
}

QVariantList DashboardViewModel::getTopCategoriesByPeriod(int limit, int days)
{
    QVariantList result;
    
    qDebug() << "=== getTopCategoriesByPeriod called with limit:" << limit << "days:" << days;
    
    QSqlQuery query(DatabaseManager::instance().database());
    // SQLite no acepta bind en LIMIT, usar QString directamente
    QString queryStr = QString(R"(
        SELECT c.name, SUM(si.quantity) as total_qty, SUM(si.subtotal) as revenue
        FROM sale_items si
        INNER JOIN sales s ON si.sale_id = s.id
        INNER JOIN products p ON si.product_id = p.id
        LEFT JOIN categories c ON p.category_id = c.id
        WHERE DATE(s.created_at) >= DATE('now', 'localtime', '-%1 days')
        AND s.status != 'CANCELLED'
        GROUP BY p.category_id
        ORDER BY total_qty DESC
        LIMIT %2
    )").arg(days).arg(limit);
    
    qDebug() << "Executing query:" << queryStr;
    
    if (query.exec(queryStr)) {
        int count = 0;
        while (query.next()) {
            QVariantMap item;
            QString name = query.value(0).toString();
            if (name.isEmpty()) {
                name = "Sin categoría";
            }
            double quantity = query.value(1).toDouble();
            double revenue = query.value(2).toDouble();
            
            item["name"] = name;
            item["quantity"] = quantity;
            item["revenue"] = revenue;
            
            result.append(item);
            count++;
            
            qDebug() << "  Category" << count << ":" << name 
                     << "| Quantity:" << quantity
                     << "| Revenue: S/" << revenue;
        }
        qDebug() << "=== Total categories returned:" << result.size();
    } else {
        qWarning() << "❌ Error getting top categories by period:" << query.lastError().text();
    }
    
    return result;
}

QVariantList DashboardViewModel::getTopProductsByPeriod(int limit, int days)
{
    QVariantList result;
    
    qDebug() << "=== getTopProductsByPeriod called with limit:" << limit << "days:" << days;
    
    QSqlQuery query(DatabaseManager::instance().database());
    // SQLite no acepta bind en LIMIT, usar QString directamente
    QString queryStr = QString(R"(
        SELECT p.name, SUM(si.quantity) as total_qty, SUM(si.subtotal) as revenue
        FROM sale_items si
        INNER JOIN sales s ON si.sale_id = s.id
        INNER JOIN products p ON si.product_id = p.id
        WHERE DATE(s.created_at) >= DATE('now', 'localtime', '-%1 days')
        AND s.status != 'CANCELLED'
        GROUP BY si.product_id
        ORDER BY total_qty DESC
        LIMIT %2
    )").arg(days).arg(limit);
    
    qDebug() << "Executing query:" << queryStr;
    
    if (query.exec(queryStr)) {
        int count = 0;
        while (query.next()) {
            QVariantMap item;
            QString name = query.value(0).toString();
            double quantity = query.value(1).toDouble();
            double revenue = query.value(2).toDouble();
            
            item["name"] = name;
            item["quantity"] = quantity;
            item["revenue"] = revenue;
            
            result.append(item);
            count++;
            
            qDebug() << "  Product" << count << ":" << name 
                     << "| Quantity:" << quantity
                     << "| Revenue: S/" << revenue;
        }
        qDebug() << "=== Total products returned:" << result.size();
    } else {
        qWarning() << "❌ Error getting top products by period:" << query.lastError().text();
    }
    
    return result;
}

QVariantList DashboardViewModel::getTopCustomers(int limit)
{
    QVariantList result;
    
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare(R"(
        SELECT c.name, COUNT(s.id) as purchases, SUM(s.total) as total_spent
        FROM sales s
        INNER JOIN customers c ON s.customer_id = c.id
        WHERE strftime('%Y-%m', s.created_at) = strftime('%Y-%m', 'now', 'localtime')
        AND s.status != 'CANCELLED'
        GROUP BY s.customer_id
        ORDER BY purchases DESC
        LIMIT :limit
    )");
    query.bindValue(":limit", limit);
    
    if (query.exec()) {
        while (query.next()) {
            QVariantMap item;
            item["name"] = query.value(0).toString();
            item["purchases"] = query.value(1).toInt();
            item["totalSpent"] = query.value(2).toDouble();
            result.append(item);
        }
    } else {
        qWarning() << "Error getting top customers:" << query.lastError().text();
    }
    
    return result;
}

QVariantList DashboardViewModel::getLowStockProducts(int limit)
{
    QVariantList result;
    
    qDebug() << "=== getLowStockProducts called with limit:" << limit;
    
    QSqlQuery query(DatabaseManager::instance().database());
    // SQLite no acepta bind en LIMIT, usar QString directamente
    QString queryStr = QString(R"(
        SELECT name, current_stock, minimum_stock
        FROM products
        WHERE current_stock >= 0
        ORDER BY current_stock ASC, name ASC
        LIMIT %1
    )").arg(limit);
    
    qDebug() << "Executing query:" << queryStr;
    
    if (query.exec(queryStr)) {
        int count = 0;
        while (query.next()) {
            QVariantMap item;
            QString name = query.value(0).toString();
            int currentStock = query.value(1).toInt();
            int minimumStock = query.value(2).toInt();
            
            item["name"] = name;
            item["currentStock"] = currentStock;
            item["minimumStock"] = minimumStock;
            item["needsRestock"] = currentStock < minimumStock;
            
            result.append(item);
            count++;
            
            qDebug() << "  Product" << count << ":" << name 
                     << "| Stock:" << currentStock << "/" << minimumStock
                     << "| Needs restock:" << (currentStock < minimumStock ? "YES" : "NO");
        }
        qDebug() << "=== Total products returned:" << result.size();
    } else {
        qWarning() << "❌ Error getting low stock products:" << query.lastError().text();
    }
    
    return result;
}

QVariantList DashboardViewModel::getSalesTrendData(int days)
{
    QVariantList result;
    
    QSqlQuery query(DatabaseManager::instance().database());
    query.prepare(R"(
        SELECT 
            DATE(created_at) as sale_date,
            COUNT(*) as sales_count,
            SUM(total) as sales_total
        FROM sales
        WHERE DATE(created_at) >= DATE('now', 'localtime', '-' || :days || ' days')
        AND status != 'CANCELLED'
        GROUP BY DATE(created_at)
        ORDER BY sale_date ASC
    )");
    query.bindValue(":days", days);
    
    if (query.exec()) {
        while (query.next()) {
            QVariantMap item;
            // Convertir fecha SQL a timestamp para QML DateTimeAxis
            QString dateStr = query.value(0).toString(); // "YYYY-MM-DD"
            QDate date = QDate::fromString(dateStr, "yyyy-MM-dd");
            QDateTime dateTime(date, QTime(12, 0)); // Mediodía para centrar en el día
            item["timestamp"] = dateTime.toMSecsSinceEpoch();
            item["date"] = dateStr;
            item["salesCount"] = query.value(1).toInt();
            item["salesTotal"] = query.value(2).toDouble();
            result.append(item);
        }
    } else {
        qWarning() << "Error getting sales trend data:" << query.lastError().text();
    }
    
    return result;
}
