//import 'package:localstorage/localstorage.dart';

//import 'ble_dev.dart';
import 'package:flutter/material.dart';
import 'dart:convert';


class Heatmap {

  var context;
  Map<String, dynamic> jsonData, mapIndexes;
  String zoneName = "";
  bool inHotSpot = false;

  Heatmap({context}){
    this.context = context;

    loadJson();
  }

  loadJson() async {
    String data = await DefaultAssetBundle.of(context).loadString('assets/json/heatmap.json');
    jsonData = json.decode(data);
    mapIndexes = jsonData["heatmap"]["indexes"];
//    print("mapIndexs: $mapIndexes");

  }

  bool isInHotSpot(double latitude, double longitude) {

    // heatmap structure is as below
    /*
{
  "heatmap": {
    "indexs": {
      "24.12_120.67": {
        "area":{
          "latitude": [24.1216, 24.1316],
          "longitude": [120.67, 120.68]
        }
      }
    }
  }
}
     */

    // You input a key, e.g. "24.1_120.6"
    String strKey = ((latitude * 10).floor() / 10).toString() + "_" +
                    ((longitude * 10).floor() / 10).toString();
//    print("strKey: $strKey");

    if (mapIndexes.containsKey(strKey)){
      for(var zone in mapIndexes[strKey]){
        List<dynamic> lat2 = zone["area"]["latitude"];
        List<dynamic> lon2 = zone["area"]["longitude"];
        lat2.sort();
        lon2.sort();

        if(lat2[0] <= latitude && latitude <= lat2[1] &&
            lon2[0] <= longitude && longitude <= lon2[1]){

          zoneName = zone["area"]["name"].toString();
          inHotSpot = true;
          return true;
        }
      }
    }
    return false;
  }
  String getZoneName(){
    return zoneName;
  }
//  bool isInitialized(){
//    return Ble == null ? false : true;
//  }

}