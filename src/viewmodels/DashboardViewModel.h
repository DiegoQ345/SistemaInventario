#ifndef DASHBOARDVIEWMODEL_H
#define DASHBOARDVIEWMODEL_H

#include <QObject>
#include <qqml.h>

/**
 * @brief ViewModel para el Dashboard principal
 * 
 * Expone datos y operaciones del dashboard a QML.
 * Implementa patrón MVVM: Model-View-ViewModel
 */
class DashboardViewModel : public QObject
{
    Q_OBJECT
    // QML_ELEMENT - Registrado manualmente en main.cpp

    // Propiedades observables para QML
    Q_PROPERTY(double todaySales READ todaySales NOTIFY todaySalesChanged)
    Q_PROPERTY(int todayTransactions READ todayTransactions NOTIFY todayTransactionsChanged)
    Q_PROPERTY(double monthSales READ monthSales NOTIFY monthSalesChanged)
    Q_PROPERTY(double averageTicket READ averageTicket NOTIFY averageTicketChanged)
    Q_PROPERTY(int lowStockProducts READ lowStockProducts NOTIFY lowStockProductsChanged)
    Q_PROPERTY(int totalProducts READ totalProducts NOTIFY totalProductsChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit DashboardViewModel(QObject *parent = nullptr);

    // Getters para propiedades
    double todaySales() const { return m_todaySales; }
    int todayTransactions() const { return m_todayTransactions; }
    double monthSales() const { return m_monthSales; }
    double averageTicket() const { return m_averageTicket; }
    int lowStockProducts() const { return m_lowStockProducts; }
    int totalProducts() const { return m_totalProducts; }
    bool isLoading() const { return m_isLoading; }

public slots:
    /**
     * @brief Refrescar estadísticas del dashboard
     */
    void refresh();

signals:
    void todaySalesChanged();
    void todayTransactionsChanged();
    void monthSalesChanged();
    void averageTicketChanged();
    void lowStockProductsChanged();
    void totalProductsChanged();
    void isLoadingChanged();

private:
    double m_todaySales = 0.0;
    int m_todayTransactions = 0;
    double m_monthSales = 0.0;
    double m_averageTicket = 0.0;
    int m_lowStockProducts = 0;
    int m_totalProducts = 0;
    bool m_isLoading = false;

    void setIsLoading(bool loading);
};

#endif // DASHBOARDVIEWMODEL_H
