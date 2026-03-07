#include "CustomerFormViewModel.h"
#include "../repositories/CustomerRepository.h"
#include "../database/DatabaseManager.h"
#include <QDebug>

CustomerFormViewModel::CustomerFormViewModel(QObject *parent)
    : QObject(parent)
{
    m_repository = new CustomerRepository(DatabaseManager::instance().database(), this);
}

CustomerFormViewModel::~CustomerFormViewModel()
{
    // m_repository se elimina automáticamente por QObject parent
}

void CustomerFormViewModel::setName(const QString& name)
{
    if (m_customer.name != name) {
        m_customer.name = name;
        emit nameChanged();
    }
}

void CustomerFormViewModel::setDocumentType(const QString& type)
{
    if (m_customer.documentType != type) {
        m_customer.documentType = type;
        emit documentTypeChanged();
    }
}

void CustomerFormViewModel::setDocumentNumber(const QString& number)
{
    if (m_customer.documentNumber != number) {
        m_customer.documentNumber = number;
        emit documentNumberChanged();
    }
}

void CustomerFormViewModel::setEmail(const QString& email)
{
    if (m_customer.email != email) {
        m_customer.email = email;
        emit emailChanged();
    }
}

void CustomerFormViewModel::setPhone(const QString& phone)
{
    if (m_customer.phone != phone) {
        m_customer.phone = phone;
        emit phoneChanged();
    }
}

void CustomerFormViewModel::setAddress(const QString& address)
{
    if (m_customer.address != address) {
        m_customer.address = address;
        emit addressChanged();
    }
}

void CustomerFormViewModel::setCreditLimit(double limit)
{
    if (qAbs(m_customer.creditLimit - limit) > 0.001) {
        m_customer.creditLimit = limit;
        emit creditLimitChanged();
    }
}

void CustomerFormViewModel::loadCustomer(int customerId)
{
    auto customer = m_repository->findById(customerId);
    if (customer) {
        m_customer = *customer;
        emit nameChanged();
        emit documentTypeChanged();
        emit documentNumberChanged();
        emit emailChanged();
        emit phoneChanged();
        emit addressChanged();
        emit creditLimitChanged();
        emit currentDebtChanged();
        emit isEditModeChanged();
    }
}

void CustomerFormViewModel::clear()
{
    m_customer = Customer();
    emit nameChanged();
    emit documentTypeChanged();
    emit documentNumberChanged();
    emit emailChanged();
    emit phoneChanged();
    emit addressChanged();
    emit creditLimitChanged();
    emit currentDebtChanged();
    emit isEditModeChanged();
}

bool CustomerFormViewModel::save()
{
    if (!validate()) {
        return false;
    }

    if (isEditMode()) {
        if (m_repository->update(m_customer)) {
            emit saved();
            return true;
        }
    } else {
        auto result = m_repository->create(m_customer);
        if (result) {
            m_customer = *result;
            emit saved();
            return true;
        }
    }

    emit errorOccurred(m_repository->lastError());
    return false;
}

bool CustomerFormViewModel::validate()
{
    if (m_customer.name.trimmed().isEmpty()) {
        emit errorOccurred("El nombre es obligatorio");
        return false;
    }

    return true;
}
