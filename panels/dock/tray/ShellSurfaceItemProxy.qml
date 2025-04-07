// SPDX-FileCopyrightText: 2024 UnionTech Software Technology Co., Ltd.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtWayland.Compositor
import org.deepin.ds.dock 1.0

Rectangle {
    id: root
    property var shellSurface: null
    signal surfaceDestroyed()
    property bool autoClose: false
    property bool inputEventsEnabled: true
    property bool hovered: hoverHandler.hovered
    property bool pressed: tapHandler.pressed

    implicitWidth: shellSurface ? shellSurface.width : 10
    implicitHeight: shellSurface ? shellSurface.height : 10
    color: "white"

    ShellSurfaceItem {
        id: impl
        anchors.fill: parent
        width: shellSurface.width
        height: shellSurface.height
        shellSurface: root.shellSurface
        inputEventsEnabled: root.inputEventsEnabled
        smooth: false
        // x: 0.5
        // y: 0.5
        // Image {
        //     source: "file:///tmp/blue-x11@1.25x.png"
        //     width: sourceSize.width / 1.25
        //     height: sourceSize.height / 1.25
        //     smooth: false
        // }
        
        Component.onCompleted: function () {
            console.log("ShellSurfaceItemComponent onCompleted", output?.scaleFactor, root.shellSurface?.width, root.shellSurface?.height, implicitWidth, implicitHeight)
        }

        onImplicitWidthChanged: function () {
            console.log("ShellSurfaceItemComponent implicitWidthChanged", output?.scaleFactor, root.shellSurface?.width, root.shellSurface?.height, implicitWidth, implicitHeight)
            console.log(impl.surface?.sourceGeometry, impl.surface?.destinationSize, impl.surface?.bufferSize, impl.surface?.bufferScale)
        }

        HoverHandler {
            id: hoverHandler
        }
        TapHandler {
            id: tapHandler
            acceptedButtons: Qt.LeftButton
            onTapped: {
                console.log("Tapped------------------------")
                impl.grabToImage()
            }
        }

        function grabToImage() {
            console.log("grabToImage------------------------")
            console.log(impl.output?.scaleFactor, root.shellSurface?.width, root.shellSurface?.height, impl.implicitWidth, impl.implicitHeight)
            console.log(impl.surface?.sourceGeometry, impl.surface?.destinationSize, impl.surface?.bufferSize, impl.surface?.bufferScale)
            DockScreenshotHelper.saveSurfaceToFile(impl.surface, "/tmp/screenshot.png")
        }

        Timer {
            id: grabTimer
            interval: 1000
            repeat: false
            running: false
            onTriggered: {
                console.log("grabTimer triggered")
                impl.grabToImage()
            }
        }

        onSurfaceChanged: {
            if (autoClose && visible && surface) {
                grabTimer.start()
            }
        }

        onVisibleChanged: function () {
            if (autoClose && !visible) {
                // surface is valid but client's shellSurface maybe invalid.
                Qt.callLater(closeShellSurface)
            } else if (autoClose && visible && surface) {
                grabTimer.start()
            }
        }
        function closeShellSurface()
        {
            if (surface && shellSurface) {
                DockCompositor.closeShellSurface(shellSurface)
            }
        }
    }
    Component.onCompleted: function () {
        impl.surfaceDestroyed.connect(root.surfaceDestroyed)
    }

    Connections {
        target: shellSurface
        // TODO it's maybe a bug for qt, we force shellSurface's value to update
        function onAboutToDestroy()
        {
            Qt.callLater(function() {
                impl.shellSurface = null
                impl.shellSurface = Qt.binding(function () {
                    return root.shellSurface
                })
            })
        }
    }
}
