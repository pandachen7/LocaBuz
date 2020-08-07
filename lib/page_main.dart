import 'dart:async';
//import 'dart:html';  <-- weird
import 'dart:isolate';
import 'dart:ui';
//import 'dart:io';
import 'dart:developer';
//import 'package:logger/logger.dart';

import 'package:background_locator/background_locator.dart';
import 'package:background_locator/location_dto.dart';
import 'package:background_locator/location_settings.dart';
import 'package:flutter/material.dart';
import 'package:location_permissions/location_permissions.dart';

import 'file_manager.dart';
import 'location_callback_handler.dart';
import 'location_service_repository.dart';

// pages
import 'page_ble_list.dart';

// BLE
import 'package:flutter_blue/flutter_blue.dart';
import 'ble_dev.dart';

// goto system setting
import 'package:system_setting/system_setting.dart';

// json storage
import 'configuration.dart';
import 'heatmap.dart';

/*
TODO list:
 - encrypt heatmap
 */
class MyApp extends StatefulWidget {
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<BluetoothDevice> foundBleDevList = new List<BluetoothDevice>();// use it as param or you get duplicate uuid
  List<BluetoothDevice> connectedDevices;
  Configuration cfg = new Configuration();
  ReceivePort port = ReceivePort();
  Heatmap hm;

  String logStr = '';
  bool isRunning;
  LocationDto lastLocation;
  DateTime lastTimeLocation;

//  String strDescription = '';

  Timer _every30Seconds, _every20Seconds;
  bool bBleScan = false;
  int ctSelectedBle = 0;

  // BLE
  // singleton
  //  BluetoothDevice bleDevice;
  //  bool bFoundDev = false, bConnected = false, bDiscovered = false;
//  static const ISSC_PROPRIETARY_SERVICE_UUID = "6e400001";
//  static const UUIDSTR_ISSC_TRANS_RX = "6e400002";
//  static const UUIDSTR_ISSC_TRANS_TX = "6e400003";
//  BluetoothCharacteristic chara_rx;
//  BluetoothCharacteristic chara_tx;
//  BluetoothDevice _connectedDevice;
//  List<BluetoothService> _services;
  BluetoothState _bluetoothState = BluetoothState.unknown;
  bool bOpenBle = true;

  // btn
  bool useLocator = false;

  List<BleDev> listBleDevs = <BleDev>[
//    BleDev('name1', 'mac1')
  ];

  @override
  void initState() {
    super.initState();

    hm = new Heatmap(context: context);

    // if someone close the APP when Locator is on
    try{
      onStop();
    }on Exception catch (_) {
      log("throwing new error $_");
    }
//    log("widget.devicesList.length = ${widget.devicesList.length}");

    if (IsolateNameServer.lookupPortByName(
        LocationServiceRepository.isolateName) !=
        null) {
      IsolateNameServer.removePortNameMapping(
          LocationServiceRepository.isolateName);
    }

    IsolateNameServer.registerPortWithName(
        port.sendPort, LocationServiceRepository.isolateName);

    port.listen(
          (dynamic data) async {
        await updateUI(data);
      },
    );
    initPlatformState();

    // BLE

    // it seems this never be used...
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        log("connected dev? ${device.name}");
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.state.listen((state) {
      _bluetoothState = state;
      if (state == BluetoothState.off) {
        //Alert user to turn on bluetooth.
//        strDescription = 'Please turn on Bluetooth';
        stopBleScan();

        bOpenBle = false;
      } else if (state == BluetoothState.on) {
        //if bluetooth is enabled then go ahead.
        // Make sure user's device gps is on.
        startBleScan();

        bOpenBle = true;
      }
    });

    _every30Seconds = Timer.periodic(Duration(seconds: 30), (Timer t) {
      if (!mounted) return; // 頁面已不存在(被使用者關掉等), 就不要再進行refresh
//        Discovering();
      chkConnection();

    });

    _every20Seconds = Timer.periodic(Duration(seconds: 20), (Timer t) {
      if (!mounted) return;
      if (hm.inHotSpot) {
        loopChkLocaAndBuz();
      }
    });

//    try {
//
//    }on Exception catch (_) {
//      print("throwing new error $_");
//
//    }
    //^BLE
  }

  _addDeviceTolist(final BluetoothDevice device, {bool isConn = false}) async {
    if (cfg == null || !cfg.isInitialized() || device.name == ""){
      // Plz wait for the configuration init
      return;
    }

    log("found dev: ${device.name} isConn: $isConn");

    if (!foundBleDevList.contains(device)) {
      setState(() {
        foundBleDevList.add(device);

        if (true){ // device.name.contains("Emitter") // device.name == "Nordic_UART"
          // if bleDev already be selected, then connect and discover it
          if(cfg.Ble.containsKey(device.id.id)) {

            BleDev bd = getDev(device, true);

            // ugly....
            bd.disconnect().then((value) =>
                bd.connect().then((value) =>
                    bd.discoverChara().then((value) =>
                        updateCountBle()))
            );

            listBleDevs.add(bd);
          }else{
            BleDev bd = getDev(device, false);
            listBleDevs.add(bd);
          }
        }
      });
    }
  }
  BleDev getDev(device, bool isSelected){
    // if already in list
    for (var bd in listBleDevs){
      if (bd.mac == device.id.id){
        return bd;
      }
    }
    // if not, then create a new one
    return new BleDev(device.id.id, device, isSelected: isSelected);
  }
  void chkConnection() async {
    // not a good method to check connection
    List<BluetoothDevice> connectedDevices = await widget.flutterBlue.connectedDevices;
    String strBuff = "";
    for(var dev in connectedDevices){
      strBuff += "\n $dev";
    }
    log("connected devs: $strBuff");

    bool connStateChanged = false;
    for (var bd in listBleDevs){
      if(!connectedDevices.contains(bd.dev) && bd.isConnected){
        bd.disconnect();
        foundBleDevList.remove(bd.dev);
//        bleDevs.remove(bd); // no way
        log("No echo from dev ${bd.dev.name}.");
        connStateChanged = true;
      }

//      try{
//        bd.writeTo([0xff]); // send if connection is successful
//      }on Exception catch (_) {
//        log("throwing new error $_");
////        successfulWrite = false;
//      }
//      if (!successfulWrite){
//        bd.disconnect();
//      }
    }
    if(connStateChanged) {
      updateCountBle();
    }
  }
  Future<void> loopChkLocaAndBuz() async {
    if (!useLocator){
      return;
    }
    for (var bd in listBleDevs) {
      // 不這樣寫，大家互搶藍牙資源就會很HAPPY
//      await bd.setNotify();
      await bd.writeTo([0xff, 0xff, 0x3, 0xa0]);
      await bd.readFrom();
    }
  }
  void startBleScan(){
    if (!bBleScan) {
      bBleScan = true;
      widget.flutterBlue.startScan();
      log("start ble scan");

      _setTimerStopBleScan();
    }
  }
  void _setTimerStopBleScan(){
    if (!bBleScan) return;

    Timer(Duration(seconds: 60), () {
      if (!mounted) return;
      stopBleScan();
    });
  }
  void stopBleScan(){
    if (bBleScan) {
      bBleScan = false;
      widget.flutterBlue.stopScan();
      log("stop ble scan");
    }
  }
  void updateCountBle(){
    int count = 0;
    for (var bd in listBleDevs) {
      if(bd.chkAvalable()){
        count ++;
      }
    }
    if(count != ctSelectedBle){
      setState(() {
        ctSelectedBle = count;
      });
    }
  }
  //^BLE

  Future<void> updateUI(LocationDto data) async {
    final log = await FileManager.readLogFile();
    setState(() {
      if (data != null) {
        lastLocation = data;
        lastTimeLocation = DateTime.now();
        print("location info: $data");
      }
      logStr = log;
    });
  }

  Future<void> initPlatformState() async {
    print('Initializing...');
    await FileManager.init();
    FileManager.writeToLogFile("_/_/_/");
    await BackgroundLocator.initialize();
    
    logStr = await FileManager.readLogFile();
    print('Initialization done');
    final _isRunning = await BackgroundLocator.isRegisterLocationUpdate();
    setState(() {
      isRunning = _isRunning;
    });
    print('Running? ${isRunning.toString()}');
  }

  @override
  Widget build(BuildContext context) {
    print("refresh page");

    final btnTurnBle = Visibility(
      child: SizedBox(
        width: double.maxFinite,
        child: RaisedButton(
          color: Colors.amber,
          child: _bluetoothState != BluetoothState.on ? Text('Please turn on Bluetooth') : Text('Turn off bluetooth'),
          onPressed: () {
            SystemSetting.goto(SettingTarget.BLUETOOTH);
          },
        ),
      ),
      visible: bOpenBle? false : true,
    );
    final msg = Visibility(
      child: SizedBox(
        width: double.maxFinite,
        child: Row(
          children: <Widget>[
            Icon(Icons.bluetooth_searching, color: Colors.blue),
            Text("Now $ctSelectedBle device(s) are connected."),
          ],
        )
      ),
      visible: ctSelectedBle > 0 ? true : false,
    );

    final btnLoca = SizedBox(
      width: double.maxFinite,
      child: RaisedButton(
        color: useLocator ? Colors.blue : Colors.grey,
        child: useLocator ? Text('Stop service') : Text('Start LocaBuz'),
        onPressed: () {
          useLocator = !useLocator;
          useLocator ? _onStart() : onStop();
        },
      ),
    );
//    final stop = SizedBox(
//      width: double.maxFinite,
//      child: RaisedButton(
//        child: Text('Stop service'),
//        onPressed: () {
////          onStop();
//        },
//      ),
//    );
    final btnClear = SizedBox(
      width: double.maxFinite,
      child: RaisedButton(
        child: Text('Clear location records'),
        onPressed: () {
          FileManager.clearLogFile();
          // setState()告知view有值有變動，因此要更新
          setState(() {
            logStr = '';
          });

        },
      ),
    );
    String msgStatus = "-";
    if (isRunning != null) {
      if (isRunning) {
        // TODO: add heatmap of something
        msgStatus = 'Activated.';
      } else {
        msgStatus = 'Deactivated';
      }
    }
    final status = Text("Locator: $msgStatus");

    String lastRunTxt = "-";
    String warningMsg = "";
    if (isRunning != null) {
      if (isRunning) {
        if (lastTimeLocation == null || lastLocation == null) {
          lastRunTxt = "?";
        } else {
          lastRunTxt = LocationServiceRepository.formatLog(lastLocation) + " @ " +
              LocationServiceRepository.formatDateLog(lastTimeLocation);
          if (hm.isInHotSpot(lastLocation.latitude, lastLocation.longitude)){
            warningMsg += "\nYou are in hot spot (${hm.getZoneName()})";
          }
        }
      }
    }
//    final lastRun = Text(
//      "Last position: $lastRunTxt",
//    );
    final lastRunAndWarning = RichText(
      text: TextSpan(
        text: "Last position: $lastRunTxt",
        style: TextStyle(color: Colors.black, fontSize: 16),
        children: <TextSpan>[
          TextSpan(text: warningMsg, style: TextStyle(color: Colors.red)),
        ],
      ),
    );
    final log = Text(
      logStr,
    );

    //drawer
    Widget _createHeader() {
      return DrawerHeader(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.blue,
//              image: DecorationImage(
//                  fit: BoxFit.fill,
//                  image:  AssetImage('path/to/header_background.png'))
                  ),
          child: Stack(children: <Widget>[
            Positioned(
                bottom: 12.0,
                left: 16.0,
                child: Text("Setting",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w500))),
          ]));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('LocaBuz'),
      ),
      body: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[btnTurnBle, msg, Divider(color: Colors.black),
              btnLoca, btnClear, status, lastRunAndWarning, Divider(),
              log],
            // description, stop, listView
          ),
        ),
      ),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            _createHeader(),
//            DrawerHeader(
//              child: Text('Setting'),
//              decoration: BoxDecoration(
//                color: Colors.blue,
//              ),
//            ),
            ListTile(
              leading: new CircleAvatar(child: Icon(Icons.bluetooth)),
//                title: Text('BLE Devices'),
              title: Text('Bluetooth List'),
              onTap: () async {
                // Update the state of the app
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) =>
                      BleListPage(start: true,
                          bleDevs: listBleDevs,
                          cfg: cfg,
                          cbUpdateCountBle: updateCountBle,
                          cbStartBleScan: startBleScan
                      )
                  ),
                );
                // note that result will be NULL if user press back button (on the left-up)
//                print("wtf? $result");
//                for (var bd in bleDevs) {
//                  print("bd name: ${bd.name}");
//                }

                // Then close the drawer
                Navigator.pop(context);

              },
            ),
//              ListTile(
//                title: Text('Item 2'),
//                onTap: () {
//                  // Update the state of the app
//                  // ...
//                  // Then close the drawer
//                  Navigator.pop(context);
//                },
//              ),
          ],
        ),
      ),
    );
  }

  void onStop() {
    BackgroundLocator.unRegisterLocationUpdate();
    setState(() {
      isRunning = false;
//      lastTimeLocation = null;
//      lastLocation = null;
    });
  }

  void _onStart() async {
    if (await _checkLocationPermission()) {
      _startLocator();
      setState(() {
        isRunning = true;
        lastTimeLocation = null;
        lastLocation = null;
      });
    } else {
      // show error

    }
  }

  Future<bool> _checkLocationPermission() async {
    final access = await LocationPermissions().checkPermissionStatus();
    switch (access) {
      case PermissionStatus.unknown:
      case PermissionStatus.denied:
      case PermissionStatus.restricted:
        final permission = await LocationPermissions().requestPermissions(
          permissionLevel: LocationPermissionLevel.locationAlways,
        );
        if (permission == PermissionStatus.granted) {
          return true;
        } else {
          return false;
        }
        break;
      case PermissionStatus.granted:
        return true;
        break;
      default:
        return false;
        break;
    }
  }

  void _startLocator() {
    Map<String, dynamic> data = {'countInit': 1};
    BackgroundLocator.registerLocationUpdate(
      LocationCallbackHandler.callback,
      initCallback: LocationCallbackHandler.initCallback,
  //    initDataCallback: data,
/*
        Comment initDataCallback, so service not set init variable,
        variable stay with value of last run after unRegisterLocationUpdate
 */
      disposeCallback: LocationCallbackHandler.disposeCallback,
      androidNotificationCallback: LocationCallbackHandler.notificationCallback,
      settings: LocationSettings(
          notificationChannelName: "Location tracking service",
          notificationTitle: "Start Location Tracking example",
          notificationMsg: "Track location in background example",
          wakeLockTime: 20,
          autoStop: false,
          distanceFilter: 10,
          interval: 5),
    );
  }

  @override
  void dispose() {
    _every30Seconds?.cancel();
    _every20Seconds?.cancel();
    super.dispose();
  }
}
