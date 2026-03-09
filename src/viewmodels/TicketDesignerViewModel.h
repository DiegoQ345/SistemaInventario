#ifndef TICKETDESIGNERVIEWMODEL_H
#define TICKETDESIGNERVIEWMODEL_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include "../repositories/TicketTemplateRepository.h"
#include "../services/PrintService.h"

/**
 * @brief ViewModel para el diseñador de tickets
 *
 * Centraliza toda la lógica de negocio del diseñador de tickets:
 * gestión de elementos, tamaños, guardado/carga de plantillas y
 * generación de PDFs de vista previa.
 */
class TicketDesignerViewModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(double ticketWidth    READ ticketWidth    WRITE setTicketWidth    NOTIFY ticketWidthChanged)
    Q_PROPERTY(double ticketHeight   READ ticketHeight   WRITE setTicketHeight   NOTIFY ticketHeightChanged)
    Q_PROPERTY(QString bulletCharacter READ bulletCharacter WRITE setBulletCharacter NOTIFY bulletCharacterChanged)
    Q_PROPERTY(QString voucherDesignType READ voucherDesignType NOTIFY voucherDesignTypeChanged)
    Q_PROPERTY(int selectedElementIndex READ selectedElementIndex WRITE setSelectedElementIndex NOTIFY selectedElementIndexChanged)
    Q_PROPERTY(QVariantList ticketElements  READ ticketElements  NOTIFY ticketElementsChanged)
    Q_PROPERTY(QVariantList ticketSizes     READ ticketSizes     CONSTANT)
    Q_PROPERTY(int selectedSizeIndex READ selectedSizeIndex WRITE setSelectedSizeIndex NOTIFY selectedSizeIndexChanged)
    Q_PROPERTY(QVariantList savedTemplates  READ savedTemplates  NOTIFY savedTemplatesChanged)

public:
    explicit TicketDesignerViewModel(QObject *parent = nullptr);

    // ── Getters ────────────────────────────────────────────────────────────
    double       ticketWidth()          const { return m_ticketWidth; }
    double       ticketHeight()         const { return m_ticketHeight; }
    QString      bulletCharacter()      const { return m_bulletCharacter; }
    QString      voucherDesignType()    const { return m_voucherDesignType; }
    int          selectedElementIndex() const { return m_selectedElementIndex; }
    QVariantList ticketElements()       const { return m_ticketElements; }
    QVariantList ticketSizes()          const { return m_ticketSizes; }
    int          selectedSizeIndex()    const { return m_selectedSizeIndex; }
    QVariantList savedTemplates()       const { return m_savedTemplates; }

    // ── Setters ────────────────────────────────────────────────────────────
    void setTicketWidth(double value);
    void setTicketHeight(double value);
    Q_INVOKABLE void setBulletCharacter(const QString &value);
    Q_INVOKABLE void setSelectedElementIndex(int index);
    Q_INVOKABLE void setSelectedSizeIndex(int index);

    // ── Template operations ────────────────────────────────────────────────
    /** Carga el template estándar para "Boleta" o "Factura". */
    Q_INVOKABLE void loadStandardTemplate(const QString &type);

    /** Guarda el diseño actual con el nombre dado. */
    Q_INVOKABLE void saveDesign(const QString &name);

    /** Carga un diseño guardado desde la base de datos. */
    Q_INVOKABLE void loadDesign(int templateId);

    /** Activa como plantilla de impresión la plantilla con el id dado. */
    Q_INVOKABLE void setActiveTemplate(int templateId);

    /** Recarga la lista de plantillas guardadas desde la base de datos. */
    Q_INVOKABLE void refreshTemplates();

    /** Genera un PDF de vista previa en la carpeta de Descargas. */
    Q_INVOKABLE void generatePreviewPdf();

    /** Reemplaza las variables {{xxx}} con valores de ejemplo para la vista previa. */
    Q_INVOKABLE QString replacePreviewVariables(const QString &text) const;

    /** Verifica si ya existe una plantilla con ese nombre. */
    Q_INVOKABLE bool templateNameExists(const QString &name);

    // ── Element add/remove ─────────────────────────────────────────────────
    Q_INVOKABLE void addTextElement();
    Q_INVOKABLE void addSeparatorElement(const QString &lineStyle = QStringLiteral("solid"));
    Q_INVOKABLE void addImageElement();
    Q_INVOKABLE void deleteSelectedElement();

    // ── Element property updates ───────────────────────────────────────────
    /** Actualiza (x, y) de un elemento tras arrastrar. */
    Q_INVOKABLE void updateElementPosition(int index, double x, double y);

    /**
     * Actualiza la geometría completa de un elemento tras redimensionar.
     * Pasar el valor actual del campo que no cambia.
     */
    Q_INVOKABLE void updateElementGeometry(int index, double x, double y, double w, double h);

    /** Actualiza una propiedad arbitraria de un elemento (label, content, fontSize, bold, align…). */
    Q_INVOKABLE void updateElementProperty(int index, const QString &key, const QVariant &value);

    /**
     * Establece la URL de imagen para un elemento de tipo "image".
     * Valida la extensión. Emite showStatus con el resultado.
     */
    Q_INVOKABLE void setElementImageUrl(int index, const QString &url);

signals:
    void ticketWidthChanged();
    void ticketHeightChanged();
    void bulletCharacterChanged();
    void voucherDesignTypeChanged();
    void selectedElementIndexChanged();
    void ticketElementsChanged();
    void selectedSizeIndexChanged();
    void savedTemplatesChanged();

    /** Emitido para mostrar un mensaje temporal en la vista. */
    void showStatus(const QString &message, bool isSuccess);

private:
    double       m_ticketWidth         = 80.0;
    double       m_ticketHeight        = 200.0;
    QString      m_bulletCharacter     = QStringLiteral("•");
    QString      m_voucherDesignType   = QStringLiteral("Boleta");
    int          m_selectedElementIndex = -1;
    QVariantList m_ticketElements;
    QVariantList m_ticketSizes;
    int          m_selectedSizeIndex   = 0;
    QVariantList m_savedTemplates;

    TicketTemplateRepository m_repository;
    PrintService             m_printService;

    void initTicketSizes();
    QVariantList buildBoletaElements() const;
    QVariantList buildFacturaElements() const;

    /** Crea un mapa de elemento con todos los campos necesarios. */
    static QVariantMap makeTextElement(const QString &id, const QString &label,
                                       double x, double y, double w, double h,
                                       const QString &content,
                                       int fontSize, bool bold,
                                       const QString &align);

    static QVariantMap makeLineElement(const QString &id, const QString &label,
                                       double x, double y, double w,
                                       const QString &lineStyle = QStringLiteral("solid"));

    static QVariantMap makeImageElement(const QString &id, const QString &label,
                                        double x, double y, double w, double h);
};

#endif // TICKETDESIGNERVIEWMODEL_H
