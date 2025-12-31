#include "DashboardViewModel.h"
#include "../services/SalesService.h"
#include <QDebug>

DashboardViewModel::DashboardViewModel(QObject *parent)
    : QObject(parent)
{
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

    setIsLoading(false);
}

void DashboardViewModel::setIsLoading(bool loading)
{
    if (m_isLoading != loading) {
        m_isLoading = loading;
        emit isLoadingChanged();
    }
}
