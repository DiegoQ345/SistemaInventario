cmake_minimum_required(VERSION 3.16)

project(SistemaInventario VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Encontrar paquetes Qt necesarios
find_package(Qt6 REQUIRED COMPONENTS 
    Core
    Quick
    QuickControls2
    Sql
    PrintSupport
    Widgets
    Gui
)

# QXlsx requiere GuiPrivate en Qt 6.10+
if(Qt6Gui_VERSION VERSION_GREATER_EQUAL "6.10.0")
    find_package(Qt6 REQUIRED COMPONENTS GuiPrivate)
endif()

qt_standard_project_setup(REQUIRES 6.8)

# ============================================
# COMPILAR QXLSX COMO SUBDIRECTORIO
# ============================================
add_subdirectory(external/QXlsx/QXlsx)

# ============================================
# ARCHIVOS QML
# ============================================
set(QML_FILES
    Main.qml
    qml/pages/LoginPage.qml
    qml/pages/DashboardPage.qml
    qml/pages/ProductsPage.qml
    qml/pages/SalesPage.qml
    qml/pages/InventoryPage.qml
    qml/pages/CustomersPage.qml
    qml/pages/ReportsPage.qml
    qml/pages/ImportPage.qml
    qml/pages/SettingsPage.qml
    qml/pages/ConsolePage.qml
    qml/pages/TicketsPage.qml
    
    # Componentes reutilizables
    qml/components/CartItemDelegate.qml
    qml/components/NotificationBar.qml
    qml/components/PrimaryButton.qml
    qml/components/SecondaryButton.qml
    qml/components/OutlinedButton.qml
    qml/components/SearchField.qml
    qml/components/QuantitySpinBox.qml
    qml/components/ConfirmDialog.qml
    qml/components/ErrorDialog.qml
    qml/components/SuccessDialog.qml
    qml/components/StyledGroupBox.qml
    qml/components/StatCard.qml
    qml/components/Badge.qml
    qml/components/LoadingSpinner.qml
    
    # Diálogos de ventas
    qml/components/dialogs/SaleSuccessDialog.qml
    qml/components/dialogs/SaleErrorDialog.qml
    qml/components/dialogs/PrintDialog.qml
    qml/components/dialogs/PrinterSettingsDialog.qml
)

# ============================================
# ARCHIVOS C++ (actualmente comentados para compilación básica)
# ============================================
set(HEADER_FILES
    src/database/DatabaseManager.h
    src/models/Product.h
    src/models/Sale.h
    src/models/Customer.h
    src/models/StockMovement.h
    src/models/User.h
    src/repositories/ProductRepository.h
    src/repositories/SaleRepository.h
    src/repositories/CustomerRepository.h
    src/repositories/UserRepository.h
    src/repositories/TicketTemplateRepository.h
    src/services/ProductService.h
    src/services/SalesService.h
    src/services/ExcelImportService.h
    src/services/PdfGeneratorService.h
    src/services/PrintService.h
    src/services/AuthenticationService.h
    src/services/NotificationService.h
    src/printing/TicketLayout.h
    src/printing/TicketRenderer.h
    src/printing/TicketDynamicSection.h
    src/viewmodels/DashboardViewModel.h
    src/viewmodels/ProductListModel.h
    src/viewmodels/SalesCartViewModel.h
    src/viewmodels/CustomerListModel.h
    src/viewmodels/CustomerFormViewModel.h
    src/viewmodels/PrintViewModel.h
    src/viewmodels/ExcelImportViewModel.h
    src/viewmodels/ReportsViewModel.h
    src/utils/BarcodeScannerHandler.h
)

set(SOURCE_FILES
    src/database/DatabaseManager.cpp
    src/repositories/ProductRepository.cpp
    src/repositories/SaleRepository.cpp
    src/repositories/CustomerRepository.cpp
    src/repositories/UserRepository.cpp
    src/repositories/TicketTemplateRepository.cpp
    src/services/ProductService.cpp
    src/services/SalesService.cpp
    src/services/ExcelImportService.cpp
    src/services/PdfGeneratorService.cpp
    src/services/PrintService.cpp
    src/services/AuthenticationService.cpp
    src/services/NotificationService.cpp
    src/printing/TicketLayout.cpp
    src/printing/TicketRenderer.cpp
    src/printing/TicketDynamicSection.cpp
    src/viewmodels/DashboardViewModel.cpp
    src/viewmodels/ProductListModel.cpp
    src/viewmodels/SalesCartViewModel.cpp
    src/viewmodels/CustomerListModel.cpp
    src/viewmodels/CustomerFormViewModel.cpp
    src/viewmodels/PrintViewModel.cpp
    src/viewmodels/ExcelImportViewModel.cpp
    src/viewmodels/ReportsViewModel.cpp
    src/utils/BarcodeScannerHandler.cpp
)

# ============================================
# CREAR EJECUTABLE
# ============================================
# Compilando backend completo con QXlsx
qt_add_executable(appSistemaInventario
    main.cpp
    ${SOURCE_FILES}
    ${HEADER_FILES}
)

# ============================================
# MÓDULO QML
# ============================================
qt_add_qml_module(appSistemaInventario
    URI SistemaInventario
    VERSION 1.0
    QML_FILES ${QML_FILES}
    # NO agregar SOURCES aquí - causará errores de moc
)

# ============================================
# RECURSOS (imágenes, iconos, etc.)
# ============================================
qt_add_resources(appSistemaInventario "recursos"
    PREFIX "/"
    FILES
        resources/logo.png
        resources/background.png
        qtquickcontrols2.conf
)

# ============================================
# NOTA IMPORTANTE SOBRE HEADERS
# ============================================
# Los headers NO se incluyen aquí porque Qt intentará procesarlos con moc
# aunque no estén compilados. Esto causa errores si tienen dependencias
# externas como QXlsx.
# 
# Los headers serán visibles en Qt Creator cuando se compilen los .cpp
# correspondientes descomentando ${SOURCE_FILES} arriba.
#
# Si necesitas verlos en Qt Creator sin compilar, ábrelos manualmente
# desde el explorador de archivos.

# Propiedades del ejecutable
set_target_properties(appSistemaInventario PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE  # TRUE para distribución sin consola
)

# Agregar directorios de include de QXlsx
target_include_directories(appSistemaInventario PRIVATE
    ${CMAKE_SOURCE_DIR}/external/QXlsx/QXlsx/header
)

# Enlazar librerías Qt y QXlsx
target_link_libraries(appSistemaInventario
    PRIVATE 
        Qt6::Core
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Sql
        Qt6::PrintSupport
        Qt6::Widgets
        Qt6::Gui
        QXlsx::QXlsx  # Biblioteca QXlsx compilada como subdirectorio
)

# Enlazar GuiPrivate si es necesario (Qt 6.10+)
if(Qt6Gui_VERSION VERSION_GREATER_EQUAL "6.10.0")
    target_link_libraries(appSistemaInventario PRIVATE Qt6::GuiPrivate)
endif()

# Instalación
include(GNUInstallDirs)
install(TARGETS appSistemaInventario
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
