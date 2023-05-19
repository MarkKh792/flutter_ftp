import 'dart:async';
import 'dart:io';

import 'package:ftpconnect/ftpconnect.dart' hide Logger;
import 'package:logger/logger.dart';

class FtpManager {
  late FTPConnect ftpConnect;
  final Logger logger = Logger(printer: PrettyPrinter(methodCount: 0));
  String currentDirectory = '/';
  bool _isConnected = false;
  late final Directory? downloadDirectory;
  final StreamController<bool> _connectionController =
      StreamController.broadcast();
  final StreamController<List<FTPEntry>> _filesController =
      StreamController.broadcast();
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

      getDirectoryContent();
    } catch (e) {
      _logErrorMessage('CONNECT', 'Connection error!, ${e.toString()}');
    }

    _connectionController.sink.add(_isConnected);
  }

  void disconnect() async {
    try {
      bool result = await ftpConnect.disconnect();
      result ? _isConnected = false : null;
    } catch (e) {
      _logErrorMessage('DISCONNECT', 'Disconnection error!, ${e.toString()}');
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

      _logErrorMessage('GET DIR NAMES', e.toString());
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
        'got ${files.length} elements in "$currentDirectory"',
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

      if (status) {
        currentDirectory = await ftpConnect.currentDirectory();
        getDirectoryContent();
      }

      _logMessage(
          'CHANGE DIR',
          status
              ? 'Changed directory to "$currentDirectory"'
              : 'Failed to change directory to "$name"');
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
  ) async {
    if (downloadDirectory == null) {
      _logErrorMessage('DOWNLOAD', 'Didn\'t found the "Downloads" directory!');
      return;
    }

    try {
      bool success = false;

      if (type == FTPEntryType.DIR) {
        final Directory destinationDir =
            Directory('${downloadDirectory!.path}/$contentName');
        success = await ftpConnect.downloadDirectory(
            contentName, destinationDir, ListCommand.LIST);
        return;
      }

      if (type == FTPEntryType.FILE) {
        final destinationPath = downloadDirectory!.path;
        final File destinationFile = File('$destinationPath/$contentName');
        success = await ftpConnect.downloadFile(contentName, destinationFile);
      }
      _logMessage(
        'DOWNLOAD',
        success ? 'Download succeeded' : 'Download failed',
      );
    } on FTPConnectException catch (e) {
      if (e.message.contains('Timeout')) {
        _updateConnectionState(false);
      }

      _logErrorMessage('DOWNLOAD', e.toString());
    } catch (e) {
      _logErrorMessage('DOWNLOAD', e.toString());
    }
  }

  void createDirectory(String name) async {
    try {
      final result = await ftpConnect.makeDirectory(name);
      _logMessage('CREATE DIR', result ? 'Success!' : 'Failed');

      if (result) {
        getDirectoryContent();
      }
    } on FTPConnectException catch (e) {
      if (e.message.contains('Timeout')) {
        _updateConnectionState(false);
      }

      _logErrorMessage('CREATE DIR', e.toString());
    } catch (e) {
      _logErrorMessage('CREATE DIR', e.toString());
    }
  }

  void deleteDirectory(String name) async {
    try {
      final result = await ftpConnect.deleteDirectory(name, ListCommand.LIST);
      _logMessage('DELETE DIR', result ? 'Success!' : 'Failed');

      if (result) {
        getDirectoryContent();
      }
    } on FTPConnectException catch (e) {
      if (e.message.contains('Timeout')) {
        _updateConnectionState(false);
      }

      _logErrorMessage('DELETE DIR', e.toString());
    } catch (e) {
      _logErrorMessage('DELETE DIR', e.toString());
    }
  }

  void deleteFile(String name) async {
    try {
      final result = await ftpConnect.deleteFile(name);
      _logMessage('DELETE FILE', result ? 'Success!' : 'Failed');

      getDirectoryContent();
    } on FTPConnectException catch (e) {
      if (e.message.contains('Timeout')) {
        _updateConnectionState(false);
      }

      _logErrorMessage('DELETE FILE', e.toString());
    } catch (e) {
      _logErrorMessage('DELETE FILE', e.toString());
    }
  }

  void uploadFile(String path) async {
    try {
      final fileToUpload = File(path);
      final result = await ftpConnect.uploadFile(fileToUpload);

      _logMessage('UPLOAD FILE', result ? 'Success!' : 'Failed');

      if (result) {
        getDirectoryContent();
      }
    } on FTPConnectException catch (e) {
      if (e.message.contains('Timeout')) {
        _updateConnectionState(false);
      }

      _logErrorMessage('UPLOAD FILE', e.toString());
    } catch (e) {
      _logErrorMessage('UPLOAD FILE', e.toString());
    }
  }

  void nextDirectory(String name) {
    _changeDirectory(name);
  }

  void previousDirectory() {
    if (currentDirectory == '/') return;
    _changeDirectory('..');
  }

  void _updateConnectionState(bool connectionState) {
    _isConnected = connectionState;
    _connectionController.sink.add(connectionState);
  }

  void _logMessage(String prefix, String message) {
    logger.i('[$prefix]: $message.');
  }

  void _logErrorMessage(String prefix, String message) {
    logger.e('[$prefix]: $message');
  }
}
