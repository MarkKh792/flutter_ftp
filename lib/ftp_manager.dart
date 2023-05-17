import 'dart:async';
import 'dart:developer';

import 'package:ftpconnect/ftpconnect.dart';

class FtpManager {
  late final FTPConnect ftpConnect;
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  final StreamController<bool> _connectionController =
      StreamController.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  void connect(String host, String login, String password, int port) async {
    ftpConnect = FTPConnect(host, user: login, pass: password, port: port);

    try {
      bool result = await ftpConnect.connect();
      _updateConnectionState(result);
    } catch (e) {
      _logErrorMessage('Connection error!');
    }

    _logMessage('Connected: $_isConnected');

    _connectionController.sink.add(_isConnected);
  }

  void disconnect() async {
    try {
      bool result = await ftpConnect.disconnect();
      result ? _isConnected = false : null;
    } catch (e) {
      _logErrorMessage('Disconnection error!');
    }

    _connectionController.sink.add(_isConnected);

    _logMessage('Connected: $_isConnected');
  }

  void getDirectoryNames() async {
    try {
      final names =
          await ftpConnect.listDirectoryContentOnlyNames(ListCommand.NLST);
      _logMessage(names.toString());
    } on FTPConnectException catch (e) {
      if (e.message.contains('Timeout')) {
        _updateConnectionState(false);
      }

      _logErrorMessage(e.message);
    } catch (e) {
      _logErrorMessage(e.toString());
    }
  }

  void getDirectoryContent() async {
    try {
      final files = await ftpConnect.listDirectoryContent(ListCommand.LIST);
      _logMessage(files.toString());
    } on FTPConnectException catch (e) {
      if (e.message.contains('Timeout')) {
        _updateConnectionState(false);
      }

      _logErrorMessage(e.toString());
    } catch (e) {
      _logErrorMessage(e.toString());
    }
  }

  void _updateConnectionState(bool connectionState) {
    _isConnected = connectionState;
    _connectionController.sink.add(connectionState);
  }

  void _logMessage(String message) {
    log(message, name: 'FTP response');
  }

  void _logErrorMessage(String message) {
    log(message, name: 'ERROR');
  }
}
