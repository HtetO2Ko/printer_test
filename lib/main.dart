import 'dart:async';
import 'dart:convert';

import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  BluetoothPrint bluetoothPrint = BluetoothPrint.instance;

  bool _connected = false;
  BluetoothDevice? _device;
  String tips = 'no device connect';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => initBluetooth());
  }

  Future<void> initBluetooth() async {
    print("bluttooth >>>>>>>>");
    bluetoothPrint.startScan(timeout: const Duration(seconds: 4));

    bool isConnected = await bluetoothPrint.isConnected ?? false;

    bluetoothPrint.state.listen((state) {
      print('******************* cur device status: $state');

      switch (state) {
        case BluetoothPrint.CONNECTED:
          setState(() {
            _connected = true;
            print("connect >>>");
            tips = 'connect success';
            print(">>>>>>>> tipes $tips");
          });
          break;
        case BluetoothPrint.DISCONNECTED:
          setState(() {
            _connected = false;
            print("not connect >>>");
            tips = 'disconnect success';
          });
          break;
        default:
          break;
      }
    });

    if (!mounted) return;

    if (isConnected) {
      setState(() {
        _connected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('BluetoothPrint example app'),
        ),
        body: RefreshIndicator(
          onRefresh: () =>
              bluetoothPrint.startScan(timeout: const Duration(seconds: 4)),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 10),
                      child: Text(tips),
                    ),
                  ],
                ),
                const Divider(),
                StreamBuilder<List<BluetoothDevice>>(
                  stream: bluetoothPrint.scanResults,
                  initialData: [],
                  builder: (c, snapshot) => Column(
                    children: snapshot.data!
                        .map((d) => ListTile(
                              title: Text(d.name ?? ''),
                              subtitle: Text(d.address ?? ''),
                              onTap: () async {
                                setState(() {
                                  _device = d;
                                });
                              },
                              trailing: _device != null &&
                                      _device!.address == d.address
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                    )
                                  : null,
                            ))
                        .toList(),
                  ),
                ),
                const Divider(),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 5, 20, 10),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          OutlinedButton(
                            child: const Text('connect'),
                            onPressed: _connected
                                ? null
                                : () async {
                                    if (_device != null &&
                                        _device!.address != null) {
                                      setState(() {
                                        tips = 'connecting...';
                                      });
                                      await bluetoothPrint.connect(_device!);
                                    } else {
                                      setState(() {
                                        tips = 'please select device';
                                      });
                                      print('please select device');
                                    }
                                  },
                          ),
                          const SizedBox(width: 10.0),
                          OutlinedButton(
                            child: const Text('disconnect'),
                            onPressed: _connected
                                ? () async {
                                    setState(() {
                                      tips = 'disconnecting...';
                                    });
                                    await bluetoothPrint.disconnect();
                                  }
                                : null,
                          ),
                        ],
                      ),
                      const Divider(),
                      OutlinedButton(
                        child: const Text('print receipt(esc)'),
                        onPressed: _connected
                            ? () async {
                              tips = "printing";
                                print(">>>>>>>>> click");
                                Map<String, dynamic> config = Map();
                                List<LineText> list = [];
                                print(">>>>>>>>> adding data to list");
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: "Hello",
                                    weight: 1,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: 'Test',
                                    weight: 1,
                                    align: LineText.ALIGN_CENTER,
                                    fontZoom: 2,
                                    linefeed: 1));
                                list.add(LineText(
                                    type: LineText.TYPE_TEXT,
                                    content: "Testing",
                                    weight: 1,
                                    align: LineText.ALIGN_CENTER,
                                    linefeed: 1));
                                print(">>>>>>>>>>> print");
                                var res = await bluetoothPrint.printReceipt(
                                    config, list);
                                // await bluetoothPrint.connect(st);
                                print(">>>>>>>>>>> printed");
                                print(">>>>>>> res >>>>>>>>>>> $res");
                                tips = "printed";
                                setState(() {
                                  
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        floatingActionButton: StreamBuilder<bool>(
          stream: bluetoothPrint.isScanning,
          initialData: false,
          builder: (c, snapshot) {
            if (snapshot.data == true) {
              return FloatingActionButton(
                child: const Icon(Icons.stop),
                onPressed: () => bluetoothPrint.stopScan(),
                backgroundColor: Colors.red,
              );
            } else {
              return FloatingActionButton(
                  child: const Icon(Icons.search),
                  onPressed: () => bluetoothPrint.startScan(
                      timeout: const Duration(seconds: 4)));
            }
          },
        ),
      ),
    );
  }
}
