cmake_minimum_required(VERSION 3.5)

project(editor VERSION 0.1 LANGUAGES CXX)

add_subdirectory(chrplugin)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Widgets)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Widgets)

set(PROJECT_SOURCES
        main.cpp
        mainwindow.cpp mainwindow.h mainwindow.ui
        canvas.h canvas.cpp
        scene.h scene.cpp
        tileset_explorer.h tileset_explorer.cpp tileset_explorer.ui
        tileset_view.h tileset_view.cpp
        brushtoolpanel.h brushtoolpanel.cpp brushtoolpanel.ui
        state.h state.cpp
)

if(${QT_VERSION_MAJOR} GREATER_EQUAL 6)
    qt_add_executable(editor
        MANUAL_FINALIZATION
        ${PROJECT_SOURCES}
    )
# Define target properties for Android with Qt 6 as:
#    set_property(TARGET editor APPEND PROPERTY QT_ANDROID_PACKAGE_SOURCE_DIR
#                 ${CMAKE_CURRENT_SOURCE_DIR}/android)
# For more information, see https://doc.qt.io/qt-6/qt-add-executable.html#target-creation
else()
    if(ANDROID)
        add_library(editor SHARED
            ${PROJECT_SOURCES}
        )
# Define properties for Android with Qt 5 after find_package() calls as:
#    set(ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
    else()
        add_executable(editor
            ${PROJECT_SOURCES}
        )
    endif()
endif()

target_link_libraries(editor PRIVATE Qt${QT_VERSION_MAJOR}::Widgets)

qt_add_binary_resources(resources resources.qrc)

add_dependencies(editor chrplugin)
add_dependencies(editor resources)

set_target_properties(editor PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

set_target_properties(chrplugin PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY_DEBUG ${CMAKE_BINARY_DIR}/imageformats
    RUNTIME_OUTPUT_DIRECTORY_RELEASE ${CMAKE_BINARY_DIR}/imageformats)

install(TARGETS editor
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})

install(TARGETS chrplugin
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}/imageformats)

if(QT_VERSION_MAJOR EQUAL 6)
    qt_finalize_executable(editor)
endif()
