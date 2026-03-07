#ifndef CUSTOMERFORMVIEWMODEL_H
#define CUSTOMERFORMVIEWMODEL_H

#include <QObject>
#include "../models/Customer.h"

class CustomerRepository;

/**
 * @brief ViewModel para formulario de clientes
 */
class CustomerFormViewModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString documentType READ documentType WRITE setDocumentType NOTIFY documentTypeChanged)
    Q_PROPERTY(QString documentNumber READ documentNumber WRITE setDocumentNumber NOTIFY documentNumberChanged)
    Q_PROPERTY(QString email READ email WRITE setEmail NOTIFY emailChanged)
    Q_PROPERTY(QString phone READ phone WRITE setPhone NOTIFY phoneChanged)
    Q_PROPERTY(QString address READ address WRITE setAddress NOTIFY addressChanged)
    Q_PROPERTY(double creditLimit READ creditLimit WRITE setCreditLimit NOTIFY creditLimitChanged)
    Q_PROPERTY(double currentDebt READ currentDebt NOTIFY currentDebtChanged)
    Q_PROPERTY(bool isEditMode READ isEditMode NOTIFY isEditModeChanged)

public:
    explicit CustomerFormViewModel(QObject *parent = nullptr);
    ~CustomerFormViewModel() override;

    QString name() const { return m_customer.name; }
    QString documentType() const { return m_customer.documentType; }
    QString documentNumber() const { return m_customer.documentNumber; }
    QString email() const { return m_customer.email; }
    QString phone() const { return m_customer.phone; }
    QString address() const { return m_customer.address; }
    double creditLimit() const { return m_customer.creditLimit; }
    double currentDebt() const { return m_customer.currentDebt; }
    bool isEditMode() const { return m_customer.id > 0; }

    void setName(const QString& name);
    void setDocumentType(const QString& type);
    void setDocumentNumber(const QString& number);
    void setEmail(const QString& email);
    void setPhone(const QString& phone);
    void setAddress(const QString& address);
    void setCreditLimit(double limit);

    Q_INVOKABLE void loadCustomer(int customerId);
    Q_INVOKABLE void clear();
    Q_INVOKABLE bool save();
    Q_INVOKABLE bool validate();

signals:
    void nameChanged();
    void documentTypeChanged();
    void documentNumberChanged();
    void emailChanged();
    void phoneChanged();
    void addressChanged();
    void creditLimitChanged();
    void currentDebtChanged();
    void isEditModeChanged();
    void saved();
    void errorOccurred(const QString& message);

private:
    CustomerRepository* m_repository;
    Customer m_customer;
};

#endif // CUSTOMERFORMVIEWMODEL_H
