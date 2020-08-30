// CONFIG
const bleDevicePrefix = "ESP32";
final cpmMinCurrentCpmPoints = 20; // cpmList will not be cut below this length
final cpmMinIntegrationCounts = 3; // no new GeigerMarker before this many CPM values
final cpmMaxIntegrationTime = Duration(minutes: 5); // new GeigerMarker after this
final chartMaxLength = 100; // max chart time axis: this * cpmMaxIntegrationTime (less while moving)
final startLatitude = 48.755757; // Stuttgarter Fernsehturm
final startLongitude = 9.190172;

// 16 bit UUIDS
final bleServiceHeartRate = '180d'; // Heart Rate Service
final bleCharHRMeasurement = '2a37'; // HR Measurement (bpm) Characteristic
final bleCharHRPosition = '2a38'; // HR Sensor Position Characteristic
final bleCharHRControlpoint = '2a39'; // HR Control Point Characteristic
final bleDescrUUID = '2901'; // 16 bit UUID of BLE Descriptor

final bleServiceEnvSense = '181a'; // Environmental Sensing Service
final bleCharESPressure = '2a6d'; // ES Pressure (Pa) Characteristic
final bleCharESTemperature = '2a6e'; // ES Temperature (degC) Characteristic
final bleCharESHumidity = '2a6f'; // ES Relative Humidity (%) Characteristic

// TUBE_TYPE values (predefined at sensor.community, DO NOT CHANGE):
const TUBETYPE_MAX = 3;
final tubeTypes = {
  0: 'TUBE_UNDEFINED', // this can be used for experimenting with other GM tubes and has a 0 CPM to uSv/h conversion factor.
  1: 'SBM20',
  2: 'SBM19',
  3: 'Si22G',
  99: 'TUBE_UNKNOWN',
};

// conversion factor CPS to ~µSv/h for ^tubeTypes
final tubeConversionFactor = {
  // UNKNOWN, use 0.0 conversion factor for unknown tubes, so it computes an "obviously-wrong" 0.0 uSv/h value rather than a confusing one.
  0: 0.0,
  // SBM20, conversion factors for SBM-20 and SBM-19 from the datasheets (according to Jürgen boehri.de)
  1: 1 / 2.47,
  // SBM19
  2: 1 / 9.81888,
  // Si22G, conversion factor from comparative measurement with odlinfo.bfs.de measurement unit in Sindelfingen (by boehri.de)
  3: 1 / 12.2792,
  99: 0.0
};
// The Si22G conversion factor was determined by Juergen Boehringer like this:
// Set up a Si22G based MultiGeiger close to the official odlinfo.bfs.de measurement unit in Sindelfingen.
// Determine how many counts the Si22G gives within the same time the odlinfo unit needs for 1uSv.
// Result: 44205 counts on the Si22G for 1 uSv.
// So, to convert from cps to uSv/h, the calculation is: uSvh = cps * 3600 / 44205 = cps / 12.2792

// Color palette for radiation rate
// key is radiation rate in µSv/h / -2 => indoor / no tube_type, -1 => offline
final rateColor = {
  -2: 0xFF9ECDEA, // no tube type
  -1: 0xFF7F7F7F, //
  0.05: 0xFF267A45,
  0.1: 0xFF66FA5F,
  0.2: 0xFFF8FC00,
  0.5: 0xFFFF0000,
  5: 0xFF9000FF,
  100: 0xFF000000,
};
