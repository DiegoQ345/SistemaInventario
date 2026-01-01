#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include "src/database/DatabaseManager.h"
#include "src/viewmodels/DashboardViewModel.h"
#include "src/viewmodels/ProductListModel.h"
#include "src/viewmodels/SalesCartViewModel.h"
#include "src/viewmodels/PrintViewModel.h"
#include "src/viewmodels/ExcelImportViewModel.h"
#include "src/utils/BarcodeScannerHandler.h"

int main(int argc, char *argv[])
{
    // Configuración de aplicación - Usar QApplication para soporte de impresión
    QApplication app(argc, argv);
    
    app.setOrganizationName("SistemaInventario");
    app.setOrganizationDomain("sistemainventario.com");
    app.setApplicationName("Sistema de Inventario");
    app.setApplicationVersion("1.0.0");

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

    // Registrar tipos QML manualmente
    qmlRegisterType<DashboardViewModel>("SistemaInventario", 1, 0, "DashboardViewModel");
    qmlRegisterType<ProductListModel>("SistemaInventario", 1, 0, "ProductListModel");
    qmlRegisterType<SalesCartViewModel>("SistemaInventario", 1, 0, "SalesCartViewModel");
    qmlRegisterType<CartItemModel>("SistemaInventario", 1, 0, "CartItemModel");
    qmlRegisterType<PrintViewModel>("SistemaInventario", 1, 0, "PrintViewModel");
    qmlRegisterType<ExcelImportViewModel>("SistemaInventario", 1, 0, "ExcelImportViewModel");
    qmlRegisterType<BarcodeScannerHandler>("SistemaInventario", 1, 0, "BarcodeScannerHandler");

    // Crear motor QML
    QQmlApplicationEngine engine;

    // Manejar errores de carga de QML
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
