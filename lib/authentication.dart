import 'dart:convert';

import 'package:async/async.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pita/main_screen.dart';
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
        if (websiteUrl != null) {
          _websiteUrlController.text = websiteUrl;
        }
        setState(() {});
      }
      var password = prefs.getString("password");
      if (password != null) {
        _passwordController.text = password;
        var username = prefs.getString("username");
        if (username != null) {
          _usernameController.text = username;
          _rememberMe = true;
        }
        setState(() {});
        if (!mounted) return;
        await _authenticate(context);
      }
    };
    super.initState();
  }

  Future<void> _authenticate(BuildContext buttonContext) async {
    var password = _passwordController.text;
    var username = _usernameController.text;
    var schoolName = _schoolNameController.text;
    var websiteName = _websiteUrlController.text;
    var authCanceled =
        false; // This is a workaround. I don't know why it is not canceling.
    var schoolNotSpecified = false;
    var auth = CancelableOperation.fromFuture(() async {
      try {
        print("BAR");
        var url = _websiteUrlController.text;
        var client = Dio(BaseOptions(baseUrl: "$url/webapi/", headers: {
          'user-agent': 'NetSchoolAPI/5.0.3',
          'referer': url,
          'accept': '*/*',
          'accept-encoding': 'gzip, deflate',
          'connection': 'keep-alive'
        }));
        // не помню точно все что нужно апи, но без этого работает)
        // client.options.headers.remove("charset");
        // client.options.headers.remove("content-type");
        //var loginData = await client.get("logindata");
        // print(loginData.data);
        // print(loginData.headers);
        // var sessionIdRoundOne =
        //     loginData.headers["Cookie"]![0].split(" ")[0]; // For `auth/getdata`
        // print(sessionIdRoundOne.substring(0, sessionIdRoundOne.length - 1));
        // client.options.headers["cookie"] =
        //     sessionIdRoundOne.substring(0, sessionIdRoundOne.length - 1);
        var preAuthDataResponse = await client.post("auth/getdata");
        print(preAuthDataResponse.headers);
        var sessionIdRoundTwo = preAuthDataResponse.headers["set-cookie"]![0]
            .split(" ")[0]; // For `login`
        //print(sessionIdRoundTwo.substring(0, sessionIdRoundTwo.length - 1));
        // client.options.headers["cookie"] =
        //     sessionIdRoundTwo.substring(0, sessionIdRoundTwo.length - 1);
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
          //возможно можно получше)
          final List<String> setCookie = [];
          authData.headers['set-cookie']?.forEach((cookie) {
            final String cookieString = cookie.split(' ').first;
            print(cookieString);
            setCookie.add(cookieString.substring(0, cookieString.length - 1));
          });
          client.options.headers.addAll({
            "Cookie": setCookie.join('; '),
          });
        } on SchoolNotFound {
          schoolNotSpecified = true;
          rethrow;
        }
        print("BLAH");
        client.options.headers["at"] = authData.data["at"];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("school_name", schoolName);
        await prefs.setString("website_name", websiteName);
        if (_rememberMe) {
          await prefs.setString("username", username);
          await prefs.setString("password", password);
        }
        print("FUG");
        if (!mounted) return;
        print("CHEECH");
        //pop прогресс диалога
        Navigator.pop(context);
        //пушим мейн скрин с реплейсментом, чтобы обратно
        //бэкбаттоном нельзя было вернуться
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MainScreen(
                      client: client,
                    )));
        print("CHWEERCH");
      } finally {
        // это и делало pop только что запушенного MainScreen,
        // поэтому казалось что ничего не происходит
        // if (!authCanceled) {
        //   Navigator.of(context).pop(true);
        // }
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
                      print("BEEP");
                      try {
                        _authenticate(context);
                      } on DioError catch (error) {
                        print("FOXY SAYS FUCK");
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
