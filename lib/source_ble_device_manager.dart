import 'dart:async';
import 'package:async/async.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'constants.dart';

class BleDeviceManager {
  final BluetoothDevice myBleDevice;
  final Function onNotifyData;

  RestartableTimer _watchdogTimer;

  String bleName = '';
  int bleTubeType = 0;

  BleDeviceManager({@required this.myBleDevice, @required this.onNotifyData});

  // notifications from HRM only, other characteristics for reading calls
  BluetoothCharacteristic _hrCharacteristic;
  BluetoothCharacteristic _tempCharacteristic;
  BluetoothCharacteristic _humCharacteristic;
  BluetoothCharacteristic _pressCharacteristic;
  bool hasThpData = false;

  BluetoothDeviceState deviceConnected = BluetoothDeviceState.disconnected;
  bool notificationStatus = false;

  StreamSubscription<List<int>> cpmSubscription;
  StreamSubscription<BluetoothDeviceState> bleStateSubscription;

  startWatchdogForNotify({int minutes: 2}) {
    Duration timeout = Duration(minutes: (minutes > 1) ? minutes : 1);
    if (_watchdogTimer != null) {
      _watchdogTimer.cancel();
      _watchdogTimer = null;
    }
    _watchdogTimer = RestartableTimer(timeout, () async {
      await setNotifications(true);
      _watchdogTimer.reset();
    });
  }

  stopWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
  }

  startDevice(Function onBleStateChange) async {
    List<BluetoothService> _bleServices;

    bleStateSubscription = myBleDevice.state.listen((event) {
      deviceConnected = event;
      onBleStateChange(event);
    });
    await myBleDevice.connect();

    bleName = myBleDevice.name.length > 0 ? myBleDevice.name : 'MultiGeiger';
    _bleServices = await myBleDevice.discoverServices();
    for (BluetoothService service in _bleServices) {
      // Heart rate service
      if (service.uuid.toString().substring(4, 8) == bleServiceHeartRate) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          // Set rate notifications
          if (characteristic.uuid.toString().substring(4, 8) == bleCharHRMeasurement) {
            _hrCharacteristic = characteristic;
            notificationStatus = true;
            await _hrCharacteristic.setNotifyValue(notificationStatus);
            cpmSubscription = _hrCharacteristic.value.listen(
              (List<int> data) {
                _watchdogTimer?.reset();
                onNotifyData(data);
              },
            );
            startWatchdogForNotify();
          }
          // Read tube type
          if (characteristic.uuid.toString().substring(4, 8) == bleCharHRPosition) {
            List<int> hrPosition = await characteristic.read();
            bleTubeType = hrPosition[0].toInt();
          }
        }
      }
      // Environmental sensing service
      if (service.uuid.toString().substring(4, 8) == bleServiceEnvSense) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid.toString().substring(4, 8) == bleCharESTemperature) {
            hasThpData = true;
            _tempCharacteristic = characteristic;
          }
          if (characteristic.uuid.toString().substring(4, 8) == bleCharESHumidity) {
            hasThpData = true;
            _humCharacteristic = characteristic;
          }
          if (characteristic.uuid.toString().substring(4, 8) == bleCharESPressure) {
            hasThpData = true;
            _pressCharacteristic = characteristic;
          }
        }
      }
    }
  }

  setNotifications(bool setMe) async {
    if (deviceConnected != BluetoothDeviceState.connected) return;

    notificationStatus = setMe;
    if (!setMe) {
      await cpmSubscription.cancel();
      await _hrCharacteristic.setNotifyValue(setMe);
      cpmSubscription = null;
      stopWatchdog();
    } else {
      await _hrCharacteristic.setNotifyValue(setMe);
      cpmSubscription = _hrCharacteristic.value.listen(onNotifyData);
      startWatchdogForNotify();
    }
  }

  stopDevice() async {
    await stopWatchdog();
    await cpmSubscription?.cancel();
    cpmSubscription = null;
    await bleStateSubscription?.cancel();
    bleStateSubscription = null;
    if (deviceConnected == BluetoothDeviceState.connected) {
      if (notificationStatus) {
        await _hrCharacteristic.setNotifyValue(false);
        notificationStatus = false;
      }
      await myBleDevice.disconnect();
    } else {
      notificationStatus = false;
    }
    _hrCharacteristic = null;
  }

  Future<double> get temperature async {
    if (!hasThpData) return 0.0;

    List<int> data = await _tempCharacteristic.read();
    if (data.length < 4) {
      return 0.0;
    }
    return ((data[3] << 24) | (data[2] << 16) | (data[1] << 8) | data[0]) /
        100.0; // BLE sends int with two shifted digits
  }

  Future<double> get humidity async {
    if (!hasThpData) return 0.0;

    List<int> data = await _humCharacteristic.read();
    if (data.length < 4) {
      return 0.0;
    }
    return ((data[3] << 24) | (data[2] << 16) | (data[1] << 8) | data[0]) /
        100.0; // BLE sends int with two shifted digits
  }

  Future<double> get pressure async {
    if (!hasThpData) return 0.0;

    List<int> data = await _pressCharacteristic.read();
    if (data.length < 4) {
      return 0.0;
    }
    return ((data[3] << 24) | (data[2] << 16) | (data[1] << 8) | data[0]) /
        10.0; // BLE sends int with one shifted digit
  }
}
