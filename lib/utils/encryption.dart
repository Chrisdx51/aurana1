import 'package:encrypt/encrypt.dart';

final key = Key.fromLength(32);
final iv = IV.fromLength(16);
final encrypter = Encrypter(AES(key));

String encryptMessage(String plainText) {
  final encrypted = encrypter.encrypt(plainText, iv: iv);
  return encrypted.base64;
}

String decryptMessage(String encryptedText) {
  final decrypted = encrypter.decrypt(Encrypted.fromBase64(encryptedText), iv: iv);
  return decrypted;
}
