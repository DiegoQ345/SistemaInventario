#include "BarcodeScannerHandler.h"
#include <QDebug>

BarcodeScannerHandler::BarcodeScannerHandler(QObject *parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
{
    m_timer->setSingleShot(true);
    connect(m_timer, &QTimer::timeout, this, &BarcodeScannerHandler::onTimeout);
}

void BarcodeScannerHandler::setEnabled(bool enabled)
{
    if (m_enabled != enabled) {
        m_enabled = enabled;
        emit enabledChanged();
        
        if (!enabled) {
            reset();
        }
    }
}

void BarcodeScannerHandler::setTimeout(int timeout)
{
    if (m_timeout != timeout) {
        m_timeout = timeout;
        emit timeoutChanged();
    }
}

void BarcodeScannerHandler::processCharacter(const QString& character)
{
    if (!m_enabled) {
        return;
    }

    // Si es Enter, procesar el código completo
    if (character == "\r" || character == "\n") {
        if (!m_buffer.isEmpty()) {
            qDebug() << "Código de barras escaneado:" << m_buffer;
            emit barcodeScanned(m_buffer);
            reset();
        }
        return;
    }

    // Agregar caracter al buffer
    m_buffer += character;

    // Reiniciar timer (si pasa mucho tiempo, no es un scanner)
    m_timer->start(m_timeout);
}

void BarcodeScannerHandler::simulateScan(const QString& barcode)
{
    qDebug() << "Simulando escaneo de:" << barcode;
    emit barcodeScanned(barcode);
}

void BarcodeScannerHandler::onTimeout()
{
    // Si pasó el timeout, resetear (no es un scanner continuo)
    reset();
}

void BarcodeScannerHandler::reset()
{
    m_buffer.clear();
    m_timer->stop();
}
