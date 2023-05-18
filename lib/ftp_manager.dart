import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart';

class FtpManager {
  late final FTPConnect ftpConnect;
  bool _isConnected = false;
  List<String> history = ['/'];
  late final Directory? downloadDirectory;
  final StreamController<bool> _connectionController =
      StreamController.broadcast();
  final StreamController<List<FTPEntry>> _filesController = StreamController();

  bool get isConnected => _isConnected;
  Stream<List<FTPEntry>> get filesStream => _filesController.stream;
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
      _filesController.add(files);
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

  void _changeDirectory(String name) async {
    try {
      final status = await ftpConnect.changeDirectory(name);
      _logMessage('Changed directory to $name: $status');

      // Get the content of this directory
      getDirectoryContent();
    } on FTPConnectException catch (e) {
      if (e.message.contains('Timeout')) {
        _updateConnectionState(false);
      }

      _logErrorMessage(e.toString());
    } catch (e) {
      _logErrorMessage(e.toString());
    }
  }

  void downloadContent(
    FTPEntryType type,
    String contentName,
    String destinationPath,
  ) {
    if (downloadDirectory == null) {
      _logErrorMessage('Can\'t find the "Downloads" directory!');
      return;
    }

    if (type == FTPEntryType.DIR) {
      final Directory destinationDir =
          Directory('${downloadDirectory!.path}/$contentName');
      ftpConnect.downloadDirectory(
          contentName, destinationDir, ListCommand.LIST);
      return;
    }

    if (type == FTPEntryType.FILE) {
      final destinationPath = downloadDirectory!.path;
      final File destinationFile = File('$destinationPath$contentName');
      ftpConnect.downloadFile(contentName, destinationFile);
    }
  }

  void nextDirectory(String name) {
    history.add(name);
    _changeDirectory(name);
  }

  void previousDirectory() {
    if (history.length <= 1) return;
    history.removeLast();

    _changeDirectory(history.last);
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
