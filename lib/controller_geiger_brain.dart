import 'dart:async';

import 'package:package_info/package_info.dart';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:map_controller/map_controller.dart';
import 'package:geojson/geojson.dart';
import 'package:geopoint/geopoint.dart';

import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:multigeigercompanion/source_location_manager.dart';

import 'package:flutter_blue/flutter_blue.dart';
import 'package:multigeigercompanion/source_ble_device_manager.dart';
import 'model_geiger_data.dart';
import 'constants.dart';

class GeigerBrain {
  PackageInfo packageInfo;
  LocationManager locationManager;
  BleDeviceManager bleDeviceManager;
  GeigerDeviceModel geigerDevice;
  CpmReadingsModel cpmReadings;

  StreamController<LatLng> latLngStream = StreamController();
  StreamController<Marker> markerStream = StreamController();
  StreamController<BluetoothDeviceState> bleStateStream = StreamController();
  StreamController<GeigerDeviceModel> geigerDeviceStream = StreamController();
  StreamController<CpmReadingsModel> cpmReadingStream = StreamController();

  GeolocationStatus geolocationStatus = GeolocationStatus.unknown;

  GeigerBrain() {
    PackageInfo.fromPlatform().then(
        (PackageInfo initialPackageInfo) => packageInfo = initialPackageInfo);
    geigerDevice = GeigerDeviceModel();
    cpmReadings = CpmReadingsModel();
    locationManager = LocationManager(onPosUpdate: _onPosUpdate);
    locationManager
        .startLocationManager()
        .then((value) => geolocationStatus = locationManager.geolocationStatus);
  }

  StatefulMapController statefulMapController;
  Future<void> bleStateStreamState;

  List<CpmDatum> cpmList = List<CpmDatum>();
  List<CpmDatum> aggregatedCpmList = List<CpmDatum>();
  GeoJsonFeatureCollection markerList = GeoJsonFeatureCollection([]);
  int markerCount = 0;

  /// called from onPosUpdate and onCpmDataUpdate to aggregate cpm data and update markers
  bool _aggregateCpm() {
    if (cpmReadings.sumCounts < cpmMinIntegrationCounts) return false;

    aggregatedCpmList.add(
      CpmDatum(
        cpmReadings.firstDataTime,
        cpmReadings.avgCpm,
        minCpm: cpmReadings.minCpm,
        maxCpm: cpmReadings.maxCpm,
      ),
    );

    markerCount++;
    statefulMapController?.addMarker(
      marker: Marker(
        anchorPos: AnchorPos.align(AnchorAlign.center),
        point: locationManager.myLatLng,
        builder: (_) => Icon(
          Icons.stop,
          color: cpmReadings.color,
          size: 15.0,
        ),
      ),
      name: '${markerCount}_${cpmReadings.radiationInfo}',
    );

    GeoJsonFeature newMarker = GeoJsonFeature();
    newMarker.type = GeoJsonFeatureType.point;
    newMarker.properties = {
      'name': '${markerCount}_${cpmReadings.radiationInfo}',
      'marker-color':
          '#${cpmReadings.color.value.toRadixString(16).padLeft(8).substring(2)}',
      'marker-size': 'small',
      'cpm-average': cpmReadings.avgCpm,
      'cpm2rate': cpmReadings.cpm2rate,
    };
    newMarker.geometry = GeoJsonPoint(
        geoPoint: GeoPoint.fromLatLng(point: locationManager.myLatLng));
    markerList.collection.add(newMarker);

    if (aggregatedCpmList.length > chartMaxLength)
      aggregatedCpmList.removeRange(
          0, aggregatedCpmList.length - chartMaxLength);
    cpmList.removeRange(0, cpmList.length - cpmReadings.sumCounts);
    return true;
  }

  _onPosUpdate(Position newPosition) {
    bool resetCpm = true;
    LatLng newLatLng = LatLng(newPosition.latitude, newPosition.longitude);

    if (statefulMapController != null) {
      statefulMapController.centerOnPoint(newLatLng);
      statefulMapController.addMarker(
          // if marker exists, it is updated
          marker: Marker(
            anchorPos: AnchorPos.align(AnchorAlign.top),
            point: newLatLng,
            builder: (_) => Icon(
              Icons.location_on,
              color: Colors.teal,
              size: 30.0,
            ),
          ),
          name: '0');
    }
    resetCpm = _aggregateCpm();
    latLngStream.add(newLatLng);
    if (resetCpm) cpmReadings.resetData();
  }

  _onCpmDataUpdate(List<int> data) {
    bool resetCpm = false;
    if (data.length < 5) {
      return;
    }
    int cpm = (data[2] << 8) | data[1];
    int packet = (data[4] << 8) | data[3];
    cpmReadings.addCpm(cpm, packet);
    cpmList.add(CpmDatum((cpmReadings?.lastDataTime ?? DateTime.now()),
        cpmReadings.currentCpm.toDouble()));
    if (cpmReadings.integrationTime > (cpmMaxIntegrationTime.inSeconds / 60))
      resetCpm = _aggregateCpm();
    cpmReadingStream
        .add(cpmReadings); // stream updates UI, incl. updated lists...
    if (resetCpm) cpmReadings.resetData();
  }

  connectBleDevice(BluetoothDevice device) async {
    if (bleDeviceManager != null) await disconnectBleDevice();
    bleDeviceManager =
        BleDeviceManager(myBleDevice: device, onNotifyData: _onCpmDataUpdate);
    await bleDeviceManager.startDevice((event) => bleStateStream.add(event));
    geigerDevice.id = bleDeviceManager.bleName;
    geigerDevice.tubeType = bleDeviceManager.bleTubeType;
    geigerDevice.hasThp = bleDeviceManager.hasThpData;
    print(geigerDevice.toString());
    geigerDeviceStream.add(geigerDevice);
    cpmReadings.cpm2rate = tubeConversionFactor[bleDeviceManager.bleTubeType];
    bleStateStream.addStream(bleDeviceManager.myBleDevice.state);
  }

  reconnectBleDevice() async {
    if (bleDeviceManager == null) return;
    await bleDeviceManager.stopDevice();
    await bleDeviceManager.startDevice((event) => bleStateStream.add(event));
    geigerDevice.id = bleDeviceManager.bleName;
    geigerDevice.tubeType = bleDeviceManager.bleTubeType;
    geigerDevice.hasThp = bleDeviceManager.hasThpData;
    geigerDeviceStream.add(geigerDevice);
    cpmReadings.cpm2rate = tubeConversionFactor[bleDeviceManager.bleTubeType];
  }

  disconnectBleDevice() async {
    if (bleDeviceManager == null) return;
    await bleDeviceManager.stopDevice();
    bleDeviceManager = null;
    geigerDevice.resetDevice();
    geigerDeviceStream.add(geigerDevice);
    cpmReadings.resetData();
    cpmReadings.cpm2rate = 0.0;
    cpmReadingStream.add(cpmReadings);
    cpmList.clear();
    aggregatedCpmList.clear();
  }

  void dispose() {
    latLngStream.close();
    bleStateStream.close();
    geigerDeviceStream.close();
    cpmReadingStream.close();
    markerStream.close();

    disconnectBleDevice();
    locationManager.stopLocationManager();
  }
}
