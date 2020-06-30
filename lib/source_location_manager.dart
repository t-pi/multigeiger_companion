import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';
import 'package:multigeigercompanion/constants.dart';

class LocationManager {
  Position myPos;
  Function(Position) onPosUpdate;
  String myAddress = '';
  LatLng get myLatLng =>
      LatLng(myPos?.latitude ?? startLatitude, myPos?.longitude ?? startLongitude);

  GeolocationStatus geolocationStatus;
  Geolocator geolocator = Geolocator();
  LocationOptions locationOptions =
      LocationOptions(accuracy: LocationAccuracy.high, distanceFilter: 10);
  StreamSubscription<Position> posStream;

  LocationManager({@required this.onPosUpdate});

  Future<void> startLocationManager() async {
    geolocationStatus = await Geolocator().checkGeolocationPermissionStatus();
    if (geolocationStatus == GeolocationStatus.granted) {
      posStream = geolocator.getPositionStream(locationOptions).listen(
        (Position pos) {
          myPos = pos;
          getAddressInfo();
          onPosUpdate(myPos);
        },
      );
    }
  }

  updateLocation() async {
    await geolocator.getCurrentPosition();
  }

  stopLocationManager() async {
    posStream?.cancel();
  }

  String get positionInfo {
    if (myPos != null) {
      return 'lat: ${myPos.latitude.toStringAsFixed(3)}, long: ${myPos.longitude.toStringAsFixed(3)}';
    } else
      return 'no position set';
  }

  Future<void> getAddressInfo() async {
    List<Placemark> place;
    if (myPos != null) {
      place = await Geolocator().placemarkFromCoordinates(myPos.latitude, myPos.longitude);
      myAddress =
          '${place == null ? '' : '${place[0].thoroughfare} ${place[0].name}, ${place[0].locality}'}';
    } else
      myAddress = '';
  }

  String get timestampInfo =>
      '${myPos?.timestamp?.toLocal()?.toIso8601String()?.substring(0, 19) ?? ''}';
}
