import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

Window {
    width: 900
    height: 600
    visible: true
    title: qsTr("Giga battle")

    property string currentScreen: "MENU"
    property string sessionId: ""

    property bool isSetupPhase: false
    property bool iAmReady: false
    property bool opponentIsReady: false

    property bool gameStarted: iAmReady && opponentIsReady

    property bool myTurn: false
    property string statusText: "Добро пожаловать"

    property var shipsQueue: [4, 3, 3, 2, 2, 2, 1, 1, 1, 1]
    property bool placeHorizontal: true

    property var myBoard: []
    property var enemyBoard: []

    Connections {
        target: network

        function onConnected() { statusText = "Сервер подключен"; }

        function onGameCreated(id) {
            sessionId = id
            currentScreen = "LOBBY"
            statusText = "ID сессии: " + id + ". Ждем игрока..."
            myTurn = true
        }

        function onGameJoined() {
            currentScreen = "GAME"
            myTurn = false
            startSetupPhase()
        }

        function onOpponentJoined() {
            currentScreen = "GAME"
            startSetupPhase()
        }

        function onOpponentReady() {
            opponentIsReady = true
            checkGameStart()
        }

        function onIncomingFire(x, y) {
            let index = y * 10 + x
            let cellValue = myBoard[index]
            let isHit = (cellValue === 1)
            let newBoard = myBoard.slice()
            newBoard[index] = isHit ? 3 : 2
            myBoard = newBoard
            let gameOver = false
            if (isHit) gameOver = checkLoss()
            network.sendHitResult(x, y, isHit, false, gameOver)
            if (gameOver) {
                statusText = "ВЫ ПРОИГРАЛИ! Все корабли уничтожены."
                myTurn = false
            } else if (isHit) {
                statusText = "Противник попал! Он ходит снова."
                myTurn = false
            } else {
                statusText = "Противник промахнулся! Ваш ход."
                myTurn = true
            }
        }

        function onIncomingResult(x, y, isHit, isKill, isGameOver) {
            let index = y * 10 + x
            let newBoard = enemyBoard.slice()
            newBoard[index] = isHit ? 3 : 2
            enemyBoard = newBoard
            if (isGameOver) {
                statusText = "ПОБЕДА! Вы уничтожили все корабли врага."
                myTurn = false
            } else if (isHit) {
                statusText = "Вы попали! Стреляйте еще."
                myTurn = true
            } else {
                statusText = "Промах. Ход противника."
                myTurn = false
            }
        }
    }

    function checkGameStart() {
        if (gameStarted) {
            isSetupPhase = false
            if (myTurn) statusText = "Все готовы! ВАШ ХОД."
            else statusText = "Все готовы! Ход противника."
        } else {
            if (iAmReady && !opponentIsReady) {
                statusText = "Ожидание готовности соперника..."
            } else if (!iAmReady && opponentIsReady) {
                statusText = "Соперник уже готов! Заканчивайте расстановку."
            }
        }
    }

    function startSetupPhase() {
        let empty = []
        for(let i=0; i<100; i++) empty.push(0)
        myBoard = empty
        enemyBoard = empty.slice()

        shipsQueue = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1]

        isSetupPhase = true
        iAmReady = false
        opponentIsReady = false

        statusText = "Режим расстановки. Нажмите на клетку."
    }

    function tryPlaceShip(x, y) {
        if (shipsQueue.length === 0) return

        let size = shipsQueue[0]

        if (canPlace(myBoard, x, y, size, placeHorizontal)) {
            let newBoard = myBoard.slice()
            for(let k=0; k<size; k++) {
                let idx = placeHorizontal ? y*10 + (x+k) : (y+k)*10 + x
                newBoard[idx] = 1
            }
            myBoard = newBoard

            let newQueue = shipsQueue.slice()
            newQueue.shift()
            shipsQueue = newQueue

            if (shipsQueue.length === 0) {
                iAmReady = true
                network.sendReady()
                checkGameStart()
            }
        }
    }

    function resetShips() { startSetupPhase() }
    function checkLoss() {
        for(let i = 0; i < 100; i++) { if (myBoard[i] === 1) return false; }
        return true;
    }
    function canPlace(board, x, y, size, hor) {
        if (hor && (x + size > 10)) return false
        if (!hor && (y + size > 10)) return false
        let startX = Math.max(0, x - 1)
        let endX = Math.min(9, hor ? x + size : x + 1)
        let startY = Math.max(0, y - 1)
        let endY = Math.min(9, hor ? y + 1 : y + size)
        for (let i = startX; i <= endX; i++) {
            for (let j = startY; j <= endY; j++) {
                if (board[j * 10 + i] !== 0) return false
            }
        }
        return true
    }

    // --- GUI ---
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: statusText
            font.pixelSize: 20
            color: "black"
        }

        // МЕНЮ
        ColumnLayout {
            visible: currentScreen === "MENU"
            Layout.alignment: Qt.AlignCenter
            spacing: 20
            TextField { id: serverUrlField; text: "ws://localhost:3000"; placeholderText: "Адрес сервера"; Layout.preferredWidth: 200 }
            Button { text: "Подключиться к серверу"; onClicked: network.connectToServer(serverUrlField.text) }
            Item { height: 20; width: 1 }
            Button { text: "1. Создать игру"; onClicked: network.createGame() }
            RowLayout {
                TextField { id: joinIdField; placeholderText: "ID сессии" }
                Button { text: "2. Присоединиться"; onClicked: network.joinGame(joinIdField.text) }
            }
        }

        // ЛОББИ
        ColumnLayout {
            visible: currentScreen === "LOBBY"
            Layout.alignment: Qt.AlignCenter
            Text { text: "Ожидание второго игрока..." }
            BusyIndicator { running: true }
        }

        // ИГРА
        RowLayout {
            visible: currentScreen === "GAME"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 20
            spacing: 50

            // МОЕ ПОЛЕ
            ColumnLayout {
                Text { text: "Мой флот"; font.bold: true }
                CellGrid {
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 300
                    gridData: myBoard
                    interactive: isSetupPhase && !iAmReady
                    onCellClicked: (x, y) => { tryPlaceShip(x, y) }
                }

                // ПАНЕЛЬ УПРАВЛЕНИЯ
                ColumnLayout {
                    visible: isSetupPhase && !iAmReady
                    spacing: 5
                    Text { text: shipsQueue.length > 0 ? "Ставим: " + shipsQueue[0] + "-палубный" : "Готово!"; font.bold: true; color: "#D32F2F" }
                    RowLayout {
                        Button { text: placeHorizontal ? "Горизонтально ⮕" : "Вертикально ⬇"; onClicked: placeHorizontal = !placeHorizontal }
                        Button { text: "Сброс"; onClicked: resetShips() }
                    }
                }
            }

            // ПОЛЕ ВРАГА
            ColumnLayout {
                opacity: gameStarted ? 1.0 : 0.3

                Text { text: "Флот противника"; font.bold: true; color: myTurn ? "green" : "black" }
                CellGrid {
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 300
                    gridData: enemyBoard

                    interactive: gameStarted && myTurn

                    onCellClicked: (x, y) => {
                        let idx = y * 10 + x
                        if (enemyBoard[idx] === 0 || enemyBoard[idx] === 1) {
                             network.fire(x, y)
                        }
                    }
                }
            }
        }
    }
}
