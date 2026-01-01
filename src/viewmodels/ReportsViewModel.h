#ifndef REPORTSVIEWMODEL_H
#define REPORTSVIEWMODEL_H

#include <QObject>
#include <QDate>
#include <QVariantMap>
#include <QVariantList>

/**
 * @brief ViewModel para página de reportes y análisis
 * 
 * Gestiona reportes de ventas diarias, semanales, mensuales y anuales
 */
class ReportsViewModel : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString periodType READ periodType WRITE setPeriodType NOTIFY periodTypeChanged)
    Q_PROPERTY(QDate startDate READ startDate WRITE setStartDate NOTIFY startDateChanged)
    Q_PROPERTY(QDate endDate READ endDate WRITE setEndDate NOTIFY endDateChanged)
    Q_PROPERTY(QVariantMap summary READ summary NOTIFY summaryChanged)
    Q_PROPERTY(QVariantList salesHistory READ salesHistory NOTIFY salesHistoryChanged)
    Q_PROPERTY(bool isLoading READ isLoading NOTIFY isLoadingChanged)

public:
    explicit ReportsViewModel(QObject *parent = nullptr);

    // Getters
    QString periodType() const { return m_periodType; }
    QDate startDate() const { return m_startDate; }
    QDate endDate() const { return m_endDate; }
    QVariantMap summary() const { return m_summary; }
    QVariantList salesHistory() const { return m_salesHistory; }
    bool isLoading() const { return m_isLoading; }

    // Setters
    void setPeriodType(const QString& type);
    void setStartDate(const QDate& date);
    void setEndDate(const QDate& date);

public slots:
    /**
     * @brief Cargar reporte según el período seleccionado
     */
    Q_INVOKABLE void loadReport();

    /**
     * @brief Establecer período rápido (hoy, esta semana, este mes, este año)
     */
    Q_INVOKABLE void setQuickPeriod(const QString& period);

    /**
     * @brief Exportar reporte a PDF
     */
    Q_INVOKABLE void exportToPdf(const QString& filePath);

    /**
     * @brief Obtener datos para gráfico de ventas por día
     */
    Q_INVOKABLE QVariantList getChartData();

signals:
    void periodTypeChanged();
    void startDateChanged();
    void endDateChanged();
    void summaryChanged();
    void salesHistoryChanged();
    void isLoadingChanged();
    void errorOccurred(const QString& message);
    void reportGenerated(const QString& message);

private:
    QString m_periodType;      // "daily", "weekly", "monthly", "yearly", "custom"
    QDate m_startDate;
    QDate m_endDate;
    QVariantMap m_summary;
    QVariantList m_salesHistory;
    bool m_isLoading;

    void setIsLoading(bool loading);
    void calculateSummary();
    void loadSalesHistory();
};

#endif // REPORTSVIEWMODEL_H
