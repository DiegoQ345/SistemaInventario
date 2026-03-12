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
    int lineHeight = 60;  // Reducido aún más
    int sectionSpacing = 120;  // Reducido aún más
    
    // === ENCABEZADO CON DISEÑO PROFESIONAL (MÁS COMPACTO) ===
    // Rectángulo de encabezado más pequeño
    painter.fillRect(0, 0, pageWidth, 500, QBrush(primaryColor));
    
    // Información del negocio en blanco
    painter.setPen(Qt::white);
    painter.setFont(QFont("Arial", 16, QFont::Bold));  // Reducido de 20 a 16
    painter.drawText(0, 150, pageWidth, 200, Qt::AlignCenter, businessName);
    
    painter.setFont(QFont("Arial", 8));  // Reducido de 9 a 8
    yPos = 350;  // Reducido de 450 a 350
    if (!businessRuc.isEmpty()) {
        painter.drawText(0, yPos, pageWidth, 100, Qt::AlignCenter, "RUC: " + businessRuc);
        yPos += 90;  // Reducido de 130 a 90
    }
    if (!businessAddress.isEmpty()) {
        painter.drawText(0, yPos, pageWidth, 100, Qt::AlignCenter, businessAddress);
        yPos += 90;
    }
    if (!businessPhone.isEmpty()) {
        painter.drawText(0, yPos, pageWidth, 100, Qt::AlignCenter, "Tel: " + businessPhone);
    }
    
    yPos = 600;  // Reducido de 1000 a 600
    
    // === TÍTULO DEL REPORTE CON DISEÑO ===
    painter.setPen(Qt::black);
    painter.setFont(QFont("Arial", 14, QFont::Bold));  // Reducido de 16 a 14
    QString reportTitle = QString("REPORTE DE VENTAS - %1").arg(periodLabel.toUpper());
    painter.drawText(0, yPos, pageWidth, 200, Qt::AlignCenter, reportTitle);  // Reducido de 300 a 200
    yPos += 180;  // Reducido de 250 a 180
    
    // Información del período con fondo más compacto
    painter.fillRect(100, yPos - 30, pageWidth - 200, 160, QBrush(lightGray));  // Reducido de 250 a 160
    painter.setFont(QFont("Arial", 9));  // Reducido de normalFont a 9
    QString periodText = QString("Período: %1 al %2")
        .arg(m_startDate.toString("dd/MM/yyyy"))
        .arg(m_endDate.toString("dd/MM/yyyy"));
    painter.drawText(100, yPos + 10, pageWidth - 200, lineHeight, Qt::AlignCenter, periodText);
    yPos += lineHeight;
    QString generatedDate = QString("Generado: %1").arg(QDateTime::currentDateTime().toString("dd/MM/yyyy hh:mm"));
    painter.drawText(100, yPos + 10, pageWidth - 200, lineHeight, Qt::AlignCenter, generatedDate);
    yPos += 100;  // Reducido de 180 a 100
    
    // === MÉTRICAS PRINCIPALES EN TARJETAS (MÁS COMPACTAS) ===
    yPos += 80;  // Reducido de 150 a 80
    double totalSales = m_summary.value("totalSales").toDouble();
    int totalTransactions = m_summary.value("totalTransactions").toInt();
    double averageTicket = m_summary.value("averageTicket").toDouble();
    double salesGrowth = m_summary.value("salesGrowth").toDouble();
    
    // Calcular total de productos vendidos
    QVariantList topProductsList = m_summary.value("topProducts").toList();
    int totalProductsSold = 0;
    for (const auto& product : topProductsList) {
        QVariantMap productMap = product.toMap();
        totalProductsSold += productMap.value("quantitySold").toInt();
    }
    
    int cardWidth = (pageWidth - 400) / 4;  // Cambiado de /3 a /4 para 4 tarjetas
    int cardHeight = 380;  // Reducido de 600 a 380
    int cardSpacing = 80;  // Reducido de 100 a 80
    int cardX = 100;
    
    // Tarjeta 1: Total Ventas
    painter.fillRect(cardX, yPos, cardWidth, cardHeight, QBrush(QColor(230, 240, 255)));
    painter.setPen(QPen(primaryColor, 2));  // Reducido de 3 a 2
    painter.drawRect(cardX, yPos, cardWidth, cardHeight);
    
    painter.setFont(QFont("Arial", 8));  // Reducido de 9 a 8
    painter.setPen(Qt::darkGray);
    painter.drawText(cardX, yPos + 100, cardWidth, 100, Qt::AlignCenter, "TOTAL VENTAS");
    
    painter.setFont(QFont("Arial", 12, QFont::Bold));  // Reducido de 18 a 12
    painter.setPen(primaryColor);
    painter.drawText(cardX, yPos + 200, cardWidth, 150, Qt::AlignCenter, 
                     QString("S/ %L1").arg(totalSales, 0, 'f', 2));
    
    // Tarjeta 2: Transacciones
    cardX += cardWidth + cardSpacing;
    painter.fillRect(cardX, yPos, cardWidth, cardHeight, QBrush(QColor(240, 255, 240)));
    painter.setPen(QPen(successColor, 2));
    painter.drawRect(cardX, yPos, cardWidth, cardHeight);
    
    painter.setFont(QFont("Arial", 8));
    painter.setPen(Qt::darkGray);
    painter.drawText(cardX, yPos + 100, cardWidth, 100, Qt::AlignCenter, "VENTAS");
    
    painter.setFont(QFont("Arial", 12, QFont::Bold));
    painter.setPen(successColor);
    painter.drawText(cardX, yPos + 200, cardWidth, 150, Qt::AlignCenter, QString::number(totalTransactions));
    
    // Tarjeta 3: Productos vendidos
    cardX += cardWidth + cardSpacing;
    painter.fillRect(cardX, yPos, cardWidth, cardHeight, QBrush(QColor(255, 240, 230)));
    painter.setPen(QPen(QColor(230, 126, 34), 2));
    painter.drawRect(cardX, yPos, cardWidth, cardHeight);
    
    painter.setFont(QFont("Arial", 8));
    painter.setPen(Qt::darkGray);
    painter.drawText(cardX, yPos + 100, cardWidth, 100, Qt::AlignCenter, "PRODUCTOS");
    
    painter.setFont(QFont("Arial", 12, QFont::Bold));
    painter.setPen(QColor(230, 126, 34));
    painter.drawText(cardX, yPos + 200, cardWidth, 150, Qt::AlignCenter, QString::number(totalProductsSold));
    
    // Tarjeta 4: Ticket Promedio
    cardX += cardWidth + cardSpacing;
    painter.fillRect(cardX, yPos, cardWidth, cardHeight, QBrush(QColor(255, 245, 230)));
    painter.setPen(QPen(accentColor, 2));
    painter.drawRect(cardX, yPos, cardWidth, cardHeight);
    
    painter.setFont(QFont("Arial", 8));
    painter.setPen(Qt::darkGray);
    painter.drawText(cardX, yPos + 100, cardWidth, 100, Qt::AlignCenter, "TICKET PROM.");
    
    painter.setFont(QFont("Arial", 12, QFont::Bold));
    painter.setPen(accentColor);
    painter.drawText(cardX, yPos + 200, cardWidth, 150, Qt::AlignCenter, 
                     QString("S/ %L1").arg(averageTicket, 0, 'f', 2));
    
    yPos += cardHeight + 100;  // Reducido de 180 a 100
    
    // Crecimiento vs período anterior
    QColor growthColor = salesGrowth >= 0 ? successColor : dangerColor;
    QString growthIcon = salesGrowth >= 0 ? "▲" : "▼";
    QString growthText = QString("%1 %2% vs período anterior")
        .arg(growthIcon)
        .arg(qAbs(salesGrowth), 0, 'f', 1);
    
    painter.setFont(QFont("Arial", 10, QFont::Bold));  // Reducido de 11 a 10
    painter.setPen(growthColor);
    painter.drawText(0, yPos, pageWidth, lineHeight, Qt::AlignCenter, growthText);
    yPos += sectionSpacing - 20;  // Reducido aún más
    
    // === PRODUCTOS MÁS VENDIDOS CON TABLA ===
    painter.setPen(primaryColor);
    painter.setFont(QFont("Arial", 12, QFont::Bold));  // Reducido de sectionFont
    painter.drawText(100, yPos, "TOP 5 PRODUCTOS MÁS VENDIDOS");
    yPos += 150;  // Reducido de 200 a 150
    
    QVariantList topProducts = m_summary.value("topProducts").toList();
    
    if (!topProducts.isEmpty()) {
        // Configuración de tabla con columnas proporcionales
        int tableX = 100;
        int tableWidth = pageWidth - 200;
        int headerHeight = 150;
        int rowHeight = lineHeight + 20;
        
        // Anchos de columnas proporcionales
        int colNumW = tableWidth * 0.08;      // 8% para #
        int colProductW = tableWidth * 0.40;  // 40% para producto
        int colUnitsW = tableWidth * 0.17;    // 17% para unidades
        int colTotalW = tableWidth * 0.20;    // 20% para total
        int colPercentW = tableWidth * 0.15;  // 15% para porcentaje
        
        // Posiciones X de cada columna
        int colNum = tableX;
        int colProduct = colNum + colNumW;
        int colUnits = colProduct + colProductW;
        int colTotal = colUnits + colUnitsW;
        int colPercent = colTotal + colTotalW;
        
        // Encabezado de tabla con bordes
        painter.fillRect(tableX, yPos, tableWidth, headerHeight, QBrush(primaryColor));
        painter.setPen(QPen(Qt::white, 2));
        painter.drawRect(tableX, yPos, tableWidth, headerHeight);
        
        // Líneas verticales de separación en encabezado
        painter.drawLine(colProduct, yPos, colProduct, yPos + headerHeight);
        painter.drawLine(colUnits, yPos, colUnits, yPos + headerHeight);
        painter.drawLine(colTotal, yPos, colTotal, yPos + headerHeight);
        painter.drawLine(colPercent, yPos, colPercent, yPos + headerHeight);
        
        painter.setPen(Qt::white);
        painter.setFont(QFont("Arial", 9, QFont::Bold));
        
        // Dibujar encabezados centrados en cada columna
        painter.drawText(colNum + 10, yPos + 60, colNumW - 20, 100, Qt::AlignCenter, "#");
        painter.drawText(colProduct + 10, yPos + 60, colProductW - 20, 100, Qt::AlignLeft | Qt::AlignVCenter, "PRODUCTO");
        painter.drawText(colUnits + 10, yPos + 60, colUnitsW - 20, 100, Qt::AlignCenter, "UNIDADES");
        painter.drawText(colTotal + 10, yPos + 60, colTotalW - 20, 100, Qt::AlignRight | Qt::AlignVCenter, "TOTAL");
        painter.drawText(colPercent + 10, yPos + 60, colPercentW - 20, 100, Qt::AlignCenter, "% TOTAL");
        yPos += headerHeight;
        
        // Filas de productos
        painter.setFont(normalFont);
        for (int i = 0; i < topProducts.size() && i < 5; ++i) {
            QVariantMap product = topProducts[i].toMap();
            QString productName = product.value("productName").toString();
            int quantitySold = product.value("quantitySold").toInt();
            double totalRevenue = product.value("totalRevenue").toDouble();
            double percentage = totalSales > 0 ? (totalRevenue / totalSales) * 100.0 : 0.0;
            
            // Alternar color de fondo
            QBrush rowBrush = (i % 2 == 0) ? QBrush(QColor(245, 250, 255)) : QBrush(Qt::white);
            painter.fillRect(tableX, yPos, tableWidth, rowHeight, rowBrush);
            
            // Dibujar bordes de la fila
            painter.setPen(QPen(QColor(220, 220, 220), 1));
            painter.drawRect(tableX, yPos, tableWidth, rowHeight);
            
            // Líneas verticales de separación
            painter.drawLine(colProduct, yPos, colProduct, yPos + rowHeight);
            painter.drawLine(colUnits, yPos, colUnits, yPos + rowHeight);
            painter.drawLine(colTotal, yPos, colTotal, yPos + rowHeight);
            painter.drawLine(colPercent, yPos, colPercent, yPos + rowHeight);
            
            painter.setPen(Qt::black);
            painter.setFont(normalFont);
            
            // Truncar nombre si es muy largo según ancho disponible
            QString displayName = productName;
            if (painter.fontMetrics().horizontalAdvance(displayName) > colProductW - 20) {
                displayName = painter.fontMetrics().elidedText(displayName, Qt::ElideRight, colProductW - 20);
            }
            
            // Dibujar contenido de cada celda
            int textY = yPos + (rowHeight / 2) + (painter.fontMetrics().height() / 4);
            
            // Número centrado
            painter.drawText(colNum + 10, textY - 10, colNumW - 20, 100, Qt::AlignCenter, QString::number(i + 1));
            
            // Producto alineado a la izquierda
            painter.drawText(colProduct + 10, textY, displayName);
            
            // Unidades centradas
            painter.drawText(colUnits + 10, textY - 10, colUnitsW - 20, 100, Qt::AlignCenter, QString::number(quantitySold));
            
            // Total alineado a la derecha
            painter.drawText(colTotal + 10, textY - 10, colTotalW - 20, 100, Qt::AlignRight, QString("S/ %L1").arg(totalRevenue, 0, 'f', 2));
            
            // Porcentaje centrado en verde
            painter.setPen(successColor);
            painter.setFont(QFont("Arial", 9, QFont::Bold));
            painter.drawText(colPercent + 10, textY - 10, colPercentW - 20, 100, Qt::AlignCenter, QString("%1%").arg(percentage, 0, 'f', 1));
            
            painter.setPen(Qt::black);
            painter.setFont(normalFont);
            yPos += rowHeight;
        }
    } else {
        painter.setPen(Qt::darkGray);
        painter.drawText(150, yPos + 50, "No hay datos de productos para este período");
        yPos += lineHeight;
    }
    
    yPos += sectionSpacing;
    
    // === HISTORIAL DE VENTAS ===
    if (yPos + 800 > painter.viewport().height()) {  // Reducido de 1000 a 800
        pdfWriter.newPage();
        yPos = 200;
    }
    
    painter.setPen(primaryColor);
    painter.setFont(QFont("Arial", 12, QFont::Bold));  // Reducido de sectionFont
    painter.drawText(100, yPos, "HISTORIAL DETALLADO DE VENTAS");
    yPos += 150;  // Reducido de 200 a 150
    
    // Configuración de columnas con ancho proporcional
    int tableX = 100;
    int tableWidth = pageWidth - 200;
    int headerHeight = 180;  // Reducido de 250 a 180
    int rowHeight = lineHeight + 15;  // Altura de cada fila
    
    int colDateW = tableWidth * 0.20;     // 20% para fecha
    int colInvoiceW = tableWidth * 0.15;  // 15% para factura
    int colCustomerW = tableWidth * 0.25; // 25% para cliente
    int colPaymentW = tableWidth * 0.20;  // 20% para pago
    int colTotalW = tableWidth * 0.20;    // 20% para total
    
    int colDate = tableX;
    int colInvoice = colDate + colDateW;
    int colCustomer = colInvoice + colInvoiceW;
    int colPayment = colCustomer + colCustomerW;
    int colTotal = colPayment + colPaymentW;
    
    // Encabezado de tabla con bordes
    painter.fillRect(tableX, yPos, tableWidth, headerHeight, QBrush(primaryColor));
    painter.setPen(QPen(Qt::white, 2));
    painter.drawRect(tableX, yPos, tableWidth, headerHeight);
    
    // Líneas verticales de separación en encabezado
    painter.drawLine(colInvoice, yPos, colInvoice, yPos + headerHeight);
    painter.drawLine(colCustomer, yPos, colCustomer, yPos + headerHeight);
    painter.drawLine(colPayment, yPos, colPayment, yPos + headerHeight);
    painter.drawLine(colTotal, yPos, colTotal, yPos + headerHeight);
    
    painter.setPen(Qt::white);
    painter.setFont(QFont("Arial", 9, QFont::Bold));
    
    painter.drawText(colDate + 10, yPos + 60, colDateW - 20, 100, Qt::AlignLeft | Qt::AlignVCenter, "FECHA/HORA");
    painter.drawText(colInvoice + 10, yPos + 60, colInvoiceW - 20, 100, Qt::AlignLeft | Qt::AlignVCenter, "FACTURA");
    painter.drawText(colCustomer + 10, yPos + 60, colCustomerW - 20, 100, Qt::AlignLeft | Qt::AlignVCenter, "CLIENTE");
    painter.drawText(colPayment + 10, yPos + 60, colPaymentW - 20, 100, Qt::AlignLeft | Qt::AlignVCenter, "PAGO");
    painter.drawText(colTotal + 10, yPos + 60, colTotalW - 20, 100, Qt::AlignRight | Qt::AlignVCenter, "TOTAL");
    yPos += headerHeight;
    
    painter.setFont(smallFont);
    
    int salesCount = 0;
    int maxSales = qMin(50, m_salesHistory.size());  // Limitar a 50 ventas por claridad
    
    for (int i = 0; i < maxSales; ++i) {
        if (yPos + rowHeight + 50 > painter.viewport().height() - 500) {
            pdfWriter.newPage();
            yPos = 200;
            
            // Repetir encabezado con bordes
            painter.fillRect(tableX, yPos, tableWidth, headerHeight, QBrush(primaryColor));
            painter.setPen(QPen(Qt::white, 2));
            painter.drawRect(tableX, yPos, tableWidth, headerHeight);
            
            // Líneas verticales en encabezado
            painter.drawLine(colInvoice, yPos, colInvoice, yPos + headerHeight);
            painter.drawLine(colCustomer, yPos, colCustomer, yPos + headerHeight);
            painter.drawLine(colPayment, yPos, colPayment, yPos + headerHeight);
            painter.drawLine(colTotal, yPos, colTotal, yPos + headerHeight);
            
            painter.setPen(Qt::white);
            painter.setFont(QFont("Arial", 9, QFont::Bold));
            painter.drawText(colDate + 10, yPos + 60, colDateW - 20, 100, Qt::AlignLeft | Qt::AlignVCenter, "FECHA/HORA");
            painter.drawText(colInvoice + 10, yPos + 60, colInvoiceW - 20, 100, Qt::AlignLeft | Qt::AlignVCenter, "FACTURA");
            painter.drawText(colCustomer + 10, yPos + 60, colCustomerW - 20, 100, Qt::AlignLeft | Qt::AlignVCenter, "CLIENTE");
            painter.drawText(colPayment + 10, yPos + 60, colPaymentW - 20, 100, Qt::AlignLeft | Qt::AlignVCenter, "PAGO");
            painter.drawText(colTotal + 10, yPos + 60, colTotalW - 20, 100, Qt::AlignRight | Qt::AlignVCenter, "TOTAL");
            yPos += headerHeight;
            painter.setFont(smallFont);
        }
        
        QVariantMap sale = m_salesHistory[i].toMap();
        QString date = sale.value("date").toString();
        QString invoice = sale.value("invoiceNumber").toString();
        QString customer = sale.value("customerName").toString();
        QString payment = sale.value("paymentMethod").toString();
        double total = sale.value("total").toDouble();
        
        // Alternar color de fondo
        QBrush rowBrush = (i % 2 == 0) ? QBrush(QColor(248, 250, 252)) : QBrush(Qt::white);
        painter.fillRect(tableX, yPos, tableWidth, rowHeight, rowBrush);
        
        // Dibujar bordes de la fila
        painter.setPen(QPen(QColor(220, 220, 220), 1));
        painter.drawRect(tableX, yPos, tableWidth, rowHeight);
        
        // Líneas verticales de separación
        painter.drawLine(colInvoice, yPos, colInvoice, yPos + rowHeight);
        painter.drawLine(colCustomer, yPos, colCustomer, yPos + rowHeight);
        painter.drawLine(colPayment, yPos, colPayment, yPos + rowHeight);
        painter.drawLine(colTotal, yPos, colTotal, yPos + rowHeight);
        
        painter.setPen(Qt::black);
        painter.setFont(smallFont);
        
        // Truncar textos largos según ancho disponible
        QString dateText = date;
        if (painter.fontMetrics().horizontalAdvance(dateText) > colDateW - 20) {
            dateText = painter.fontMetrics().elidedText(dateText, Qt::ElideRight, colDateW - 20);
        }
        
        QString invoiceText = invoice;
        if (painter.fontMetrics().horizontalAdvance(invoiceText) > colInvoiceW - 20) {
            invoiceText = painter.fontMetrics().elidedText(invoiceText, Qt::ElideRight, colInvoiceW - 20);
        }
        
        QString customerText = customer;
        if (painter.fontMetrics().horizontalAdvance(customerText) > colCustomerW - 20) {
            customerText = painter.fontMetrics().elidedText(customerText, Qt::ElideRight, colCustomerW - 20);
        }
        
        QString paymentText = payment;
        if (painter.fontMetrics().horizontalAdvance(paymentText) > colPaymentW - 20) {
            paymentText = painter.fontMetrics().elidedText(paymentText, Qt::ElideRight, colPaymentW - 20);
        }
        
        // Dibujar texto centrado verticalmente en cada celda
        int textY = yPos + (rowHeight / 2) + (painter.fontMetrics().height() / 4);
        painter.drawText(colDate + 10, textY, dateText);
        painter.drawText(colInvoice + 10, textY, invoiceText);
        painter.drawText(colCustomer + 10, textY, customerText);
        painter.drawText(colPayment + 10, textY, paymentText);
        
        painter.setFont(QFont("Arial", 9, QFont::Bold));
        painter.drawText(colTotal + 10, textY - 10, colTotalW - 20, 100, Qt::AlignRight, QString("S/ %L1").arg(total, 0, 'f', 2));
        painter.setFont(smallFont);
        
        yPos += rowHeight;
        salesCount++;
    }
    
    if (m_salesHistory.size() > maxSales) {
        yPos += 120;  // Reducido de 200 a 120
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
        saleMap["paymentType"] = sale.paymentType;  // CONTADO o CREDITO
        saleMap["paymentStatus"] = sale.paymentStatus;  // PAID, PENDING, PARTIAL
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
