import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<String?> signIn() async {
    try {
      await _googleSignIn.signOut(); // force account picker
      final account = await _googleSignIn.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      return auth.idToken;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
