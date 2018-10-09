#include "spreadsheet.h"
#include <QQmlEngine>
#include <QDebug>

SpreadSheet::SpreadSheet(): QAbstractListModel ()
{
    QQmlEngine::setObjectOwnership(this, QQmlEngine::CppOwnership);
    setColumnList(1, QStringList(), QList<double>());
}

SpreadSheet::~SpreadSheet() { }

void SpreadSheet::setColumnList(int columnCount, const QStringList &columnNameList, const QList<double>& columnWidthList, int leftColumnCount) {
    if (columnCount<1) {
        qWarning() << "Number of columns out of range: " << columnCount;
        return;
    }
    beginResetModel();
    _columnCount = columnCount;
    _readOnlyColumnSet.clear();
    _checkableColumnSet.clear();
    _columnComboModel.clear();
    _columnTextAlignment.clear();
    _actionColumnSet.clear();
    _resizableColumn.clear();
    _hiddenColumnSet.clear();

    _columnNameList = columnNameList.mid(0, _columnCount); // truncate if too long
    for (int c=_columnNameList.count(); c<_columnCount; c++) _columnNameList << QString("%0").arg(QChar('A'+c)); // append if too short

    _columnWidthList = columnWidthList.mid(0, _columnCount);
    for (int c=_columnWidthList.count(); c<_columnCount; c++) _columnWidthList << 150; // append if too short

    _leftColumnCount = leftColumnCount;
    if (_leftColumnCount<0 || _leftColumnCount>_columnCount-1) _leftColumnCount = 0;
    emit columnListChanged();
    emit tableColumnCountChanged();
    endResetModel();

}

void SpreadSheet::setColumnName(int index, const QString& name) {
    if (index<0 || index>=_columnCount) return;
    QString str = name;
    if (name.isEmpty()) str = QString("%0").arg(QChar('A'+index));
    _columnNameList[index] = str;
    emit columnListChanged();

}

void SpreadSheet::setColumnWidth(int index, double width) {  // width as multiple of fontsize
    if (index<0 || index>=_columnWidthList.count()) return;
    if (width<2) return; // limit at 2
    _columnWidthList[index] = width;
    //beginResetModel();
    emit columnListChanged();
    //endResetModel();
}

void SpreadSheet::setColumnVisible(int index, bool visible) {
    if (index<0 || index>=_columnWidthList.count()) return;
    if (visible) _hiddenColumnSet.remove(index);
    else _hiddenColumnSet.insert(index);
    beginResetModel();
    emit columnListChanged();
    endResetModel();
}

void SpreadSheet::setResizableColumn(int index, bool resizable) {
    _resizableColumn.insert(index, resizable);
    emit columnListChanged();
}

void SpreadSheet::setSortEnabledColumn(int index, bool sortEnabled) {
    _sortEnabledColumn.insert(index, sortEnabled);
    emit columnListChanged();
}

void SpreadSheet::setColumnBgColor(int index, const QString &color) {
    _columnBgColor.insert(index, color);
}

void SpreadSheet::setCheckableColumn(int index) {
    _checkableColumnSet.insert(index);
}

void SpreadSheet::setReadOnlyColumn(int index) {
    _readOnlyColumnSet.insert(index);
}

void SpreadSheet::setActionColumn(int index) {
    _actionColumnSet.insert(index);
}

void SpreadSheet::setComboModelForColumn(int index, const QStringList &comboModel) {
    _columnComboModel.insert(index, comboModel);
}

void SpreadSheet::setTextAlignmentForColumn(int index, int alignment) {
    _columnTextAlignment.insert(index, alignment);
}

QList<double> SpreadSheet::columnWidthList() const {
    QList<double> list;
    for (int i=0; i<_columnCount; i++) {
        if (_hiddenColumnSet.contains(i)) list << 0; else list << _columnWidthList.value(i);
    }
    return list;
}

QList<bool> SpreadSheet::resizableColumnList() const {
    QList<bool> list;
    for (int i=0; i<_columnCount; i++) list << _resizableColumn.value(i, true);
    return list;
}

QList<bool> SpreadSheet::sortEnabledColumnList() const {
    QList<bool> list;
    for (int i=0; i<_columnCount; i++) list << _sortEnabledColumn.value(i, true);
    return list;
}


QHash<int, QByteArray> SpreadSheet::roleNames() const {
    QHash<int, QByteArray> hash;
    hash.insert(textList, "textList");
    hash.insert(readOnlyList, "readOnlyList");
    hash.insert(actionList, "actionList");
    hash.insert(textAlignmentList, "textAlignmentList");
    hash.insert(checkedList, "checkedList");
    hash.insert(comboIndexList, "comboIndexList");
    hash.insert(comboModelList, "comboModelList");
    hash.insert(checkableList, "checkableList");
    hash.insert(bgColorList, "bgColorList");

    return hash;
}


void SpreadSheet::rowUpdated(int rowIndex) {
    emit dataChanged(createIndex(rowIndex, 0), createIndex(rowIndex, 0));
}

int SpreadSheet::rowCount(const QModelIndex &parent) const {
    return rowCount();
}


QVariant SpreadSheet::data(const QModelIndex &index, int role) const {

    switch (role) {

        case textList: {
            QStringList list;
            for (int i=0; i<_columnCount; i++) list << text(index.row(), i);
            return QVariant(list);
        }
        case readOnlyList: {
            QVariantList list;
            for (int i=0; i<_columnCount; i++) list << QVariant(readOnly(index.row(), i));
            return QVariant(list);
        }
        case actionList: {
            QVariantList list;
            for (int i=0; i<_columnCount; i++) list << QVariant(action(index.row(), i));
            return QVariant(list);
        }
        case comboIndexList: {
            QVariantList list;
            for (int i=0; i<_columnCount; i++) list << QVariant(comboIndex(index.row(), i));
            return QVariant(list);
        }
        case comboModelList: {
            QVariantList list;
            for (int i=0; i<_columnCount; i++) list << QVariant(comboModel(index.row(), i));
            return QVariant(list);
        }
        case checkableList: {
            QVariantList list;
            for (int i=0; i<_columnCount; i++) list << QVariant(checkable(index.row(), i));
            return QVariant(list);
        }
        case checkedList: {
            QVariantList list;
            for (int i=0; i<_columnCount; i++) list << QVariant(checked(index.row(), i));
            return QVariant(list);
        }
        case textAlignmentList: {
            QVariantList list;
            for (int i=0; i<_columnCount; i++) list << QVariant(textAlignment(index.row(), i));
            return QVariant(list);
        }
        case bgColorList: {
            QStringList list;
            for (int i=0; i<_columnCount; i++) {
                QString color = bgColor(index.row(), i);
                if (color.isEmpty()) color = _columnBgColor.value(i);
                list << color;
            }
            return QVariant(list);
        }

        default: return QVariant();
    }

}

void SpreadSheet::requestCheckedChange(int rowIndex, int columnIndex, bool checked) {
    RowModel* row = internalRow(rowIndex);
    row->checkedMap.insert(columnIndex, checked);
    rowUpdated(rowIndex);
}

void SpreadSheet::requestComboIndexChange(int rowIndex, int columnIndex, int index) {
    RowModel* row = internalRow(rowIndex);
    row->comboIndexMap.insert(columnIndex, index);
    rowUpdated(rowIndex);
}

void SpreadSheet::requestTextChange(int rowIndex, int columnIndex, const QString& text) {
    RowModel* row = internalRow(rowIndex);
    row->textMap.insert(columnIndex, text);
    rowUpdated(rowIndex);
}

void SpreadSheet::requestAction(int rowIndex, int columnIndex) {
    qDebug() << "Requesting action for cell " << (rowIndex+1) << ":" << (columnIndex+1);
}


QString SpreadSheet::text(int rowIndex, int columnIndex) const {
    RowModel* row = _internalModel.value(rowIndex, nullptr);
    if (row==nullptr) return QString();
    return row->textMap.value(columnIndex, QString());
}

QString SpreadSheet::bgColor(int rowIndex, int columnIndex) const {
    return QString();
}

int SpreadSheet::comboIndex(int rowIndex, int columnIndex) const {
    RowModel* row = _internalModel.value(rowIndex, nullptr);
    if (row==nullptr) return 0;
    return row->comboIndexMap.value(columnIndex, 0);
}

int SpreadSheet::textAlignment(int rowIndex, int columnIndex) const {
    return _columnTextAlignment.value(columnIndex, 0);
}

QStringList SpreadSheet::comboModel(int rowIndex, int columnIndex) const {
    return _columnComboModel.value(columnIndex);
}

bool SpreadSheet::readOnly(int rowIndex, int columnIndex) const {
    return _readOnlyColumnSet.contains(columnIndex);
}

bool SpreadSheet::action(int rowIndex, int columnIndex) const {
    return _actionColumnSet.contains(columnIndex);
}

bool SpreadSheet::checkable(int rowIndex, int columnIndex) const {
    return _checkableColumnSet.contains(columnIndex);
}

bool SpreadSheet::checked(int rowIndex, int columnIndex) const {
    RowModel* row = _internalModel.value(rowIndex, nullptr);
    if (row==nullptr) return false;
    return row->checkedMap.value(columnIndex, false);
}

void SpreadSheet::sortByColumn(int index, bool asc) {
    qDebug() << "Sorting by column is not implemented by subclass";
}

SpreadSheet::RowModel* SpreadSheet::internalRow(int rowIndex) {
    RowModel* row = _internalModel.value(rowIndex, nullptr);
    if (row==nullptr) {
        row = new RowModel();
        _internalModel.insert(rowIndex, row);
    }
    return row;
}
