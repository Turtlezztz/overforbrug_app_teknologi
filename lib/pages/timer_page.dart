import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:convert';
import '../services/language_service.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with AutomaticKeepAliveClientMixin {
  BluetoothDevice? connectedDevice;
  List<BluetoothDevice> foundDevices = [];
  bool isScanning = false;
  StreamSubscription? _scanResultsSubscription;
  StreamSubscription? _connectionStateSubscription;
  final List<StreamSubscription> _characteristicSubscriptions = [];
  bool _isDisposed = false;
  BluetoothCharacteristic? _writeCharacteristic;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
  }

  Future<void> _initializeBluetooth() async {
    if (_isDisposed) return;
    
    try {
      await requestPermissions();
      
      if (await FlutterBluePlus.isAvailable == false) {
        if (_isDisposed) return;
        setState(() {
          isScanning = false;
        });
        return;
      }

      if (await FlutterBluePlus.isOn == false) {
        if (_isDisposed) return;
        setState(() {
          isScanning = false;
        });
        return;
      }
    } catch (e) {
      if (_isDisposed) return;
      setState(() {
        isScanning = false;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _scanResultsSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    for (var subscription in _characteristicSubscriptions) {
      subscription.cancel();
    }
    _characteristicSubscriptions.clear();
    
    if (connectedDevice != null) {
      connectedDevice!.disconnect();
    }
    
    super.dispose();
  }

  Future<void> requestPermissions() async {
    await Permission.location.request();
    
    if (await Permission.bluetooth.isDenied) {
      await Permission.bluetooth.request();
    }
    if (await Permission.bluetoothScan.isDenied) {
      await Permission.bluetoothScan.request();
    }
    if (await Permission.bluetoothConnect.isDenied) {
      await Permission.bluetoothConnect.request();
    }
  }

  Future<void> startScan() async {
    if (_isDisposed) return;
    
    setState(() {
      isScanning = true;
      foundDevices = [];
    });

    try {
      await requestPermissions();

      if (await FlutterBluePlus.isAvailable == false) {
        if (_isDisposed) return;
        setState(() {
          isScanning = false;
        });
        return;
      }

      if (await FlutterBluePlus.isOn == false) {
        if (_isDisposed) return;
        setState(() {
          isScanning = false;
        });
        return;
      }

      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      
      _scanResultsSubscription?.cancel();
      _scanResultsSubscription = FlutterBluePlus.scanResults.listen((results) {
        if (_isDisposed) return;
        for (ScanResult r in results) {
          if (r.device.advName.contains('timer2.0')) {
            setState(() {
              if (!foundDevices.any((device) => device.id == r.device.id)) {
                foundDevices.add(r.device);
              }
            });
          }
        }
      });

      await Future.delayed(const Duration(seconds: 4));
      if (_isDisposed) return;
      setState(() {
        isScanning = false;
      });
    } catch (e) {
      if (_isDisposed) return;
      setState(() {
        isScanning = false;
      });
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      if (_isDisposed) return;
      setState(() {
        connectedDevice = device;
      });

      await device.connect();

      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = device.connectionState.listen((state) {
        if (_isDisposed) return;
        setState(() {
          if (state == BluetoothConnectionState.disconnected) {
            connectedDevice = null;
            _writeCharacteristic = null;
          }
        });
      });

      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.properties.write || characteristic.properties.writeWithoutResponse) {
            _writeCharacteristic = characteristic;
          }
        }
      }
    } catch (e) {
      if (_isDisposed) return;
      setState(() {
        connectedDevice = null;
        _writeCharacteristic = null;
      });
    }
  }

  Future<void> disconnectDevice() async {
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
        if (_isDisposed) return;
        setState(() {
          connectedDevice = null;
          _writeCharacteristic = null;
        });
      } catch (e) {
        if (_isDisposed) return;
        setState(() {
          connectedDevice = null;
          _writeCharacteristic = null;
        });
      }
    }
  }

  Future<void> sendCommand(String command) async {
    if (_writeCharacteristic == null) return;

    try {
      await _writeCharacteristic!.write(utf8.encode(command));
    } catch (e) {
      if (_isDisposed) return;
      setState(() {
        connectedDevice = null;
        _writeCharacteristic = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final languageService = context.watch<LanguageService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(languageService.translate('timer')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (connectedDevice == null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                languageService.translate('timer_connection'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isScanning)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: startScan,
                  child: Text(languageService.translate('search_timers')),
                ),
              ),
            if (foundDevices.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(languageService.translate('no_devices')),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: foundDevices.length,
                  itemBuilder: (context, index) {
                    final device = foundDevices[index];
                    return ListTile(
                      title: Text(device.advName),
                      subtitle: Text(device.id.id),
                      trailing: ElevatedButton(
                        onPressed: () => connectToDevice(device),
                        child: Text(languageService.translate('connect')),
                      ),
                    );
                  },
                ),
              ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${languageService.translate('connected_to')} ${connectedDevice!.advName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => sendCommand('START'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    'START',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => sendCommand('STOP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text(
                    'STOP',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: disconnectDevice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text(
                languageService.translate('disconnect'),
                style: const TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 