#include "CustomerListModel.h"
#include "../repositories/CustomerRepository.h"
#include "../repositories/SaleRepository.h"
#include "../services/PdfGeneratorService.h"
#include "../database/DatabaseManager.h"
#include "../models/Sale.h"
#include <QDebug>
#include <QSettings>
#include <QDir>
#include <QFileInfo>
#include <QDate>
#include <QRegularExpression>
#include <QDesktopServices>
#include <QUrl>
#include <QDateTime>
#include "xlsxdocument.h"
#include "xlsxformat.h"

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
    // Obtener datos del cliente primero
    auto customerOpt = m_repository->findById(customerId);
    if (!customerOpt) {
        emit errorOccurred("Cliente no encontrado");
        return false;
    }
    
    Customer customer = *customerOpt;
    
    // Cargar información del negocio desde configuración
    QSettings settings;
    QString businessName = settings.value("businessName", "Mi_Negocio").toString();
    
    // Sanitizar nombre del negocio para nombre de carpeta
    QString sanitizedBusinessName = businessName;
    sanitizedBusinessName.replace(QRegularExpression("[^a-zA-Z0-9_]"), "_");
    sanitizedBusinessName.replace(QRegularExpression("_+"), "_");
    
    // Sanitizar nombre del cliente para nombre de archivo
    QString sanitizedCustomerName = customer.name;
    sanitizedCustomerName.replace(QRegularExpression("[^a-zA-Z0-9_]"), "_");
    sanitizedCustomerName.replace(QRegularExpression("_+"), "_");
    
    // Construir estructura de carpetas: Reportes_{NombreNegocio}/Reportes_Clientes/
    QString baseDir = "C:/Reportes_" + sanitizedBusinessName;
    QString reportsDir = baseDir + "/Reportes_Clientes";
    
    // Crear directorios si no existen
    QDir dir;
    if (!dir.exists(reportsDir)) {
        qDebug() << "Creando estructura de directorios:" << reportsDir;
        if (!dir.mkpath(reportsDir)) {
            qCritical() << "Error al crear directorio de reportes:" << reportsDir;
            emit errorOccurred("Error al crear directorio de reportes");
            return false;
        }
    }
    
    // Generar nombre de archivo: NombreCliente_FECHA.pdf
    QString dateStr = QDate::currentDate().toString("yyyy-MM-dd");
    QString fileName = sanitizedCustomerName + "_" + dateStr + ".pdf";
    QString finalPath = reportsDir + "/" + fileName;
    
    qDebug() << "Generando PDF en:" << finalPath;
    
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
    
    businessInfo.name = settings.value("businessName", "Mi Negocio").toString();
    businessInfo.taxId = settings.value("businessRuc", "").toString();
    businessInfo.address = settings.value("businessAddress", "Dirección del negocio").toString();
    businessInfo.phone = settings.value("businessPhone", "(000) 000-0000").toString();
    businessInfo.email = settings.value("businessEmail", "").toString();
    
    pdfService.setBusinessInfo(businessInfo);
    
    if (!pdfService.generateCustomerPurchaseHistory(customer, sales, finalPath)) {
        emit errorOccurred("Error al generar el PDF");
        return false;
    }
    
    qDebug() << "PDF de historial generado exitosamente:" << finalPath;
    
    // Abrir el PDF automáticamente
    QDesktopServices::openUrl(QUrl::fromLocalFile(finalPath));
    
    return true;
}

bool CustomerListModel::generateCustomerReport(int customerId, const QString& format, const QString& reportType)
{
    qDebug() << "Generando reporte - Cliente:" << customerId << "Formato:" << format << "Tipo:" << reportType;
    
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
    
    // Filtrar ventas según el tipo de reporte
    QList<Sale> filteredSales;
    if (reportType == "deudas") {
        // Solo ventas pendientes o parciales
        for (const Sale& sale : sales) {
            if (sale.paymentStatus == "PENDING" || sale.paymentStatus == "PARTIAL") {
                filteredSales.append(sale);
            }
        }
        
        if (filteredSales.isEmpty()) {
            emit errorOccurred("El cliente no tiene deudas pendientes");
            return false;
        }
    } else {
        // Todas las ventas
        filteredSales = sales;
    }
    
    // Cargar información del negocio
    QSettings settings;
    QString businessName = settings.value("businessName", "Mi_Negocio").toString();
    
    // Sanitizar nombres
    QString sanitizedBusinessName = businessName;
    sanitizedBusinessName.replace(QRegularExpression("[^a-zA-Z0-9_]"), "_");
    sanitizedBusinessName.replace(QRegularExpression("_+"), "_");
    
    QString sanitizedCustomerName = customer.name;
    sanitizedCustomerName.replace(QRegularExpression("[^a-zA-Z0-9_]"), "_");
    sanitizedCustomerName.replace(QRegularExpression("_+"), "_");
    
    // Construir estructura de carpetas
    QString baseDir = "C:/Reportes_" + sanitizedBusinessName;
    QString reportsDir = baseDir + "/Reportes_Clientes";
    
    // Crear directorios si no existen
    QDir dir;
    if (!dir.exists(reportsDir)) {
        if (!dir.mkpath(reportsDir)) {
            emit errorOccurred("Error al crear directorio de reportes");
            return false;
        }
    }
    
    // Generar nombre de archivo
    QString dateStr = QDate::currentDate().toString("yyyy-MM-dd");
    QString reportTypeSuffix = (reportType == "deudas") ? "_Deudas" : "_Completo";
    QString extension = (format == "excel") ? ".xlsx" : ".pdf";
    QString fileName = sanitizedCustomerName + reportTypeSuffix + "_" + dateStr + extension;
    QString finalPath = reportsDir + "/" + fileName;
    
    qDebug() << "Generando reporte en:" << finalPath;
    
    bool success = false;
    
    if (format == "pdf") {
        // Generar PDF
        PdfGeneratorService pdfService;
        PdfGeneratorService::BusinessInfo businessInfo;
        
        businessInfo.name = settings.value("businessName", "Mi Negocio").toString();
        businessInfo.taxId = settings.value("businessRuc", "").toString();
        businessInfo.address = settings.value("businessAddress", "Dirección del negocio").toString();
        businessInfo.phone = settings.value("businessPhone", "(000) 000-0000").toString();
        businessInfo.email = settings.value("businessEmail", "").toString();
        
        pdfService.setBusinessInfo(businessInfo);
        
        success = pdfService.generateCustomerPurchaseHistory(customer, filteredSales, finalPath);
        
    } else if (format == "excel") {
        // Generar Excel
        success = generateExcelReport(customer, filteredSales, finalPath, reportType);
    }
    
    if (!success) {
        emit errorOccurred("Error al generar el reporte");
        return false;
    }
    
    qDebug() << "Reporte generado exitosamente:" << finalPath;
    
    // Abrir el archivo automáticamente
    QDesktopServices::openUrl(QUrl::fromLocalFile(finalPath));
    
    return true;
}

bool CustomerListModel::generateExcelReport(const Customer& customer, const QList<Sale>& sales, 
                                            const QString& outputPath, const QString& reportType)
{
    using namespace QXlsx;
    
    // Cargar configuración del negocio
    QSettings settings;
    
    QXlsx::Document xlsx;
    
    // Configurar formatos
    Format headerFormat;
    headerFormat.setFontBold(true);
    headerFormat.setFontSize(12);
    headerFormat.setFontColor(Qt::white);
    headerFormat.setPatternBackgroundColor(QColor(25, 118, 210));
    headerFormat.setHorizontalAlignment(Format::AlignHCenter);
    headerFormat.setVerticalAlignment(Format::AlignVCenter);
    
    Format titleFormat;
    titleFormat.setFontBold(true);
    titleFormat.setFontSize(14);
    titleFormat.setFontColor(QColor(33, 150, 243));
    
    Format subtitleFormat;
    subtitleFormat.setFontBold(true);
    subtitleFormat.setFontSize(11);
    
    Format moneyFormat;
    moneyFormat.setNumberFormat("S/ #,##0.00");
    
    Format dateFormat;
    dateFormat.setNumberFormat("dd/mm/yyyy");
    
    // Título del reporte
    int row = 1;
    xlsx.write(row, 1, settings.value("businessName", "Mi Negocio").toString(), titleFormat);
    row++;
    
    QString reportTitle = (reportType == "deudas") ? 
        "Reporte de Deudas Pendientes" : "Historial Completo de Compras";
    xlsx.write(row, 1, reportTitle, subtitleFormat);
    row += 2;
    
    // Información del cliente
    xlsx.write(row, 1, "Cliente:", subtitleFormat);
    xlsx.write(row, 2, customer.name);
    row++;
    xlsx.write(row, 1, "Documento:", subtitleFormat);
    xlsx.write(row, 2, customer.documentType + " " + customer.documentNumber);
    row++;
    if (!customer.phone.isEmpty()) {
        xlsx.write(row, 1, "Teléfono:", subtitleFormat);
        xlsx.write(row, 2, customer.phone);
        row++;
    }
    if (!customer.email.isEmpty()) {
        xlsx.write(row, 1, "Email:", subtitleFormat);
        xlsx.write(row, 2, customer.email);
        row++;
    }
    row++;
    
    // Fecha de generación
    xlsx.write(row, 1, "Fecha de generación:", subtitleFormat);
    xlsx.write(row, 2, QDateTime::currentDateTime().toString("dd/MM/yyyy hh:mm"));
    row += 2;
    
    // Encabezados de tabla
    xlsx.write(row, 1, "Fecha", headerFormat);
    xlsx.write(row, 2, "Factura", headerFormat);
    xlsx.write(row, 3, "Tipo", headerFormat);
    xlsx.write(row, 4, "Items", headerFormat);
    xlsx.write(row, 5, "Productos", headerFormat);
    xlsx.write(row, 6, "Pago", headerFormat);
    xlsx.write(row, 7, "Estado", headerFormat);
    xlsx.write(row, 8, "Total", headerFormat);
    row++;
    
    // Datos de ventas
    double totalGeneral = 0.0;
    double totalPendiente = 0.0;
    
    Format detailFormat;
    detailFormat.setFontSize(9);
    detailFormat.setFontColor(QColor(85, 85, 85));
    detailFormat.setVerticalAlignment(Format::AlignTop);
    
    for (const Sale& sale : sales) {
        int startRow = row;
        
        xlsx.write(row, 1, sale.createdAt.toString("dd/MM/yyyy"));
        xlsx.write(row, 2, sale.invoiceNumber);
        xlsx.write(row, 3, sale.voucherType.isEmpty() ? "TICKET" : sale.voucherType);
        xlsx.write(row, 4, sale.storedItemCount > 0 ? sale.storedItemCount : sale.items.size());
        xlsx.write(row, 5, sale.productNames.isEmpty() ? 
            QString("%1 productos").arg(sale.items.size()) : sale.productNames);
        xlsx.write(row, 6, sale.paymentType.isEmpty() ? "CONTADO" : sale.paymentType);
        
        QString paymentStatus = sale.paymentStatus.isEmpty() ? "PAID" : sale.paymentStatus;
        QString statusDisplay;
        if (paymentStatus == "PENDING") {
            statusDisplay = "Pendiente";
            totalPendiente += sale.total;
        } else if (paymentStatus == "PARTIAL") {
            statusDisplay = "Parcial";
            totalPendiente += sale.total;
        } else {
            statusDisplay = "Pagado";
        }
        xlsx.write(row, 7, statusDisplay);
        xlsx.write(row, 8, sale.total, moneyFormat);
        
        totalGeneral += sale.total;
        row++;
        
        // Fila de detalle de productos (viñetas con cantidad y total)
        if (!sale.items.isEmpty()) {
            QString productsDetail = "  Productos:\n";
            for (const SaleItem& item : sale.items) {
                productsDetail += QString("    • %1 %2 - S/ %3\n")
                    .arg(QString::number(item.quantity, 'f', 0))
                    .arg(item.productName)
                    .arg(QString::number(item.subtotal, 'f', 2));
            }
            
            // Primero fusionar las celdas (sin formato), luego escribir con formato
            xlsx.mergeCells(CellRange(row, 2, row, 8));
            xlsx.write(row, 2, productsDetail, detailFormat);
            
            // Ajustar altura de fila para acomodar múltiples líneas
            xlsx.setRowHeight(row, 15.0 * (sale.items.size() + 1));
            
            row++;
        }
    }
    
    // Totales
    row++;
    if (totalPendiente > 0.0) {
        Format pendingFormat;
        pendingFormat.setFontBold(true);
        pendingFormat.setFontColor(Qt::red);
        pendingFormat.setNumberFormat("S/ #,##0.00");
        
        xlsx.write(row, 7, "TOTAL PENDIENTE:", pendingFormat);
        xlsx.write(row, 8, totalPendiente, pendingFormat);
        row++;
    }
    
    Format totalFormat;
    totalFormat.setFontBold(true);
    totalFormat.setFontSize(11);
    totalFormat.setNumberFormat("S/ #,##0.00");
    
    xlsx.write(row, 7, "TOTAL GENERAL:", totalFormat);
    xlsx.write(row, 8, totalGeneral, totalFormat);
    
    // Ajustar anchos de columna
    xlsx.setColumnWidth(1, 12);  // Fecha
    xlsx.setColumnWidth(2, 15);  // Factura
    xlsx.setColumnWidth(3, 10);  // Tipo
    xlsx.setColumnWidth(4, 8);   // Items
    xlsx.setColumnWidth(5, 40);  // Productos
    xlsx.setColumnWidth(6, 12);  // Pago
    xlsx.setColumnWidth(7, 12);  // Estado
    xlsx.setColumnWidth(8, 12);  // Total
    
    return xlsx.saveAs(outputPath);
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
        
        // Usar campos de resumen almacenados en BD si están disponibles
        if (sale.storedItemCount > 0) {
            saleMap["totalItems"] = sale.storedItemCount;
        } else {
            // Calcular desde items si no está en BD (retrocompatibilidad)
            double totalItems = 0;
            for (const SaleItem& item : sale.items) {
                totalItems += item.quantity;
            }
            saleMap["totalItems"] = totalItems;
        }
        
        // Agregar lista de productos
        if (!sale.productNames.isEmpty()) {
            saleMap["productNames"] = sale.productNames;
        } else {
            // Generar desde items si no está en BD (retrocompatibilidad)
            QStringList names;
            for (const SaleItem& item : sale.items) {
                if (!names.contains(item.productName)) {
                    names << item.productName;
                }
            }
            saleMap["productNames"] = names.join(", ");
        }
        
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

bool CustomerListModel::paySingleDebt(int saleId)
{
    qDebug() << "[CustomerListModel] Pagando venta individual ID:" << saleId;
    
    SaleRepository saleRepo;
    bool success = saleRepo.markSaleAsPaid(saleId);
    
    if (success) {
        qDebug() << "[CustomerListModel] Venta marcada como pagada exitosamente";
        // Refrescar la lista de clientes para actualizar la deuda actual
        refresh();
        qDebug() << "[CustomerListModel] Lista de clientes actualizada";
    } else {
        qCritical() << "[CustomerListModel] Error al marcar la venta como pagada";
    }
    
    return success;
}

void CustomerListModel::setCustomers(const QList<Customer>& customers)
{
    beginResetModel();
    m_customers = customers;
    endResetModel();
    emit countChanged();
}
