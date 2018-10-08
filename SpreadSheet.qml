import QtQuick 2.10
import QtQuick.Controls 2.3
import QtQuick.Controls.Material 2.1


FocusScope {

    id: spreadSheet

    property var spreadSheetModel: defaultSpreadSheetModel
    property int headerHeight: spreadSheetModel.fontSize*2.3
    property var columnWidthList: spreadSheetModel.columnWidthList

    property color primaryColor: Material.color(Material.Blue)
    property color colorShade100: Material.color(Material.Blue, Material.Shade100)
    property color colorShade700: Material.color(Material.Blue, Material.Shade700)

    property int _leftContentWidth: 0
    property int _rightContentWidth: 0
    property var _leftColumnSum: []
    property var _rightColumnSum: []

    onColumnWidthListChanged: {
        _leftContentWidth = 0
        _rightContentWidth = 0
        _leftColumnSum = []
        _rightColumnSum = []
        var sum = 0;
        for (var i=0; i<columnWidthList.length; i++) {
            if (i===spreadSheetModel.leftColumnCount) sum = 0;
            sum+=columnWidthList[i]

            if (i<spreadSheetModel.leftColumnCount) {
                _leftContentWidth+=columnWidthList[i]
                _leftColumnSum[i]=sum
            }
            else {
                _rightContentWidth+=columnWidthList[i]
                _rightColumnSum[i-spreadSheetModel.leftColumnCount]=sum
            }

        }
        rightTable.contentX = rightHeaderRow.contentX
    }


    focus: true

    property int _selectedColumn: -1
    property bool _editionInProgress: textFieldEditor.visible || comboBoxEditor.visible

    Rectangle {
        anchors.fill: parent
        color: spreadSheet.primaryColor

    }

    Item {

        id: leftSpreadSheet
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: _leftContentWidth
        visible: width > 0

        HeaderRow {
            id: leftHeaderRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            columnWidth: spreadSheetModel.columnWidthList.slice(0, spreadSheetModel.leftColumnCount)
            sortEnabledColumnList: spreadSheetModel.sortEnabledColumnList.slice(0, spreadSheetModel.leftColumnCount)
            model: spreadSheetModel.columnNameList.slice(0, spreadSheetModel.leftColumnCount)
            height: spreadSheet.headerHeight
            onSortByColumn: spreadSheetModel.sortByColumn(index, asc)
        }

        SpreadSheetTable {
            id: leftTable

            tableId: 0
            anchors.top: leftHeaderRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            ScrollBar.vertical: ScrollBar {
                id: leftVerticalScrollBar
                parent: leftTable.parent
                anchors.top: leftTable.top
                anchors.horizontalCenter: leftTable.right
                anchors.bottom: leftTable.bottom
            }

            model: spreadSheetModel
            columnCount: spreadSheetModel.leftColumnCount
            columnWidth: spreadSheetModel.columnWidthList.slice(0, spreadSheetModel.leftColumnCount)
            contentWidth: parent.width
            firstIndex: 0

            onContentYChanged: { // sync both tables
                if (leftTable.movingVertically || leftVerticalScrollBar.pressed) rightTable.contentY = leftTable.contentY
            }
            onCurrentIndexChanged: {
                rightTable.currentIndex = leftTable.currentIndex
            }

        }

        HeaderMouseArea {
            id: leftHeaderMouseArea
            anchors.fill: leftHeaderRow

            columnWidthSum: _leftColumnSum
            columnWidthList: spreadSheetModel.columnWidthList.slice(0, spreadSheetModel.leftColumnCount)
            resizableColumnList: spreadSheetModel.resizableColumnList.slice(0, spreadSheetModel.leftColumnCount)

            onWidthChangeRequest: spreadSheetModel.setColumnWidth(index, width)
        }

    }

    Item {

        id: rightSpreadSheet

        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.left: leftSpreadSheet.right
        anchors.leftMargin: 3

        width: _rightContentWidth

        HeaderRow {
            id: rightHeaderRow
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            columnWidth: spreadSheetModel.columnWidthList.slice(spreadSheetModel.leftColumnCount)
            sortEnabledColumnList: spreadSheetModel.sortEnabledColumnList.slice(spreadSheetModel.leftColumnCount)
            height: spreadSheet.headerHeight
            model: spreadSheetModel.columnNameList.slice(spreadSheetModel.leftColumnCount)
            onSortByColumn: spreadSheetModel.sortByColumn(index, asc)
            onContentXChanged: {
                if (rightHeaderRow.movingHorizontally) rightTable.contentX = rightHeaderRow.contentX
            }

        }

        SpreadSheetTable {
            id: rightTable

            tableId: 1
            anchors.top: rightHeaderRow.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            flickableDirection: Flickable.AutoFlickIfNeeded

            ScrollBar.horizontal: ScrollBar {
                id: rightHorizontalScrollBar
                parent: rightTable.parent
                anchors.bottom: rightTable.bottom
                anchors.left: rightTable.left
                anchors.right: rightTable.right
            }

            model: spreadSheetModel
            columnCount: spreadSheetModel.tableColumnCount-spreadSheetModel.leftColumnCount
            firstIndex: spreadSheetModel.leftColumnCount
            columnWidth: spreadSheetModel.columnWidthList.slice(spreadSheetModel.leftColumnCount)
            contentWidth: _rightContentWidth

            onContentYChanged: { // sync both tables
                if (rightTable.movingVertically) leftTable.contentY = rightTable.contentY
            }
            onContentXChanged: { // sync with header
                if (rightTable.movingHorizontally  || rightHorizontalScrollBar.pressed) rightHeaderRow.contentX = rightTable.contentX
            }
            onCurrentIndexChanged: {
                leftTable.currentIndex = rightTable.currentIndex
            }

        }

        HeaderMouseArea {
            id: rightHeaderMouseArea
            anchors.fill: rightHeaderRow

            xShift: rightHeaderRow.contentX

            columnWidthSum: _rightColumnSum
            columnWidthList: spreadSheetModel.columnWidthList.slice(spreadSheetModel.leftColumnCount)
            resizableColumnList: spreadSheetModel.resizableColumnList.slice(spreadSheetModel.leftColumnCount)

            onWidthChangeRequest: {
                var xcontent = rightTable.contentX
                spreadSheetModel.setColumnWidth(index+spreadSheetModel.leftColumnCount, width)
                rightTable.contentX = xcontent
                rightHeaderRow.contentX = rightTable.contentX

            }

        }

    }


    Rectangle {
        color: Material.primary
        opacity: 0.25
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        x: leftHeaderMouseArea.borderX>-1?leftHeaderMouseArea.borderX:rightHeaderMouseArea.borderX>0?rightHeaderMouseArea.borderX+rightSpreadSheet.x:rightSpreadSheet.x
        width: leftHeaderMouseArea.cursorX>-1?(leftHeaderMouseArea.cursorX-leftHeaderMouseArea.borderX):rightHeaderMouseArea.borderX>0?rightHeaderMouseArea.cursorX-rightHeaderMouseArea.borderX:rightHeaderMouseArea.cursorX
        visible: leftHeaderMouseArea.cursorX>-1 || rightHeaderMouseArea.cursorX>-1

        Rectangle {
            color: "black"
            width: 1
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right

        }

    }

    Rectangle {
        id: textFieldEditor
        visible: false
        color: spreadSheet.colorShade100

        property int rowIndex: -1
        property int columnIndex: -1
        property alias text: textField.text

        onVisibleChanged: {
            if (textFieldEditor.visible) textField.forceActiveFocus()
        }

        TextField {
            id: textField
            anchors.fill: parent
            padding: 5
            selectByMouse: true
            font.pixelSize: spreadSheetModel.fontSize
            onAccepted: {
                textFieldEditor.visible = false
                spreadSheetModel.requestTextChange(textFieldEditor.rowIndex,
                                                 textFieldEditor.columnIndex,
                                                 textField.displayText)
            }

            Keys.onEscapePressed: {
                abortEditor()
            }

        }

    }

    Rectangle {
        id: comboBoxEditor

        property alias model: comboBox.model
        property alias currentIndex: comboBox.currentIndex
        property int rowIndex: -1
        property int columnIndex: -1

        visible: false
        color: "white"

        onVisibleChanged: {
            if (comboBoxEditor.visible) {
                comboBox.forceActiveFocus()

            }
        }

        ComboBox {
            id: comboBox
            anchors.fill: parent
            font.pixelSize: spreadSheetModel.fontSize
            popup.onClosed: {

                spreadSheetModel.requestComboIndexChange(comboBoxEditor.rowIndex,
                                               comboBoxEditor.columnIndex,
                                               comboBox.currentIndex)
            }

        }

    }


    function popupTextFieldEditor(table, x, y, width, height,
                                  rowIndex, columnIndex, text) {
        textFieldEditor.x = table*leftSpreadSheet.width+x+2
        textFieldEditor.y = y+headerHeight+4
        textFieldEditor.width = width
        textFieldEditor.height = height
        textFieldEditor.visible = true
        textFieldEditor.rowIndex = rowIndex
        textFieldEditor.columnIndex = columnIndex
        textFieldEditor.text = text

    }

    function popupComboBoxEditor(table, x, y, width, height, model,
                                 rowIndex, columnIndex, currentIndex) {

        comboBoxEditor.x = table*leftSpreadSheet.width+x
        comboBoxEditor.y = y+headerHeight
        comboBoxEditor.width = width
        comboBoxEditor.height = height
        comboBoxEditor.visible = true
        comboBoxEditor.model = model
        comboBoxEditor.rowIndex = rowIndex
        comboBoxEditor.columnIndex = columnIndex
        comboBoxEditor.currentIndex = currentIndex
    }

    function abortEditor() {
        textFieldEditor.visible = false
        comboBoxEditor.visible = false

    }

    Item {
        id: defaultSpreadSheetModel

        property int fontSize: 18
        property var columnWidthList: [150, 150, 150]

    }


}

