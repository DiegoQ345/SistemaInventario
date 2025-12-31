#ifndef SALESSERVICE_H
#define SALESSERVICE_H

#include "../models/Sale.h"
#include "../repositories/SaleRepository.h"
#include <QObject>
#include <QList>
#include <QDate>

/**
 * @brief Servicio de negocio para gestión de ventas
 * 
 * Coordina la creación de ventas, actualización de stock,
 * y generación de comprobantes.
 */
class SalesService : public QObject
{
    Q_OBJECT

public:
    explicit SalesService(QObject *parent = nullptr);

    /**
     * @brief Crear nueva venta
     * 
     * Este método:
     * 1. Valida la venta y items
     * 2. Genera número de factura
     * 3. Crea la venta en la BD
     * 4. Actualiza stock de productos
     * 5. Registra movimientos de stock
     */
    bool createSale(Sale& sale, QString& errorMessage);

    /**
     * @brief Cancelar venta (revertir stock)
     */
    bool cancelSale(int saleId, QString& errorMessage);

    /**
     * @brief Obtener venta por ID
     */
    std::optional<Sale> getSale(int saleId);

    /**
     * @brief Obtener venta por número de factura
     */
    std::optional<Sale> getSaleByInvoice(const QString& invoiceNumber);

    /**
     * @brief Obtener ventas por rango de fechas
     */
    QList<Sale> getSalesByDateRange(const QDate& from, const QDate& to);

    /**
     * @brief Obtener ventas del día
     */
    QList<Sale> getTodaySales();

    /**
     * @brief Obtener estadísticas de ventas
     */
    struct DashboardStats {
        double todaySales = 0.0;
        int todayTransactions = 0;
        double monthSales = 0.0;
        double averageTicket = 0.0;
        int lowStockProducts = 0;
        int totalProducts = 0;
    };

    DashboardStats getDashboardStats();

signals:
    /**
     * @brief Emitido cuando se completa una venta
     */
    void saleCompleted(int saleId, const QString& invoiceNumber);

    /**
     * @brief Emitido cuando se cancela una venta
     */
    void saleCancelled(int saleId);

private:
    SaleRepository m_saleRepo;

    /**
     * @brief Validar venta antes de guardar
     */
    bool validateSale(const Sale& sale, QString& errorMessage);

    /**
     * @brief Actualizar stock de productos vendidos
     */
    bool updateStockForSale(const Sale& sale, QString& errorMessage);

    /**
     * @brief Revertir stock al cancelar venta
     */
    bool revertStockForSale(const Sale& sale, QString& errorMessage);
};

#endif // SALESSERVICE_H
