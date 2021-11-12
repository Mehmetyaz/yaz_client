import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaz_client/src/models/user/current_user.dart';
import 'package:yaz_client/src/services/pass_reset.dart';

import '../models/socket_data/socket_data.dart';
import '../socket_service.dart';
import 'encryption.dart';

///
AuthService authService = AuthService();

///
class AuthService extends ChangeNotifier {
  ///Singleton
  factory AuthService() => _instance;

  AuthService._internal();

  static final AuthService _instance = AuthService._internal();

  /// İf not nul Current User Logged In
  String? userID;

  ///Current Session Auth Token
  String? authToken;

  ///Is Logged In
  bool isLoggedIn = false;

  /// If not null isLoggedIn
  CurrentUser? currentUser;

  /// Nonces for shared prefs crypt
  ///
  ///
  /// F... Nonce for shared pref
  final _nonce = Nonce(<int>[98, 45, 55, 37, 85, 6, 48, 2, 59, 65, 55, 48]);

  /// F... Cnonce for shared pref
  final _cNonce = Nonce(<int>[98, 66, 55, 25, 85, 6, 55, 2, 59, 7, 88, 8]);

  ///
  ///

  /// Return remember button is marked
  Future<bool> get _isLoggedRemember async {
    var preferences = await SharedPreferences.getInstance();
    var remember = preferences.containsKey('remember_user');
    if (remember) {
      return (preferences.getBool('remember_user') ?? false);
    } else {
      return false;
    }
  }

  ///
  Future<void> saveAuthData(Map<String, dynamic> authData) async {
    var preferences = await SharedPreferences.getInstance();
    await preferences.setBool('remember_user', true);
    var encryptData = await encryptionService.encrypt1(
        data: authData, cnonce: _cNonce, nonce: _nonce);
    var jsonString = jsonEncode({'data': encryptData});
    await preferences.setString('auth_data', jsonString);
  }

  Future<Map<String, dynamic>> get _savedAuthData async {
    var preferences = await SharedPreferences.getInstance();

    var authData = preferences.containsKey('auth_data');

    if (authData) {
      try {
        ///   {
        ///   data : [UInt8List]
        ///   }
        var dataEncrypted = json.decode(preferences.getString('auth_data')!);

        ///   {
        ///
        ///   data : {
        ///             "mail" : "mail",
        ///          }
        ///
        ///   }
        var decryptedData = await (encryptionService.decrypt1(
            data: dataEncrypted['data'], nonce: _nonce, cnonce: _cNonce));

        return {
          'auth_type': 'auth',
          'user_mail': decryptedData['user_mail'],
          'password': decryptedData['password'],
          'time': DateTime.now().millisecondsSinceEpoch,
        };
      } catch (e) {
        preferences.remove("auth_data");
        preferences.remove("remember_user");
        return {
          'auth_type': 'guess',
          'time': DateTime.now().millisecondsSinceEpoch
        };
      }
    } else {
      return {
        'auth_type': 'guess',
        'time': DateTime.now().millisecondsSinceEpoch
      };
    }
  }

  /// User data at the beginning of the session
  Future<Map<String, dynamic>> get initialAuthData async {
    var _isLogged = await (_isLoggedRemember);
    if (_isLogged) {
      return _savedAuthData;
    } else {
      return {
        'auth_type': 'guess',
        'time': DateTime.now().millisecondsSinceEpoch
      };
    }
  }

  ///Login initial
  Future<void> loginWithTokenInit(
      String? token, Map<String, dynamic> userData) async {
    //TODO: Set User Data
    currentUser = CurrentUser.fromJson(userData);
    userID = currentUser?.userID;
    //TODO:Set User Image
    authToken = token;
    isLoggedIn = true;
  }

  Future<bool?> userExist(String mail) async {
    var res = await socketService
        .customOperation("user_exists", {"mail_or_phone": mail});
    return res.isSuccess && res["exists"];
  }

  Future<PasswordResetRequest?> passwordResetRequest(String mail,
      {Duration verificationDuration = const Duration(minutes: 1)}) async {
    if ((await userExist(mail)) ?? false) {
      return PasswordResetRequest(mail);
    } else {
      print("USER NOT EXISTS");
      return null;
    }
  }

  ///Register User
  Future<CurrentUser?> register(String mail, String password,
      {String? name,
      String? lastName,
      DateTime? birthDate,
      String? biography}) async {
    try {
      if (!socketService.connected) {
        await socketService.connect();
      }
      var _us = CurrentUser.create(
          mail: mail,
          firstName: name,
          lastName: lastName,
          birthDate: birthDate,
          biography: biography);

      var user = _us.toJson();

      user["password"] = password;
      var dat = await socketService.sendAndWaitMessage(SocketData.create(
          data: user,
          type: "register",
          messageId: socketService.options.deviceID));
      await dat.decrypt();

      if (dat.data != null && !dat.data!["success"]) {
        throw Exception(dat.data!["reason"]);
      }

      var resUs = CurrentUser.fromJson(dat.data!["user"]);
      return resUs;
    } on Exception {
      return null;
    }
  }

  ///Login
  Future<bool> login(String mail, String pass, {bool remember = true}) async {
    if (isLoggedIn) return isLoggedIn;

    if (!socketService.connected) {
      await socketService.connect();
    }

    var response = await socketService.sendAndWaitMessage(SocketData.create(
        data: {
          'token': socketService.options.token,
          'user_mail': mail,
          'password': pass
        },
        type: "login"));

    if (response.isSuccess) {
      if (remember) {
        await saveAuthData({'user_mail': mail, 'password': pass});
      }
      currentUser = CurrentUser.fromJson(response.data!);
      userID = currentUser?.userID;

      //TODO:Set User Image

      print("LOGIN TOKEN: ${response.fullData}");

      authToken = response.data!['token'];
      socketService.options.token = authToken;
      isLoggedIn = true;
      notifyListeners();
    } else {
      notifyListeners();
      isLoggedIn = false;
    }
    return isLoggedIn;
  }

  ///Logout
  Future<void> logout(Function onLogOut) async {
    var preferences = await SharedPreferences.getInstance();
    await preferences.setBool('remember_user', false);
    await preferences.remove('auth_data');
    isLoggedIn = false;
    currentUser = null;
    userID = null;
    authToken = null;
    onLogOut();
    notifyListeners();
  }
}
