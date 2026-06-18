import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  GoogleSignIn _buildSignIn() => GoogleSignIn(
        clientId: dotenv.env['GOOGLE_CLIENT_ID'],
        scopes: ['email', 'profile'],
      );

  Future<String?> signIn() async {
    try {
      final signIn = _buildSignIn();
      await signIn.signOut(); // force account picker every time
      final account = await signIn.signIn();
      if (account == null) return null;
      final auth = await account.authentication;
      return auth.idToken;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await _buildSignIn().signOut();
    } catch (_) {}
  }
}
