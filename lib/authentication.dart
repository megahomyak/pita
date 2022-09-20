import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:windows1251/windows1251.dart';

class SchoolNotFound implements Exception {}

class AuthenticationScreen extends StatefulWidget {
  const AuthenticationScreen({super.key});

  @override
  State<AuthenticationScreen> createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  bool rememberMe = false;
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final schoolNameController = TextEditingController();

  void _authenticate(BuildContext context) async {
    var url = "https://sgo.edu-74.ru";
    var client = Dio(BaseOptions(
        baseUrl: "$url/webapi/",
        headers: {'user-agent': 'NetSchoolAPI/5.0.3', 'referer': url}));
    var authCookiesResponse = await client.get("logindata");
    var authCookies = authCookiesResponse.headers["set-cookie"]!;
    client.options.headers.addAll({"cookie": authCookies[0]});
    var preAuthData = (await client.post("auth/getdata")).data;
    var salt = preAuthData["salt"];
    preAuthData.remove("salt");
    var password = passwordController.text;
    var encodedPassword = utf8.encode(
        md5.convert(const Windows1251Encoder().convert(password)).toString());
    var pw2 = md5.convert(utf8.encode(salt) + encodedPassword).toString();
    var pw = pw2.substring(0, password.length);
    Response authData;
    try {
      authData = await client.post("login", queryParameters: {
        ...(await _address(schoolNameController.text, client)),
        ...preAuthData,
        "loginType": 1,
        "un": usernameController.text,
        "pw": pw,
        "pw2": pw2,
      });
    } on DioError catch (e) {
      print(e.response);
      print(e.response?.statusCode);
      rethrow;
    }
    client.options.headers["at"] = authData.headers["at"];
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
                        controller: schoolNameController,
                        decoration: const InputDecoration(
                            hintText: "School Name",
                            border: OutlineInputBorder()))),
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
