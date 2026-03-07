#include "DashboardViewModel.h"
#include "../services/SalesService.h"
#include "../services/AuthenticationService.h"
#include "../database/DatabaseManager.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>
#include <QSqlQuery>
#include <QSqlError>

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
