#ifndef GAMENETWORKMANAGER_H
#define GAMENETWORKMANAGER_H

#include <QObject>
#include <QWebSocket>
#include <QJsonObject>

class GameNetworkManager : public QObject
{
    Q_OBJECT
public:
    explicit GameNetworkManager(QObject *parent = nullptr);

    Q_INVOKABLE void connectToServer(const QString &url);
    Q_INVOKABLE void createGame();
    Q_INVOKABLE void joinGame(const QString &sessionId);
    Q_INVOKABLE void fire(int x, int y);
    Q_INVOKABLE void sendHitResult(int x, int y, bool isHit, bool isKill);

signals:
    void connected();
    void gameCreated(QString sessionId);
    void gameJoined();
    void opponentJoined();
    void opponentLeft();

    void incomingFire(int x, int y);
    void incomingResult(int x, int y, bool isHit, bool isKill);
    void errorOccurred(QString message);

private slots:
    void onConnected();
    void onTextMessageReceived(QString message);

private:
    QWebSocket m_webSocket;
    void sendJson(const QJsonObject &json);
};

#endif // GAMENETWORKMANAGER_H
