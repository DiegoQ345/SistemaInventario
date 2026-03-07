import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import SistemaInventario

/**
 * @brief Selector simple de clientes con búsqueda integrada
 * ComboBox estándar que funciona con clic y Tab
 */
ColumnLayout {
    id: root
    spacing: 8
    
    // Propiedades públicas
    property int selectedCustomerId: -1
    property string selectedCustomerName: ""
    property string selectedDocumentNumber: ""
    property string selectedAddress: ""
    property alias searchText: searchField.text
    property alias model: customerModel
    
    // Señales
    signal customerSelected(int customerId, string customerName, string documentNumber, string address)
    signal customerCleared()
    
    // Función pública para limpiar selección
    function clearSelection() {
        comboBox.currentIndex = -1
        searchField.text = ""
        selectedCustomerId = -1
        selectedCustomerName = ""
        selectedDocumentNumber = ""
        selectedAddress = ""
        customerModel.refresh()
        customerCleared()
    }
    
    // Campo de búsqueda
    TextField {
        id: searchField
        Layout.fillWidth: true
        Layout.preferredHeight: 42
        placeholderText: qsTr("Buscar cliente por nombre o documento...")
        
        leftPadding: 40
        
        Label {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "\uE721"  // Icono búsqueda
            font.family: "Segoe MDL2 Assets"
            font.pixelSize: 16
            color: Material.accentColor
        }
        
        onTextChanged: {
            if (text.length > 0) {
                customerModel.search(text)
            } else {
                customerModel.refresh()
            }
            // Si hay búsqueda activa, resetear combobox para evitar confusión
            if (text.length > 0 && comboBox.currentIndex >= 0) {
                comboBox.currentIndex = -1
            }
        }
        
        // Al presionar Enter, seleccionar primer resultado si existe
        Keys.onReturnPressed: {
            if (customerModel.count > 0) {
                comboBox.currentIndex = 0
                comboBox.activated(0)
            }
        }
        Keys.onEnterPressed: Keys.onReturnPressed(event)
        
        // Flecha abajo: mover foco al combobox
        Keys.onDownPressed: {
            comboBox.forceActiveFocus()
            if (customerModel.count > 0) {
                comboBox.currentIndex = 0
            }
        }
    }
    
    // ComboBox simple NO editable
    ComboBox {
        id: comboBox
        Layout.fillWidth: true
        Layout.preferredHeight: 48
        
        model: CustomerListModel {
            id: customerModel
            Component.onCompleted: refresh()
        }
        
        textRole: "displayName"
        valueRole: "customerId"
        
        displayText: selectedCustomerId > 0 ? 
                    "\uE77B  " + selectedCustomerName : 
                    "\uE77B  Seleccionar cliente..."
        
        font.family: "Segoe MDL2 Assets"
        
        // NO editable - solo selección
        editable: false
        
        // Manejo de selección con clic o Tab+Enter
        onActivated: function(index) {
            if (index >= 0) {
                var customer = customerModel.get(index)
                selectedCustomerId = customer.customerId
                selectedCustomerName = customer.customerName
                selectedDocumentNumber = customer.documentNumber || ""
                selectedAddress = customer.address || ""
                
                // Limpiar búsqueda tras selección
                searchField.text = ""
                customerModel.refresh()
                
                customerSelected(selectedCustomerId, selectedCustomerName, selectedDocumentNumber, selectedAddress)
                
                console.log("✅ Cliente seleccionado:", selectedCustomerId, selectedCustomerName, "Doc:", selectedDocumentNumber)
            }
        }
        
        // También manejar cuando cambia currentIndex (ej: con teclado/Tab)
        onCurrentIndexChanged: {
            if (currentIndex >= 0 && activeFocus) {
                Qt.callLater(function() {
                    activated(currentIndex)
                })
            }
        }
        
        // Delegado con información del cliente
        delegate: ItemDelegate {
            width: comboBox.popup.width
            height: 60
            
            contentItem: ColumnLayout {
                spacing: 2
                
                Label {
                    Layout.fillWidth: true
                    text: model.displayName
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: Material.primaryTextColor
                    elide: Text.ElideRight
                }
                
                Label {
                    Layout.fillWidth: true
                    text: model.documentNumber ? "Doc: " + model.documentNumber : "Sin documento"
                    font.pixelSize: 11
                    color: Material.secondaryTextColor
                    elide: Text.ElideRight
                }
                
                // Estadísticas de compras
                Label {
                    visible: model.totalPurchases > 0
                    text: "🛒 " + model.totalPurchases + " compras • S/ " + model.totalSpent.toFixed(2)
                    font.pixelSize: 11
                    color: Material.color(Material.Green)
                }
            }
            
            highlighted: comboBox.highlightedIndex === index
            
            background: Rectangle {
                color: parent.highlighted ? Material.listHighlightColor : "transparent"
            }
        }
        
        popup: Popup {
            y: comboBox.height + 2
            width: comboBox.width
            implicitHeight: Math.min(contentItem.implicitHeight + 10, 350)
            padding: 5
            
            Material.elevation: 8
            
            background: Rectangle {
                color: Material.dialogColor
                border.color: Material.frameColor
                border.width: 1
                radius: 4
            }
            
            contentItem: ListView {
                clip: true
                implicitHeight: contentHeight
                model: comboBox.popup.visible ? comboBox.delegateModel : null
                currentIndex: comboBox.highlightedIndex
                
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
                
                // Header con contador
                header: Rectangle {
                    width: parent ? parent.width : 0
                    height: 35
                    color: Material.theme === Material.Dark ? 
                           Qt.darker(Material.dialogColor, 1.1) : 
                           Material.color(Material.Grey, Material.Shade100)
                    
                    Label {
                        anchors.centerIn: parent
                        text: customerModel.count + " cliente" + (customerModel.count !== 1 ? "s" : "")
                        font.pixelSize: 11
                        color: Material.secondaryTextColor
                    }
                }
            }
        }
    }
}
