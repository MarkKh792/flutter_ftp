import 'package:flutter/material.dart';

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

  bool showPassword = false;

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
                  _buildTextField(loginTextController, 'login'),
                  const SizedBox(width: 20),
                  _buildPasswordField(passwordTextController, 'Password'),
                  const SizedBox(width: 20),
                  _buildOutlinedButton(themeColor),
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
      flex: 1,
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
      flex: 1,
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

  Widget _buildOutlinedButton(Color backgroundColor) {
    return SizedBox(
      width: 200,
      height: 55,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
        ),
        onPressed: () {},
        child: const Text(
          'Connect',
          style: TextStyle(fontSize: 20, color: Colors.black),
        ),
      ),
    );
  }
}
