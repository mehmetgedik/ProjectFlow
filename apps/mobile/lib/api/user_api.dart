import 'openproject_base.dart';

class UserApi {
  UserApi(this._base);

  final OpenProjectBase _base;

  Future<void> validateMe() async {
    await _base.getJson('/users/me');
  }

  Future<String?> getMeDisplayName() async {
    final data = await getMe();
    return data['name'] ?? data['login'];
  }

  Future<Map<String, String>> getMe() async {
    final data = await _base.getJson('/users/me') as Map<String, dynamic>?;
    if (data == null) return <String, String>{'firstName': '', 'lastName': ''};
    String? name = data['name']?.toString();
    final first = data['firstName']?.toString() ?? '';
    final last = data['lastName']?.toString() ?? '';
    if (name == null || name.isEmpty) {
      name = '$first $last'.trim();
    }
    if (name.isEmpty) name = data['login']?.toString();
    final login = data['login']?.toString();
    String? avatar = data['avatar']?.toString();
    if (avatar == null || avatar.isEmpty) {
      final links = data['_links'] as Map<String, dynamic>?;
      final avatarLink = links?['avatar'];
      if (avatarLink is Map) {
        avatar = avatarLink['href']?.toString();
      } else if (avatarLink != null) {
        avatar = avatarLink.toString();
      }
    }
    if (avatar != null && avatar.isNotEmpty && avatar.startsWith('/')) {
      avatar = _base.apiBase.origin + avatar;
    }
    final idObj = data['id'];
    final idStr = idObj?.toString();
    if (idStr != null && idStr.isNotEmpty) {
      final base = _base.apiBase.toString().replaceAll(RegExp(r'/+$'), '');
      avatar = '$base/users/$idStr/avatar';
    }
    final email = data['email']?.toString();
    return <String, String>{
      if (idStr != null && idStr.isNotEmpty) 'id': idStr,
      if (name != null && name.isNotEmpty) 'name': name,
      if (login != null && login.isNotEmpty) 'login': login,
      if (avatar != null && avatar.isNotEmpty) 'avatar': avatar,
      if (email != null && email.isNotEmpty) 'email': email,
      'firstName': first,
      'lastName': last,
    };
  }

  Future<void> patchMe({String? firstName, String? lastName}) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['firstName'] = firstName;
    if (lastName != null) body['lastName'] = lastName;
    if (body.isEmpty) return;
    await _base.patchJson('/users/me', body);
  }

  Future<Map<String, dynamic>> getMyPreferences() async {
    return _base.getJson('/my_preferences');
  }

  Future<void> patchMyPreferences(Map<String, dynamic> body) async {
    if (body.isEmpty) return;
    await _base.patchJson('/my_preferences', body);
  }
}
