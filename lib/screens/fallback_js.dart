// lib/screens/fallback_js.dart
dynamic newObject() => <String,dynamic>{};
void setProperty(dynamic o, String name, dynamic value) {
  if (o is Map<String, dynamic>) o[name] = value;
}
dynamic getProperty(dynamic o, String name) {
  if (o is Map<String, dynamic>) return o[name];
  return null;
}
dynamic callConstructor(dynamic ctor, List args) {
  return {'_constructed': true, 'args': args};
}
dynamic callMethod(dynamic target, String method, List args) {
  if (target is Map<String, dynamic>) {
    // no-op fallback
    return null;
  }
  return null;
}
