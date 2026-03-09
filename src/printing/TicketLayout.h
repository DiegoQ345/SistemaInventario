#ifndef TICKETLAYOUT_H
#define TICKETLAYOUT_H

#include <QString>
#include <QList>
#include <QJsonObject>
#include <QJsonArray>
#include <QColor>

/**
 * @brief Tipos de elementos en el diseño de ticket
 */
enum class ElementType {
    Text,
    Image,
    Line,
    ItemsPlaceholder  // Marcador para inserción dinámica de productos
};

/**
 * @brief Elemento individual del diseño de ticket
 * 
 * IMPORTANTE: Todas las medidas se almacenan en MILÍMETROS
 * La conversión a píxeles se hace en TicketRenderer según DPI del dispositivo
 */
struct TicketElement {
    QString id;
    ElementType type;
    
    // Posición y tamaño en MILÍMETROS
    double xMM;
    double yMM;
    double widthMM;
    double heightMM;
    
    // Propiedades de texto
    QString content;
    double fontSizeMM;  // Tamaño de fuente en MM (convertido desde unidad del diseñador con factor /3)
    QString fontFamily;
    bool bold;
    bool italic;
    bool underline;
    QString alignment;  // "left", "center", "right"
    QColor color;
    
    // Propiedades de línea
    double lineWidthMM;  // Ancho de línea en MM
    QString lineStyle;  // "solid", "dashed", "dotted"
    
    // Propiedades de imagen
    QString imagePath;
    double opacity;
    bool maintainAspectRatio;
    
    // Constructor por defecto
    TicketElement()
        : type(ElementType::Text)
        , xMM(0), yMM(0), widthMM(0), heightMM(0)
        , fontSizeMM(10)
        , fontFamily("Courier New")
        , bold(false), italic(false), underline(false)
        , alignment("left")
        , color(Qt::black)
        , lineWidthMM(1.0)
        , lineStyle("solid")
        , opacity(1.0)
        , maintainAspectRatio(true)
    {}
};

/**
 * @brief Modelo del diseño de ticket
 * 
 * RESPONSABILIDAD: Solo almacenar la estructura del diseño
 * - NO realiza renderizado
 * - NO modifica posiciones
 * - NO convierte unidades (todo ya debe estar en píxeles)
 */
class TicketLayout
{
public:
    TicketLayout();
    
    /**
     * @brief Cargar diseño desde JSON
     * @param json JSON con el diseño del ticket
     * @return true si se cargó correctamente
     */
    bool loadFromJson(const QString& json);
    
    /**
     * @brief Obtener todos los elementos del diseño EN ORDEN
     * @return Lista de elementos ordenados por posición Y
     */
    QList<TicketElement> getElements() const;
    
    /**
     * @brief Obtener ancho del ticket en milímetros
     */
    double getWidthMM() const { return m_widthMM; }
    
    /**
     * @brief Obtener altura inicial del ticket en milímetros (sin secciones dinámicas)
     */
    double getInitialHeightMM() const { return m_initialHeightMM; }
    
    /**
     * @brief Obtener carácter de viñeta para productos
     */
    QString getBulletChar() const { return m_bulletChar; }
    
    /**
     * @brief Verificar si el diseño es válido
     */
    bool isValid() const { return m_isValid; }
    
    /**
     * @brief Obtener mensajes de error
     */
    QString getError() const { return m_errorMessage; }

private:
    QList<TicketElement> m_elements;
    double m_widthMM;  // Ancho en milímetros
    double m_initialHeightMM;  // Altura en milímetros
    QString m_bulletChar;  // Carácter de viñeta
    bool m_isValid;
    QString m_errorMessage;
    
    // Convertir objeto JSON a elemento (ya no necesita isLegacyFormat, siempre es MM)
    TicketElement parseElement(const QJsonObject& obj);
    
    // Convertir string a ElementType
    ElementType parseElementType(const QString& typeStr);
};

#endif // TICKETLAYOUT_H
