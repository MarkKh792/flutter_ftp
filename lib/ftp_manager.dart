import 'dart:async';
import 'dart:developer';

import 'package:ftpconnect/ftpconnect.dart';

class FtpManager {
  late final FTPConnect ftpConnect;
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  final StreamController<bool> _connectionController = StreamController();
  Stream<bool> get connectionStream => _connectionController.stream;

  void connect(String host, String login, String password, int port) async {
    ftpConnect = FTPConnect(host, user: login, pass: password, port: port);

    try {
      _isConnected = await ftpConnect.connect();
    } catch (e) {
      log('Connection error!', name: 'ERROR');
    }

    _logMessage('Connected: $_isConnected');

    _connectionController.sink.add(_isConnected);
  }

  void disconnect() async {
    try {
      bool result = await ftpConnect.disconnect();
      result ? _isConnected = false : null;
    } catch (e) {
      log('Disconnection error!', name: 'ERROR');
    }

    _connectionController.sink.add(_isConnected);

    _logMessage('Connected $_isConnected');
  }

  void _logMessage(String message) {
    log(message, name: 'FTP response');
  }
}
