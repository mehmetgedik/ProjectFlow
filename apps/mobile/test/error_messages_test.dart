import 'package:flutter_test/flutter_test.dart';

import 'package:openproject_mobile/utils/error_messages.dart';

void main() {
  group('ErrorMessages.userFriendly', () {
    test('404 / not found returns İstenen kayıt bulunamadı', () {
      expect(
        ErrorMessages.userFriendly('404 Not Found'),
        'İstenen kayıt bulunamadı.',
      );
      expect(
        ErrorMessages.userFriendly(Exception('Kayıt bulunamadı')),
        'İstenen kayıt bulunamadı.',
      );
    });

    test('timeout returns Sunucu yanıt vermedi', () {
      expect(
        ErrorMessages.userFriendly('Connection timeout'),
        'Sunucu yanıt vermedi. Bağlantıyı kontrol edip tekrar deneyin.',
      );
      expect(
        ErrorMessages.userFriendly('timed out'),
        'Sunucu yanıt vermedi. Bağlantıyı kontrol edip tekrar deneyin.',
      );
    });

    test('401 / unauthorized returns Oturum geçersiz', () {
      expect(
        ErrorMessages.userFriendly('401 Unauthorized'),
        'Oturum geçersiz. Lütfen tekrar giriş yapın.',
      );
    });

    test('403 / forbidden returns yetki mesajı', () {
      expect(
        ErrorMessages.userFriendly('403 Forbidden'),
        'Bu işlem için yetkiniz yok.',
      );
    });

    test('socket/connection/network returns Bağlantı hatası', () {
      expect(
        ErrorMessages.userFriendly('SocketException: Connection failed'),
        'Bağlantı hatası. İnternet bağlantınızı kontrol edin.',
      );
    });

    test('empty or null returns Beklenmeyen bir hata', () {
      expect(
        ErrorMessages.userFriendly(''),
        'Beklenmeyen bir hata oluştu.',
      );
      expect(
        ErrorMessages.userFriendly('   '),
        'Beklenmeyen bir hata oluştu.',
      );
    });

    test('message parameter overrides error', () {
      expect(
        ErrorMessages.userFriendly(Exception('404'), message: 'Custom'),
        'Custom',
      );
    });

    test('long raw message returns generic message', () {
      final long = 'x' * 150;
      expect(
        ErrorMessages.userFriendly(long),
        'Bir hata oluştu. Lütfen tekrar deneyin veya bağlantınızı kontrol edin.',
      );
    });
  });
}
