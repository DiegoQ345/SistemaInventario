#include "SalesService.h"
#include "ProductService.h"
#include "../database/DatabaseManager.h"
#include <QDebug>

SalesService::SalesService(QObject *parent)
    : QObject(parent)
{
}

bool SalesService::createSale(Sale& sale, QString& errorMessage)
{
    qDebug() << "=== SalesService::createSale ===";
    
    // Validar venta
    if (!validateSale(sale, errorMessage)) {
        qWarning() << "  Validation failed:" << errorMessage;
        return false;
    }
    
    qDebug() << "  Sale validated successfully";

    // Generar número de factura si no se proporcionó
    if (sale.invoiceNumber.isEmpty()) {
        sale.invoiceNumber = m_saleRepo.generateNextInvoiceNumber();
        qDebug() << "  Generated invoice number:" << sale.invoiceNumber;
    }

    // Calcular totales
    sale.calculateTotals();
    qDebug() << "  Totals calculated - Total:" << sale.total;

    // Iniciar transacción
    if (!DatabaseManager::instance().beginTransaction()) {
        errorMessage = "Error iniciando transacción";
        qCritical() << "  " << errorMessage;
        return false;
    }
    
    qDebug() << "  Transaction started";

    // Actualizar stock de productos
    if (!updateStockForSale(sale, errorMessage)) {
        qCritical() << "  Stock update failed:" << errorMessage;
        DatabaseManager::instance().rollback();
        return false;
    }
    
    qDebug() << "  Stock updated successfully";

    // Crear venta
    int saleId = m_saleRepo.create(sale);
    if (saleId == 0) {
        DatabaseManager::instance().rollback();
        errorMessage = "Error guardando la venta";
        qCritical() << "  " << errorMessage;
        return false;
    }
    
    qDebug() << "  Sale saved with ID:" << saleId;

    // Confirmar transacción
    if (!DatabaseManager::instance().commit()) {
        DatabaseManager::instance().rollback();
        errorMessage = "Error confirmando la venta";
        qCritical() << "  " << errorMessage;
        return false;
    }
    
    qDebug() << "  Transaction committed successfully";

    emit saleCompleted(saleId, sale.invoiceNumber);
    return true;
}

bool SalesService::cancelSale(int saleId, QString& errorMessage)
{
    // Obtener venta
    auto sale = m_saleRepo.findById(saleId);
    if (!sale) {
        errorMessage = "Venta no encontrada";
        return false;
    }

    if (sale->status == "CANCELLED") {
        errorMessage = "La venta ya está cancelada";
        return false;
    }

    // Iniciar transacción
    if (!DatabaseManager::instance().beginTransaction()) {
        errorMessage = "Error iniciando transacción";
        return false;
    }

    // Revertir stock
    if (!revertStockForSale(*sale, errorMessage)) {
        DatabaseManager::instance().rollback();
        return false;
    }

    // Marcar venta como cancelada
    if (!m_saleRepo.cancel(saleId)) {
        DatabaseManager::instance().rollback();
        errorMessage = "Error cancelando la venta";
        return false;
    }

    // Confirmar transacción
    if (!DatabaseManager::instance().commit()) {
        DatabaseManager::instance().rollback();
        errorMessage = "Error confirmando la cancelación";
        return false;
    }

    emit saleCancelled(saleId);
    return true;
}

std::optional<Sale> SalesService::getSale(int saleId)
{
    return m_saleRepo.findById(saleId);
}

std::optional<Sale> SalesService::getSaleByInvoice(const QString& invoiceNumber)
{
    return m_saleRepo.findByInvoiceNumber(invoiceNumber);
}

QList<Sale> SalesService::getSalesByDateRange(const QDate& from, const QDate& to)
{
    return m_saleRepo.findByDateRange(from, to);
}

QList<Sale> SalesService::getTodaySales()
{
    return m_saleRepo.findToday();
}

SalesService::DashboardStats SalesService::getDashboardStats()
{
    DashboardStats stats;

    // Estadísticas del día
    auto todayStats = m_saleRepo.getStatsForDate(QDate::currentDate());
    stats.todaySales = todayStats.totalSales;
    stats.todayTransactions = todayStats.totalTransactions;

    // Estadísticas del mes
    QDate firstDayOfMonth(QDate::currentDate().year(), QDate::currentDate().month(), 1);
    QDate today = QDate::currentDate();
    auto monthStats = m_saleRepo.getStatsForDateRange(firstDayOfMonth, today);
    stats.monthSales = monthStats.totalSales;
    
    if (monthStats.totalTransactions > 0) {
        stats.averageTicket = monthStats.totalSales / monthStats.totalTransactions;
    }

    // Productos con stock bajo
    ProductService productService;
    stats.lowStockProducts = productService.getLowStockProducts().size();
    stats.totalProducts = productService.getAllProducts(true).size();

    return stats;
}

bool SalesService::validateSale(const Sale& sale, QString& errorMessage)
{
    if (sale.items.isEmpty()) {
        errorMessage = "La venta debe tener al menos un item";
        return false;
    }

    if (sale.total <= 0) {
        errorMessage = "El total de la venta debe ser mayor a cero";
        return false;
    }

    // Validar cada item
    for (const auto& item : sale.items) {
        if (item.quantity <= 0) {
            errorMessage = QString("Cantidad inválida para producto: %1").arg(item.productName);
            return false;
        }

        if (item.unitPrice < 0) {
            errorMessage = QString("Precio inválido para producto: %1").arg(item.productName);
            return false;
        }
    }

    return true;
}

bool SalesService::updateStockForSale(const Sale& sale, QString& errorMessage)
{
    ProductService productService;

    for (const auto& item : sale.items) {
        // Registrar salida de stock
        QString error;
        if (!productService.registerStockMovement(
                item.productId,
                "VENTA",
                item.quantity,
                item.unitPrice,
                sale.invoiceNumber,
                QString("Venta #%1").arg(sale.invoiceNumber),
                error)) {
            errorMessage = QString("Error actualizando stock de '%1': %2")
                              .arg(item.productName, error);
            return false;
        }
    }

    return true;
}

bool SalesService::revertStockForSale(const Sale& sale, QString& errorMessage)
{
    ProductService productService;

    for (const auto& item : sale.items) {
        // Registrar devolución (entrada de stock)
        QString error;
        if (!productService.registerStockMovement(
                item.productId,
                "DEVOLUCION_VENTA",
                item.quantity,
                item.unitPrice,
                sale.invoiceNumber,
                QString("Cancelación venta #%1").arg(sale.invoiceNumber),
                error)) {
            errorMessage = QString("Error revirtiendo stock de '%1': %2")
                              .arg(item.productName, error);
            return false;
        }
    }

    return true;
}
