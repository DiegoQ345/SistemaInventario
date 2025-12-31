#ifndef BARCODESCANNERHANDLER_H
#define BARCODESCANNERHANDLER_H

#include <QObject>
#include <QString>
#include <QTimer>
#include <qqml.h>

/**
 * @brief Manejador de lectores de código de barras
 * 
 * Los lectores de código de barras generalmente emulan un teclado,
 * enviando los caracteres del código seguidos de Enter.
 * 
 * Este handler detecta y procesa estos eventos.
 */
class BarcodeScannerHandler : public QObject
{
    Q_OBJECT
    // QML_ELEMENT - Registrado manualmente en main.cpp

    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(int timeout READ timeout WRITE setTimeout NOTIFY timeoutChanged)

public:
    explicit BarcodeScannerHandler(QObject *parent = nullptr);

    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);

    int timeout() const { return m_timeout; }
    void setTimeout(int timeout);

    /**
     * @brief Procesar caracter recibido
     * @param character Caracter del código de barras
     */
    Q_INVOKABLE void processCharacter(const QString& character);

    /**
     * @brief Simular escaneo (para testing)
     */
    Q_INVOKABLE void simulateScan(const QString& barcode);

signals:
    /**
     * @brief Emitido cuando se escanea un código de barras completo
     */
    void barcodeScanned(const QString& barcode);

    void enabledChanged();
    void timeoutChanged();

private slots:
    void onTimeout();

private:
    bool m_enabled = true;
    int m_timeout = 100;  // ms entre caracteres
    QString m_buffer;
    QTimer* m_timer;

    void reset();
};

#endif // BARCODESCANNERHANDLER_H
