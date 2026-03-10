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
    // Obtener el reporte del día
    QString reportJson = getDailyReport();
    
    // TODO: Implementar generación de PDF del reporte diario
    // Por ahora, solo mostramos un mensaje
    qDebug() << "Generando PDF del reporte diario...";
    qDebug() << "Reporte:" << reportJson;
    
    // Aquí se podría integrar con PdfGeneratorService
    // para crear un PDF del reporte completo
}

void DashboardViewModel::generateDailyReportExcel()
{
    using namespace QXlsx;
    
    // Obtener información del negocio
    QSettings settings("SistemaInventario", "Config");
    QString businessName = settings.value("businessName", "Mi Negocio").toString();
    
    // Obtener datos de ventas
    SalesService salesService;
    auto todaySales = salesService.getTodaySales();
    
    if (todaySales.isEmpty()) {
        qDebug() << "No hay ventas para exportar hoy";
        return;
    }
    
    // Directorio de documentos del usuario
    QString documentsPath = QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation);
    QString fileName = QString("Reporte_Diario_%1.xlsx")
        .arg(QDate::currentDate().toString("yyyy-MM-dd"));
    QString defaultPath = documentsPath + "/" + fileName;
    
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
