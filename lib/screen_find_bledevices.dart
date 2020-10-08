import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'constants.dart';

//
// Code below adapted from flutter_blue example
// https://github.com/pauldemarco/flutter_blue/
//
//Copyright 2017 Paul DeMarco. All rights reserved.
//
//Redistribution and use in source and binary forms, with or without
//modification, are permitted provided that the following conditions are
//met:
//
//* Redistributions of source code must retain the above copyright
//notice, this list of conditions and the following disclaimer.
//* Redistributions in binary form must reproduce the above
//copyright notice, this list of conditions and the following disclaimer
//in the documentation and/or other materials provided with the
//distribution.
//* Neither the name of Buffalo PC Inc. nor the names of its
//contributors may be used to endorse or promote products derived from
//this software without specific prior written permission.
//
//THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
//"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
//LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
//A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
//OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
//LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
//THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
//(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
//OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

// below:
// class ScanResultTile

class FindBleDevicesScreen extends StatelessWidget {
  Widget _connectedDevices(BuildContext context) {
    return StreamBuilder<List<BluetoothDevice>>(
      stream: Stream.fromFuture(FlutterBlue.instance.connectedDevices),
      initialData: [],
      builder: (c, snapshot) => Column(
        children: snapshot.data
            .map((d) => ListTile(
                  title: Text(d.name),
                  subtitle: Text(d.id.toString()),
                  trailing: StreamBuilder<BluetoothDeviceState>(
                    stream: d.state,
                    initialData: BluetoothDeviceState.disconnected,
                    builder: (c, snapshot) {
                      if (snapshot.data == BluetoothDeviceState.connected) {
                        return RaisedButton(
                          child: Text('RETURN'),
                          onPressed: () {
                            FlutterBlue.instance.stopScan();
                            Navigator.of(context).pop(d);
                          },
                        );
                      }
                      return Text(snapshot.data.toString().split('.')[1]);
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _availableDevices(BuildContext context) {
    return StreamBuilder<List<ScanResult>>(
      stream: FlutterBlue.instance.scanResults,
      initialData: [],
      builder: (c, snapshot) => Column(
        children: snapshot.data
            .map(
              (r) => ScanResultTile(
                result: r,
                onTap: () {
                  FlutterBlue.instance.stopScan();
                  Navigator.of(context).pop(r.device);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _bluetoothOffWidget(BuildContext context, BluetoothState state) {
    return Container(
      color: Colors.lightBlue,
      child: FlatButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subtitle1
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    FlutterBlue.instance.startScan(timeout: Duration(seconds: 6));
    return Scaffold(
      appBar: AppBar(
        title: Text('Find BLE devices'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            StreamBuilder<BluetoothState>(
              stream: FlutterBlue.instance.state,
              initialData: BluetoothState.unknown,
              builder: (c, snapshot) {
                final state = snapshot.data;
                if (state == BluetoothState.on) {
                  return Column(
                    children: <Widget>[
                      _connectedDevices(context),
                      _availableDevices(context),
                    ],
                  );
                } else {
                  return _bluetoothOffWidget(context, state);
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 10)));
          }
        },
      ),
    );
  }
}

// ExpansionTile
class ScanResultTile extends StatelessWidget {
  const ScanResultTile({Key key, this.result, this.onTap}) : super(key: key);

  final ScanResult result;
  final VoidCallback onTap;

  // check for name prefix (e.g. "ESP32") and then for heart rate service
  Widget _buildButton(BuildContext context) {
    if (result.device.name.startsWith(bleDevicePrefix)) {
      if (result.advertisementData.serviceUuids
          .toString()
          .toLowerCase()
          .contains(bleServiceHeartRate)) {
        return RaisedButton(
          child: Text('SELECT'),
          color: Colors.teal,
          textColor: Colors.white,
          onPressed: onTap,
        );
      }
    }
    return FlatButton(
      child: Text('-'),
      onPressed: () => Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text('No MultiGeiger device'),
          duration: Duration(milliseconds: 400),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    if (result.device.name.length > 0) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            result.device.name,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            result.device.id.toString(),
            style: Theme.of(context).textTheme.caption,
          )
        ],
      );
    } else {
      return Text(result.device.id.toString());
    }
  }

  Widget _buildAdvRow(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.caption),
          SizedBox(
            width: 12.0,
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .caption
                  .apply(color: Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  // --> "[00, 0A, 23, ...]"
  String getNiceHexArray(List<int> bytes) {
    return '[${bytes.map((i) => i.toRadixString(16).padLeft(2, '0')).join(', ')}]'
        .toUpperCase();
  }

  String getNiceManufacturerData(Map<int, List<int>> data) {
    if (data.isEmpty || data == null) {
      return '';
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add(
          '${id.toRadixString(16).toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  String getNiceServiceData(Map<String, List<int>> data) {
    if (data.isEmpty || data == null) {
      return '';
    }
    List<String> res = [];
    data.forEach((id, bytes) {
      res.add('${id.toUpperCase()}: ${getNiceHexArray(bytes)}');
    });
    return res.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      leading: Text(result.rssi.toString()),
      trailing: _buildButton(context),
      children: <Widget>[
        SizedBox(
          width: 100.0,
          height: 20.0,
        ),
        _buildAdvRow(
            context, 'Complete Local Name', result.advertisementData.localName),
        _buildAdvRow(context, 'Tx Power Level',
            '${result.advertisementData.txPowerLevel ?? 'N/A'}'),
        _buildAdvRow(
            context,
            'Manufacturer Data',
            getNiceManufacturerData(
                    result.advertisementData.manufacturerData) ??
                'N/A'),
        _buildAdvRow(
            context,
            'Service UUIDs',
            (result.advertisementData.serviceUuids.isNotEmpty)
                ? result.advertisementData.serviceUuids.join(', ').toUpperCase()
                : 'N/A'),
        _buildAdvRow(context, 'Service Data',
            getNiceServiceData(result.advertisementData.serviceData) ?? 'N/A'),
      ],
    );
  }
}
