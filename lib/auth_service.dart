import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthenticationDataSource {
  Future<void> register(String email, String password, String passwordConfirm);
  Future<void> login(String email, String password);
}

class AuthenticationRemote extends AuthenticationDataSource {
  User? currentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  @override
  Future<void> login(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(), password: password.trim());
    } catch (e) {
      throw e;
    }
  }

  @override
  Future<void> register(
      String email, String password, String passwordConfirm) async {
    if (password != passwordConfirm) {
      throw Exception("Passwords do not match.");
    }

    if (password == passwordConfirm) {
      try {
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // await FirebaseAuth.instance
        //     .createUserWithEmailAndPassword(email: email, password: password)
        //     .then((value) {
        // FirestoreDataSource().createUser(email);

        // .then(value) 이후부터는 firestore 연동을 위해 추가된 부분이다.
        // .then(onValue)는 createUserWithEmailAndPassword 함수가 비동기적으로 완료된 후,
        // 그 결과를 onValue라는 콜백 함수에 전달하여 실행됩니다.
        print('Create Accouht Success');
      } catch (e) {
        print('Create Accouh Fail : ${e.toString()}');
        throw e;
      }
    }
  }
}
