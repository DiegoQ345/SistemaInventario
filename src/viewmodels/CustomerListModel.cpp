#include "CustomerListModel.h"
#include "../repositories/CustomerRepository.h"
#include "../database/DatabaseManager.h"
#include <QDebug>

CustomerListModel::CustomerListModel(QObject *parent)
    : QAbstractListModel(parent)
{
    m_repository = new CustomerRepository(DatabaseManager::instance().database(), this);
    refresh();
}

CustomerListModel::~CustomerListModel()
{
    // m_repository se elimina automáticamente por QObject parent
}

int CustomerListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_customers.size();
}

QVariant CustomerListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_customers.size())
        return QVariant();

    const Customer& customer = m_customers[index.row()];

    switch (role) {
    case IdRole:
        return customer.id;
    case NameRole:
        return customer.name;
    case DocumentTypeRole:
        return customer.documentType;
    case DocumentNumberRole:
        return customer.documentNumber;
    case EmailRole:
        return customer.email;
    case PhoneRole:
        return customer.phone;
    case AddressRole:
        return customer.address;
    case DisplayNameRole:
        return customer.displayName();
    default:
        return QVariant();
    }
}

QHash<int, QByteArray> CustomerListModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "customerId";
    roles[NameRole] = "customerName";
    roles[DocumentTypeRole] = "documentType";
    roles[DocumentNumberRole] = "documentNumber";
    roles[EmailRole] = "email";
    roles[PhoneRole] = "phone";
    roles[AddressRole] = "address";
    roles[DisplayNameRole] = "displayName";
    return roles;
}

void CustomerListModel::refresh()
{
    setCustomers(m_repository->findAll());
}

void CustomerListModel::search(const QString& searchTerm)
{
    if (searchTerm.trimmed().isEmpty()) {
        refresh();
    } else {
        setCustomers(m_repository->search(searchTerm));
    }
}

QVariantMap CustomerListModel::get(int index) const
{
    QVariantMap map;
    if (index < 0 || index >= m_customers.size())
        return map;

    const Customer& customer = m_customers[index];
    map["customerId"] = customer.id;
    map["customerName"] = customer.name;
    map["documentType"] = customer.documentType;
    map["documentNumber"] = customer.documentNumber;
    map["email"] = customer.email;
    map["phone"] = customer.phone;
    map["address"] = customer.address;

    return map;
}

bool CustomerListModel::remove(int customerId)
{
    if (m_repository->deleteById(customerId)) {
        refresh();
        return true;
    }
    
    emit errorOccurred(m_repository->lastError());
    return false;
}

void CustomerListModel::setCustomers(const QList<Customer>& customers)
{
    beginResetModel();
    m_customers = customers;
    endResetModel();
    emit countChanged();
}
