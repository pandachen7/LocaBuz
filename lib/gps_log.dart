import 'package:localstorage/localstorage.dart';

class GpsLog {

  static LocalStorage storage = new LocalStorage('LocaBuz_gps_log');
  static Map<String, dynamic> gpsLog;

//  GpsLog(){
//    loadConfigure();
//  }

//  static Future<void> writeToLogFile(String log) async {
//    final file = await _getTempLogFile();
//    await file.writeAsString(log, mode: FileMode.append);
//  }
//
//  static Future<String> readLogFile() async {
//    await storage.ready;
//    gpsLog = await storage.getItem('gps_log')?? {};
//    return file.readAsString();
//  }
//
//
//  static Future<void> clearLogFile() async {
//    final file = await _getTempLogFile();
//    await file.writeAsString('');
//  }
}
