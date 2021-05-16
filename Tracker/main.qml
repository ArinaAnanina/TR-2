import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.0

Window {
    id: window
    width: 800
    height: 500
    visible: true
    color: "#ffffff"
    title: qsTr("Hello World")
    flags: Qt.FramelessWindowHint | Qt.Window // убирается верхняя рамка окна
    property var onNodeClicked: (index) => { // функция, запускающаяся при нажатии на один из узлов графа
        console.log('onNodeClicked', index);
        window.currentResult = window.calculatePath(index);
        window.calculatedNode = index;
        textTracResult.text = window.resultText();
        textLenghtResult.text = window.resultLength();
        canvas.requestPaint();
    }
    property var calculatePath: (index) => { // нахождение траектории коммивояжера
        console.log('calculatePath', index, window.links);
        const result = [];
        const U_LINK = -1;

        let path = window.links.map(row => row.map((cell) => cell === 0 ? U_LINK : cell)); //скопировали матрицу

        let count = 0;
        while(result.length < window.nodesCount && count < window.nodesCount) {
            const rates = new Array(window.links.length).fill(0).map(() => new Array(window.links.length).fill(0));
            path = path.map(row => {
                const min = Math.min(...row.filter(cell => cell !== U_LINK));
                return row.map(cell => cell === U_LINK ? U_LINK : cell - min);
            });
            for (let i = 0; i < path.length; i++) {
                let min;
                for (let j = 0; j < path[i].length; j++) {
                    if(path[j][i] === U_LINK) {
                        continue;
                    }
                    if(min === undefined || path[j][i] < min) {
                        min = path[j][i];
                    }
                }
                if (!min) {
                   continue;
                }

                for (let j = 0; j < path[i].length; j++) {
                    if(path[j][i] === U_LINK) {
                        continue;
                    }
                    path[j][i] = path[j][i] - min;
                }
            }
            let pathHasZeros = false;
            path.forEach((row, rowI) => {
                 row.forEach((cell, colI) => {
                    if (cell !== 0) {
                        return;
                    }
                    pathHasZeros = true;
                    let minCol;
                    let minRow;
                    for (let j = 0; j < path.length; j++) {
                        if (path[rowI][j] !== U_LINK && j !== colI && (minRow > path[rowI][j] || !minRow)) {
                            minRow = path[rowI][j];
                        }
                        if (path[j][colI] !== U_LINK && j !== rowI && (minCol > path[j][colI] || !minCol)) {
                            minCol = path[j][colI];
                        }
                    }
                    rates[rowI][colI] += !minRow ? 0 : minRow;
                    rates[rowI][colI] += !minCol ? 0 : minCol;
                 });
            });

            let max = 0;
            let maxI = 0;
            let maxJ = 0;
            rates.forEach((row, rowI) => {
                row.forEach((cell, colI) => {
                    if (max <= cell) {
                        max = cell;
                        maxI = rowI;
                        maxJ = colI;
                    }
                });
            });

            path.forEach((row, rowI) => {
                 row.forEach((cell, colI) => {
                    if (max === 0 && cell !== U_LINK) {
                         let inRowCount = 0;
                         let inColCount = 0;
                         for (let i = 0; i < row.length; i++) {
                             if (path[rowI][i] >= 0) {
                                 inRowCount++;
                             }
                             if (path[i][colI] >= 0) {
                                 inColCount++;
                             }
                         }
                         if (inRowCount === 1 || inColCount === 1) {
                             result.push([rowI, colI]);
                         }
                    }

                    if (rowI === maxI || colI === maxJ || rowI === maxJ && colI === maxI) {
                        row[colI] = U_LINK;
                    }
                 });
            });
            if (max !== 0) {
                result.push([maxI, maxJ]);
            }
            path.forEach((i) => console.log(i));
            count++;
        }
        console.log(result);
        return result.length === 7 ? result : false;
    }
    property var calcX: (index) => { //подсчёт координаты x
        return nodesContainer.width / 2 + Math.cos(rep.th * index) * nodesContainer.containerRadius;
    }
    property var calcY: (index) => { //подсёт координаты y
        return nodesContainer.width / 2 + Math.sin(rep.th * index) * nodesContainer.containerRadius;
    }
    property var isHighlightedLink: (i1, i2) => {
        if (!window.currentResult || !window.currentResult.length) {
            return false;
        }
        return !!window.currentResult.find(i => i[0] === i1 && i[1] === i2 || i[1] === i1 && i[0] === i2);
    }
    property var resultText: () => {
        let res = [window.calculatedNode - 1];
        while (true) {
             const nextPath = window.currentResult.find(i => i[0] === res[res.length-1]);
             if (!nextPath) {
                break;
             }
             res.push(nextPath[1]);
             if (res[0] === res[res.length-1]) {
                break;
             }
        }
        for (var i =0;i<8;i++)
        {
               res[i]++;
        }
        // [1, 2, 3, 4] => join(", ") => "1, 2, 3, 4"
        return res.join(">");
    }
    property var resultLength: () => {
        let result1 = 0;
        for (let l = 0; l <= 6; l++)
        {
             result1 += window.links[window.currentResult[l][0]][window.currentResult[l][1]];
        }
        return result1;
    }
    property var currentResult;
    property int nodeRadius: 20
    property int nodesCount: 7
    property int calculatedNode;
    property var nodes: [3, 1, 7, 6, 4, 2, 5]
    property var links: [[0, 42, 19 , 0, 0, 0, 12 ],
                         [42, 0, 0, 23, 19, 0, 0 ],
                         [19, 0, 0, 0, 34, 30, 0 ],
                         [0, 23, 0, 0, 0, 9, 0 ],
                         [0, 19, 34, 0, 0, 0, 47 ],
                         [0, 0, 30, 9, 0, 0, 26 ],
                         [12, 0, 0, 0, 47, 26, 0 ]]

    property real th: 2 * 3.1415926 / nodesCount

    Rectangle {
        id: nodesContainer
        width: 453 //window.width
        height: 425 //window.height
        property int containerRadius: 160
        x: 339
        y: 45
        Canvas {
            id: canvas
            x: 0
            y: 0
            width: nodesContainer.width
            height: nodesContainer.height
            onPaint: {
                const ctx = getContext('2d');
                const drawLinesGroup = (group, color, width = 2) => {
                    ctx.lineWidth = width;
                    ctx.strokeStyle = color;
                    ctx.beginPath();
                    group.forEach((item) => {
                      ctx.moveTo(item[0], item[1]);
                      ctx.lineTo(item[2], item[3]);
                    });
                    ctx.stroke();
                };

                const hLines = [];
                const bLines = [];
                const gLines = [];
                for (let i = 0; i < window.links.length; i++) {
                    for (let j = i + 1; j < window.links[i].length; j++) {
                        const _i = nodes.findIndex(item => item === i + 1);
                        const _j = nodes.findIndex(item => item === j + 1); // получеие индекса узла из массива nodes
                        if (window.links[i][j] === 0 && window.links[j][i] === 0) {
                            hLines.push([calcX(_i), calcY(_i), calcX(_j), calcY(_j)]);
                            continue;
                        }

                        if (window.isHighlightedLink(i, j)) {
                            gLines.push([calcX(_i), calcY(_i), calcX(_j), calcY(_j)]);
                            continue;
                        }

                        bLines.push([calcX(_i), calcY(_i), calcX(_j), calcY(_j)]);
                    }
                }

                ctx.clearRect(0, 0, canvas.width, canvas.height);//очистка линий
                drawLinesGroup(hLines, 'rgba(0, 0, 0, 0.15)', 2);
                drawLinesGroup(bLines, 'rgba(0, 0, 0, 0.8)', 4);
                drawLinesGroup(gLines, '#fccfea', 6);
            }
        }
        Repeater {
            id: rep
            model: nodesCount
            property real th: 2 * 3.1415926 / model
            Rectangle {
                id: nodeRect
                property int radiusVal: window.nodeRadius
                width: radiusVal * 2
                height: radiusVal * 2
                x: calcX(index)
                y: calcY(index)
                color: window.calculatedNode === window.nodes[index] ? "#f790ce" : "black"
                border.color: "black"
                border.width: 0
                radius: radiusVal
                transform: Translate {
                    x: -1 * radiusVal
                    y: -1 * radiusVal
                }
                TapHandler {
                    onSingleTapped: window.onNodeClicked(window.nodes[index]) // при нажатии
                }
                Text {
                    id: nodeText
                    x: 0
                    y: 0
                    width: nodeRect.radiusVal * 2
                    height: nodeRect.radiusVal * 2
                    color: "white"
                    text: window.nodes[index]
                    font.pixelSize: 20
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

    }

    Rectangle {
        x: 90
        y: 107
        Repeater {
            id: tableRep
            x: 0
            y: 0
            width: 224
            height: 250
            model: nodesCount
            Repeater {
                id: rowRep
                model: nodesCount
                property int rowIndex: index;
                TextField {
                    id: textField
                    x: (index) * 32
                    y: (rowIndex) * 36
                    width: 31
                    height: 34
                    text: window.links[rowIndex][index]
                    font.pointSize: 9
                    opacity: index === rowIndex ? 0 : 1
                    onTextEdited: {
                        window.links[rowIndex][index] = (+text);
                    }
                }
            }

        }
        Repeater {
            id: diagRep
            model: nodesCount
            Text {
                id: diagText
                x: (index) * 32
                y: -34
                width: 31
                height: 34
                color: "#000000"
                text: index + 1
                font.pixelSize: 19
                font.family: "Courier"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.bold: true
            }
        }
        Repeater {
            id: diagRep2
            model: nodesCount
            Text {
                id: diagText2
                x: -32
                y: (index)*36
                width: 31
                height: 34
                color: "#000000"
                text: index + 1
                font.pixelSize: 19
                font.family: "Courier"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.bold: true
            }
        }
    }

    Text {
        id: textTrac
        x: 31
        y: 395
        width: 145
        height: 30
        opacity: 0.745
        color: "#060606"
        text: qsTr("Траектория :")
        font.pixelSize: 21
        styleColor: "#392525"
        font.family: "Courier"
    }

    Text {
        id: textTracResult
        x: 186
        y: 395
        width: 145
        height: 30
        opacity: 0.745
        color: "#060606"
        font.pixelSize: 21
        styleColor: "#222"
        font.family: "Courier"
    }

    Text {
        id: textLenght
        x: 31
        y: 440
        width: 145
        height: 30
        opacity: 0.745
        color: "#060606"
        text: qsTr("Длина пути :")
        font.pixelSize: 21
        font.family: "Courier"
        styleColor: "#392525"
    }

    Text {
        id: textLenghtResult
        x: 186
        y: 440
        width: 145
        height: 30
        opacity: 0.745
        color: "#060606"
        font.pixelSize: 21
        styleColor: "#222"
        font.family: "Courier"
    }

    ToolBar {
        id: toolBar
        x: 0
        y: 0
        width: window.width
        height: 24

        visible: true
        background: Rectangle {
            color: "#000"
            opacity: 0.5
        }
        ToolButton {
            x: 0
            y: 0
            width: window.width - 64
            height: 24
            background: Rectangle {
                opacity: 0
            }
            Text {
                width: window.width - 64
                height: 24
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: "#fff"
                font.pixelSize: 14
                text: 'App by Ananina A.'
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 0
                anchors.bottomMargin: 0
                anchors.leftMargin: 0
                anchors.topMargin: 0
                property real lastMouseX: 0
                property real lastMouseY: 0
                onPressed: {
                    lastMouseX = mouseX
                    lastMouseY = mouseY
                }
                onMouseXChanged: window.x += (mouseX - lastMouseX)
                onMouseYChanged: window.y += (mouseY - lastMouseY)
            }
        }
        ToolButton {
            id: _button
            x: window.width - 64
            y: 0
            width: 32
            height: 24
            background: _ButtonBG
            onHoveredChanged: hovered ? _ButtonBG.opacity = 1 : _ButtonBG.opacity = 0
            onClicked: window.showMinimized()
            Rectangle {
                id: _ButtonBG
                color: "#fddff1"
                opacity: 0
            }
            Image {
                id: _ButtonImage
                source: "_.png"
                opacity: 0.8
            }
        }
        ToolButton {
            id: xButton
            x: window.width - 32
            y: 0
            width: 32
            height: 24
            background: xButtonBG
            onHoveredChanged: hovered ? xButtonBG.opacity = 1 : xButtonBG.opacity = 0
            onClicked: window.close()
            Rectangle {
                id: xButtonBG
                color: "#b72f00"
                opacity: 0
            }

            Image {
                id: xButtonImage
                source: "x.png"
                opacity: 0.8
            }
        }
    }
}


