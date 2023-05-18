import 'dart:async';
import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart' hide Logger;
import 'package:logger/logger.dart';

class FtpManager {
  late FTPConnect ftpConnect;
  final Logger logger = Logger(printer: PrettyPrinter(methodCount: 0));
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
    ftpConnect = FTPConnect(
      host,
      user: login,
      pass: password,
      port: port,
      timeout: 15,
    );

    try {
      bool result = await ftpConnect.connect();
      _updateConnectionState(result);
      _logMessage('CONNECT', 'Connected: $_isConnected');
    } catch (e) {
      _logErrorMessage('CONNECT', 'Connection error!');
    }

    _connectionController.sink.add(_isConnected);
  }

  void disconnect() async {
    try {
      bool result = await ftpConnect.disconnect();
      result ? _isConnected = false : null;
    } catch (e) {
      _logErrorMessage('DISCONNECT', 'Disconnection error!');
    }

    _connectionController.sink.add(_isConnected);

    _logMessage('DISCONNECT', 'Connected: $_isConnected');
  }

  void getDirectoryNames() async {
    try {
      final names =
          await ftpConnect.listDirectoryContentOnlyNames(ListCommand.NLST);
      _logMessage('GET DIR NAMES', names.toString());
    } on FTPConnectException catch (e) {
      if (e.message.contains('Timeout')) {
        _updateConnectionState(false);
      }

      _logErrorMessage('GET DIR NAMES', e.message);
    } catch (e) {
      _logErrorMessage('GET DIR NAMES', e.toString());
    }
  }

  void getDirectoryContent() async {
    try {
      final files = await ftpConnect.listDirectoryContent(ListCommand.LIST);
      _filesController.add(files);
      _logMessage(
        'GET DIR CONTENT',
        'got ${files.length} elements in "${history.last}"',
      );
    } on FTPConnectException catch (e) {
      if (e.message.contains('Timeout')) {
        _updateConnectionState(false);
      }

      _logErrorMessage('GET DIR CONTENT', e.toString());
    } catch (e) {
      _logErrorMessage('GET DIR CONTENT', e.toString());
    }
  }

  void _changeDirectory(String name) async {
    try {
      final status = await ftpConnect.changeDirectory(name);

      status
          ? _logMessage('CHANGE DIR', 'Changed directory to $name')
          : _logErrorMessage(
              'CHANGE DIR', 'Failed to change directory to $name');

      // Get the content of this directory
      getDirectoryContent();
    } on FTPConnectException catch (e) {
      if (e.message.contains('Timeout')) {
        _updateConnectionState(false);
      }

      _logErrorMessage('CHANGE DIR', e.toString());
    } catch (e) {
      _logErrorMessage('CHANGE DIR', e.toString());
    }
  }

  void downloadContent(
    FTPEntryType type,
    String contentName,
    String destinationPath,
  ) {
    if (downloadDirectory == null) {
      _logErrorMessage('DOWNLOAD', 'Didn\'t found the "Downloads" directory!');
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

  void _logMessage(String prefix, String message) {
    logger.i('[$prefix]: $message.');
    //log(message, name: 'FTP response');
  }

  void _logErrorMessage(String prefix, String message) {
    logger.e('[$prefix]: $message');
    //log(message, name: 'ERROR');
  }
}
