#include "TicketDynamicSection.h"
#include <QDebug>

TicketDynamicSection::TicketDynamicSection()
    : m_lastCalculatedHeight(0)
{
}

double TicketDynamicSection::calculateHeight(QPainter& painter, const QList<SaleItem>& items, const Config& config)
{
    m_lastCalculatedHeight = 0;
    
    if (items.isEmpty()) {
        return 0;
    }
    
    // Crear fuentes usando setPixelSize CRÍTICO: Sin multiplicadores
    QFont itemFont(config.fontFamily);
    itemFont.setPixelSize(config.itemFontSizePixels);
    itemFont.setBold(true);  // Headers en negrita
    
    QFont detailFont(config.fontFamily);
    detailFont.setPixelSize(config.detailFontSizePixels);
    
    // Obtener métricas DESPUÉS de setFont en painter
    painter.setFont(itemFont);
    QFontMetrics fmItem = painter.fontMetrics();
    
    painter.setFont(detailFont);
    QFontMetrics fmDetail = painter.fontMetrics();
    
    qDebug() << "[TicketDynamicSection] Calculando altura para" << items.size() << "productos";
    qDebug() << "  Font item:" << config.itemFontSizePixels << "px, altura métrica:" << fmItem.height();
    qDebug() << "  Font detail:" << config.detailFontSizePixels << "px, altura métrica:" << fmDetail.height();
    
    // Agregar altura de los headers
    m_lastCalculatedHeight += fmItem.height() + config.itemSpacing;
    
    // Calcular altura de cada producto
    for (const SaleItem& item : items) {
        double itemHeight = calculateItemHeight(fmItem, fmDetail, item, config.maxWidth);
        m_lastCalculatedHeight += itemHeight + config.itemSpacing;
    }
    
    // Quitar último espaciado
    if (!items.isEmpty()) {
        m_lastCalculatedHeight -= config.itemSpacing;
    }
    
    qDebug() << "  Altura total calculada:" << m_lastCalculatedHeight << "px";
    
    return m_lastCalculatedHeight;
}

double TicketDynamicSection::render(QPainter& painter, const QList<SaleItem>& items, const Config& config)
{
    if (items.isEmpty()) {
        return config.startY;
    }
    
    // Crear fuentes idénticas al cálculo
    QFont itemFont(config.fontFamily);
    itemFont.setPixelSize(config.itemFontSizePixels);
    
    QFont headerFont(config.fontFamily);
    headerFont.setPixelSize(config.itemFontSizePixels);
    headerFont.setBold(true);
    
    QFont detailFont(config.fontFamily);
    detailFont.setPixelSize(config.detailFontSizePixels);
    
    // Obtener métricas DESPUÉS de setFont
    painter.setFont(itemFont);
    QFontMetrics fmItem = painter.fontMetrics();
    
    painter.setFont(detailFont);
    QFontMetrics fmDetail = painter.fontMetrics();
    
    painter.setFont(headerFont);
    QFontMetrics fmHeader = painter.fontMetrics();
    
    double currentY = config.startY;
    
    qDebug() << "[TicketDynamicSection] Renderizando" << items.size() << "productos desde Y=" << currentY;
    
    // Definir anchos de columnas (proporcional al maxWidth)
    double bulletWidth = config.maxWidth * 0.05;      // 5% para viñeta
    double colProductWidth = config.maxWidth * 0.35;  // 35% para nombre
    double colQtyWidth = config.maxWidth * 0.15;      // 15% para cantidad
    double colPriceWidth = config.maxWidth * 0.20;    // 20% para precio unitario
    double colTotalWidth = config.maxWidth * 0.25;    // 25% para subtotal
    
    // Renderizar headers de la tabla
    painter.setFont(headerFont);
    
    // Header vacío para la columna de viñetas
    QRectF headerBulletRect(config.startX, currentY, bulletWidth, fmHeader.height());
    // No dibujamos nada en la columna de viñetas
    
    QRectF headerProductRect(config.startX + bulletWidth, currentY, colProductWidth, fmHeader.height());
    painter.drawText(headerProductRect, Qt::AlignLeft | Qt::AlignVCenter, "Producto");
    
    QRectF headerQtyRect(config.startX + bulletWidth + colProductWidth, currentY, colQtyWidth, fmHeader.height());
    painter.drawText(headerQtyRect, Qt::AlignCenter | Qt::AlignVCenter, "Cant");
    
    QRectF headerPriceRect(config.startX + bulletWidth + colProductWidth + colQtyWidth, currentY, colPriceWidth, fmHeader.height());
    painter.drawText(headerPriceRect, Qt::AlignRight | Qt::AlignVCenter, "P.Unit");
    
    QRectF headerTotalRect(config.startX + bulletWidth + colProductWidth + colQtyWidth + colPriceWidth, currentY, colTotalWidth, fmHeader.height());
    painter.drawText(headerTotalRect, Qt::AlignRight | Qt::AlignVCenter, "Subtotal");
    
    currentY += fmHeader.height() + config.itemSpacing;
    
    // Renderizar cada producto como fila de tabla
    for (int i = 0; i < items.size(); ++i) {
        const SaleItem& item = items[i];
        
        // Viñeta (bullet point)
        QRectF bulletRect(config.startX, currentY, bulletWidth, fmDetail.height());
        painter.setFont(detailFont);
        painter.drawText(bulletRect, Qt::AlignCenter | Qt::AlignVCenter, config.bulletChar);
        
        // Nombre del producto (columna 1)
        QRect nameRect = fmItem.boundingRect(
            QRect(0, 0, static_cast<int>(colProductWidth), 10000),
            Qt::AlignLeft | Qt::TextWordWrap,
            item.productName
        );
        
        double nameHeight = nameRect.height();
        QRectF nameDrawRect(config.startX + bulletWidth, currentY, colProductWidth, nameHeight);
        painter.setFont(itemFont);
        painter.drawText(nameDrawRect, Qt::AlignLeft | Qt::AlignTop | Qt::TextWordWrap, item.productName);
        
        // Cantidad (columna 2) - Enteros sin decimales
        QString qtyText = QString::number(static_cast<int>(item.quantity));
        QRectF qtyDrawRect(config.startX + bulletWidth + colProductWidth, currentY, colQtyWidth, nameHeight);
        painter.setFont(detailFont);
        painter.drawText(qtyDrawRect, Qt::AlignCenter | Qt::AlignVCenter, qtyText);
        
        // Precio unitario (columna 3)
        QString priceText = QString("S/%1").arg(item.unitPrice, 0, 'f', 2);
        QRectF priceDrawRect(config.startX + bulletWidth + colProductWidth + colQtyWidth, currentY, colPriceWidth, nameHeight);
        painter.drawText(priceDrawRect, Qt::AlignRight | Qt::AlignVCenter, priceText);
        
        // Subtotal (columna 4)
        QString totalText = QString("S/%1").arg(item.subtotal, 0, 'f', 2);
        QRectF totalDrawRect(config.startX + bulletWidth + colProductWidth + colQtyWidth + colPriceWidth, currentY, colTotalWidth, nameHeight);
        painter.drawText(totalDrawRect, Qt::AlignRight | Qt::AlignVCenter, totalText);
        
        double itemHeight = nameHeight;
        
        qDebug() << "  Producto" << (i+1) << ":" << item.productName.left(20) 
                 << "cantidad:" << static_cast<int>(item.quantity)
                 << "altura:" << itemHeight << "px, finalY:" << (currentY + itemHeight);
        
        currentY += itemHeight + config.itemSpacing;
    }
    
    // Quitar último espaciado para obtener Y final exacto
    currentY -= config.itemSpacing;
    
    m_lastCalculatedHeight = currentY - config.startY;
    
    qDebug() << "  Y final después de productos:" << currentY;
    qDebug() << "  Altura total renderizada:" << m_lastCalculatedHeight << "px";
    
    return currentY;
}

double TicketDynamicSection::calculateItemHeight(QFontMetrics& fmItem, QFontMetrics& fmDetail,
                                                  const SaleItem& item, double maxWidth)
{
    // En formato tabla, solo necesitamos la altura del nombre del producto
    // (las columnas cantidad, precio y subtotal están en la misma línea)
    // El maxWidth aquí debe ser el ancho de la columna de producto (35% del total, ya que 5% es para viñeta)
    double colProductWidth = maxWidth * 0.35;
    
    // Calcular altura del nombre con word wrap
    QRect nameRect = fmItem.boundingRect(
        QRect(0, 0, static_cast<int>(colProductWidth), 10000),
        Qt::AlignLeft | Qt::TextWordWrap,
        item.productName
    );
    
    double nameHeight = nameRect.height();
    
    return nameHeight;
}

double TicketDynamicSection::renderItem(QPainter& painter, QFontMetrics& fmItem, QFontMetrics& fmDetail,
                                        const SaleItem& item, double x, double y, double maxWidth, const Config& config)
{
    // Renderizar nombre con word wrap
    QRect nameRect = fmItem.boundingRect(
        QRect(0, 0, static_cast<int>(maxWidth), 10000),
        Qt::AlignLeft | Qt::TextWordWrap,
        item.productName
    );
    
    double nameHeight = nameRect.height();
    
    QRectF nameDrawRect(x, y, maxWidth, nameHeight);
    painter.setFont(QFont(config.fontFamily));
    QFont nameFont = painter.font();
    nameFont.setPixelSize(config.itemFontSizePixels);
    painter.setFont(nameFont);
    
    painter.drawText(nameDrawRect, Qt::AlignLeft | Qt::AlignTop | Qt::TextWordWrap, item.productName);
    
    // Renderizar detalles
    QString detailText = QString("%1 x S/ %2 = S/ %3")
        .arg(item.quantity, 0, 'f', 2)
        .arg(item.unitPrice, 0, 'f', 2)
        .arg(item.subtotal, 0, 'f', 2);
    
    double detailHeight = fmDetail.height();
    QRectF detailDrawRect(x, y + nameHeight, maxWidth, detailHeight);
    
    QFont detailFont(config.fontFamily);
    detailFont.setPixelSize(config.detailFontSizePixels);
    painter.setFont(detailFont);
    
    painter.drawText(detailDrawRect, Qt::AlignLeft | Qt::AlignVCenter, detailText);
    
    return nameHeight + detailHeight;
}
