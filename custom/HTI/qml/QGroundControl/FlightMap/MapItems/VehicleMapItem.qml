import QtQuick
import QtLocation

import QGroundControl
import QGroundControl.Controls

/// Marker for displaying a vehicle location on the map.
MapQuickItem {
    id: _root

    property var    vehicle
    property var    map
    property double heading:                    vehicle ? vehicle.heading.value : Number.NaN
    property real   size:                       ScreenTools.defaultFontPixelHeight * 3
    property real   aircraftMarkerSize:         100
    property real   aircraftMarkerScale:        1.2

    anchorPoint.x:  vehicleItem.width / 2
    anchorPoint.y:  vehicleItem.height / 2
    visible:        coordinate.isValid

    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property var    _map:                       map
    property bool   _multiVehicle:              QGroundControl.multiVehicleManager.vehicles.count > 1
    property bool   _useCustomAircraftMarker:   vehicle && (!_map || !_map.planView)

    sourceItem: Item {
        id:         vehicleItem
        width:      vehicleIcon.width
        height:     vehicleIcon.height
        opacity:    vehicle === _activeVehicle ? 1.0 : 0.5

        Repeater {
            model: vehicle ? vehicle.gimbalController.gimbals : []

            Item {
                id:                           canvasItem
                anchors.centerIn:             vehicleItem
                width:                        vehicleItem.width * 2
                height:                       vehicleItem.height * 2
                property var gimbalYaw:       object.absoluteYaw.rawValue
                rotation:                     gimbalYaw + 180
                onGimbalYawChanged:           canvas.requestPaint()
                visible:                      vehicle && !isNaN(gimbalYaw) && QGroundControl.settingsManager.gimbalControllerSettings.showAzimuthIndicatorOnMap.rawValue
                opacity:                      object === vehicle.gimbalController.activeGimbal ? 1.0 : 0.4

                Canvas {
                    id:                           canvas
                    anchors.centerIn:             canvasItem
                    anchors.verticalCenterOffset: vehicleItem.width
                    width:                        vehicleItem.width
                    height:                       vehicleItem.height

                    onPaint:                      paintHeading()

                    function paintHeading() {
                        var context = getContext("2d")
                        context.clearRect(0, 0, vehicleIcon.width, vehicleIcon.height)

                        var centerX = canvas.width / 2
                        var centerY = canvas.height / 2
                        var width = canvas.width * 0.6

                        var point1 = [centerX - width, centerY + canvas.height * 0.6]
                        var point2 = [centerX, centerY - canvas.height * 0.5]
                        var point3 = [centerX + width, centerY + canvas.height * 0.6]
                        var point4 = [centerX, centerY + canvas.height * 0.2]

                        context.save()
                        context.globalAlpha = 0.9
                        context.beginPath()
                        context.moveTo(centerX, centerY + canvas.height * 0.2)
                        context.lineTo(point1[0], point1[1])
                        context.lineTo(point2[0], point2[1])
                        context.lineTo(point3[0], point3[1])
                        context.lineTo(point4[0], point4[1])
                        context.closePath()

                        const gradient = context.createLinearGradient(canvas.width / 2, canvas.height, canvas.width / 2, 0)
                        gradient.addColorStop(0.3, Qt.rgba(255, 255, 255, 0))
                        gradient.addColorStop(0.5, Qt.rgba(255, 255, 255, 0.5))
                        gradient.addColorStop(1, qgcPal.mapIndicator)

                        context.fillStyle = gradient
                        context.fill()
                        context.restore()
                    }
                }
            }
        }

        Image {
            id:                 vehicleIcon
            anchors.centerIn:   parent
            source:             _root._useCustomAircraftMarker ? "qrc:/HTI/images/aircraft_marker.png" : (_root.vehicle ? _root.vehicle.vehicleImageOpaque : "")
            width:              _root._useCustomAircraftMarker ? _root.aircraftMarkerSize * _root.aircraftMarkerScale : _root.size
            height:             width
            sourceSize.width:   Math.round(width)
            sourceSize.height:  Math.round(height)
            fillMode:           Image.PreserveAspectFit
            mipmap:             false
            smooth:             true
            transform: Rotation {
                origin.x:       vehicleIcon.width / 2
                origin.y:       vehicleIcon.height / 2
                angle:          isNaN(_root.heading) ? 0 : _root.heading
            }
        }

        QGCMapLabel {
            id:                         vehicleLabel
            anchors.top:                parent.bottom
            anchors.horizontalCenter:   parent.horizontalCenter
            map:                        _map
            text:                       visible && vehicle ? qsTr("Vehicle %1").arg(vehicle.id) : ""
            font.pointSize:             ScreenTools.smallFontPointSize
            visible:                    _multiVehicle
        }
    }
}
