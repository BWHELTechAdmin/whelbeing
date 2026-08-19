import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whelbeing/config/supabase_config.dart';
import 'package:whelbeing/repositories/auth_repository.dart';

void main() {
  group('AuthRepository.updateEmail', () {
    test(
      'normalizes the address and includes the confirmation redirect',
      () async {
        late UserAttributes capturedAttributes;
        String? capturedRedirect;
        final repository = AuthRepository(
          SupabaseClient('https://example.supabase.co', 'test-anon-key'),
          updateUser: (attributes, {emailRedirectTo}) async {
            capturedAttributes = attributes;
            capturedRedirect = emailRedirectTo;
          },
        );

        await repository.updateEmail('  New.Address@Example.COM ');

        expect(capturedAttributes.email, 'new.address@example.com');
        expect(capturedRedirect, SupabaseConfig.emailConfirmationRedirectUrl);
      },
    );

    test('rejects an invalid address before requesting an update', () async {
      var requestCount = 0;
      final repository = AuthRepository(
        SupabaseClient('https://example.supabase.co', 'test-anon-key'),
        updateUser: (_, {emailRedirectTo}) async {
          requestCount++;
        },
      );

      await expectLater(
        repository.updateEmail('not-an-email'),
        throwsArgumentError,
      );

      expect(requestCount, 0);
    });
  });
}
