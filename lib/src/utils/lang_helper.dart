const Map<String, String> langKeyMap = {
  'en': 'english',
  'es': 'spanish',
  'pt': 'portuguese',
};

/// Obtiene un String de un Map anidado de localización.
/// Ejemplo de uso:
///   getLang(langStrings, 'en', ['appbarTitle', 'settings'])
///   getLang(langStrings, 'es', ['magicList'])
String? getLang(Map? langStrings, String langCode, List<String> keys) {
  if (langStrings == null) return null;
  final langKey = langKeyMap[langCode] ?? langCode;
  dynamic value = langStrings[langKey] ?? langStrings['english'];
  for (final key in keys) {
    if (value is Map && value.containsKey(key)) {
      value = value[key];
    } else {
      return null;
    }
  }
  return value is String ? value : null;
}
