#include "PrintService.h"
#include <QApplication>
#include <QFont>
#include <QFontMetrics>
#include <QDateTime>
#include <QPrinterInfo>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

PrintService::PrintService(QObject *parent)
    : QObject(parent)
{
}

bool PrintService::printVoucher(const Sale& sale, VoucherType type, const InvoiceData& invoiceData)
{
    emit printStarted();

    QPrinter printer(QPrinter::HighResolution);
    printer.setPageSize(QPageSize::A4);
    printer.setPageOrientation(QPageLayout::Portrait);

    if (!m_defaultPrinter.isEmpty()) {
        printer.setPrinterName(m_defaultPrinter);
    }
    else {
        QPrinterInfo defaultPrinter = QPrinterInfo::defaultPrinter();
        if (defaultPrinter.isNull()) {
            emit printFailed("No hay impresora configurada");
            return false;
        }
        printer.setPrinterName(defaultPrinter.printerName());
    }

    QPainter painter;
    if (!painter.begin(&printer)) {
        emit printFailed("Error iniciando impresion");
        return false;
    }

    painter.setRenderHint(QPainter::Antialiasing, true);
    painter.setRenderHint(QPainter::TextAntialiasing, true);
    painter.setRenderHint(QPainter::SmoothPixmapTransform, true);

    drawVoucherA4(painter, sale, type, invoiceData);

    painter.end();
    emit printCompleted();
    return true;
}

bool PrintService::showPrintPreview(const Sale& sale, VoucherType type, const InvoiceData& invoiceData)
{
    return printVoucher(sale, type, invoiceData);
}

bool PrintService::printTicket(const Sale& sale, VoucherType type, const InvoiceData& invoiceData)
{
    emit printStarted();

    QPrinter printer(QPrinter::HighResolution);
    printer.setPageSize(QPageSize(QSizeF(80, 200), QPageSize::Millimeter));
    printer.setPageOrientation(QPageLayout::Portrait);
    printer.setPageMargins(QMarginsF(2, 2, 2, 2), QPageLayout::Millimeter);

    if (!m_defaultPrinter.isEmpty()) {
        printer.setPrinterName(m_defaultPrinter);
    }

    QPainter painter;
    if (!painter.begin(&printer)) {
        emit printFailed("Error iniciando impresion de ticket");
        return false;
    }

    painter.setRenderHint(QPainter::Antialiasing, true);
    painter.setRenderHint(QPainter::TextAntialiasing, true);

    drawTicket(painter, sale, type, invoiceData);

    painter.end();
    emit printCompleted();
    return true;
}
