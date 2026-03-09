#ifndef CUSTOMERLISTMODEL_H
#define CUSTOMERLISTMODEL_H

#include <QAbstractListModel>
#include <QDate>
#include "../models/Customer.h"

class CustomerRepository;
class Sale;

/**
 * @brief Modelo de lista de clientes para QML
 */
class CustomerListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum CustomerRoles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        DocumentTypeRole,
        DocumentNumberRole,
        EmailRole,
        PhoneRole,
        AddressRole,
        DisplayNameRole,
        TotalPurchasesRole,
        TotalSpentRole,
        LastPurchaseDateRole,
        DisplayNameWithStatsRole,
        CreditLimitRole,
        CurrentDebtRole,
        AvailableCreditRole
    };

    explicit CustomerListModel(QObject *parent = nullptr);
    ~CustomerListModel() override;

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void search(const QString& searchTerm);
    Q_INVOKABLE QVariantMap get(int index) const;
    Q_INVOKABLE bool remove(int customerId);
    Q_INVOKABLE bool generatePurchaseHistoryPdf(int customerId, const QString& outputPath);
    Q_INVOKABLE bool generateCustomerReport(int customerId, const QString& format, const QString& reportType);
    Q_INVOKABLE QVariantList getCustomerSales(int customerId, const QDate& fromDate = QDate(), const QDate& toDate = QDate());
    Q_INVOKABLE int payCustomerDebts(int customerId);
    Q_INVOKABLE bool paySingleDebt(int saleId);

signals:
    void countChanged();
    void errorOccurred(const QString& message);

private:
    CustomerRepository* m_repository;
    QList<Customer> m_customers;

    void setCustomers(const QList<Customer>& customers);
    bool generateExcelReport(const Customer& customer, const QList<Sale>& sales, 
                            const QString& outputPath, const QString& reportType);
};

#endif // CUSTOMERLISTMODEL_H
