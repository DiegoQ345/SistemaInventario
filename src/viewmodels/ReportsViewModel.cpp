#include "ReportsViewModel.h"
#include "../repositories/SaleRepository.h"
#include <QDebug>
#include <QPdfWriter>
#include <QPainter>
#include <QSettings>
#include <QDir>
#include <QDesktopServices>
#include <QUrl>
#include <QRegularExpression>
#include <QDateTime>
#include <QPageSize>
#include <QPageLayout>

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
    Q_UNUSED(filePath);  // No usamos el parámetro obsoleto
    
    // Obtener información del negocio
    QSettings settings("SistemaInventario", "Config");
    QString businessName = settings.value("businessName", "Mi Negocio").toString();
    QString businessRuc = settings.value("businessRuc", "").toString();
    QString businessAddress = settings.value("businessAddress", "").toString();
    QString businessPhone = settings.value("businessPhone", "").toString();
    
    // Sanitizar nombre del negocio para carpetas
    QString sanitizedBusinessName = businessName;
    sanitizedBusinessName.replace(QRegularExpression("[^a-zA-Z0-9_]"), "_");
    sanitizedBusinessName.replace(QRegularExpression("_+"), "_");
    
    // Construir estructura de carpetas: {reportsFolder}/{NombreNegocio}/Reportes/Reportes del sistema/
    QString reportsBaseFolder = settings.value("reportsFolder", "C:/Reportes_SistemaInventario").toString();
    QString baseDir = reportsBaseFolder + "/" + sanitizedBusinessName;
    QString reportsDir = baseDir + "/Reportes/Reportes del sistema";
    
    // Crear directorios si no existen
    QDir dir;
    if (!dir.exists(reportsDir)) {
        qDebug() << "Creando estructura de directorios:" << reportsDir;
        if (!dir.mkpath(reportsDir)) {
            qCritical() << "Error al crear directorio de reportes:" << reportsDir;
            emit errorOccurred("Error al crear directorio de reportes");
            return;
        }
    }
    
    // Generar nombre de archivo con período y fecha
    QString periodLabel = m_periodType;
    if (periodLabel == "daily") periodLabel = "Diario";
    else if (periodLabel == "weekly") periodLabel = "Semanal";
    else if (periodLabel == "monthly") periodLabel = "Mensual";
    else if (periodLabel == "yearly") periodLabel = "Anual";
    else periodLabel = "Personalizado";
    
    QString dateRange = m_startDate.toString("yyyy-MM-dd");
    if (m_startDate != m_endDate) {
        dateRange += "_a_" + m_endDate.toString("yyyy-MM-dd");
    }
    
    QString fileName = QString("Reporte_%1_%2.pdf").arg(periodLabel, dateRange);
    QString outputPath = reportsDir + "/" + fileName;
    
    qDebug() << "Generando PDF del reporte en:" << outputPath;
    
    // Crear el PDF
    QPdfWriter pdfWriter(outputPath);
    pdfWriter.setPageSize(QPageSize(QPageSize::A4));
    pdfWriter.setPageMargins(QMarginsF(15, 15, 15, 15), QPageLayout::Millimeter);
    pdfWriter.setResolution(300);
    
    QPainter painter(&pdfWriter);
    if (!painter.isActive()) {
        qCritical() << "Error: No se pudo inicializar el painter para el PDF";
        emit errorOccurred("Error al crear el archivo PDF");
        return;
    }
    
    // Configurar fuentes y colores
    QFont titleFont("Arial", 24, QFont::Bold);
    QFont sectionFont("Arial", 16, QFont::Bold);
    QFont headerFont("Arial", 12, QFont::Bold);
    QFont normalFont("Arial", 10);
    QFont smallFont("Arial", 8);
    
    QColor primaryColor(68, 114, 196);      // Azul profesional
    QColor accentColor(79, 129, 189);       // Azul claro
    QColor successColor(112, 173, 71);      // Verde
    QColor dangerColor(192, 80, 77);        // Rojo
    QColor lightGray(240, 240, 240);
    
    int pageWidth = painter.viewport().width();
    int yPos = 200;
    int lineHeight = 180;
    int sectionSpacing = 400;
    
    // === ENCABEZADO CON DISEÑO PROFESIONAL ===
    // Rectángulo de encabezado
    painter.fillRect(0, 0, pageWidth, 800, QBrush(primaryColor));
    
    // Información del negocio en blanco
    painter.setPen(Qt::white);
    painter.setFont(QFont("Arial", 20, QFont::Bold));
    painter.drawText(0, 200, pageWidth, 250, Qt::AlignCenter, businessName);
    
    painter.setFont(QFont("Arial", 9));
    yPos = 450;
    if (!businessRuc.isEmpty()) {
        painter.drawText(0, yPos, pageWidth, 150, Qt::AlignCenter, "RUC: " + businessRuc);
        yPos += 130;
    }
    if (!businessAddress.isEmpty()) {
        painter.drawText(0, yPos, pageWidth, 150, Qt::AlignCenter, businessAddress);
        yPos += 130;
    }
    if (!businessPhone.isEmpty()) {
        painter.drawText(0, yPos, pageWidth, 150, Qt::AlignCenter, "Tel: " + businessPhone);
    }
    
    yPos = 1000;
    
    // === TÍTULO DEL REPORTE CON DISEÑO ===
    painter.setPen(Qt::black);
    painter.setFont(sectionFont);
    QString reportTitle = QString("REPORTE DE VENTAS - %1").arg(periodLabel.toUpper());
    painter.drawText(0, yPos, pageWidth, 300, Qt::AlignCenter, reportTitle);
    yPos += 350;
    
    // Información del período con fondo
    painter.fillRect(100, yPos - 50, pageWidth - 200, 250, QBrush(lightGray));
    painter.setFont(normalFont);
    QString periodText = QString("Período: %1 al %2")
        .arg(m_startDate.toString("dd/MM/yyyy"))
        .arg(m_endDate.toString("dd/MM/yyyy"));
    painter.drawText(100, yPos, pageWidth - 200, lineHeight, Qt::AlignCenter, periodText);
    yPos += lineHeight;
    QString generatedDate = QString("Generado: %1").arg(QDateTime::currentDateTime().toString("dd/MM/yyyy hh:mm"));
    painter.drawText(100, yPos, pageWidth - 200, lineHeight, Qt::AlignCenter, generatedDate);
    yPos += 300;
    
    // === MÉTRICAS PRINCIPALES EN TARJETAS ===
    yPos += 200;
    double totalSales = m_summary.value("totalSales").toDouble();
    int totalTransactions = m_summary.value("totalTransactions").toInt();
    double averageTicket = m_summary.value("averageTicket").toDouble();
    double salesGrowth = m_summary.value("salesGrowth").toDouble();
    
    int cardWidth = (pageWidth - 400) / 3;
    int cardHeight = 600;
    int cardSpacing = 100;
    int cardX = 100;
    
    // Tarjeta 1: Total Ventas
    painter.fillRect(cardX, yPos, cardWidth, cardHeight, QBrush(QColor(230, 240, 255)));
    painter.setPen(QPen(primaryColor, 3));
    painter.drawRect(cardX, yPos, cardWidth, cardHeight);
    
    painter.setFont(QFont("Arial", 9));
    painter.setPen(Qt::darkGray);
    painter.drawText(cardX, yPos + 150, cardWidth, 150, Qt::AlignCenter, "TOTAL VENTAS");
    
    painter.setFont(QFont("Arial", 18, QFont::Bold));
    painter.setPen(primaryColor);
    painter.drawText(cardX, yPos + 330, cardWidth, 250, Qt::AlignCenter, 
                     QString("S/ %L1").arg(totalSales, 0, 'f', 2));
    
    // Tarjeta 2: Transacciones
    cardX += cardWidth + cardSpacing;
    painter.fillRect(cardX, yPos, cardWidth, cardHeight, QBrush(QColor(240, 255, 240)));
    painter.setPen(QPen(successColor, 3));
    painter.drawRect(cardX, yPos, cardWidth, cardHeight);
    
    painter.setFont(QFont("Arial", 9));
    painter.setPen(Qt::darkGray);
    painter.drawText(cardX, yPos + 150, cardWidth, 150, Qt::AlignCenter, "TRANSACCIONES");
    
    painter.setFont(QFont("Arial", 18, QFont::Bold));
    painter.setPen(successColor);
    painter.drawText(cardX, yPos + 330, cardWidth, 250, Qt::AlignCenter, QString::number(totalTransactions));
    
    // Tarjeta 3: Ticket Promedio
    cardX += cardWidth + cardSpacing;
    painter.fillRect(cardX, yPos, cardWidth, cardHeight, QBrush(QColor(255, 245, 230)));
    painter.setPen(QPen(accentColor, 3));
    painter.drawRect(cardX, yPos, cardWidth, cardHeight);
    
    painter.setFont(QFont("Arial", 9));
    painter.setPen(Qt::darkGray);
    painter.drawText(cardX, yPos + 150, cardWidth, 150, Qt::AlignCenter, "TICKET PROMEDIO");
    
    painter.setFont(QFont("Arial", 18, QFont::Bold));
    painter.setPen(accentColor);
    painter.drawText(cardX, yPos + 330, cardWidth, 250, Qt::AlignCenter, 
                     QString("S/ %L1").arg(averageTicket, 0, 'f', 2));
    
    yPos += cardHeight + 300;
    
    // Crecimiento vs período anterior
    QColor growthColor = salesGrowth >= 0 ? successColor : dangerColor;
    QString growthIcon = salesGrowth >= 0 ? "▲" : "▼";
    QString growthText = QString("%1 %2% vs período anterior")
        .arg(growthIcon)
        .arg(qAbs(salesGrowth), 0, 'f', 1);
    
    painter.setFont(QFont("Arial", 11, QFont::Bold));
    painter.setPen(growthColor);
    painter.drawText(0, yPos, pageWidth, lineHeight, Qt::AlignCenter, growthText);
    yPos += sectionSpacing;
    
    // === PRODUCTOS MÁS VENDIDOS CON TABLA ===
    painter.setPen(primaryColor);
    painter.setFont(sectionFont);
    painter.drawText(100, yPos, "TOP 5 PRODUCTOS MÁS VENDIDOS");
    yPos += 300;
    
    QVariantList topProducts = m_summary.value("topProducts").toList();
    
    if (!topProducts.isEmpty()) {
        // Encabezado de tabla
        int col1X = 150;
        int col2X = pageWidth - 2500;
        int col3X = pageWidth - 1500;
        int col4X = pageWidth - 700;
        
        painter.fillRect(100, yPos, pageWidth - 200, 250, QBrush(primaryColor));
        painter.setPen(Qt::white);
        painter.setFont(QFont("Arial", 10, QFont::Bold));
        
        painter.drawText(col1X, yPos + 80, "#");
        painter.drawText(col1X + 150, yPos + 80, "PRODUCTO");
        painter.drawText(col2X, yPos + 80, "UNIDADES");
        painter.drawText(col3X, yPos + 80, "TOTAL");
        painter.drawText(col4X, yPos + 80, "% DEL TOTAL");
        yPos += 250;
        
        // Filas de productos
        painter.setFont(normalFont);
        for (int i = 0; i < topProducts.size() && i < 5; ++i) {
            QVariantMap product = topProducts[i].toMap();
            QString productName = product.value("productName").toString();
            int quantitySold = product.value("quantitySold").toInt();
            double totalRevenue = product.value("totalRevenue").toDouble();
            double percentage = totalSales > 0 ? (totalRevenue / totalSales) * 100.0 : 0.0;
            
            // Alternar color de fondo
            if (i % 2 == 0) {
                painter.fillRect(100, yPos - 30, pageWidth - 200, lineHeight + 60, QBrush(QColor(245, 250, 255)));
            }
            
            painter.setPen(Qt::black);
            painter.drawText(col1X, yPos + 50, QString::number(i + 1));
            
            // Truncar nombre si es muy largo
            if (productName.length() > 35) {
                productName = productName.left(32) + "...";
            }
            painter.drawText(col1X + 150, yPos + 50, productName);
            painter.drawText(col2X, yPos + 50, QString::number(quantitySold));
            painter.drawText(col3X, yPos + 50, QString("S/ %L1").arg(totalRevenue, 0, 'f', 2));
            
            // Barra de porcentaje
            painter.setPen(successColor);
            painter.setFont(QFont("Arial", 9, QFont::Bold));
            painter.drawText(col4X, yPos + 50, QString("%1%").arg(percentage, 0, 'f', 1));
            
            painter.setFont(normalFont);
            yPos += lineHeight + 60;
        }
    } else {
        painter.setPen(Qt::darkGray);
        painter.drawText(150, yPos + 50, "No hay datos de productos para este período");
        yPos += lineHeight;
    }
    
    yPos += sectionSpacing;
    
    // === HISTORIAL DE VENTAS ===
    if (yPos + 1000 > painter.viewport().height()) {
        pdfWriter.newPage();
        yPos = 200;
    }
    
    painter.setPen(primaryColor);
    painter.setFont(sectionFont);
    painter.drawText(100, yPos, "HISTORIAL DETALLADO DE VENTAS");
    yPos += 300;
    
    // Encabezado de tabla
    painter.fillRect(100, yPos, pageWidth - 200, 250, QBrush(primaryColor));
    painter.setPen(Qt::white);
    painter.setFont(QFont("Arial", 9, QFont::Bold));
    
    int colDate = 150;
    int colInvoice = 1200;
    int colCustomer = 2300;
    int colPayment = 4000;
    int colTotal = pageWidth - 800;
    
    painter.drawText(colDate, yPos + 80, "FECHA/HORA");
    painter.drawText(colInvoice, yPos + 80, "FACTURA");
    painter.drawText(colCustomer, yPos + 80, "CLIENTE");
    painter.drawText(colPayment, yPos + 80, "PAGO");
    painter.drawText(colTotal, yPos + 80, "TOTAL");
    yPos += 250;
    
    painter.setFont(smallFont);
    
    int salesCount = 0;
    int maxSales = qMin(50, m_salesHistory.size());  // Limitar a 50 ventas por claridad
    
    for (int i = 0; i < maxSales; ++i) {
        if (yPos + lineHeight + 50 > painter.viewport().height() - 500) {
            pdfWriter.newPage();
            yPos = 200;
            
            // Repetir encabezado
            painter.fillRect(100, yPos, pageWidth - 200, 250, QBrush(primaryColor));
            painter.setPen(Qt::white);
            painter.setFont(QFont("Arial", 9, QFont::Bold));
            painter.drawText(colDate, yPos + 80, "FECHA/HORA");
            painter.drawText(colInvoice, yPos + 80, "FACTURA");
            painter.drawText(colCustomer, yPos + 80, "CLIENTE");
            painter.drawText(colPayment, yPos + 80, "PAGO");
            painter.drawText(colTotal, yPos + 80, "TOTAL");
            yPos += 250;
            painter.setFont(smallFont);
        }
        
        QVariantMap sale = m_salesHistory[i].toMap();
        QString date = sale.value("date").toString();
        QString invoice = sale.value("invoiceNumber").toString();
        QString customer = sale.value("customerName").toString();
        QString payment = sale.value("paymentMethod").toString();
        double total = sale.value("total").toDouble();
        
        // Alternar color de fondo
        if (i % 2 == 0) {
            painter.fillRect(100, yPos - 20, pageWidth - 200, lineHeight + 40, QBrush(QColor(248, 250, 252)));
        }
        
        painter.setPen(Qt::black);
        
        // Truncar textos largos
        if (customer.length() > 18) customer = customer.left(15) + "...";
        if (payment.length() > 12) payment = payment.left(10) + "..";
        
        painter.drawText(colDate, yPos + 40, date);
        painter.drawText(colInvoice, yPos + 40, invoice);
        painter.drawText(colCustomer, yPos + 40, customer);
        painter.drawText(colPayment, yPos + 40, payment);
        
        painter.setFont(QFont("Arial", 9, QFont::Bold));
        painter.drawText(colTotal, yPos + 40, QString("S/ %L1").arg(total, 0, 'f', 2));
        painter.setFont(smallFont);
        
        yPos += lineHeight + 40;
        salesCount++;
    }
    
    if (m_salesHistory.size() > maxSales) {
        yPos += 200;
        painter.setPen(Qt::darkGray);
        QFont italicFont("Arial", 9);
        italicFont.setItalic(true);
        painter.setFont(italicFont);
        painter.drawText(0, yPos, pageWidth, lineHeight, Qt::AlignCenter, 
            QString("... y %1 ventas más (mostrando primeras %2)")
            .arg(m_salesHistory.size() - maxSales)
            .arg(maxSales));
    }
    
    // === PIE DE PÁGINA ===
    if (yPos + 600 > painter.viewport().height()) {
        pdfWriter.newPage();
        yPos = painter.viewport().height() - 600;
    } else {
        yPos = painter.viewport().height() - 400;
    }
    
    painter.setPen(QPen(Qt::lightGray, 2));
    painter.drawLine(100, yPos, pageWidth - 100, yPos);
    yPos += 150;
    
    painter.setFont(QFont("Arial", 8));
    painter.setPen(Qt::darkGray);
    QString footer = QString("Sistema de Inventario • %1 • Página generada automáticamente")
        .arg(QDateTime::currentDateTime().toString("dd/MM/yyyy hh:mm"));
    painter.drawText(0, yPos, pageWidth, 150, Qt::AlignCenter, footer);
    
    // Finalizar
    painter.end();
    
    qDebug() << "PDF generado exitosamente:" << outputPath;
    emit reportGenerated("Reporte exportado exitosamente a PDF");
    
    // Abrir el archivo automáticamente
    QDesktopServices::openUrl(QUrl::fromLocalFile(outputPath));
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
        
        // Agregar items con sus detalles
        QVariantList itemsList;
        for (const auto& item : sale.items) {
            QVariantMap itemMap;
            itemMap["productName"] = item.productName;
            itemMap["quantity"] = item.quantity;
            itemMap["unitPrice"] = item.unitPrice;
            itemMap["subtotal"] = item.subtotal;
            itemsList.append(itemMap);
        }
        saleMap["items"] = itemsList;
        
        m_salesHistory.append(saleMap);
    }
    
    emit salesHistoryChanged();
}
