#include "TicketDesignerViewModel.h"

#include <QDateTime>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocale>
#include <QStandardPaths>

// ─────────────────────────────────────────────────────────────────────────────
// Construction
// ─────────────────────────────────────────────────────────────────────────────

TicketDesignerViewModel::TicketDesignerViewModel(QObject *parent)
    : QObject(parent)
{
    initTicketSizes();
    loadStandardTemplate(m_voucherDesignType);
}

// ─────────────────────────────────────────────────────────────────────────────
// Setters
// ─────────────────────────────────────────────────────────────────────────────

void TicketDesignerViewModel::setTicketWidth(double value)
{
    if (qFuzzyCompare(m_ticketWidth, value)) return;
    m_ticketWidth = value;
    emit ticketWidthChanged();
}

void TicketDesignerViewModel::setTicketHeight(double value)
{
    if (qFuzzyCompare(m_ticketHeight, value)) return;
    m_ticketHeight = value;
    emit ticketHeightChanged();
}

void TicketDesignerViewModel::setBulletCharacter(const QString &value)
{
    if (m_bulletCharacter == value) return;
    m_bulletCharacter = value;
    emit bulletCharacterChanged();
}

void TicketDesignerViewModel::setSelectedElementIndex(int index)
{
    if (m_selectedElementIndex == index) return;
    m_selectedElementIndex = index;
    emit selectedElementIndexChanged();
}

void TicketDesignerViewModel::setSelectedSizeIndex(int index)
{
    if (m_selectedSizeIndex == index) return;
    m_selectedSizeIndex = index;
    emit selectedSizeIndexChanged();

    if (index >= 0 && index < m_ticketSizes.count()) {
        auto sizeMap = m_ticketSizes.at(index).toMap();
        setTicketWidth(sizeMap.value(QStringLiteral("width")).toDouble());
        setTicketHeight(sizeMap.value(QStringLiteral("height")).toDouble());
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Template operations
// ─────────────────────────────────────────────────────────────────────────────

void TicketDesignerViewModel::loadStandardTemplate(const QString &type)
{
    if (type == QLatin1String("Factura")) {
        m_ticketElements = buildFacturaElements();
    } else {
        m_ticketElements = buildBoletaElements();
    }

    if (m_voucherDesignType != type) {
        m_voucherDesignType = type;
        emit voucherDesignTypeChanged();
    }

    m_selectedElementIndex = -1;
    emit selectedElementIndexChanged();
    emit ticketElementsChanged();
}

void TicketDesignerViewModel::saveDesign(const QString &name)
{
    if (name.isEmpty()) return;

    if (m_repository.templateNameExists(name)) {
        emit showStatus(tr("Ya existe un diseño con ese nombre"), false);
        return;
    }

    QVariantMap layoutData;
    layoutData[QStringLiteral("size")] = QVariantMap{
        {QStringLiteral("width"),  m_ticketWidth},
        {QStringLiteral("height"), m_ticketHeight}
    };
    layoutData[QStringLiteral("bulletChar")] = m_bulletCharacter;
    layoutData[QStringLiteral("elements")]   = m_ticketElements;

    const QString layoutJson = QString::fromUtf8(
        QJsonDocument::fromVariant(layoutData).toJson(QJsonDocument::Compact));

    int id = m_repository.saveTemplate(name, layoutJson);
    if (id > 0) {
        refreshTemplates();
        // Activate automatically when it is the first saved template
        if (m_savedTemplates.count() == 1) {
            m_repository.setActiveTemplate(id);
        }
        emit showStatus(tr("Diseño guardado correctamente"), true);
    } else {
        emit showStatus(tr("Error al guardar el diseño"), false);
    }
}

void TicketDesignerViewModel::loadDesign(int templateId)
{
    QVariantMap tmpl = m_repository.getTemplate(templateId);
    if (!tmpl.contains(QStringLiteral("id"))) {
        emit showStatus(tr("Error al cargar el diseño"), false);
        return;
    }

    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(
        tmpl.value(QStringLiteral("layoutJson")).toString().toUtf8(), &err);

    if (err.error != QJsonParseError::NoError) {
        emit showStatus(tr("Error al parsear el diseño: %1").arg(err.errorString()), false);
        return;
    }

    QJsonObject layoutData = doc.object();

    if (layoutData.contains(QStringLiteral("size"))) {
        QJsonObject size = layoutData[QStringLiteral("size")].toObject();
        double newWidth  = size.value(QStringLiteral("width")).toDouble(m_ticketWidth);
        double newHeight = size.value(QStringLiteral("height")).toDouble(m_ticketHeight);

        setTicketWidth(newWidth);
        setTicketHeight(newHeight);

        if (layoutData.contains(QStringLiteral("bulletChar"))) {
            setBulletCharacter(layoutData[QStringLiteral("bulletChar")].toString());
        }

        // Sync selected size index
        for (int i = 0; i < m_ticketSizes.count(); ++i) {
            auto s = m_ticketSizes.at(i).toMap();
            if (qFuzzyCompare(s.value(QStringLiteral("width")).toDouble(),  m_ticketWidth) &&
                qFuzzyCompare(s.value(QStringLiteral("height")).toDouble(), m_ticketHeight)) {
                setSelectedSizeIndex(i);
                break;
            }
        }
    }

    QJsonArray arr = layoutData.contains(QStringLiteral("elements"))
                         ? layoutData[QStringLiteral("elements")].toArray()
                         : doc.array(); // legacy: top-level array

    QVariantList elements;
    elements.reserve(arr.size());
    for (const QJsonValue &v : arr) {
        elements.append(v.toVariant());
    }
    m_ticketElements = elements;
    m_selectedElementIndex = -1;
    emit selectedElementIndexChanged();
    emit ticketElementsChanged();

    emit showStatus(tr("Diseño cargado: %1").arg(tmpl.value(QStringLiteral("name")).toString()), true);
}

void TicketDesignerViewModel::setActiveTemplate(int templateId)
{
    if (m_repository.setActiveTemplate(templateId)) {
        refreshTemplates();
        emit showStatus(tr("Diseño activado para impresión"), true);
    } else {
        emit showStatus(tr("Error al activar el diseño"), false);
    }
}

void TicketDesignerViewModel::refreshTemplates()
{
    m_savedTemplates = m_repository.getAllTemplates();
    emit savedTemplatesChanged();
}

void TicketDesignerViewModel::generatePreviewPdf()
{
    QVariantMap layoutData;
    layoutData[QStringLiteral("size")] = QVariantMap{
        {QStringLiteral("width"),  m_ticketWidth},
        {QStringLiteral("height"), m_ticketHeight}
    };
    layoutData[QStringLiteral("bulletChar")] = m_bulletCharacter;
    layoutData[QStringLiteral("elements")]   = m_ticketElements;

    const QString layoutJson = QString::fromUtf8(
        QJsonDocument::fromVariant(layoutData).toJson(QJsonDocument::Compact));

    const QString timestamp = QDateTime::currentDateTime().toString(
        QStringLiteral("yyyy-MM-ddTHH-mm-ss"));

    const QString downloads = QStandardPaths::writableLocation(
        QStandardPaths::DownloadLocation);

    const QString outputPath = downloads + QStringLiteral("/ticket_preview_")
                               + timestamp + QStringLiteral(".pdf");

    bool success = m_printService.generatePreviewPdf(layoutJson, outputPath);

    if (success) {
        emit showStatus(
            tr("PDF generado en Descargas: ticket_preview_%1.pdf").arg(timestamp), true);
    } else {
        emit showStatus(tr("Error al generar el PDF"), false);
    }
}

QString TicketDesignerViewModel::replacePreviewVariables(const QString &text) const
{
    if (text.isEmpty()) return text;

    // Sample product row for the {{Productos}} placeholder
    const QString productsBlock =
        QStringLiteral("   Producto         Cant  P.Unit  Subtotal\n")
        + m_bulletCharacter + QStringLiteral(" Producto A         2   25.00    50.00\n")
        + m_bulletCharacter + QStringLiteral(" Producto B         1   30.00    30.00\n")
        + m_bulletCharacter + QStringLiteral(" Producto C         3    6.67    20.00");

    QString result = text;
    result.replace(QStringLiteral("{{businessName}}"),        QStringLiteral("Mi Negocio E.I.R.L."));
    result.replace(QStringLiteral("{{ruc}}"),                 QStringLiteral("20123456789"));
    result.replace(QStringLiteral("{{address}}"),             QStringLiteral("Av. Principal 123, Lima"));
    result.replace(QStringLiteral("{{phone}}"),               QStringLiteral("01-234-5678"));
    result.replace(QStringLiteral("{{email}}"),               QStringLiteral("ventas@minegocio.com"));
    result.replace(QStringLiteral("{{invoiceNumber}}"),       QStringLiteral("B001-00123"));
    result.replace(QStringLiteral("{{date}}"),                QLocale::system().toString(QDate::currentDate(), QLocale::ShortFormat));
    result.replace(QStringLiteral("{{time}}"),                QLocale::system().toString(QTime::currentTime(), QLocale::ShortFormat));
    result.replace(QStringLiteral("{{datetime}}"),            QLocale::system().toString(QDateTime::currentDateTime(), QLocale::ShortFormat));
    result.replace(QStringLiteral("{{customerName}}"),        QStringLiteral("Cliente Ejemplo"));
    result.replace(QStringLiteral("{{customerRuc}}"),         QStringLiteral("10987654321"));
    result.replace(QStringLiteral("{{customerBusinessName}}"),QStringLiteral("EMPRESA EJEMPLO S.A.C."));
    result.replace(QStringLiteral("{{customerRazonSocial}}"), QStringLiteral("EMPRESA EJEMPLO S.A.C."));
    result.replace(QStringLiteral("{{customerAddress}}"),     QStringLiteral("Jr. Ejemplo 456, Lima"));
    result.replace(QStringLiteral("{{subtotal}}"),            QStringLiteral("100.00"));
    result.replace(QStringLiteral("{{discount}}"),            QStringLiteral("10.00"));
    result.replace(QStringLiteral("{{tax}}"),                 QStringLiteral("16.20"));
    result.replace(QStringLiteral("{{total}}"),               QStringLiteral("106.20"));
    result.replace(QStringLiteral("{{amountPaid}}"),          QStringLiteral("150.00"));
    result.replace(QStringLiteral("{{changeGiven}}"),         QStringLiteral("43.80"));
    result.replace(QStringLiteral("{{voucherType}}"),         m_voucherDesignType.toUpper());
    result.replace(QStringLiteral("{{Productos}}"),           productsBlock);
    return result;
}

bool TicketDesignerViewModel::templateNameExists(const QString &name)
{
    return m_repository.templateNameExists(name);
}

// ─────────────────────────────────────────────────────────────────────────────
// Element add / remove
// ─────────────────────────────────────────────────────────────────────────────

void TicketDesignerViewModel::addTextElement()
{
    QVariantList elements = m_ticketElements;
    const QString id = QStringLiteral("text_") + QString::number(QDateTime::currentMSecsSinceEpoch());
    elements.append(makeTextElement(id, QStringLiteral("Texto Nuevo"),
                                    10, 100, 60, 8,
                                    QStringLiteral("Nuevo texto"),
                                    10, false, QStringLiteral("left")));
    m_ticketElements = elements;
    m_selectedElementIndex = elements.count() - 1;
    emit selectedElementIndexChanged();
    emit ticketElementsChanged();
}

void TicketDesignerViewModel::addSeparatorElement(const QString &lineStyle)
{
    QVariantList elements = m_ticketElements;
    const QString id = QStringLiteral("separator_") + QString::number(QDateTime::currentMSecsSinceEpoch());
    QString label = QStringLiteral("Separador");
    if (lineStyle == QLatin1String("dotted"))  label = QStringLiteral("Separador Punteado");
    if (lineStyle == QLatin1String("dashed"))  label = QStringLiteral("Separador Discontinuo");
    elements.append(makeLineElement(id, label, 5, 100, 70, lineStyle));
    m_ticketElements = elements;
    m_selectedElementIndex = elements.count() - 1;
    emit selectedElementIndexChanged();
    emit ticketElementsChanged();
}

void TicketDesignerViewModel::addImageElement()
{
    QVariantList elements = m_ticketElements;
    const QString id = QStringLiteral("image_") + QString::number(QDateTime::currentMSecsSinceEpoch());
    elements.append(makeImageElement(id, QStringLiteral("Imagen"), 10, 100, 60, 30));
    m_ticketElements = elements;
    m_selectedElementIndex = elements.count() - 1;
    emit selectedElementIndexChanged();
    emit ticketElementsChanged();
}

void TicketDesignerViewModel::deleteSelectedElement()
{
    if (m_selectedElementIndex < 0 || m_selectedElementIndex >= m_ticketElements.count())
        return;

    QVariantList elements = m_ticketElements;
    elements.removeAt(m_selectedElementIndex);
    m_ticketElements = elements;
    m_selectedElementIndex = -1;
    emit selectedElementIndexChanged();
    emit ticketElementsChanged();
}

// ─────────────────────────────────────────────────────────────────────────────
// Element property updates
// ─────────────────────────────────────────────────────────────────────────────

void TicketDesignerViewModel::updateElementPosition(int index, double x, double y)
{
    if (index < 0 || index >= m_ticketElements.count()) return;
    QVariantMap elem = m_ticketElements.at(index).toMap();
    elem[QStringLiteral("x")] = x;
    elem[QStringLiteral("y")] = y;
    m_ticketElements.replace(index, elem);
    emit ticketElementsChanged();
}

void TicketDesignerViewModel::updateElementGeometry(int index, double x, double y, double w, double h)
{
    if (index < 0 || index >= m_ticketElements.count()) return;
    QVariantMap elem = m_ticketElements.at(index).toMap();
    elem[QStringLiteral("x")]      = x;
    elem[QStringLiteral("y")]      = y;
    elem[QStringLiteral("width")]  = w;
    elem[QStringLiteral("height")] = h;
    m_ticketElements.replace(index, elem);
    emit ticketElementsChanged();
}

void TicketDesignerViewModel::updateElementProperty(int index, const QString &key, const QVariant &value)
{
    if (index < 0 || index >= m_ticketElements.count()) return;
    QVariantMap elem = m_ticketElements.at(index).toMap();
    elem[key] = value;
    m_ticketElements.replace(index, elem);
    emit ticketElementsChanged();
}

void TicketDesignerViewModel::setElementImageUrl(int index, const QString &url)
{
    if (index < 0 || index >= m_ticketElements.count()) return;

    // Validate image extension
    const QString lower = url.toLower();
    const QStringList validExts = {
        QStringLiteral(".png"), QStringLiteral(".jpg"),
        QStringLiteral(".jpeg"), QStringLiteral(".bmp"),
        QStringLiteral(".gif")
    };
    bool valid = false;
    for (const QString &ext : validExts) {
        if (lower.endsWith(ext)) { valid = true; break; }
    }

    if (!valid) {
        emit showStatus(tr("Solo se permiten archivos de imagen"), false);
        return;
    }

    QVariantMap elem = m_ticketElements.at(index).toMap();
    elem[QStringLiteral("content")] = url;
    m_ticketElements.replace(index, elem);
    emit ticketElementsChanged();
    emit showStatus(tr("Imagen cargada correctamente"), true);
}

// ─────────────────────────────────────────────────────────────────────────────
// Private helpers
// ─────────────────────────────────────────────────────────────────────────────

void TicketDesignerViewModel::initTicketSizes()
{
    m_ticketSizes = {
        QVariantMap{{QStringLiteral("name"),   QStringLiteral("80mm x 200mm (Estándar)")},
                    {QStringLiteral("width"),  80.0}, {QStringLiteral("height"), 200.0}},
        QVariantMap{{QStringLiteral("name"),   QStringLiteral("80mm x 297mm (A4 Largo)")},
                    {QStringLiteral("width"),  80.0}, {QStringLiteral("height"), 297.0}},
        QVariantMap{{QStringLiteral("name"),   QStringLiteral("58mm x 200mm (Compacto)")},
                    {QStringLiteral("width"),  58.0}, {QStringLiteral("height"), 200.0}},
        QVariantMap{{QStringLiteral("name"),   QStringLiteral("58mm x 297mm (Compacto Largo)")},
                    {QStringLiteral("width"),  58.0}, {QStringLiteral("height"), 297.0}},
        QVariantMap{{QStringLiteral("name"),   QStringLiteral("80mm x 150mm (Corto)")},
                    {QStringLiteral("width"),  80.0}, {QStringLiteral("height"), 150.0}},
    };
}

QVariantList TicketDesignerViewModel::buildBoletaElements() const
{
    return {
        makeImageElement(QStringLiteral("logo"),            QStringLiteral("Logo"),                     10,   5, 60, 30),
        makeTextElement( QStringLiteral("businessName"),     QStringLiteral("Nombre del Negocio"),        10,  40, 60,  8, QStringLiteral("{{businessName}}"),              14, true,  QStringLiteral("center")),
        makeTextElement( QStringLiteral("ruc"),              QStringLiteral("RUC"),                       10,  50, 60,  6, QStringLiteral("RUC: {{ruc}}"),                  10, false, QStringLiteral("center")),
        makeTextElement( QStringLiteral("address"),          QStringLiteral("Dirección"),                 10,  58, 60, 10, QStringLiteral("{{address}}"),                    8, false, QStringLiteral("center")),
        makeTextElement( QStringLiteral("phone"),            QStringLiteral("Teléfono"),                  10,  70, 60,  6, QStringLiteral("Tel: {{phone}}"),                 8, false, QStringLiteral("center")),
        makeLineElement( QStringLiteral("separator1"),       QStringLiteral("Línea Separadora 1"),         5,  80, 70),
        makeTextElement( QStringLiteral("invoiceNumber"),    QStringLiteral("Número de Comprobante"),     10,  85, 60,  8, QStringLiteral("{{voucherType}}: {{invoiceNumber}}"), 12, true, QStringLiteral("center")),
        makeTextElement( QStringLiteral("date"),             QStringLiteral("Fecha"),                     10,  95, 60,  6, QStringLiteral("{{datetime}}"),                   9, false, QStringLiteral("left")),
        makeTextElement( QStringLiteral("customer"),         QStringLiteral("Cliente"),                   10, 103, 60,  6, QStringLiteral("Cliente: {{customerName}}"),       8, false, QStringLiteral("left")),
        makeLineElement( QStringLiteral("separator2"),       QStringLiteral("Línea Separadora 2"),         5, 111, 70),
        makeTextElement( QStringLiteral("itemsHeader"),      QStringLiteral("[TABLA PRODUCTOS - Auto]"),  10, 115, 60,  6, QStringLiteral("{{Productos}}"),                  8, false, QStringLiteral("left")),
        makeLineElement( QStringLiteral("separator3"),       QStringLiteral("Línea Separadora 3"),         5, 165, 70),
        makeTextElement( QStringLiteral("subtotal"),         QStringLiteral("Subtotal"),                  10, 170, 60,  6, QStringLiteral("Subtotal: S/ {{subtotal}}"),       9, false, QStringLiteral("right")),
        makeTextElement( QStringLiteral("total"),            QStringLiteral("Total"),                     10, 178, 60,  8, QStringLiteral("TOTAL: S/ {{total}}"),           12, true,  QStringLiteral("right")),
        makeTextElement( QStringLiteral("amountPaid"),       QStringLiteral("Monto Pagado"),              10, 188, 60,  6, QStringLiteral("Pagado: S/ {{amountPaid}}"),       9, false, QStringLiteral("right")),
        makeTextElement( QStringLiteral("changeGiven"),      QStringLiteral("Vuelto"),                    10, 195, 60,  6, QStringLiteral("Vuelto: S/ {{changeGiven}}"),      9, false, QStringLiteral("right")),
        makeLineElement( QStringLiteral("separator4"),       QStringLiteral("Línea Separadora 4"),         5, 203, 70),
        makeTextElement( QStringLiteral("footer"),           QStringLiteral("Pie de Página"),             10, 207, 60,  6, QStringLiteral("¡Gracias por su compra!"),         9, false, QStringLiteral("center")),
    };
}

QVariantList TicketDesignerViewModel::buildFacturaElements() const
{
    return {
        makeImageElement(QStringLiteral("logo"),                 QStringLiteral("Logo"),                         10,   5, 60, 30),
        makeTextElement( QStringLiteral("businessName"),          QStringLiteral("Nombre del Negocio"),            10,  40, 60,  8, QStringLiteral("{{businessName}}"),                     14, true,  QStringLiteral("center")),
        makeTextElement( QStringLiteral("ruc"),                   QStringLiteral("RUC"),                           10,  50, 60,  6, QStringLiteral("RUC: {{ruc}}"),                         10, false, QStringLiteral("center")),
        makeTextElement( QStringLiteral("address"),               QStringLiteral("Dirección"),                     10,  58, 60, 10, QStringLiteral("{{address}}"),                           8, false, QStringLiteral("center")),
        makeTextElement( QStringLiteral("phone"),                 QStringLiteral("Teléfono"),                      10,  70, 60,  6, QStringLiteral("Tel: {{phone}}"),                        8, false, QStringLiteral("center")),
        makeLineElement( QStringLiteral("separator1"),            QStringLiteral("Línea Separadora 1"),             5,  80, 70),
        makeTextElement( QStringLiteral("invoiceNumber"),         QStringLiteral("Número de Comprobante"),         10,  85, 60,  8, QStringLiteral("{{voucherType}}: {{invoiceNumber}}"),   12, true,  QStringLiteral("center")),
        makeTextElement( QStringLiteral("date"),                  QStringLiteral("Fecha"),                         10,  95, 60,  6, QStringLiteral("{{datetime}}"),                          9, false, QStringLiteral("left")),
        makeTextElement( QStringLiteral("customer"),              QStringLiteral("Cliente"),                       10, 103, 60,  6, QStringLiteral("Cliente: {{customerName}}"),              8, false, QStringLiteral("left")),
        makeTextElement( QStringLiteral("customerRuc"),           QStringLiteral("RUC Cliente"),                   10, 110, 60,  6, QStringLiteral("RUC: {{customerRuc}}"),                  8, false, QStringLiteral("left")),
        makeTextElement( QStringLiteral("customerBusinessName"),  QStringLiteral("Razón Social"),                  10, 117, 60,  6, QStringLiteral("{{customerBusinessName}}"),              8, false, QStringLiteral("left")),
        makeTextElement( QStringLiteral("customerAddress"),       QStringLiteral("Dirección Cliente"),             10, 124, 60,  8, QStringLiteral("Dir: {{customerAddress}}"),              8, false, QStringLiteral("left")),
        makeLineElement( QStringLiteral("separator2"),            QStringLiteral("Línea Separadora 2"),             5, 134, 70),
        makeTextElement( QStringLiteral("itemsHeader"),           QStringLiteral("[TABLA PRODUCTOS - Auto]"),      10, 138, 60,  6, QStringLiteral("{{Productos}}"),                         8, false, QStringLiteral("left")),
        makeLineElement( QStringLiteral("separator3"),            QStringLiteral("Línea Separadora 3"),             5, 188, 70),
        makeTextElement( QStringLiteral("subtotal"),              QStringLiteral("Subtotal"),                      10, 193, 60,  6, QStringLiteral("Subtotal: S/ {{subtotal}}"),              9, false, QStringLiteral("right")),
        makeTextElement( QStringLiteral("total"),                 QStringLiteral("Total"),                         10, 201, 60,  8, QStringLiteral("TOTAL: S/ {{total}}"),                  12, true,  QStringLiteral("right")),
        makeTextElement( QStringLiteral("amountPaid"),            QStringLiteral("Monto Pagado"),                  10, 211, 60,  6, QStringLiteral("Pagado: S/ {{amountPaid}}"),              9, false, QStringLiteral("right")),
        makeTextElement( QStringLiteral("changeGiven"),           QStringLiteral("Vuelto"),                        10, 218, 60,  6, QStringLiteral("Vuelto: S/ {{changeGiven}}"),             9, false, QStringLiteral("right")),
        makeLineElement( QStringLiteral("separator4"),            QStringLiteral("Línea Separadora 4"),             5, 226, 70),
        makeTextElement( QStringLiteral("footer"),                QStringLiteral("Pie de Página"),                 10, 230, 60,  6, QStringLiteral("¡Gracias por su compra!"),               9, false, QStringLiteral("center")),
    };
}

// ─────────────────────────────────────────────────────────────────────────────
// Static element factories
// ─────────────────────────────────────────────────────────────────────────────

QVariantMap TicketDesignerViewModel::makeTextElement(
    const QString &id, const QString &label,
    double x, double y, double w, double h,
    const QString &content,
    int fontSize, bool bold,
    const QString &align)
{
    return QVariantMap{
        {QStringLiteral("id"),       id},
        {QStringLiteral("type"),     QStringLiteral("text")},
        {QStringLiteral("label"),    label},
        {QStringLiteral("x"),        x},
        {QStringLiteral("y"),        y},
        {QStringLiteral("width"),    w},
        {QStringLiteral("height"),   h},
        {QStringLiteral("content"),  content},
        {QStringLiteral("fontSize"), fontSize},
        {QStringLiteral("bold"),     bold},
        {QStringLiteral("align"),    align},
        {QStringLiteral("editable"),  true},
    };
}

QVariantMap TicketDesignerViewModel::makeLineElement(
    const QString &id, const QString &label,
    double x, double y, double w,
    const QString &lineStyle)
{
    return QVariantMap{
        {QStringLiteral("id"),        id},
        {QStringLiteral("type"),      QStringLiteral("line")},
        {QStringLiteral("label"),     label},
        {QStringLiteral("x"),         x},
        {QStringLiteral("y"),         y},
        {QStringLiteral("width"),     w},
        {QStringLiteral("height"),    1.0},
        {QStringLiteral("lineStyle"), lineStyle},
        // Propiedades de texto con valores por defecto (no se usan pero evitan undefined)
        {QStringLiteral("content"),   QString()},
        {QStringLiteral("fontSize"),  12},
        {QStringLiteral("bold"),      false},
        {QStringLiteral("align"),     QStringLiteral("left")},
        {QStringLiteral("editable"),  true},
    };
}

QVariantMap TicketDesignerViewModel::makeImageElement(
    const QString &id, const QString &label,
    double x, double y, double w, double h)
{
    return QVariantMap{
        {QStringLiteral("id"),       id},
        {QStringLiteral("type"),     QStringLiteral("image")},
        {QStringLiteral("label"),    label},
        {QStringLiteral("x"),        x},
        {QStringLiteral("y"),        y},
        {QStringLiteral("width"),    w},
        {QStringLiteral("height"),   h},
        {QStringLiteral("content"),  QString()},
        {QStringLiteral("fontSize"), 12},
        {QStringLiteral("bold"),     false},
        {QStringLiteral("align"),    QStringLiteral("center")},
        {QStringLiteral("editable"),  true},
    };
}
