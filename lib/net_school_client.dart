import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio_log/interceptor/dio_log_interceptor.dart';
import 'package:pita/models.dart';
import 'package:windows1251/windows1251.dart';

class SchoolNotFound implements Exception {}

class LogInParams {
  String username;
  String url;
  String password;
  String schoolName;

  LogInParams(
      {required this.username,
      required this.url,
      required this.password,
      required this.schoolName});
}

class NetSchoolClient {
  late final Dio _inner;
  final LogInParams _logInParams;

  NetSchoolClient(this._logInParams) {
    _inner = Dio(BaseOptions(baseUrl: "${_logInParams.url}/webapi/", headers: {
      'user-agent': 'NetSchoolAPI/5.0.3',
      'referer': _logInParams.url,
    }));
  }

  Future<List<Announcement>> getAnnouncements({int take = -1}) async {
    var resp = await _request("announcements",
        options: Options(method: "GET"), queryParameters: {"take": take}) as List<dynamic>;
    var announcements = resp
        .map((announcement) => Announcement.fromJson(announcement))
        .toList();
    return announcements;
  }

  Future<dynamic> _request(
    String path, {
    data,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    int reloginAttemptsAmount = 0;
    int readAttemptsAmount = 0;
    int connectionAttemptsAmount = 0;
    while (true) {
      try {
        return await _inner.request(path,
            data: data,
            queryParameters: queryParameters,
            cancelToken: cancelToken,
            options: options,
            onSendProgress: onSendProgress,
            onReceiveProgress: onReceiveProgress);
      } on DioError catch (e) {
        if (e.response?.statusCode == HttpStatus.unauthorized &&
            reloginAttemptsAmount < 5) {
          ++reloginAttemptsAmount;
          logIn();
        } else if (e.type == DioErrorType.connectTimeout &&
            connectionAttemptsAmount < 5) {
          ++connectionAttemptsAmount;
        } else if (e.type == DioErrorType.receiveTimeout &&
            readAttemptsAmount < 10) {
          ++readAttemptsAmount;
        } else {
          rethrow;
        }
      }
    }
  }

  Future<Map<String, int>> _address(String schoolName, Dio client) async {
    DioLogInterceptor.enablePrintLog = false;
    var resp = (await client.get("addresses/schools")).data;
    DioLogInterceptor.enablePrintLog = true;
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

  void logIn() async {
    var client =
        Dio(BaseOptions(baseUrl: "${_logInParams.url}/webapi/", headers: {
      'user-agent': 'NetSchoolAPI/5.0.3',
      'referer': _logInParams.url,
    }));
    client.interceptors.add(DioLogInterceptor());
    var loginData = await client.get("logindata");
    var sessionIdRoundOne =
        loginData.headers["set-cookie"]![0].split(" ")[0]; // For `auth/getdata`
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
        .convert(const Windows1251Encoder().convert(_logInParams.password))
        .toString());
    var pw2 = md5.convert(utf8.encode(salt) + encodedPassword).toString();
    var pw = pw2.substring(0, _logInParams.password.length);
    Response authData;
    final params = <String, dynamic>{
      ...(await _address(_logInParams.schoolName, client)),
      ...preAuthData,
      "loginType": 1,
      "un": _logInParams.username,
      "pw": pw,
      "pw2": pw2,
    };
    client.options.headers.addAll({
      "Cookie": sessionIdRoundTwo.substring(0, sessionIdRoundTwo.length - 1),
      "Content-Type": "application/x-www-form-urlencoded"
    });
    authData = await client.post("login", data: params);
    client.options.headers["at"] = authData.headers["at"];
  }
}
