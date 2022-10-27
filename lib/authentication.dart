import 'package:async/async.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pita/main_screen.dart';
import 'package:pita/net_school_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool _rememberMe = false;
  final _websiteUrlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _schoolNameController = TextEditingController();

  @override
  void initState() {
    () async {
      var prefs = await SharedPreferences.getInstance();
      var schoolName = prefs.getString("school_name");
      if (schoolName != null) {
        _schoolNameController.text = schoolName;
        var websiteUrl = prefs.getString("website_url");
        _websiteUrlController.text = websiteUrl!;
        setState(() {});
      }
      var password = prefs.getString("password");
      if (password != null) {
        _passwordController.text = password;
        var username = prefs.getString("username");
        _usernameController.text = username!;
        _rememberMe = true;
        setState(() {});
        if (!mounted) return;
        await _authenticate(context);
      }
    }();
    super.initState();
  }

  Future<void> _authenticate(BuildContext buttonContext) async {
    var password = _passwordController.text;
    var username = _usernameController.text;
    var schoolName = _schoolNameController.text;
    var websiteUrl = _websiteUrlController.text;
    var popDialog =
        true; // This is a workaround. I don't know why the future is not canceling.
    var auth = CancelableOperation.fromFuture(() async {
      try {
        var client = NetSchoolClient(LogInParams(
            url: websiteUrl,
            username: username,
            password: password,
            schoolName: schoolName));
        client.logIn();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("school_name", schoolName);
        await prefs.setString("website_url", websiteUrl);
        if (_rememberMe) {
          await prefs.setString("username", username);
          await prefs.setString("password", password);
        }
        if (!mounted) return;
        if (popDialog) {
          popDialog = false;
          Navigator.of(context).pop(true);
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => MainScreen(
                        client: client,
                      )));
        }
      } on SchoolNotFound {
        if (popDialog) {
          Navigator.of(context).pop(true);
        }
        await showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                actions: [
                  TextButton(
                    child: const Text("Got it"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  )
                ],
                content:
                    const Text("The school you specified cannot be found."),
              );
            });
      }
    }());
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
            child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: const [
            CircularProgressIndicator(
              value: null,
            ),
            SizedBox(width: 16),
            Text("Authenticating..."),
          ]),
        ));
      },
    ).then((result) {
      if (result == null) {
        // The user tapped out of the dialog.
        auth.cancel();
        popDialog = false;
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _schoolNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Pita")),
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
                        controller: _websiteUrlController,
                        decoration: const InputDecoration(
                            labelText: "Website link",
                            border: OutlineInputBorder()))),
                const SizedBox(height: 10),
                Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: TextField(
                        controller: _schoolNameController,
                        decoration: const InputDecoration(
                            labelText: "School name",
                            border: OutlineInputBorder()))),
                const SizedBox(height: 10),
                Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                            labelText: "Username",
                            border: OutlineInputBorder()))),
                const SizedBox(height: 10),
                Container(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: TextField(
                      obscureText: true,
                      controller: _passwordController,
                      autocorrect: false,
                      decoration: const InputDecoration(
                          labelText: "Password", border: OutlineInputBorder())),
                ),
                const SizedBox(height: 10),
                Container(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Row(
                      children: [
                        Checkbox(
                            value: _rememberMe,
                            onChanged: (state) {
                              setState(() {
                                _rememberMe = state!;
                                if (!_rememberMe) {
                                  () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    await prefs.remove("username");
                                    await prefs.remove("password");
                                    _passwordController.text = "";
                                    _usernameController.text = "";
                                  }();
                                }
                              });
                            }),
                        const Text("Remember me")
                      ],
                    )),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: () {
                      try {
                        _authenticate(context);
                      } on DioError catch (error) {
                        if (error.type == DioErrorType.other) {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  actions: [
                                    TextButton(
                                      child: const Text("Got it"),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    )
                                  ],
                                  content: const Text(
                                      "The website URL you specified is invalid."),
                                );
                              });
                        }
                      }
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
