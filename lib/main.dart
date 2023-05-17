import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'FTP client home page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
