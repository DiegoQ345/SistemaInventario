#include "TicketRenderer.h"
#include <QDebug>
#include <QImage>
#include <QPen>

TicketRenderer::TicketRenderer()
    : m_dynamicSectionOffset(0)
    , m_placeholderY(0)
    , m_deviceDpiX(300.0)  // Valor por defecto
    , m_deviceDpiY(300.0)
    , m_pixelsPerMM(11.811024)  // 300 / 25.4
{
}

double TicketRenderer::calculateTotalHeight(QPainter& painter, const TicketLayout& layout, const Sale& sale)
{
    if (!layout.isValid()) {
        qWarning() << "[TicketRenderer] Layout inválido";
        return 0;
    }
    
    // Obtener DPI del dispositivo
    m_deviceDpiX = painter.device()->logicalDpiX();
    m_deviceDpiY = painter.device()->logicalDpiY();
    m_pixelsPerMM = m_deviceDpiX / 25.4;
    
    QList<TicketElement> elements = layout.getElements();
    double maxY = 0;
    
    m_dynamicSectionOffset = 0;
    m_placeholderY = 0;
    
    qDebug() << "[TicketRenderer] Calculando altura total con device DPI:" << m_deviceDpiX;
    
    for (const TicketElement& element : elements) {
        // Convertir MM → píxeles
        double yPx = mmToPixels(element.yMM);
        double heightPx = mmToPixels(element.heightMM);
        
        if (element.type == ElementType::ItemsPlaceholder) {
            // Calcular altura de productos dinámicamente
            double xPx = mmToPixels(element.xMM);
            double widthPx = mmToPixels(element.widthMM);
            
            TicketDynamicSection::Config config;
            config.startX = xPx;
            config.startY = yPx;
            config.maxWidth = widthPx;
            config.itemFontSizePixels = qRound(mmToPixels(element.fontSizeMM));
            config.detailFontSizePixels = qRound(mmToPixels(element.fontSizeMM * 0.875));
            config.fontFamily = element.fontFamily;
            config.itemSpacing = 2;
            
            double dynamicHeight = m_dynamicSection.calculateHeight(painter, sale.items, config);
            m_placeholderY = yPx;
            m_dynamicSectionOffset = dynamicHeight - heightPx;
            
            qDebug() << "  Placeholder en Y=" << yPx << "px, altura diseñada=" << heightPx
                     << "px, altura real=" << dynamicHeight << "px, offset=" << m_dynamicSectionOffset << "px";
            
            maxY = qMax(maxY, yPx + dynamicHeight);
            
        } else {
            // Elemento normal, aplicar offset si está después del placeholder
            double adjustedY = yPx + calculateDynamicOffset(yPx);
            maxY = qMax(maxY, adjustedY + heightPx);
        }
    }
    
    qDebug() << "  Altura total calculada:" << maxY << "px";
    
    return maxY;
}

void TicketRenderer::render(QPainter& painter, 
                            const TicketLayout& layout, 
                            const Sale& sale,
                            VoucherType type,
                            const InvoiceData& invoiceData,
                            const QMap<QString, QString>& variables)
{
    if (!layout.isValid()) {
        qWarning() << "[TicketRenderer] Layout inválido, no se puede renderizar";
        return;
    }
    
    // Obtener DPI REAL del dispositivo
    m_deviceDpiX = painter.device()->logicalDpiX();
    m_deviceDpiY = painter.device()->logicalDpiY();
    m_pixelsPerMM = m_deviceDpiX / 25.4;
    
    qDebug() << "[TicketRenderer] Device DPI:" << m_deviceDpiX << "x" << m_deviceDpiY;
    qDebug() << "[TicketRenderer] PixelsPerMM:" << m_pixelsPerMM;
    qDebug() << "[TicketRenderer] Dimensiones en MM:" << layout.getWidthMM() << "x" << layout.getInitialHeightMM();
    qDebug() << "[TicketRenderer] Dimensiones en px:" << mmToPixels(layout.getWidthMM()) << "x" << mmToPixels(layout.getInitialHeightMM());
    
    QList<TicketElement> elements = layout.getElements();
    
    m_dynamicSectionOffset = 0;
    m_placeholderY = 0;
    
    qDebug() << "[TicketRenderer] Iniciando renderizado de" << elements.size() << "elementos";
    
    for (int i = 0; i < elements.size(); ++i) {
        const TicketElement& element = elements[i];
        
        // Convertir coordenadas MM → píxeles
        double xPx = mmToPixels(element.xMM);
        double yPx = mmToPixels(element.yMM);
        double widthPx = mmToPixels(element.widthMM);
        double heightPx = mmToPixels(element.heightMM);
        
        if (element.type == ElementType::ItemsPlaceholder) {
            // Renderizar productos dinámicamente
            TicketDynamicSection::Config config;
            config.startX = xPx;
            config.startY = yPx;
            config.maxWidth = widthPx;
            config.itemFontSizePixels = qRound(mmToPixels(element.fontSizeMM));
            config.detailFontSizePixels = qRound(mmToPixels(element.fontSizeMM * 0.875));  // 7/8
            config.fontFamily = element.fontFamily;
            config.itemSpacing = 2;
            
            double finalY = m_dynamicSection.render(painter, sale.items, config);
            double dynamicHeight = m_dynamicSection.getLastCalculatedHeight();
            
            m_placeholderY = yPx;
            m_dynamicSectionOffset = dynamicHeight - heightPx;
            
            qDebug() << "  [PRODUCTOS] Renderizados en Y=" << yPx 
                     << ", altura=" << dynamicHeight << "px, finalY=" << finalY 
                     << ", offset=" << m_dynamicSectionOffset << "px";
            
        } else {
            // Renderizar elemento normal
            renderElement(painter, element, variables);
        }
    }
    
    qDebug() << "[TicketRenderer] Renderizado completado";
}

void TicketRenderer::renderElement(QPainter& painter, const TicketElement& element,
                                   const QMap<QString, QString>& variables)
{
    // Convertir coordenadas MM → píxeles usando DPI del dispositivo
    double xPx = mmToPixels(element.xMM);
    double yPx = mmToPixels(element.yMM);
    double widthPx = mmToPixels(element.widthMM);
    double heightPx = mmToPixels(element.heightMM);
    int fontSizePx = qRound(mmToPixels(element.fontSizeMM));
    double lineWidthPx = mmToPixels(element.lineWidthMM);
    
    // Ajustar Y si está después del placeholder dinámico
    yPx += calculateDynamicOffset(yPx);
    
    switch (element.type) {
    case ElementType::Text:
        {
            QString text = replaceVariables(element.content, variables);
            renderText(painter, xPx, yPx, widthPx, heightPx, text, fontSizePx, element);
        }
        break;
        
    case ElementType::Line:
        renderLine(painter, xPx, yPx, widthPx, lineWidthPx, element);
        break;
        
    case ElementType::Image:
        renderImage(painter, xPx, yPx, widthPx, heightPx, element);
        break;
        
    case ElementType::ItemsPlaceholder:
        // Ya renderizado en el paso anterior
        break;
    }
}

void TicketRenderer::renderText(QPainter& painter, double x, double y, double width, double height,
                                const QString& text, int fontSizePixels, const TicketElement& element)
{
    // Crear fuente con setPixelSize (independiente de DPI)
    QFont font(element.fontFamily);
    font.setPixelSize(fontSizePixels);
    font.setBold(element.bold);
    font.setItalic(element.italic);
    font.setUnderline(element.underline);
    
    painter.setFont(font);
    painter.setPen(element.color);
    
    // Alineación
    Qt::Alignment alignment = Qt::AlignLeft | Qt::AlignTop;
    if (element.alignment == "center") {
        alignment = Qt::AlignHCenter | Qt::AlignTop;
    } else if (element.alignment == "right") {
        alignment = Qt::AlignRight | Qt::AlignTop;
    }
    
    // Rectángulo de dibujo con dimensiones EXACTAS en píxeles
    QRectF textRect(x, y, width, height);
    
    painter.drawText(textRect, alignment, text);
    
    qDebug() << "  [TEXT]" << text.left(30) << "@ (" << x << "," << y << ")"
             << "font:" << fontSizePixels << "px";
}

void TicketRenderer::renderLine(QPainter& painter, double x, double y, double width, 
                                double lineWidth, const TicketElement& element)
{
    // Estilo de línea
    Qt::PenStyle penStyle = Qt::SolidLine;
    if (element.lineStyle == "dashed") {
        penStyle = Qt::DashLine;
    } else if (element.lineStyle == "dotted") {
        penStyle = Qt::DotLine;
    }
    
    QPen pen(element.color, lineWidth, penStyle);
    painter.setPen(pen);
    
    // Dibujar línea horizontal
    painter.drawLine(QPointF(x, y), QPointF(x + width, y));
    
    qDebug() << "  [LINE] @ (" << x << "," << y << ") ancho:" << width << "px";
}

void TicketRenderer::renderImage(QPainter& painter, double x, double y, double width, double height,
                                 const TicketElement& element)
{
    QString imagePath = element.imagePath;
    
    // Convertir URI a ruta nativa si es necesario
    if (imagePath.startsWith("file:///")) {
        imagePath = imagePath.mid(8);
    }
    
    QImage image(imagePath);
    if (image.isNull()) {
        qWarning() << "  [IMAGE] No se pudo cargar:" << imagePath;
        
        // Dibujar placeholder
        painter.setPen(QPen(Qt::red, 1, Qt::DashLine));
        painter.drawRect(QRectF(x, y, width, height));
        painter.drawLine(QPointF(x, y), QPointF(x + width, y + height));
        painter.drawLine(QPointF(x + width, y), QPointF(x, y + height));
        return;
    }
    
    // Aplicar opacidad
    double oldOpacity = painter.opacity();
    if (element.opacity < 1.0 && element.opacity > 0.0) {
        painter.setOpacity(element.opacity);
    }
    
    QRectF imageRect(x, y, width, height);
    
    if (element.maintainAspectRatio) {
        // Mantener aspect ratio, centrar en rectángulo
        double imgRatio = (double)image.width() / image.height();
        double rectRatio = width / height;
        
        QRectF scaledRect = imageRect;
        if (imgRatio > rectRatio) {
            // Imagen más ancha
            double newHeight = width / imgRatio;
            double offsetY = (height - newHeight) / 2.0;
            scaledRect = QRectF(x, y + offsetY, width, newHeight);
        } else {
            // Imagen más alta
            double newWidth = height * imgRatio;
            double offsetX = (width - newWidth) / 2.0;
            scaledRect = QRectF(x + offsetX, y, newWidth, height);
        }
        painter.drawImage(scaledRect, image);
    } else {
        // Estirar para llenar
        painter.drawImage(imageRect, image);
    }
    
    // Restaurar opacidad
    painter.setOpacity(oldOpacity);
    
    qDebug() << "  [IMAGE]" << imagePath << "@ (" << x << "," << y << ")";
}

QString TicketRenderer::replaceVariables(const QString& text, const QMap<QString, QString>& variables)
{
    QString result = text;
    
    QMapIterator<QString, QString> it(variables);
    while (it.hasNext()) {
        it.next();
        QString placeholder = "{{" + it.key() + "}}";
        result.replace(placeholder, it.value());
    }
    
    return result;
}

double TicketRenderer::calculateDynamicOffset(double elementY) const
{
    // Si el elemento está después del placeholder, aplicar offset dinámico
    if (elementY > m_placeholderY && m_placeholderY > 0) {
        return m_dynamicSectionOffset;
    }
    
    return 0;
}
