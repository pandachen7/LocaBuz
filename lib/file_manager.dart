import 'dart:io';

import 'package:path_provider/path_provider.dart';

class FileManager {

  static String buff = "123";
  static Directory directory;
  static File _file;

  static Future<void> init() async {
    directory = await getTemporaryDirectory();
    print("FileManager init done ${directory.toString()}");
    _file = File('${directory.path}/log.txt');
  }

  static Future<void> writeToLogFile(String log) async {
    final file = await _getTempLogFile();
    await file.writeAsString(log, mode: FileMode.append);
  }

  static Future<String> readLogFile() async {
    final file = await _getTempLogFile();
    return file.readAsString();
  }

  static Future<File> _getTempLogFile() async {
    // I have no method to handle it
    _file = File('/data/user/0/panda.loca_buz/cache/log.txt');
    if (!await _file.exists()) {
      await _file.writeAsString('');
    }
    return _file;
  }

  static Future<void> clearLogFile() async {
    final file = await _getTempLogFile();
    await file.writeAsString('');
  }
}
