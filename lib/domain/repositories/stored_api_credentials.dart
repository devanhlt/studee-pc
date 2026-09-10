/// Snapshot of all API credentials loaded in one Keychain read.
class StoredApiCredentials {
  const StoredApiCredentials({
    this.deepSeekApiKey,
    this.mathpixAppId,
    this.mathpixAppKey,
    this.mathpixBaseUrl,
  });

  final String? deepSeekApiKey;
  final String? mathpixAppId;
  final String? mathpixAppKey;
  final String? mathpixBaseUrl;

  bool get hasDeepSeekApiKey =>
      deepSeekApiKey != null && deepSeekApiKey!.isNotEmpty;

  bool get hasMathpixCredentials =>
      mathpixAppId != null &&
      mathpixAppId!.isNotEmpty &&
      mathpixAppKey != null &&
      mathpixAppKey!.isNotEmpty;
}
