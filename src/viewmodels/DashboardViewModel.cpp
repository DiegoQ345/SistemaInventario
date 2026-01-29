#include "DashboardViewModel.h"
#include "../services/SalesService.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDateTime>

DashboardViewModel::DashboardViewModel(QObject *parent)
    : QObject(parent)
{
    // Lista de cajeros disponibles (hardcoded por ahora)
    m_availableCashiers << "Cajero Principal" << "Cajero 2" << "Cajero 3" << "Administrador";
    
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
