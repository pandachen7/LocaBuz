import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:developer';

//import 'package:flutter_blue/flutter_blue.dart';
import 'ble_dev.dart';

//json storage
import 'configuration.dart';

typedef void MyCallback();

class BleListPage extends StatefulWidget {

  final bool start;
  final List<BleDev> bleDevs;
  final Configuration cfg;

//  final MyCallback callback;
  // ALTER
  final Function() cbUpdateCountBle;
  final Function() cbStartBleScan;

  BleListPage({this.start = true, this.bleDevs, this.cfg,
    this.cbUpdateCountBle, this.cbStartBleScan});

  _BleListPage createState() => new _BleListPage();
}

class _BleListPage extends State<BleListPage> {

//  FlutterBlue flutterBlue = FlutterBlue.instance;
//  List<BluetoothDevice> devicesList = new List<BluetoothDevice>();

//  List<BleDev> bleDevs = <BleDev>[
////    BleDev('name1', 'mac1')
//  ];

//  FlutterBlue.instance.state.listen
  bool isDiscovering;
  String strMsg = "";

  Timer t1;
  final TextEditingController textController = new TextEditingController();

  @override
  void initState() {
    super.initState();

    isDiscovering = widget.start;

    // TODO: found bleDev .then call setState to update list
    t1 = Timer.periodic(Duration(seconds: 3), (Timer t) {
      if (!mounted) return; // 頁面已不存在(被使用者關掉等), 就不要再進行refresh
//      log("update list");
      setState(() {});
    });
//    flutterBlue.state.listen((state) {
//      if (state == BluetoothState.off) {
//        //Alert user to turn on bluetooth.
//        //        strDescription = 'Please turn on Bluetooth';
//      } else if (state == BluetoothState.on) {
//        //if bluetooth is enabled then go ahead.
//        // Make sure user's device gps is on.
//        var tt = flutterBlue.startScan();
//      }
//    });
//
//    // BLE
//    flutterBlue.connectedDevices
//        .asStream()
//        .listen((List<BluetoothDevice> devices) {
//      for (BluetoothDevice device in devices) {
//        _addDeviceTolist(device, isConnected: true);
//      }
//    });
//    flutterBlue.scanResults.listen((List<ScanResult> results) {
//      for (ScanResult result in results) {
//        _addDeviceTolist(result.device);
//      }
//    });
//  }
//
//  _addDeviceTolist(final BluetoothDevice device, {bool isConnected = false}) async {
//    if (!cfg.isInitialized()){
//      // Plz wait for the configuration init
//      return;
//    }
//    log("found ${device.name}");
//
//    if (!widget.devicesList.contains(device)) {
//      if (!mounted) return;
//      setState(() {
//        widget.devicesList.add(device);
//
//        if (device.name != "") { //  && device.name.contains("Emitter")
////          log("now mConfBle is $mConfBle");
//          if(cfg.Ble.containsKey(device.id.id)) {
//            BleDev bd = new BleDev(device.name, device.id.id, device, selected: true);
//            if (!isConnected) {
//              bd.dev.connect().then((value) => bd.discoverChara());
//            }
//            widget.bleDevs.add(bd);
//          }else{
//            widget.bleDevs.add(BleDev(device.name, device.id.id, device));
//          }
//        }
//      });
//    }
  }
  Widget _buildListView(){
    return ConstrainedBox(
      constraints: new BoxConstraints(
        minHeight: 100.0,
        maxHeight: 300.0,
      ),

      child: new ListView(
        children: List.generate(widget.bleDevs.length, (index) {

          var trailingIcon, colorItem;
          if (widget.bleDevs[index].isSelected) {
            if (widget.bleDevs[index].isDiscovered) {
              // already connected
              colorItem = Colors.blue;
              trailingIcon = Icons.bluetooth_connected;
            }else{
              // now connecting (not completed)
              colorItem = Colors.blueGrey;
              trailingIcon = Icons.sync;
            }
          }else{
            // scanned
            colorItem = Colors.grey;
            trailingIcon = Icons.bluetooth;
          }

          return ListTile(
            onLongPress: () {
              setState(() {
                widget.bleDevs[index].isSelected = !widget.bleDevs[index].isSelected;
              });
              if(widget.bleDevs[index].isSelected){
                widget.bleDevs[index].connect().then((value) =>
                  widget.bleDevs[index].discoverChara().then((value) =>
                   widget.cbUpdateCountBle()));
                widget.cfg.addToConfigure(widget.bleDevs[index].mac);
//                  log("bleDevs = ${bleDevs.length}");
              }else{
                widget.bleDevs[index].disconnect();
                widget.cfg.delFromConfigure(widget.bleDevs[index].mac);
//                  log("bleDevs = ${bleDevs.length}");
                widget.cbUpdateCountBle();
              }
//            log(paints[index].selected.toString());
            },
            selected: widget.bleDevs[index].isSelected,
            leading: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: Container(
                width: 48,
                height: 20,
                padding: EdgeInsets.symmetric(vertical: 0.0),
                alignment: Alignment.center,
                child: CircleAvatar(
//                  backgroundColor: paints[index].colorpicture,
//                    backgroundColor: (widget.bleDevs[index].isSelected)? Colors.blue: Colors.grey
                  backgroundColor: colorItem,
                ),
              ),
            ),
            title: Text(widget.bleDevs[index].dev.name),
            subtitle: Text(widget.bleDevs[index].mac),
//              Row(
//                children: <Widget>[
//
//                  Visibility(
//                    child:  Icon(Icons.sync),
//                    visible: widget.bleDevs[index].isDiscovered? false : true,
//                  )
//                ]
//            ),
//            trailing: (widget.bleDevs[index].isSelected)
//                ? Icon(Icons.bluetooth_connected)
//                : Icon(Icons.bluetooth),
            trailing: Icon(trailingIcon),
          );
        }),
      ),
    );
  }
  void updateState() {
    setState(() {});
  }
  @override
  Widget build(BuildContext context) {
    final bleLabel = Text(
      "Connect bluetooth device (LongPress to toggle)",
    );
    final listView = _buildListView();
    final msg = Text(
      strMsg
    );
    final btnTestBleDev = Center(
      child: RaisedButton(
        onPressed: () async {
//          bool bNotDiscover = false;
//          String strBuff = "";
          // Navigate back to first route when tapped.
          for (var bd in widget.bleDevs) {
            if (!bd.isSelected || !bd.isDiscovered) {
//            if (!bd.bDiscovered){
//              strBuff = "${bd.dev.name} not ready\n";
//              bNotDiscover = true;
//            }
              continue;
            }

            await bd.writeTo([0xff, 0xff, 0x3, 0xa0]);
          }
//          if (bNotDiscover){
//            strMsg = strBuff;
//          }else{
//            strMsg = "";
//          }
        },
        child: Text('Test Speaker 📢'),
      ),
    );
    final btnTestBleDevLoud = Center(
      child: RaisedButton(
        onPressed: () async {
          for (var bd in widget.bleDevs) {
            await bd.writeTo([0xff, 0xff, 0x3, 0x28]);
          }
        },
        child: Text('LOUDLY 📢📢📢'),
      ),
    );
    final btnsInRow1 = new Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[btnTestBleDev, btnTestBleDevLoud],
    );

    // must add Flexible if be added in a Row, or raise "no size Exception"
    final txtInput = new Flexible(
        child: TextField(
        controller: textController,
        textAlign: TextAlign.left,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Enter text to be sent',
          hintStyle: TextStyle(color: Colors.grey),
        ),
      )
    );

    final btnBleSend = RaisedButton(
      onPressed: () async {

        for (var bd in widget.bleDevs) {
          await bd.writeStrTo(textController.text);
        }

//          Fluttertoast.showToast(
//              msg: "Sent msg ${textController.text}",
//              toastLength: Toast.LENGTH_SHORT,
//              gravity: ToastGravity.CENTER,
//              timeInSecForIosWeb: 1
//          );
          Fluttertoast.showToast(
              msg: "Sent msg ${textController.text}",
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
              timeInSecForIosWeb: 1,
              backgroundColor: Colors.blueGrey,
              textColor: Colors.white,
              fontSize: 16.0
          );

      },
      child: Text('Send text'),
    );

    final btnsInRow2 = new Row(
      children: <Widget>[txtInput, btnBleSend],
    );

    final btnDone = Center(
      child: RaisedButton(
        onPressed: () {
          // Navigate back to first route when tapped.

          // if user press back btn, no data return lol (e.g. the "back" as below)
          Navigator.pop(context, "back");
        },
        child: Text('Done'),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text("Bluetooth device list"),
        actions: <Widget>[
          Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  widget.cbStartBleScan();
                },
                child: Text('SCAN',
                    style: TextStyle(height: 2, fontSize: 15),)
              )
          ),
        ],
      ),
      body: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[bleLabel, listView, btnsInRow1, btnsInRow2], // description, stop, btnDone
//              children: <Widget>[description, divider, btnLoca, btnClear, status, lastRun, divider, log], // stop
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel scan
    t1?.cancel();
    log("back to main page");

    textController?.dispose();
    super.dispose();
  }
}