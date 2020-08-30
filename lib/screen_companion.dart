import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:multigeigercompanion/controller_geiger_brain.dart';
import 'package:multigeigercompanion/model_geiger_data.dart';
import 'package:multigeigercompanion/screen_find_bledevices.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:multigeigercompanion/widget_cpm_chart.dart';
import 'package:latlong/latlong.dart';
import 'package:multigeigercompanion/widget_map.dart';
import 'helper_hyperlinks.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'constants.dart';

class CompanionScreen extends StatefulWidget {
  @override
  _CompanionScreenState createState() => _CompanionScreenState();
}

class _CompanionScreenState extends State<CompanionScreen> {
  String title = "MultiGeiger Companion";
  GeigerBrain geigerBrain = GeigerBrain();
  MapWidget mapWidget;

  @override
  void initState() {
    mapWidget = MapWidget(geigerBrain);
    super.initState();
  }

  Widget _companionAppBar(BuildContext context) {
    return AppBar(
      title: StreamBuilder<GeigerDeviceModel>(
        stream: geigerBrain.geigerDeviceStream.stream,
        builder: (c, snapshot) {
          return Text(snapshot?.data?.name ?? title);
        },
      ),
      titleSpacing: 0.0,
      actions: <Widget>[
        StreamBuilder<BluetoothDeviceState>(
          stream: geigerBrain.bleStateStream.stream,
          initialData: BluetoothDeviceState.disconnected,
          builder: (c, snapshot) {
            Function onPressed = () {};
            IconData icon = Icons.hourglass_empty;
            Color color = Colors.amberAccent;
            switch (snapshot.data) {
              case BluetoothDeviceState.connected:
                icon = Icons.bluetooth_connected;
                color = Colors.lightBlue[100];
                onPressed = (() {
                  geigerBrain.reconnectBleDevice();
                });
                break;
              case BluetoothDeviceState.disconnected:
                if (geigerBrain.bleDeviceManager == null) {
                  icon = Icons.bluetooth_disabled;
                  color = Colors.red[200];
                  onPressed = (() async {
                    BluetoothDevice newBleDevice = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FindBleDevicesScreen(),
                      ),
                    );
                    if (newBleDevice != null) {
                      geigerBrain.connectBleDevice(newBleDevice);
                    }
                  });
                } else {
                  icon = Icons.settings_bluetooth;
                  color = Colors.amberAccent;
                  onPressed = (() {
                    geigerBrain.reconnectBleDevice();
                  });
                }
                break;
              default:
                icon = Icons.error;
                color = Colors.red;
                onPressed = null;
                break;
            }
            return IconButton(
              onPressed: onPressed,
              icon: Icon(
                icon,
                color: color,
              ),
            );
          },
        )
      ],
    );
  }

  Widget _companionDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.teal[700],
            ),
            child: Text(
              'MultiGeiger Devices',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.bluetooth_searching),
            title: Text('Search for devices'),
            onTap: () async {
              await geigerBrain.disconnectBleDevice();
              Navigator.pop(context);
              BluetoothDevice newBleDevice = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FindBleDevicesScreen(),
                ),
              );
              if (newBleDevice != null) {
                geigerBrain.connectBleDevice(newBleDevice);
              }
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.bluetooth_disabled),
            title: Text('Disconnect device'),
            onTap: () async {
              await geigerBrain.disconnectBleDevice();
              Navigator.pop(context);
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Future<Settings>'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(
                context: context,
                applicationVersion: geigerBrain.packageInfo?.version ?? '?.?.?',
                applicationIcon: Image.asset(
                  'assets/multigeiger_companion_appicon.png',
                  width: 60.0,
                ),
                children: [
                  Text(
                    'Hi! This app is set as companion to a MultiGeiger device with Bluetooth® ' +
                        'support (firmware 1.15.0+). It collects the local radiation level from ' +
                        'the MultiGeiger device, displays the data on a map and allows to export ' +
                        'the tracks. More Info:',
                  ),
                  Hyperlink('https://multigeiger.citysensor.de', '\nMultiGeiger Map'),
                  Hyperlink(
                      'https://github.com/ecocurious2/multigeiger', '\nMultiGeiger on GitHub'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _companionBody(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          children: <Widget>[
            StreamBuilder<CpmReadingsModel>(
                stream: geigerBrain.cpmReadingStream.stream,
                builder: (c, snapshot) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Flexible(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      'Current CPM:',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    Text(
                                      '${snapshot?.data?.currentCpm ?? 0}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
                                    ),
                                    Text(
                                      (snapshot?.data?.rate ?? 0) > 0
                                          ? '${snapshot.data.rate.toStringAsFixed(3)} µSv/h\n(${snapshot.data.integrationTime.toStringAsFixed(1)} min)'
                                          : '',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Text(
                                      'packet count: ${snapshot?.data?.packetCounter} \n@${snapshot?.data?.lastDataTime?.toIso8601String()?.substring(0, 19)}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          Flexible(
                            flex: 3,
                            child: Container(
                              height: 140.0,
                              child: CpmChartWidget(
                                geigerBrain.aggregatedCpmList + geigerBrain.cpmList,
                                animate: false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            StreamBuilder(
                stream: geigerBrain.latLngStream.stream,
                initialData: LatLng(startLatitude, startLongitude),
                builder: (c, snapshot) {
                  if (snapshot.hasData && geigerBrain.statefulMapController != null)
                    geigerBrain.statefulMapController.centerOnPoint(snapshot.data);
                  return Center(
                    child: Column(
                      children: <Widget>[
                        SizedBox(
                          height: 20.0,
                        ),
                        InkWell(
                          onTap: () => geigerBrain.locationManager.updateLocation(),
                          child: Text(
                            'Location: ${(snapshot?.data == null) ? 'Unknown' : 'Lat: ${snapshot.data.latitude.toStringAsFixed(3)}, Lng: ${snapshot.data.longitude.toStringAsFixed(3)}'}\r\n' +
                                '${geigerBrain.locationManager?.myAddress ?? ''}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                        (geigerBrain.geolocationStatus == GeolocationStatus.granted)
                            ? mapWidget
                            : Container(
                                height: 200.0,
                                child: Text(
                                  'Waiting for location service permission',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16.0),
                                ),
                              ),
                        Text(
                          'Last update: ${(geigerBrain.locationManager?.myPos == null) ? 'No valid position' : geigerBrain.locationManager.timestampInfo}',
                          style: TextStyle(fontSize: 12),
                        )
                      ],
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }

  Widget _companionFAB(BuildContext context) {
    return FloatingActionButton(
      child: Icon(Icons.mail_outline),
      onPressed: () {
        final Email email = Email(
          subject:
              'MultiGeiger GeoJSON ${DateTime.now().toLocal().toIso8601String().substring(0, 19)}',
          body: 'MultiGeiger data:\n\r' + geigerBrain.markerList.serialize(),
//          recipients: ['to@example.com'],
//          cc: ['cc@example.com'],
//          bcc: ['bcc@example.com'],
//          attachmentPaths: ['/path/to/attachment.zip'],
          isHTML: false,
        );

        FlutterEmailSender.send(email);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _companionAppBar(context),
      drawer: _companionDrawer(context),
      body: _companionBody(context),
      floatingActionButton: _companionFAB(context),
    );
  }
}
