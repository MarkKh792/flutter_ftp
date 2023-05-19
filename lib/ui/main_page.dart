import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path_provider/path_provider.dart';

import '../ftp_manager.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // You can set controllers initial values to avoid entering them every time
  final TextEditingController addressTextController =
      TextEditingController(text: '192.168.1.167');
  final TextEditingController loginTextController =
      TextEditingController(text: 'ftp');
  final TextEditingController passwordTextController =
      TextEditingController(text: 'ftp');
  final TextEditingController portTextController =
      TextEditingController(text: '21');

  final TextEditingController newDirController = TextEditingController();

  bool showPassword = false;

  final FtpManager ftpManager = FtpManager();

  @override
  void initState() {
    // Get the "Downloads" directory. Does not work on Android.
    getDownloadsDirectory().then(
      (value) => ftpManager.downloadDirectory = value,
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).colorScheme.inversePrimary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(addressTextController, 'Host'),
                  const SizedBox(width: 20),
                  _buildTextField(loginTextController, 'Login'),
                  const SizedBox(width: 20),
                  _buildPasswordField(passwordTextController, 'Password'),
                  const SizedBox(width: 20),
                  _buildPortField(portTextController, 'Port'),
                  const SizedBox(width: 20),
                  StreamBuilder<bool>(
                    initialData: false,
                    stream: ftpManager.connectionStream,
                    builder: (context, snapshot) {
                      return _buildOutlinedButton(
                        themeColor,
                        _getConnectionButtonSpecs(snapshot.data!),
                      );
                    },
                  ),
                ],
              ),
              StreamBuilder<bool>(
                  initialData: false,
                  stream: ftpManager.connectionStream,
                  builder: (context, snapshot) {
                    return Row(
                      children: [
                        _buildOutlinedButton(
                          themeColor,
                          _getGetDirectoryContentButtonSpecs(snapshot.data!),
                        ),
                        const SizedBox(width: 10),
                        _buildOutlinedButton(
                          themeColor,
                          _getGetDirectoryNamesButtonSpecs(snapshot.data!),
                        ),
                        const SizedBox(width: 10),
                        _buildOutlinedButton(
                          themeColor,
                          _getUploadFileSpecs(
                            snapshot.data!,
                            '/home/mark/Downloads/btn_lava.png',
                          ),
                        ),
                      ],
                    );
                  }),
              const SizedBox(height: 10),
              StreamBuilder<bool>(
                  initialData: false,
                  stream: ftpManager.connectionStream,
                  builder: (context, snapshot) {
                    return Row(
                      children: [
                        _buildOutlinedButton(
                          Colors.transparent,
                          _getBackButtonSpecs(snapshot.data!),
                        ),
                      ],
                    );
                  }),
              StreamBuilder<bool>(
                initialData: false,
                stream: ftpManager.connectionStream,
                builder: (context, snapshot) {
                  return Visibility(
                    visible: snapshot.data!,
                    child: Expanded(
                      child: StreamBuilder<List<FTPEntry>>(
                        initialData: const [],
                        stream: ftpManager.filesStream,
                        builder: (context, snapshot) {
                          return _buildFilesList(snapshot.data!);
                        },
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String title,
  ) {
    return Expanded(
      flex: 4,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: title,
        ),
      ),
    );
  }

  Widget _buildPasswordField(TextEditingController controller, String title) {
    return Expanded(
      flex: 4,
      child: TextField(
        obscureText: !showPassword,
        obscuringCharacter: '*',
        controller: controller,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          counter: Row(
            children: [
              Checkbox(
                value: showPassword,
                onChanged: (state) => setState(
                  () => showPassword = !showPassword,
                ),
              ),
              const Text('Show password'),
            ],
          ),
          labelText: title,
        ),
      ),
    );
  }

  Widget _buildPortField(TextEditingController controller, String title) {
    return Expanded(
      flex: 1,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: title,
        ),
      ),
    );
  }

  Widget _buildOutlinedButton(
    Color backgroundColor,
    (void Function()? onTap, Widget title) specs,
  ) {
    return SizedBox(
      width: 200,
      height: 55,
      child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: backgroundColor,
          ),
          onPressed: specs.$1,
          child: specs.$2),
    );
  }

  Widget _buildFilesList(List<FTPEntry> elements) {
    return ListView(
      children: [
        ListTile(
          title: Row(
            children: [
              _buildTextField(newDirController, 'New directory'),
              _buildOutlinedButton(
                Colors.transparent,
                _getCreateDirSpecs(newDirController),
              ),
            ],
          ),
        ),
        for (int i = 0; i < elements.length; i++)
          ListTile(
            trailing: SizedBox(
              width: 220,
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => ftpManager.downloadContent(
                        elements[i].type, elements[i].name, 'destinationPath'),
                    child: const Text('Download'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () {
                      elements[i].type == FTPEntryType.DIR
                          ? ftpManager.deleteDirectory(elements[i].name)
                          : ftpManager.deleteFile(elements[i].name);
                    },
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ),
            title: Text(
              '[${elements[i].type.name}]  ${elements[i].size}  ${elements[i].name}',
            ),
            onTap: () {
              if (elements[i].type == FTPEntryType.DIR) {
                ftpManager.nextDirectory(elements[i].name);
              }
            },
          )
      ],
    );
  }

  (void Function() onTap, Widget title) _getConnectionButtonSpecs(
    bool isConnected,
  ) {
    return (
      () => !isConnected
          ? ftpManager.connect(
              addressTextController.text,
              loginTextController.text,
              passwordTextController.text,
              int.parse(portTextController.text),
            )
          : ftpManager.disconnect(),
      Text(
        isConnected ? 'Disconnect' : 'Connect',
        style: const TextStyle(fontSize: 20, color: Colors.black),
      ),
    );
  }

  (void Function()? onTap, Widget title) _getGetDirectoryContentButtonSpecs(
    bool isConnected,
  ) {
    return (
      isConnected ? () => ftpManager.getDirectoryContent() : null,
      Text(
        'Get directory content',
        style: TextStyle(
            fontSize: 14, color: isConnected ? Colors.black : Colors.grey),
      ),
    );
  }

  (void Function()? onTap, Widget title) _getGetDirectoryNamesButtonSpecs(
    bool isConnected,
  ) {
    return (
      isConnected ? () => ftpManager.getDirectoryNames() : null,
      Text(
        'Get names only',
        style: TextStyle(
            fontSize: 14, color: isConnected ? Colors.black : Colors.grey),
      ),
    );
  }

  (void Function()? onTap, Widget title) _getBackButtonSpecs(bool isConnected) {
    return (
      isConnected ? () => ftpManager.previousDirectory() : null,
      GestureDetector(
        child: Icon(
          Icons.arrow_back,
          color: isConnected ? Colors.red : null,
        ),
      ),
    );
  }

  (void Function()? onTap, Widget title) _getUploadFileSpecs(
    bool isConnected,
    String filePath,
  ) {
    return (
      isConnected ? () => ftpManager.uploadFile(filePath) : null,
      Text(
        'Upload file',
        style: TextStyle(
            fontSize: 14, color: isConnected ? Colors.black : Colors.grey),
      ),
    );
  }

  (void Function()? onTap, Widget title) _getCreateDirSpecs(
    TextEditingController controller,
  ) {
    return (
      () {
        ftpManager.createDirectory(controller.text);
        controller.clear();
      },
      const Text('Create'),
    );
  }
}
