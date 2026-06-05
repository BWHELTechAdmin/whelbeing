/// BWhel auth configuration.
///
/// Replace the placeholder values below with your real credentials before
/// running the app.  None of these values should be committed to a public
/// repository — consider using --dart-define or a .env approach for CI.
///
/// Setup checklist:
///   1. Create a project at https://supabase.com and copy the project URL
///      and anon key from Project Settings → API.
///   2. Enable Google provider in Supabase Authentication → Providers → Google.
///      Paste the Web Client ID (and secret) from Google Cloud Console.
///   3. For iOS Google Sign-In:
///      - Download GoogleService-Info.plist from Firebase / Google Cloud Console.
///      - Add it to ios/Runner/ in Xcode.
///      - Add the REVERSED_CLIENT_ID as a URL scheme in Info.plist.
///   4. For iOS Apple Sign-In:
///      - Enable "Sign In with Apple" capability in Xcode (Signing & Capabilities).
///      - Enable the Apple provider in Supabase Authentication → Providers → Apple.
class SupabaseConfig {
  SupabaseConfig._();

  /// Your Supabase project URL.
  ///
  /// For local dev, pass via --dart-define=SUPABASE_URL=http://127.0.0.1:54321
  /// For production, use your hosted project URL.
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project-ref.supabase.co',
  );

  /// Your Supabase project anonymous/public key.
  ///
  /// For local dev, get this from `supabase status` after running `supabase start`.
  /// Pass via --dart-define=SUPABASE_ANON_KEY=eyJ...
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-supabase-anon-key',
  );

  /// The OAuth 2.0 **Web** Client ID from Google Cloud Console.
  /// Used by google_sign_in to obtain an ID token for Supabase.
  ///
  /// Pass via --dart-define=GOOGLE_WEB_CLIENT_ID=123456789-abc.apps.googleusercontent.com
  static const googleServerClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: 'your-web-client-id.apps.googleusercontent.com',
  );
}
