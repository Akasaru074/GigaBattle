#include "gamenetworkmanager.h"
#include <QJsonDocument>
#include <QDebug>

GameNetworkManager::GameNetworkManager(QObject *parent) : QObject(parent)
{
    // Подключаем внутренние сигналы сокета к нашим слотам
    connect(&m_webSocket, &QWebSocket::connected, this, &GameNetworkManager::onConnected);
    connect(&m_webSocket, &QWebSocket::textMessageReceived, this, &GameNetworkManager::onTextMessageReceived);
}

void GameNetworkManager::connectToServer(const QString &url)
{
    m_webSocket.open(QUrl(url));
}

void GameNetworkManager::onConnected()
{
    emit connected();
}

/*
 * Разбирает все входящие JSON-сообщения от сервера.
 * В зависимости от поля "type", мы определяем, что произошло (подключение, выстрел, результат),
 * и отправляем соответствующий сигнал в QML для обновления интерфейса.
 */
void GameNetworkManager::onTextMessageReceived(QString message)
{
    QJsonDocument doc = QJsonDocument::fromJson(message.toUtf8());
    QJsonObject obj = doc.object();
    QString type = obj["type"].toString();

    if (type == "CREATED") {
        emit gameCreated(obj["sessionId"].toString());
    }
    else if (type == "JOINED_SUCCESS") {
        emit gameJoined();
    }
    else if (type == "OPPONENT_JOINED") {
        emit opponentJoined();
    }
    else if (type == "OPPONENT_LEFT") {
        emit opponentLeft();
    }
    else if (type == "READY") {
        emit opponentReady();
    }
    else if (type == "FIRE") {
        emit incomingFire(obj["x"].toInt(), obj["y"].toInt());
    }
    else if (type == "RESULT") {
        emit incomingResult(obj["x"].toInt(), obj["y"].toInt(),
                            obj["isHit"].toBool(), obj["isKill"].toBool(), obj["isGameOver"].toBool());
    }
    else if (type == "ERROR") {
        emit errorOccurred(obj["message"].toString());
    }
}

// --- Методы отправки (API для QML) ---

void GameNetworkManager::createGame()
{
    QJsonObject json;
    json["type"] = "CREATE";
    sendJson(json);
}

void GameNetworkManager::joinGame(const QString &sessionId)
{
    QJsonObject json;
    json["type"] = "JOIN";
    json["sessionId"] = sessionId;
    sendJson(json);
}

void GameNetworkManager::fire(int x, int y)
{
    QJsonObject json;
    json["type"] = "FIRE";
    json["x"] = x;
    json["y"] = y;
    sendJson(json);
}

void GameNetworkManager::sendHitResult(int x, int y, bool isHit, bool isKill, bool isGameOver)
{
    QJsonObject json;
    json["type"] = "RESULT";
    json["x"] = x;
    json["y"] = y;
    json["isHit"] = isHit;
    json["isKill"] = isKill;
    json["isGameOver"] = isGameOver;
    sendJson(json);
}

void GameNetworkManager::sendJson(const QJsonObject &json)
{
    QJsonDocument doc(json);
    m_webSocket.sendTextMessage(QString::fromUtf8(doc.toJson(QJsonDocument::Compact)));
}

void GameNetworkManager::sendReady()
{
    QJsonObject json;
    json["type"] = "READY";
    sendJson(json);
}
