cmake_minimum_required(VERSION 3.16)

project(GigaBattle VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick WebSockets Network)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appGigaBattle
    main.cpp
)

qt_add_qml_module(appGigaBattle
    URI GigaBattle
    VERSION 1.0
    QML_FILES
        Main.qml
        SOURCES gamenetworkmanager.h gamenetworkmanager.cpp
        QML_FILES CellGrid.qml
        RESOURCES README.md
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appGigaBattle PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appGigaBattle
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appGigaBattle PRIVATE
    Qt6::Quick
    Qt6::WebSockets
    Qt6::Network
)

include(GNUInstallDirs)
install(TARGETS appGigaBattle
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
