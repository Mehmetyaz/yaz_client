import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';


///
mixin TypeCasts {
  ///
  static Nonce nonceCast(List<dynamic> nonce) {
    var nListInt = <int>[];
    for (var i in nonce) {
      if (i.runtimeType == int) {
        nListInt.add(i);
      } else {
        nListInt.add(int.parse(i));
      }
    }
    return Nonce(nListInt);
  }

  ///
  static Uint8List uint8Cast(List listDynamic) {
    var nListInt = <int>[];
    for (var i in listDynamic) {
      if (i.runtimeType == int) {
        nListInt.add(i);
      } else {
        nListInt.add(int.parse(i));
      }
    }
    return Uint8List.fromList(nListInt);
  }
}

/// Static methods about User Model
mixin UserModelStatics {
  /// return DateTime from json stored type time (millisecondsSinceEpoch)
  static DateTime dateFromJson(int raw) =>
      DateTime.fromMillisecondsSinceEpoch(raw ?? 0);

  /// return json stored type time (millisecondsSinceEpoch) from DateTime
  static int dateToInt(DateTime time) => time == null ? null : time.millisecondsSinceEpoch;
}

///
mixin Statics {
  ///
  static String getRandomId(int len) {
    var _characters =
        'ABCDEFGHIJKLMNOPRSTUQYZXWabcdefghijqklmnoprstuvyzwx0123456789';
    var _listChar = _characters.split('');
    var _lentList = _listChar.length;
    var _randId = <String>[];

    for (var i = 0; i < len; i++) {
      var _randNum = Random();
      var _r = _randNum.nextInt(_lentList);
      _randId.add(_listChar[_r]);
    }
    var id = StringBuffer();
    for (var c in _randId) {
      id.write(c);
    }
    return id.toString() ?? '';
  }

  ///Get Time Ago
}
