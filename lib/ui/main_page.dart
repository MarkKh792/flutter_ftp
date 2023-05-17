import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ftp/ftp_manager.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key, required this.title});

  final String title;

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final TextEditingController addressTextController = TextEditingController();
  final TextEditingController loginTextController = TextEditingController();
  final TextEditingController passwordTextController = TextEditingController();
  final TextEditingController portTextController =
      TextEditingController(text: '21');

  bool showPassword = false;

  FtpManager ftpManager = FtpManager();

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
                      return _buildOutlinedButton(themeColor, snapshot.data!);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(child: Container(color: Colors.grey))
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

  Widget _buildOutlinedButton(Color backgroundColor, bool isConnected) {
    return SizedBox(
      width: 200,
      height: 55,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
        ),
        onPressed: () {
          !isConnected
              ? ftpManager.connect(
                  addressTextController.text,
                  loginTextController.text,
                  passwordTextController.text,
                  int.parse(portTextController.text),
                )
              : ftpManager.disconnect();
        },
        child: Text(
          isConnected ? 'Disconnect' : 'Connect',
          style: const TextStyle(fontSize: 20, color: Colors.black),
        ),
      ),
    );
  }
}
