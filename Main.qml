import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

Window {
    width: 800
    height: 600
    visible: true
    title: qsTr("Sea Battle - Qt Quick")

    // --- СОСТОЯНИЕ ИГРЫ ---
    property string currentScreen: "MENU"
    property string sessionId: ""
    property bool myTurn: false
    property string statusText: "Добро пожаловать"

    // 0=вода, 1=корабль, 2=мимо, 3=попал
    property var myBoard: []
    property var enemyBoard: []

    // --- ЛОГИКА СЕТИ ---
    Connections {
        target: network

        function onConnected() { statusText = "Сервер подключен"; }

        function onGameCreated(id) {
            sessionId = id
            currentScreen = "LOBBY"
            statusText = "ID сессии: " + id + ". Ждем игрока..."
            myTurn = true
            initializeBoards()
        }

        function onGameJoined() {
            currentScreen = "GAME"
            statusText = "Вы подключились! Ход противника."
            myTurn = false
            initializeBoards()
        }

        function onOpponentJoined() {
            currentScreen = "GAME"
            statusText = "Игрок найден! Ваш ход."
        }

        /* *
         * Обработка выстрела ПРОТИВНИКА по нам.
         * Проверяет, попал ли враг в наш корабль.
         * Если попал (1) -> меняем на 3 (ранен), отправляем "isHit: true".
         * Если мимо (0) -> меняем на 2 (мимо), отправляем "isHit: false".
         * Если враг попал, мы НЕ меняем myTurn, он продолжает ходить.
         * Если промахнулся - ход переходит к нам.
         */
        function onIncomingFire(x, y) {
            let index = y * 10 + x
            let cellValue = myBoard[index]
            let isHit = (cellValue === 1)

            let newBoard = myBoard.slice()
            newBoard[index] = isHit ? 3 : 2
            myBoard = newBoard

            let isKill = false

            network.sendHitResult(x, y, isHit, isKill)

            if (isHit) {
                statusText = "Противник попал! Он ходит снова."
                myTurn = false
            } else {
                statusText = "Противник промахнулся! Ваш ход."
                myTurn = true
            }
        }

        /*
         * Обработка результата нашего выстрела.
         * Клиент врага ответил, попали мы или нет.
         */
        function onIncomingResult(x, y, isHit, isKill) {
            let index = y * 10 + x
            let newBoard = enemyBoard.slice()

            // 3 - попал, 2 - мимо
            newBoard[index] = isHit ? 3 : 2
            enemyBoard = newBoard

            if (isHit) {
                statusText = "Вы попали! Стреляйте еще."
                myTurn = true
            } else {
                statusText = "Промах. Ход противника."
                myTurn = false
            }
        }
    }

    // --- ИНИЦИАЛИЗАЦИЯ ПОЛЕЙ ---
    function initializeBoards() {
        let empty = []
        for(let i=0; i<100; i++) empty.push(0)
        enemyBoard = empty

        myBoard = placeShipsRandomly()
    }

    function placeShipsRandomly() {
        let board = []
        for(let i=0; i<100; i++) board.push(0)

        let ships = [4, 3, 3, 2, 2, 2, 1, 1, 1, 1]

        for (let size of ships) {
            let placed = false
            while (!placed) {
                let horizontal = Math.random() > 0.5
                let x = Math.floor(Math.random() * 10)
                let y = Math.floor(Math.random() * 10)

                if (canPlace(board, x, y, size, horizontal)) {
                    for(let k=0; k<size; k++) {
                        let idx = horizontal ? y*10 + (x+k) : (y+k)*10 + x
                        board[idx] = 1
                    }
                    placed = true
                }
            }
        }
        return board
    }

    function canPlace(board, x, y, size, hor) {
        if (hor && (x + size > 10)) return false
        if (!hor && (y + size > 10)) return false


        for(let k=0; k<size; k++) {
             let idx = hor ? y*10 + (x+k) : (y+k)*10 + x
             if (board[idx] !== 0) return false
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

        ColumnLayout {
            visible: currentScreen === "MENU"
            Layout.alignment: Qt.AlignCenter
            spacing: 20

            TextField {
                id: serverUrlField
                text: "ws://localhost:3000"
                placeholderText: "Адрес сервера"
                Layout.preferredWidth: 200
            }
            Button {
                text: "Подключиться к серверу"
                onClicked: network.connectToServer(serverUrlField.text)
            }

            Item { height: 20; width: 1 } // Spacer

            Button {
                text: "1. Создать игру"
                onClicked: network.createGame()
            }
            RowLayout {
                TextField { id: joinIdField; placeholderText: "ID сессии" }
                Button {
                    text: "2. Присоединиться"
                    onClicked: network.joinGame(joinIdField.text)
                }
            }
        }

        // ЭКРАН ЛОББИ
        ColumnLayout {
            visible: currentScreen === "LOBBY"
            Layout.alignment: Qt.AlignCenter
            Text { text: "Ожидание второго игрока..." }
            BusyIndicator { running: true }
        }

        // ЭКРАН ИГРЫ
        RowLayout {
            visible: currentScreen === "GAME"
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 20
            spacing: 50

            // Наше поле
            ColumnLayout {
                Text { text: "Мой флот"; font.bold: true }
                CellGrid {
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 300
                    gridData: myBoard
                    interactive: false
                }
            }

            // Поле врага
            ColumnLayout {
                Text { text: "Флот противника"; font.bold: true; color: myTurn ? "green" : "black" }
                CellGrid {
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 300
                    gridData: enemyBoard
                    interactive: myTurn

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
