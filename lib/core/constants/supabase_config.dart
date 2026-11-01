class SupabaseConfig {
  static const String supabaseUrl = 'https://dcasrlbzqoqwymovkbgx.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRjYXNybGJ6cW9xd3ltb3ZrYmd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk0NTE2OTEsImV4cCI6MjA5NTAyNzY5MX0.JrhN1xTw5eeaem2z8n0x_0wPCSARNdEkY6cHuvKQOwc';

  // Deep link callback untuk reset password, harus cocok dengan
  // intent-filter di AndroidManifest.xml dan CFBundleURLSchemes di Info.plist.
  static const String resetPasswordRedirectUrl =
      'posyandumerpati://reset-callback';
}
