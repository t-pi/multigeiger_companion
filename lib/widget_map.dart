import 'dart:async';

import 'package:flutter_map/flutter_map.dart';
import 'package:map_controller/map_controller.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter/material.dart';
import 'package:multigeigercompanion/constants.dart';
import 'controller_geiger_brain.dart';

class MapWidget extends StatefulWidget {
  final GeigerBrain geigerBrain;

  MapWidget(this.geigerBrain);

  @override
  _MapWidgetState createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  MapController mapController;
  StreamSubscription<StatefulMapControllerStateChange>
      statefulMapControllerSubscription;
  bool _ready = false;

  @override
  void initState() {
    mapController = MapController();
    widget.geigerBrain.statefulMapController =
        StatefulMapController(mapController: mapController);
    widget.geigerBrain.statefulMapController.onReady.then((_) => _ready = true);
    statefulMapControllerSubscription =
        widget.geigerBrain.statefulMapController.changeFeed.listen((_) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    statefulMapControllerSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        center: LatLng(startLatitude, startLongitude),
        zoom: 14.0,
      ),
      layers: [
        // widget.statefulMapController.tileLayer didn't show map tiles...
        TileLayerOptions(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayerOptions(
            markers: widget.geigerBrain.statefulMapController?.markers ?? []),
//          PolylineLayerOptions(
//              polylines: widget.geigerBrain.statefulMapController?.lines ?? Polyline()),
//          PolygonLayerOptions(
//              polygons: widget.geigerBrain.statefulMapController?.polygons ?? Polygon()),
      ],
    );
  }
}
