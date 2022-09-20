import 'package:flutter/material.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool rememberMe = false;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void authenticate(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              content: Text(
                  usernameController.text + ", " + passwordController.text));
        });
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Pita"),
        ),
        body: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text("Authentication", style: TextStyle(fontSize: 30)),
                const SizedBox(height: 10),
                Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: TextField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                            hintText: "Username",
                            border: OutlineInputBorder()))),
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: TextField(
                      obscureText: true,
                      controller: passwordController,
                      autocorrect: false,
                      decoration: const InputDecoration(
                          hintText: "Password", border: OutlineInputBorder())),
                ),
                const SizedBox(height: 10),
                Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Row(
                      children: [
                        Checkbox(
                            value: rememberMe,
                            onChanged: (state) {
                              setState(() {
                                rememberMe = state!;
                              });
                            }),
                        const Text("Remember Me")
                      ],
                    )),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: () {
                      authenticate(context);
                    },
                    child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Text(
                          "Authenticate",
                          style: TextStyle(fontSize: 18),
                        ))),
              ]),
        ));
  }
}
