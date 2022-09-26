import 'dart:convert';

import 'package:async/async.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:windows1251/windows1251.dart';

class SchoolNotFound implements Exception {}

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool _rememberMe = false;
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _schoolNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    () async {
      var prefs = await SharedPreferences.getInstance();
      var password = prefs.getString("password");
      if (password != null) {
        var username = prefs.getString("username");
        var schoolName = prefs.getString("school_name");
        setState(() {
          _usernameController.text = username!;
          _schoolNameController.text = schoolName!;
          _passwordController.text = password;
          _rememberMe = true;
        });
        if (!mounted) return;
        await _authenticate(context);
      }
    }();
  }

  Future<void> _authenticate(BuildContext context) async {
    var password = _passwordController.text;
    var username = _usernameController.text;
    var schoolName = _schoolNameController.text;
    var authCanceled =
        false; // This is a workaround. I don't know why it is not canceling.
    var schoolNotSpecified = false;
    var auth = CancelableOperation.fromFuture(() async {
      try {
        var url = "https://sgo.edu-74.ru";
        var client = Dio(BaseOptions(baseUrl: "$url/webapi/", headers: {
          'user-agent': 'NetSchoolAPI/5.0.3',
          'referer': url,
          'accept': '*/*',
          'accept-encoding': 'gzip, deflate',
          'connection': 'keep-alive'
        }));
        client.options.headers.remove("charset");
        client.options.headers.remove("content-type");
        var loginData = await client.get("logindata");
        var sessionIdRoundOne = loginData.headers["set-cookie"]![0]
            .split(" ")[0]; // For `auth/getdata`
        client.options.headers["cookie"] =
            sessionIdRoundOne.substring(0, sessionIdRoundOne.length - 1);
        var preAuthDataResponse = await client.post("auth/getdata");
        var sessionIdRoundTwo = preAuthDataResponse.headers["set-cookie"]![0]
            .split(" ")[0]; // For `login`
        client.options.headers["cookie"] =
            sessionIdRoundTwo.substring(0, sessionIdRoundOne.length - 1);
        var preAuthData = preAuthDataResponse.data;
        var salt = preAuthData["salt"];
        preAuthData.remove("salt");
        var encodedPassword = utf8.encode(md5
            .convert(const Windows1251Encoder().convert(password))
            .toString());
        var pw2 = md5.convert(utf8.encode(salt) + encodedPassword).toString();
        var pw = pw2.substring(0, password.length);
        Response authData;
        try {
          final params = <String, dynamic>{
            ...(await _address(schoolName, client)),
            ...preAuthData,
            "loginType": 1,
            "un": username,
            "pw": pw,
            "pw2": pw2,
          };
          client.options.headers.addAll({
            "Cookie":
                sessionIdRoundTwo.substring(0, sessionIdRoundTwo.length - 1),
            "Content-Type": "application/x-www-form-urlencoded"
          });
          authData = await client.post("login", data: params);
        } on SchoolNotFound {
          schoolNotSpecified = true;
          rethrow;
        }
        client.options.headers["at"] = authData.headers["at"];
        if (_rememberMe) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString("username", username);
          await prefs.setString("password", password);
          await prefs.setString("school_name", schoolName);
        }
      } finally {
        if (!authCanceled) {
          Navigator.of(context).pop(true);
        }
        if (schoolNotSpecified) {
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
        authCanceled = true;
      }
    });
  }

  Future<Map<String, int>> _address(String schoolName, Dio client) async {
    var resp = (await client.get("addresses/schools")).data;
    for (final school in resp) {
      if (school["name"] == schoolName) {
        return {
          "cid": school["countryId"],
          "sid": school["stateId"],
          "pid": school["municipalityDistrictId"],
          "cn": school["cityId"],
          "sft": 2,
          "scid": school["id"],
        };
      }
    }
    throw SchoolNotFound();
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
                                    await prefs.remove("school_name");
                                    _passwordController.text = "";
                                    _usernameController.text = "";
                                    _schoolNameController.text = "";
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
                      _authenticate(context);
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
