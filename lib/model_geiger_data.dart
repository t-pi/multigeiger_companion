import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';
import 'package:multigeigercompanion/constants.dart';

class GeigerDeviceModel {
  String id; // e.g. "ESP32-1234567"
  String myName = ''; // e.g. "My first MultiGeiger"
  int tubeType = 0;
  bool hasThp = false;

  String get name => (myName.length > 0 ? myName : id);

  String toString() {
    return 'id: $id, myName: $myName, tubeType: $tubeType, hasThp: $hasThp';
  }

  resetDevice() {
    id = null;
    myName = ''; // e.g. "My first MultiGeiger"
    tubeType = 0;
    hasThp = false;
  }
}

// For chart list
class CpmDatum {
  DateTime timestamp;
  double avgCpm = 0.0;
  int minCpm = 0;
  int maxCpm = 0;

  CpmDatum(this.timestamp, this.avgCpm, {this.minCpm, this.maxCpm});
}

class GeigerMarker {
  DateTime timestamp;
  double integrationMinutes;
  double avgCpm;
  double avgRate;
  int minCpm;
  int maxCpm;
  Color color;
  LatLng position;

  GeigerMarker({CpmReadingsModel geigerData, LatLng markerPosition}) {
    timestamp = geigerData.firstDataTime;
    integrationMinutes = geigerData.integrationTime;
    avgCpm = geigerData.avgCpm;
    avgRate = geigerData.rate;
    minCpm = geigerData.minCpm;
    maxCpm = geigerData.maxCpm;
    color = geigerData.color;
    position = markerPosition;
  }
}

class CpmReadingsModel {
  DateTime firstDataTime;
  DateTime lastDataTime;
  int currentCpm = 0;
  int packetCounter = 0;
  int minCpm = 0;
  int maxCpm = 0;
  int sumCpm = 0;
  int sumCounts = 0;
  double avgCpm = 0.0;
  double cpm2rate = 0.0;

  /// Returns radiation rate in µSv/h, 0 if no conversion factor available
  double get rate => (((avgCpm ?? 0) / 60) * cpm2rate);

  /// Returns lastDataTime - firstDataTime in (double) minutes
  double get integrationTime => (lastDataTime?.difference(firstDataTime)?.inSeconds ?? 0.0) / 60;

  /// Returns 'CPM: (currentCpm) (avg: (avgCpm) over (integrationTime) min)'
  String get cpmInfo =>
      'CPM: $currentCpm (avg: ${avgCpm.toStringAsFixed(1)} over ${integrationTime.toStringAsFixed(1)} min)';

  /// Returns '(rate) µSv/h', if available, else '(cpm) CPM'
  String get radiationInfo =>
      (rate > 0 ? '${rate.toStringAsFixed(3)} µSv/h' : '${avgCpm.toStringAsFixed(1)} CPM');

  addCpm(int newCpm, int currentPacketCount) {
    packetCounter = currentPacketCount;
    if (newCpm == 0) return;
    lastDataTime = DateTime.now();
    if (firstDataTime == null) firstDataTime = lastDataTime;
    currentCpm = newCpm;
    if (newCpm > maxCpm) maxCpm = newCpm;
    if (minCpm == 0) minCpm = newCpm;
    if (newCpm < minCpm) minCpm = newCpm;

    sumCpm += newCpm;
    sumCounts++;
    avgCpm = sumCpm / sumCounts;
  }

  Color rate2Color(double r) {
    if (r == 0) return Color(rateColor[-2]); // default for cpm2rate == 0
    if (r <= 0.05) return Color(rateColor[0.05]);
    if (r <= 0.1)
      return Color.lerp(Color(rateColor[0.05]), Color(rateColor[0.1]), (r - 0.05) / 0.05);
    if (r <= 0.2) return Color.lerp(Color(rateColor[0.1]), Color(rateColor[0.2]), (r - 0.1) / 0.1);
    if (r <= 0.5) return Color.lerp(Color(rateColor[0.2]), Color(rateColor[0.5]), (r - 0.2) / 0.3);
    if (r <= 5) return Color.lerp(Color(rateColor[0.5]), Color(rateColor[5]), (r - 0.5) / 4.5);
    if (r <= 100) return Color.lerp(Color(rateColor[5]), Color(rateColor[100]), (r - 5) / 95);
    return Color(rateColor[100]);
  }

  Color get color => rate2Color(rate);

  resetData() {
    firstDataTime = null;
    lastDataTime = null;
    currentCpm = 0;
    packetCounter = 0;
    minCpm = 0;
    maxCpm = 0;
    sumCpm = 0;
    sumCounts = 0;
    avgCpm = 0.0;
  }
}
