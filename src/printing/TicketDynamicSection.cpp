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
    
    QFont detailFont(config.fontFamily);
    detailFont.setPixelSize(config.detailFontSizePixels);
    
    // Obtener métricas DESPUÉS de setFont
    painter.setFont(itemFont);
    QFontMetrics fmItem = painter.fontMetrics();
    
    painter.setFont(detailFont);
    QFontMetrics fmDetail = painter.fontMetrics();
    
    double currentY = config.startY;
    
    qDebug() << "[TicketDynamicSection] Renderizando" << items.size() << "productos desde Y=" << currentY;
    
    for (int i = 0; i < items.size(); ++i) {
        const SaleItem& item = items[i];
        
        double itemHeight = renderItem(painter, fmItem, fmDetail, item, 
                                       config.startX, currentY, config.maxWidth, config);
        
        qDebug() << "  Producto" << (i+1) << ":" << item.productName.left(20) 
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
    // Calcular altura del nombre con word wrap
    QRect nameRect = fmItem.boundingRect(
        QRect(0, 0, static_cast<int>(maxWidth), 10000),
        Qt::AlignLeft | Qt::TextWordWrap,
        item.productName
    );
    
    double nameHeight = nameRect.height();
    
    // Altura de los detalles (cantidad x precio = subtotal)
    double detailHeight = fmDetail.height();
    
    return nameHeight + detailHeight;
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
