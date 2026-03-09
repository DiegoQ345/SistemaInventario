#include "TicketLayout.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <algorithm>

TicketLayout::TicketLayout()
    : m_widthMM(0)
    , m_initialHeightMM(0)
    , m_bulletChar("•")
    , m_isValid(false)
{
}

bool TicketLayout::loadFromJson(const QString& json)
{
    m_isValid = false;
    m_errorMessage.clear();
    m_elements.clear();
    
    QJsonDocument doc = QJsonDocument::fromJson(json.toUtf8());
    if (doc.isNull()) {
        m_errorMessage = "JSON inválido";
        return false;
    }
    
    QJsonObject root;
    QJsonArray elementsArray;
    
    if (doc.isObject()) {
        root = doc.object();
        
        // Leer tamaño del ticket (siempre en milímetros)
        if (root.contains("size")) {
            QJsonObject sizeObj = root["size"].toObject();
            
            // El diseñador QML guarda como "width" y "height" en MM
            if (sizeObj.contains("width") && sizeObj.contains("height")) {
                m_widthMM = sizeObj["width"].toDouble(0);
                m_initialHeightMM = sizeObj["height"].toDouble(0);
                qDebug() << "[TicketLayout] Tamaño del ticket:" << m_widthMM << "x" << m_initialHeightMM << "mm";
            } else {
                m_errorMessage = "Tamaño del ticket inválido. Debe especificar 'width' y 'height' en MM";
                return false;
            }
            
            if (m_widthMM <= 0 || m_initialHeightMM <= 0) {
                m_errorMessage = "Tamaño del ticket debe ser positivo";
                return false;
            }
        } else {
            m_errorMessage = "Falta especificación de tamaño (size)";
            return false;
        }
        
        // Leer carácter de viñeta (opcional, por defecto •)
        if (root.contains("bulletChar")) {
            m_bulletChar = root["bulletChar"].toString("•");
            qDebug() << "[TicketLayout] Carácter de viñeta:" << m_bulletChar;
        }
        
        // Leer elementos
        if (root.contains("elements") && root["elements"].isArray()) {
            elementsArray = root["elements"].toArray();
        } else {
            m_errorMessage = "Falta array de elementos";
            return false;
        }
        
    } else if (doc.isArray()) {
        m_errorMessage = "Formato incompleto: falta objeto 'size'";
        return false;
    }
    
    // Parsear cada elemento
    for (const QJsonValue& value : elementsArray) {
        if (value.isObject()) {
            TicketElement element = parseElement(value.toObject());
            m_elements.append(element);
        }
    }
    
    if (m_elements.isEmpty()) {
        m_errorMessage = "No se encontraron elementos válidos";
        return false;
    }
    
    // Ordenar elementos por posición Y (de arriba hacia abajo)
    std::sort(m_elements.begin(), m_elements.end(), 
              [](const TicketElement& a, const TicketElement& b) {
                  return a.yMM < b.yMM;
              });
    
    m_isValid = true;
    qDebug() << "[TicketLayout] Diseño cargado:" << m_elements.size() << "elementos,"
             << "tamaño:" << m_widthMM << "x" << m_initialHeightMM << "mm";
    
    return true;
}

QList<TicketElement> TicketLayout::getElements() const
{
    return m_elements;
}

TicketElement TicketLayout::parseElement(const QJsonObject& obj)
{
    TicketElement element;
    
    element.id = obj["id"].toString();
    element.type = parseElementType(obj["type"].toString());
    
    // Leer coordenadas y tamaño directamente en MM (como están en el JSON del diseñador)
    element.xMM = obj["x"].toDouble(0);
    element.yMM = obj["y"].toDouble(0);
    element.widthMM = obj["width"].toDouble(0);
    element.heightMM = obj["height"].toDouble(0);
    
    // IMPORTANTE: El diseñador QML usa una unidad especial para fontSize
    // En el diseñador se visualiza como: fontSize * (pixelsPerMM / 3)
    // Para convertir a MM reales debemos dividir por 3
    // Ejemplo: fontSize=12 del diseñador → 12/3 = 4 MM reales
    double fontSizeDesigner = obj["fontSize"].toDouble(10);
    element.fontSizeMM = fontSizeDesigner / 3.0;
    
    // Propiedades de texto
    element.content = obj["content"].toString();
    element.fontFamily = obj["fontFamily"].toString("Courier New");
    element.bold = obj["bold"].toBool(false);
    element.italic = obj["italic"].toBool(false);
    element.underline = obj["underline"].toBool(false);
    element.alignment = obj["align"].toString("left");
    
    // Detección especial: si el content es "{{Productos}}" es un placeholder de items
    if (element.content == "{{Productos}}" && element.type == ElementType::Text) {
        element.type = ElementType::ItemsPlaceholder;
        qDebug() << "  [Detected] ItemsPlaceholder por content '{{Productos}}'";
    }
    
    // Color
    QString colorStr = obj["color"].toString("#000000");
    element.color = QColor(colorStr);
    if (!element.color.isValid()) {
        element.color = Qt::black;
    }
    
    // Propiedades de línea
    // El diseñador guarda 'height' como grosor de línea en MM
    // Si existe 'lineWidth', usarlo; si no, usar 'height' para líneas
    element.lineWidthMM = obj["lineWidth"].toDouble(
        element.type == ElementType::Line ? element.heightMM : 1.0
    );
    element.lineStyle = obj["lineStyle"].toString("solid");
    
    // Propiedades de imagen
    element.imagePath = obj["imagePath"].toString();
    // Si content contiene una ruta de imagen y no hay imagePath, usar content
    if (element.imagePath.isEmpty() && element.type == ElementType::Image) {
        element.imagePath = element.content;
    }
    element.opacity = obj["opacity"].toDouble(1.0);
    element.maintainAspectRatio = obj["maintainAspectRatio"].toBool(true);
    
    qDebug() << "  [Element]" << element.id << "@" << element.xMM << "," << element.yMM << "mm";
    
    return element;
}

ElementType TicketLayout::parseElementType(const QString& typeStr)
{
    QString type = typeStr.toLower();
    
    if (type == "text") return ElementType::Text;
    if (type == "image") return ElementType::Image;
    if (type == "line") return ElementType::Line;
    if (type == "items" || type == "items_placeholder" || type == "products") {
        return ElementType::ItemsPlaceholder;
    }
    
    // Por defecto
    return ElementType::Text;
}
