#ifndef TICKETDYNAMICSECTION_H
#define TICKETDYNAMICSECTION_H

#include "../models/Sale.h"
#include <QPainter>
#include <QFont>
#include <QFontMetrics>
#include <QRectF>

/**
 * @brief Contenedor dinámico para renderizar lista de productos
 * 
 * RESPONSABILIDADES:
 * - Renderizar productos secuencialmente
 * - Medir altura real usando QFontMetrics
 * - Calcular altura total acumulada
 * - Proporcionar posición final (Y) después del último producto
 * 
 * NO modifica el layout original, solo calcula dinámicamente la altura
 */
class TicketDynamicSection
{
public:
    struct Config {
        double startX;          // Posición X inicial (px)
        double startY;          // Posición Y inicial (px)
        double maxWidth;        // Ancho máximo para productos (px)
        int itemFontSizePixels; // Tamaño fuente nombre producto (px)
        int detailFontSizePixels; // Tamaño fuente detalles (px)
        QString fontFamily;     // Familia de fuente
        double itemSpacing;     // Espaciado entre productos (px)
        QString bulletChar;     // Carácter de viñeta (•, -, *, etc.)
        
        Config()
            : startX(0), startY(0), maxWidth(200)
            , itemFontSizePixels(8), detailFontSizePixels(7)
            , fontFamily("Courier New")
            , itemSpacing(2)
            , bulletChar("•")
        {}
    };
    
    TicketDynamicSection();
    
    /**
     * @brief Calcular altura necesaria sin renderizar
     * @param painter Painter para obtener métricas correctas
     * @param items Lista de productos
     * @param config Configuración de la sección
     * @return Altura total en píxeles
     */
    double calculateHeight(QPainter& painter, const QList<SaleItem>& items, const Config& config);
    
    /**
     * @brief Renderizar productos y devolver posición final
     * @param painter Painter configurado para dibujar
     * @param items Lista de productos
     * @param config Configuración de la sección
     * @return Posición Y final después del último producto
     */
    double render(QPainter& painter, const QList<SaleItem>& items, const Config& config);
    
    /**
     * @brief Obtener altura calculada en el último render/cálculo
     */
    double getLastCalculatedHeight() const { return m_lastCalculatedHeight; }

private:
    double m_lastCalculatedHeight;
    
    // Calcular altura de un producto individual
    double calculateItemHeight(QFontMetrics& fmItem, QFontMetrics& fmDetail, 
                               const SaleItem& item, double maxWidth);
    
    // Renderizar un producto individual
    double renderItem(QPainter& painter, QFontMetrics& fmItem, QFontMetrics& fmDetail,
                     const SaleItem& item, double x, double y, double maxWidth, const Config& config);
};

#endif // TICKETDYNAMICSECTION_H
