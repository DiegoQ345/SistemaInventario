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
    
    // Propiedades de vendedor/cajero
    Q_PROPERTY(QString currentCashier READ currentCashier WRITE setCurrentCashier NOTIFY currentCashierChanged)
    Q_PROPERTY(QStringList availableCashiers READ availableCashiers NOTIFY availableCashiersChanged)
    Q_PROPERTY(int todayTransactionsByCashier READ todayTransactionsByCashier NOTIFY todayTransactionsByCashierChanged)
    Q_PROPERTY(double todaySalesByCashier READ todaySalesByCashier NOTIFY todaySalesByCashierChanged)

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
    
    // Getters para cajero
    QString currentCashier() const { return m_currentCashier; }
    QStringList availableCashiers() const { return m_availableCashiers; }
    int todayTransactionsByCashier() const { return m_todayTransactionsByCashier; }
    double todaySalesByCashier() const { return m_todaySalesByCashier; }
    
    // Setters
    void setCurrentCashier(const QString& cashier);

public slots:
    /**
     * @brief Refrescar estadísticas del dashboard
     */
    void refresh();
    
    /**
     * @brief Realizar cierre de día y obtener reporte
     * @return JSON con reporte de cierre (ventas totales, por cajero, productos más vendidos)
     */
    Q_INVOKABLE QString closeDayShift();
    
    /**
     * @brief Obtener reporte del día actual sin cerrar
     * @return JSON con estadísticas actuales del día
     */
    Q_INVOKABLE QString getDailyReport();
    
    /**
     * @brief Generar PDF del reporte del día actual
     */
    Q_INVOKABLE void generateDailyReportPDF();
    
    /**
     * @brief Obtener ventas por tipo de comprobante (hoy)
     * @return QVariantList con {label, value, count} para cada tipo
     */
    Q_INVOKABLE QVariantList getSalesByVoucherType();
    
    /**
     * @brief Obtener top productos más vendidos (hoy)
     * @param limit Cantidad máxima de productos
     * @return QVariantList con {name, quantity, revenue} para cada producto
     */
    Q_INVOKABLE QVariantList getTopProducts(int limit = 5);
    
    /**
     * @brief Obtener clientes frecuentes (este mes)
     * @param limit Cantidad máxima de clientes
     * @return QVariantList con {name, purchases, totalSpent} para cada cliente
     */
    Q_INVOKABLE QVariantList getTopCustomers(int limit = 5);

signals:
    void todaySalesChanged();
    void todayTransactionsChanged();
    void monthSalesChanged();
    void averageTicketChanged();
    void lowStockProductsChanged();
    void totalProductsChanged();
    void isLoadingChanged();
    
    // Signals para cajero
    void currentCashierChanged();
    void availableCashiersChanged();
    void todayTransactionsByCashierChanged();
    void todaySalesByCashierChanged();
    void dayClosingCompleted(const QString& report);

private:
    double m_todaySales = 0.0;
    int m_todayTransactions = 0;
    double m_monthSales = 0.0;
    double m_averageTicket = 0.0;
    int m_lowStockProducts = 0;
    int m_totalProducts = 0;
    bool m_isLoading = false;
    
    // Cajero/vendedor
    QString m_currentCashier;
    QStringList m_availableCashiers;
    int m_todayTransactionsByCashier = 0;
    double m_todaySalesByCashier = 0.0;

    void setIsLoading(bool loading);
    void loadCashierStats();
    void loadAvailableCashiers();
};

#endif // DASHBOARDVIEWMODEL_H
