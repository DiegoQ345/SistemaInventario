#ifndef SALEREPOSITORY_H
#define SALEREPOSITORY_H

#include "../models/Sale.h"
#include <QList>
#include <QDate>
#include <optional>

/**
 * @brief Repositorio para gestión de ventas
 */
class SaleRepository
{
public:
    SaleRepository() = default;

    /**
     * @brief Crear nueva venta con sus items
     * @return ID de la venta creada, o 0 si falla
     */
    int create(Sale& sale);

    /**
     * @brief Buscar venta por ID (incluye items)
     */
    std::optional<Sale> findById(int id);

    /**
     * @brief Buscar venta por número de factura
     */
    std::optional<Sale> findByInvoiceNumber(const QString& invoiceNumber);

    /**
     * @brief Obtener ventas por rango de fechas
     */
    QList<Sale> findByDateRange(const QDate& from, const QDate& to);

    /**
     * @brief Obtener ventas del día
     */
    QList<Sale> findToday();

    /**
     * @brief Cancelar venta (cambia estado a CANCELLED)
     */
    bool cancel(int saleId);

    /**
     * @brief Generar siguiente número de factura
     */
    QString generateNextInvoiceNumber();

    /**
     * @brief Estadísticas de ventas
     */
    struct SalesStats {
        double totalSales = 0.0;
        int totalTransactions = 0;
        double averageTicket = 0.0;
    };

    SalesStats getStatsForDate(const QDate& date);
    SalesStats getStatsForDateRange(const QDate& from, const QDate& to);

    /**
     * @brief Obtener ventas agrupadas por día en un rango
     */
    struct DailySales {
        QDate date;
        double totalSales = 0.0;
        int transactionCount = 0;
    };
    QList<DailySales> getDailySalesInRange(const QDate& from, const QDate& to);

    /**
     * @brief Obtener productos más vendidos en un rango de fechas
     */
    struct TopProduct {
        int productId = 0;
        QString productName;
        double quantitySold = 0.0;
        double totalRevenue = 0.0;
    };
    QList<TopProduct> getTopProducts(const QDate& from, const QDate& to, int limit = 10);

private:
    Sale mapFromQuery(const class QSqlQuery& query);
    QList<SaleItem> loadSaleItems(int saleId);
};

#endif // SALEREPOSITORY_H
