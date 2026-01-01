#include "ReportsViewModel.h"
#include "../repositories/SaleRepository.h"
#include <QDebug>

ReportsViewModel::ReportsViewModel(QObject *parent)
    : QObject(parent)
    , m_periodType("daily")
    , m_startDate(QDate::currentDate())
    , m_endDate(QDate::currentDate())
    , m_isLoading(false)
{
}

void ReportsViewModel::setPeriodType(const QString& type)
{
    if (m_periodType != type) {
        m_periodType = type;
        emit periodTypeChanged();
        loadReport();
    }
}

void ReportsViewModel::setStartDate(const QDate& date)
{
    if (m_startDate != date) {
        m_startDate = date;
        emit startDateChanged();
    }
}

void ReportsViewModel::setEndDate(const QDate& date)
{
    if (m_endDate != date) {
        m_endDate = date;
        emit endDateChanged();
    }
}

void ReportsViewModel::setQuickPeriod(const QString& period)
{
    QDate today = QDate::currentDate();
    
    if (period == "today") {
        m_periodType = "daily";
        m_startDate = today;
        m_endDate = today;
    }
    else if (period == "week") {
        m_periodType = "weekly";
        m_startDate = today.addDays(-(today.dayOfWeek() - 1)); // Lunes
        m_endDate = m_startDate.addDays(6); // Domingo
    }
    else if (period == "month") {
        m_periodType = "monthly";
        m_startDate = QDate(today.year(), today.month(), 1);
        m_endDate = QDate(today.year(), today.month(), today.daysInMonth());
    }
    else if (period == "year") {
        m_periodType = "yearly";
        m_startDate = QDate(today.year(), 1, 1);
        m_endDate = QDate(today.year(), 12, 31);
    }
    else if (period == "lastWeek") {
        m_periodType = "weekly";
        QDate lastWeekStart = today.addDays(-(today.dayOfWeek() - 1) - 7);
        m_startDate = lastWeekStart;
        m_endDate = lastWeekStart.addDays(6);
    }
    else if (period == "lastMonth") {
        m_periodType = "monthly";
        QDate lastMonth = today.addMonths(-1);
        m_startDate = QDate(lastMonth.year(), lastMonth.month(), 1);
        m_endDate = QDate(lastMonth.year(), lastMonth.month(), lastMonth.daysInMonth());
    }
    
    emit periodTypeChanged();
    emit startDateChanged();
    emit endDateChanged();
    
    loadReport();
}

void ReportsViewModel::loadReport()
{
    setIsLoading(true);
    
    qDebug() << "Cargando reporte:" << m_periodType << "desde" << m_startDate << "hasta" << m_endDate;
    
    calculateSummary();
    loadSalesHistory();
    
    setIsLoading(false);
    
    emit reportGenerated("Reporte generado exitosamente");
}

void ReportsViewModel::exportToPdf(const QString& filePath)
{
    // TODO: Implementar exportación a PDF usando PdfGeneratorService
    qDebug() << "Exportando reporte a PDF:" << filePath;
    emit reportGenerated("Funcionalidad de exportación próximamente");
}

QVariantList ReportsViewModel::getChartData()
{
    QVariantList chartData;
    
    SaleRepository repo;
    auto dailySales = repo.getDailySalesInRange(m_startDate, m_endDate);
    
    for (const auto& daily : dailySales) {
        QVariantMap dataPoint;
        dataPoint["date"] = daily.date.toString("dd/MM");
        dataPoint["sales"] = daily.totalSales;
        dataPoint["transactions"] = daily.transactionCount;
        chartData.append(dataPoint);
    }
    
    return chartData;
}

void ReportsViewModel::setIsLoading(bool loading)
{
    if (m_isLoading != loading) {
        m_isLoading = loading;
        emit isLoadingChanged();
    }
}

void ReportsViewModel::calculateSummary()
{
    SaleRepository repo;
    auto stats = repo.getStatsForDateRange(m_startDate, m_endDate);
    
    m_summary.clear();
    m_summary["totalSales"] = stats.totalSales;
    m_summary["totalTransactions"] = stats.totalTransactions;
    m_summary["averageTicket"] = stats.averageTicket;
    
    // Obtener productos más vendidos
    auto topProducts = repo.getTopProducts(m_startDate, m_endDate, 5);
    QVariantList topProductsList;
    for (const auto& product : topProducts) {
        QVariantMap productMap;
        productMap["productId"] = product.productId;
        productMap["productName"] = product.productName;
        productMap["quantitySold"] = product.quantitySold;
        productMap["totalRevenue"] = product.totalRevenue;
        topProductsList.append(productMap);
    }
    m_summary["topProducts"] = topProductsList;
    
    // Calcular comparación con período anterior (opcional)
    QDate previousStart, previousEnd;
    int days = m_startDate.daysTo(m_endDate) + 1;
    previousStart = m_startDate.addDays(-days);
    previousEnd = m_endDate.addDays(-days);
    
    auto previousStats = repo.getStatsForDateRange(previousStart, previousEnd);
    
    double salesGrowth = 0.0;
    if (previousStats.totalSales > 0) {
        salesGrowth = ((stats.totalSales - previousStats.totalSales) / previousStats.totalSales) * 100.0;
    }
    m_summary["salesGrowth"] = salesGrowth;
    m_summary["previousSales"] = previousStats.totalSales;
    
    emit summaryChanged();
}

void ReportsViewModel::loadSalesHistory()
{
    SaleRepository repo;
    auto sales = repo.findByDateRange(m_startDate, m_endDate);
    
    m_salesHistory.clear();
    
    for (const auto& sale : sales) {
        QVariantMap saleMap;
        saleMap["id"] = sale.id;
        saleMap["invoiceNumber"] = sale.invoiceNumber;
        saleMap["customerName"] = sale.customerName.isEmpty() ? "Cliente General" : sale.customerName;
        saleMap["total"] = sale.total;
        saleMap["paymentMethod"] = sale.paymentMethodName;
        saleMap["status"] = sale.status;
        saleMap["date"] = sale.createdAt.toString("dd/MM/yyyy hh:mm");
        saleMap["itemCount"] = sale.items.count();
        
        m_salesHistory.append(saleMap);
    }
    
    emit salesHistoryChanged();
}
