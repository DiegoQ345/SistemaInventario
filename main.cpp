#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQmlContext>
#include <QIcon>
#include <QFile>
#include <QTextStream>
#include <QDateTime>
#include <QMessageLogContext>
#include "src/database/DatabaseManager.h"
#include "src/services/AuthenticationService.h"
#include "src/services/NotificationService.h"
#include "src/services/PrintService.h"
#include "src/viewmodels/DashboardViewModel.h"
#include "src/viewmodels/TicketDesignerViewModel.h"
#include "src/viewmodels/ProductListModel.h"
#include "src/viewmodels/UserListModel.h"
#include "src/viewmodels/SalesCartViewModel.h"
#include "src/viewmodels/CustomerListModel.h"
#include "src/viewmodels/CustomerFormViewModel.h"
#include "src/viewmodels/PrintViewModel.h"
#include "src/viewmodels/ExcelImportViewModel.h"
#include "src/viewmodels/ReportsViewModel.h"
#include "src/utils/BarcodeScannerHandler.h"
#include "src/repositories/TicketTemplateRepository.h"

// ─── Handler de logs: escribe a archivo ANTES de que el proceso muera ─────────
void customMessageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    // Escribir a archivo en la carpeta del ejecutable
    QFile logFile("crash_log.txt");
    if (logFile.open(QIODevice::Append | QIODevice::Text)) {
        QTextStream out(&logFile);
        QString timestamp = QDateTime::currentDateTime().toString("hh:mm:ss.zzz");

        switch (type) {
        case QtDebugMsg:    out << timestamp << " [DEBUG] "; break;
        case QtInfoMsg:     out << timestamp << " [INFO]  "; break;
        case QtWarningMsg:  out << timestamp << " [WARN]  "; break;
        case QtCriticalMsg: out << timestamp << " [CRIT]  "; break;
        case QtFatalMsg:    out << timestamp << " [FATAL] "; break;
        }

        out << msg;
        if (context.file) out << "  (" << context.file << ":" << context.line << ")";
        out << "\n";
        logFile.close();
    }

    // También imprimir en stderr para que Qt Creator lo siga mostrando
    QTextStream(stderr) << msg << "\n";

    if (type == QtFatalMsg) abort();
}
// ─────────────────────────────────────────────────────────────────────────────

int main(int argc, char *argv[])
{
    // Instalar handler ANTES de cualquier otra cosa
    qInstallMessageHandler(customMessageHandler);

    // Limpiar log anterior al iniciar
    QFile::remove("crash_log.txt");

    // Configuración de aplicación
    QApplication app(argc, argv);

    app.setOrganizationName("SistemaInventario");
    app.setOrganizationDomain("sistemainventario.com");
    app.setApplicationName("Sistema de Inventario");
    app.setApplicationVersion("1.0.0");

    // Configurar ícono de la aplicación
    QIcon appIcon;
    appIcon.addFile(":/resources/logo.png");
    appIcon.addFile(":/resources/favicon-32x32.png", QSize(32, 32));
    appIcon.addFile(":/resources/android-chrome-192x192.png", QSize(192, 192));
    appIcon.addFile(":/resources/android-chrome-512x512.png", QSize(512, 512));
    app.setWindowIcon(appIcon);

    // Aplicar estilo Material Design
    QQuickStyle::setStyle("Material");

    qDebug() << "=== Inicializando Sistema de Inventario ===";

    // Inicializar base de datos
    qDebug() << "Inicializando base de datos...";
    DatabaseManager& db = DatabaseManager::instance();
    if (!db.initialize()) {
        qCritical() << "Error inicializando base de datos:" << db.lastError();
        qCritical() << "La aplicación continuará con funcionalidad limitada";
    } else {
        qDebug() << "✓ Base de datos inicializada correctamente";
    }

    // Registrar tipos QML
    qmlRegisterType<DashboardViewModel>      ("SistemaInventario", 1, 0, "DashboardViewModel");
    qmlRegisterType<TicketDesignerViewModel> ("SistemaInventario", 1, 0, "TicketDesignerViewModel");
    qmlRegisterType<ProductListModel>        ("SistemaInventario", 1, 0, "ProductListModel");
    qmlRegisterType<UserListModel>           ("SistemaInventario", 1, 0, "UserListModel");
    qmlRegisterType<SalesCartViewModel>      ("SistemaInventario", 1, 0, "SalesCartViewModel");
    qmlRegisterType<CartItemModel>           ("SistemaInventario", 1, 0, "CartItemModel");
    qmlRegisterType<CustomerListModel>       ("SistemaInventario", 1, 0, "CustomerListModel");
    qmlRegisterType<CustomerFormViewModel>   ("SistemaInventario", 1, 0, "CustomerFormViewModel");
    qmlRegisterType<PrintViewModel>          ("SistemaInventario", 1, 0, "PrintViewModel");
    qmlRegisterType<PrintService>            ("SistemaInventario", 1, 0, "PrintService");
    qmlRegisterType<ExcelImportViewModel>    ("SistemaInventario", 1, 0, "ExcelImportViewModel");
    qmlRegisterType<ReportsViewModel>        ("SistemaInventario", 1, 0, "ReportsViewModel");
    qmlRegisterType<BarcodeScannerHandler>   ("SistemaInventario", 1, 0, "BarcodeScannerHandler");
    qmlRegisterType<TicketTemplateRepository>("SistemaInventario", 1, 0, "TicketTemplateRepository");

    // Crear motor QML
    QQmlApplicationEngine engine;

    // Exponer servicios singleton a QML
    engine.rootContext()->setContextProperty("authService",        &AuthenticationService::instance());
    engine.rootContext()->setContextProperty("notificationService",&NotificationService::instance());
    engine.rootContext()->setContextProperty("databaseManager",    &DatabaseManager::instance());

    // Manejar errores de carga QML
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() {
            qCritical() << "Error: No se pudo cargar la interfaz QML";
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
        );

    // Cargar QML principal
    engine.loadFromModule("SistemaInventario", "Main");

    if (engine.rootObjects().isEmpty()) {
        qCritical() << "Error: No se pudo crear la ventana principal";
        return -1;
    }

    qDebug() << "=== Sistema iniciado correctamente ===";

    return app.exec();
}
