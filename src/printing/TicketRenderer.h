#ifndef TICKETRENDERER_H
#define TICKETRENDERER_H

#include "TicketLayout.h"
#include "TicketDynamicSection.h"
#include "../models/Sale.h"
#include <QPainter>
#include <QString>
#include <QMap>

// Forward declarations
class PrintService;

/**
 * @brief Datos adicionales para factura
 */
struct InvoiceData {
    QString ruc;
    QString businessName;
    QString address;
};

/**
 * @brief Tipos de comprobante
 */
enum class VoucherType {
    BOLETA,
    FACTURA
};

/**
 * @brief Motor de renderizado de tickets
 * 
 * RESPONSABILIDADES:
 * - Interpretar el layout y dibujarlo
 * - Delegar renderizado de productos a TicketDynamicSection
 * - Ajustar posiciones de elementos después del placeholder dinámico
 * - NO modificar el layout original
 * 
 * FLUJO DE RENDERIZADO:
 * 1. Iterar elementos en orden Y
 * 2. Al encontrar ItemsPlaceholder:
 *    a) Renderizar productos dinámicamente
 *    b) Calcular altura real
 *    c) Guardar offset dinámico
 * 3. Elementos después del placeholder:
 *    - Usar offset dinámico basado en altura real de productos
 */
class TicketRenderer
{
public:
    TicketRenderer();
    
    /**
     * @brief Calcular altura total del ticket con productos
     * @param painter Painter para métricas
     * @param layout Layout del diseño
     * @param sale Venta con productos
     * @return Altura total en píxeles
     */
    double calculateTotalHeight(QPainter& painter, const TicketLayout& layout, const Sale& sale);
    
    /**
     * @brief Renderizar ticket completo
     * @param painter Painter configurado
     * @param layout Layout del diseño
     * @param sale Venta con productos
     * @param type Tipo de comprobante
     * @param invoiceData Datos de factura
     * @param variables Mapa de variables para reemplazo
     */
    void render(QPainter& painter, 
                const TicketLayout& layout, 
                const Sale& sale,
                VoucherType type,
                const InvoiceData& invoiceData,
                const QMap<QString, QString>& variables);

private:
    TicketDynamicSection m_dynamicSection;
    double m_dynamicSectionOffset;  // Offset Y causado por sección dinámica
    double m_placeholderY;          // Posición Y del placeholder
    double m_deviceDpiX;            // DPI del dispositivo actual
    double m_deviceDpiY;
    double m_pixelsPerMM;           // Píxeles por MM según device DPI
    
    // Convertir MM a píxeles según DPI del dispositivo
    inline double mmToPixels(double mm) const {
        return mm * m_pixelsPerMM;
    }
    
    // Renderizar elemento individual
    void renderElement(QPainter& painter, const TicketElement& element,
                      const QMap<QString, QString>& variables);
    
    // Renderizar texto (coordenadas ya en píxeles)
    void renderText(QPainter& painter, double x, double y, double width, double height,
                   const QString& text, int fontSizePixels, const TicketElement& element);
    
    // Renderizar línea (coordenadas ya en píxeles)
    void renderLine(QPainter& painter, double x, double y, double width, 
                   double lineWidth, const TicketElement& element);
    
    // Renderizar imagen (coordenadas ya en píxeles)
    void renderImage(QPainter& painter, double x, double y, double width, double height,
                    const TicketElement& element);
    
    // Reemplazar variables en texto
    QString replaceVariables(const QString& text, const QMap<QString, QString>& variables);
    
    // Calcular offset dinámico para elemento
    double calculateDynamicOffset(double elementY) const;
};

#endif // TICKETRENDERER_H
