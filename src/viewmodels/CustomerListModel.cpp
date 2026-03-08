#include "CustomerListModel.h"
#include "../repositories/CustomerRepository.h"
#include "../repositories/SaleRepository.h"
#include "../services/PdfGeneratorService.h"
#include "../database/DatabaseManager.h"
#include <QDebug>
#include <QSettings>

CustomerListModel::CustomerListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_repository = new CustomerRepository(DatabaseManager::instance().database(), this);
    refresh();
}

CustomerListModel::~CustomerListModel()
{
    // m_repository se elimina automáticamente por QObject parent
}

int CustomerListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_customers.size();
}

QVariant CustomerListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_customers.size())
        return QVariant();

    const Customer& customer = m_customers[index.row()];

    switch (role) {
    case IdRole:
        return customer.id;
    case NameRole:
        return customer.name;
    case DocumentTypeRole:
        return customer.documentType;
    case DocumentNumberRole:
        return customer.documentNumber;
    case EmailRole:
        return customer.email;
    case PhoneRole:
        return customer.phone;
    case AddressRole:
        return customer.address;
    case DisplayNameRole:
        return customer.displayName();
    case TotalPurchasesRole:
        return customer.totalPurchases;
    case TotalSpentRole:
        return customer.totalSpent;
    case LastPurchaseDateRole:
        return customer.lastPurchaseDate;
    case DisplayNameWithStatsRole:
        return customer.displayNameWithStats();
    case CreditLimitRole:
        return customer.creditLimit;
    case CurrentDebtRole:
        return customer.currentDebt;
    case AvailableCreditRole:
        return customer.availableCredit();
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> CustomerListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "customerId";
    roles[NameRole] = "customerName";
    roles[DocumentTypeRole] = "documentType";
    roles[DocumentNumberRole] = "documentNumber";
    roles[EmailRole] = "email";
    roles[PhoneRole] = "phone";
    roles[AddressRole] = "address";
    roles[DisplayNameRole] = "displayName";
    roles[TotalPurchasesRole] = "totalPurchases";
    roles[TotalSpentRole] = "totalSpent";
    roles[LastPurchaseDateRole] = "lastPurchaseDate";
    roles[DisplayNameWithStatsRole] = "displayNameWithStats";
    roles[CreditLimitRole] = "creditLimit";
    roles[CurrentDebtRole] = "currentDebt";
    roles[AvailableCreditRole] = "availableCredit";
    return roles;
}

void CustomerListModel::refresh()
{
    setCustomers(m_repository->findAll());
}

void CustomerListModel::search(const QString& searchTerm)
{
    if (searchTerm.trimmed().isEmpty()) {
        refresh();
    } else {
        setCustomers(m_repository->search(searchTerm));
    }
}

QVariantMap CustomerListModel::get(int index) const
{
    QVariantMap map;
    if (index < 0 || index >= m_customers.size())
        return map;

    const Customer& customer = m_customers[index];
    map["customerId"] = customer.id;
    map["customerName"] = customer.name;
    map["documentType"] = customer.documentType;
    map["documentNumber"] = customer.documentNumber;
    map["email"] = customer.email;
    map["phone"] = customer.phone;
    map["address"] = customer.address;
    map["totalPurchases"] = customer.totalPurchases;
    map["totalSpent"] = customer.totalSpent;
    map["lastPurchaseDate"] = customer.lastPurchaseDate;
    map["displayName"] = customer.displayName();
    map["displayNameWithStats"] = customer.displayNameWithStats();

    return map;
}

bool CustomerListModel::remove(int customerId)
{
    if (m_repository->deleteById(customerId)) {
        refresh();
        return true;
    }
    
    emit errorOccurred(m_repository->lastError());
    return false;
}

bool CustomerListModel::generatePurchaseHistoryPdf(int customerId, const QString& outputPath)
{
    // Obtener datos del cliente
    auto customerOpt = m_repository->findById(customerId);
    if (!customerOpt) {
        emit errorOccurred("Cliente no encontrado");
        return false;
    }
    
    Customer customer = *customerOpt;
    
    // Obtener ventas del cliente
    SaleRepository saleRepo;
    QList<Sale> sales = saleRepo.findByCustomerId(customerId);
    
    if (sales.isEmpty()) {
        emit errorOccurred("El cliente no tiene historial de compras");
        return false;
    }
    
    // Generar PDF
    PdfGeneratorService pdfService;
    PdfGeneratorService::BusinessInfo businessInfo;
    
    // Cargar información del negocio desde configuración
    QSettings settings;
    businessInfo.name = settings.value("businessName", "Mi Negocio").toString();
    businessInfo.taxId = settings.value("businessRuc", "").toString();
    businessInfo.address = settings.value("businessAddress", "Dirección del negocio").toString();
    businessInfo.phone = settings.value("businessPhone", "(000) 000-0000").toString();
    businessInfo.email = settings.value("businessEmail", "").toString();
    
    pdfService.setBusinessInfo(businessInfo);
    
    if (!pdfService.generateCustomerPurchaseHistory(customer, sales, outputPath)) {
        emit errorOccurred("Error al generar el PDF");
        return false;
    }
    
    qDebug() << "PDF de historial generado exitosamente:" << outputPath;
    return true;
}

QVariantList CustomerListModel::getCustomerSales(int customerId, const QDate& fromDate, const QDate& toDate)
{
    QVariantList result;
    
    // Obtener ventas del cliente
    SaleRepository saleRepo;
    QList<Sale> sales = saleRepo.findByCustomerId(customerId);
    
    // Filtrar por fecha si se proporcionan
    bool hasFromDate = fromDate.isValid();
    bool hasToDate = toDate.isValid();
    
    for (const Sale& sale : sales) {
        // Aplicar filtros de fecha
        QDate saleDate = sale.createdAt.date();
        if (hasFromDate && saleDate < fromDate) {
            continue;
        }
        if (hasToDate && saleDate > toDate) {
            continue;
        }
        
        // Crear mapa con los datos de la venta
        QVariantMap saleMap;
        saleMap["saleId"] = sale.id;
        saleMap["invoiceNumber"] = sale.invoiceNumber;
        saleMap["saleDate"] = saleDate.toString("dd/MM/yyyy");
        saleMap["saleDateRaw"] = saleDate;
        saleMap["total"] = sale.total;
        saleMap["discount"] = sale.discount;
        saleMap["paymentMethod"] = sale.paymentMethodName;
        saleMap["paymentType"] = sale.paymentType;
        saleMap["paymentStatus"] = sale.paymentStatus;
        saleMap["itemCount"] = sale.items.size();
        
        // Calcular total de items
        double totalItems = 0;
        for (const SaleItem& item : sale.items) {
            totalItems += item.quantity;
        }
        saleMap["totalItems"] = totalItems;
        
        result.append(saleMap);
    }
    
    return result;
}

int CustomerListModel::payCustomerDebts(int customerId)
{
    qDebug() << "[CustomerListModel] Pagando deudas del cliente ID:" << customerId;
    
    SaleRepository saleRepo;
    int updatedCount = saleRepo.markCustomerDebtsAsPaid(customerId);
    
    qDebug() << "[CustomerListModel] Ventas actualizadas:" << updatedCount;
    
    if (updatedCount > 0) {
        qDebug() << "[CustomerListModel] Refrescando lista de clientes...";
        // Refrescar la lista de clientes para actualizar la deuda actual
        refresh();
        qDebug() << "[CustomerListModel] Lista de clientes actualizada";
    } else {
        qDebug() << "[CustomerListModel] No se encontraron ventas pendientes para actualizar";
    }
    
    return updatedCount;
}

void CustomerListModel::setCustomers(const QList<Customer>& customers)
{
    beginResetModel();
    m_customers = customers;
    endResetModel();
    emit countChanged();
}
