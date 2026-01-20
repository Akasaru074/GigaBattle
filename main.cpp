#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "gamenetworkmanager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    GameNetworkManager networkManager;

    engine.rootContext()->setContextProperty("network", &networkManager);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("GigaBattle", "Main");

    return app.exec();
}
