import 'package:localstorage/localstorage.dart';

import 'ble_dev.dart';

class Configuration {

  //    for reference
//    SharedPreferences prefs = await SharedPreferences.getInstance();
//    int counter = (prefs.getInt('counter') ?? 0) + 1;
//    print('Pressed $counter times.');
//    await prefs.setInt('counter', counter);

  Map<String, dynamic> Ble;  // dict
  LocalStorage storage = new LocalStorage('LocaBuz_conf');
  List<BleDev> bleDevs = <BleDev>[
//    BleDev('name1', 'mac1')
  ];

  Configuration(){
    loadConfigure();
  }

  bool isInitialized(){
    return Ble == null ? false : true;
  }

  Future<void> loadConfigure() async{
    await storage.ready;
    print("load configuration");
    Ble = await storage.getItem('ble')?? {};
//    print("mConfBle = $mConfBle");
  }
  Future<void> addToConfigure(String mac) async{
    await storage.ready;
    if (!Ble.containsKey(mac)){
      Ble[mac] = 1;
      await updateConfigure();
//      print("mConfBle = $mConfBle");
    }
  }
  Future<void> delFromConfigure(String mac) async{
    await storage.ready;
    if (Ble.containsKey(mac)){
//      mConfBle[mac] = 0;
      Ble.remove(mac);
      await updateConfigure();
//      print("mConfBle = $mConfBle");
    }
  }
  Future<void> updateConfigure() async{
    await storage.ready;

    return storage.setItem('ble', Ble);
  }

}