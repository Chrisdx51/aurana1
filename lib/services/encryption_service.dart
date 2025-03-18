import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionService {
  // 32 characters = 256-bit encryption key (symmetric key for now)
  static final _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1');
  static final _iv = encrypt.IV.fromLength(16); // 16 bytes Initialization Vector

  /// Encrypts plain text and returns an encrypted Base64 string
  static String encryptMessage(String plainText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));

    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64; // Returns the encrypted text in Base64 format
  }

  /// Decrypts Base64 string and returns the plain text
  static String decryptMessage(String encryptedText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(_key));

    final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted; // Returns the original message
  }
}
