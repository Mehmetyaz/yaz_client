import 'package:yaz_client/src/services/auth_service.dart';
import 'package:yaz_client/src/services/verification.dart';
import 'package:yaz/yaz.dart';
import 'package:yaz_client/src/socket_service.dart';

class PasswordResetRequest {
  PasswordResetRequest(this.mail);

  final _verified = false.notifier;

  final String mail;

  VerificationSession? session;

  VerificationSession verifyUser(void Function() onVerifySuccess) {
    session = VerificationSession.create(
        topic: "password_reset",
        onVerify: () async {
          _verified.value = true;
          onVerifySuccess();
        },
        type: VerificationType.mail,
        receivePort: mail);
    return session!;
  }

  Future<bool> setNewPassword(String password) async {
    if (_verified.value) {
      var res = await socketService.customOperation("set_new_password",
          {"id": session!.id, "password": password});
      print("DB REF: ${res.fullData}");
      return res.isSuccess && res.data!["success"];
    }
    print("Before ensure verified");
    return false;
  }
}
