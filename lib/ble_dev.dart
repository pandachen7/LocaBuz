import 'dart:convert';
import 'dart:developer';

import 'package:flutter_blue/flutter_blue.dart';

class BleDev {
  static const ISSC_PROPRIETARY_SERVICE_UUID = "6e400001";
  // may be 6e400002-****-****-****-************
  static const UUIDSTR_ISSC_TRANS_RX = "6e400002";
  static const UUIDSTR_ISSC_TRANS_TX = "6e400003";

//  final String name;
  final String mac;
  bool isSelected;
  bool isConnected = false, isDiscovered = false;
  BluetoothDevice dev;
  BluetoothCharacteristic charaRx;
  BluetoothCharacteristic charaTx;

  BleDev(this.mac, this.dev, {this.isSelected : false});

  Future<void> connect() async{
    log("connect to ${dev.name}");
    await dev.connect();
    isSelected = true;
    isConnected = true;
  }
  bool chkAvalable(){
    // change what you want
    return isDiscovered && isSelected;
  }
  Future<void> discoverChara() async{
    if(!isConnected)return;
    int settingBle = 0;
    await this.dev.discoverServices().then((list) {
      for (var service in list) {
        if (service.uuid.toString().substring(0, 8) !=
            ISSC_PROPRIETARY_SERVICE_UUID) {
          continue;
        }
        for (var chara in service.characteristics) {
          if (chara.uuid.toString().substring(0, 8) ==
              UUIDSTR_ISSC_TRANS_RX) {
            this.charaRx = chara;
            settingBle += 1;
          }
          if (chara.uuid.toString().substring(0, 8) ==
              UUIDSTR_ISSC_TRANS_TX) {
            this.charaTx = chara;
            settingBle += 2;
          }
        }
      }
      if (settingBle == 3){
        log("[${this.mac}] found chara Rx and Tx");
        this.isDiscovered = true;
      }else{
        log("[${this.mac}] setting BLE failed!!");
      }
    });
  }
  Future<void> setNotify() async{
    if(!chkAvalable())return;

    if (!this.charaTx.isNotifying) {
      log("set Notify as true");
      await this.charaTx.setNotifyValue(true);
    }
  }
  Future<void> writeStrTo(String txt) async{
    List<int> bytes = utf8.encode(txt);

    writeTo(bytes);
  }
  Future<void> writeTo(List<int> bytes) async{
    if(!chkAvalable())return;

    if (this.charaRx != null) {
//      bool successfulWrite = true;
//      try{
      this.charaRx.write(bytes, withoutResponse: true); // send if connection is successful
//      }on Exception catch (_) {
//        log("throwing new error $_");
//        successfulWrite = false;
//      }
//      if (!successfulWrite){
//        disconnect();
//      }

//      String data = "test";
//      List<int> bytes = utf8.encode(data);

      log("[${this.mac}] write $bytes to ${this.charaRx.uuid}");
    }else{
      log("[${this.mac}] charaRx is null!!");
    }
  }
  Future<void> readFrom() async {
    if(!chkAvalable())return;

    if (this.charaTx != null) {
      this.charaTx.value.listen((value) {
//          widget.readValues[this.chara_tx.uuid] = value;
        if(value.length > 0) {
          print("read $value from ${this.charaTx.uuid}");
        }
      });

      // Dont know how to resolve, maybe the architecture of Nordic is diff?
//      sleep(const Duration(seconds: 5));
//      try{
//        List<int> value = await chara.read() ;
//        print("value $value from ${chara.uuid}");
//      }on Exception catch (_) {
//        print("throwing new error $_");
//      }

//      if(chara.properties.read) {

//      print("value $value from ${chara.uuid}");
//      }
    }else{
      print("charaTx is null!!");
    }
  }
  Future<void> disconnect() async{
    dev.disconnect();
    isSelected = false;
    isConnected = false;
    isDiscovered = false;
  }
}