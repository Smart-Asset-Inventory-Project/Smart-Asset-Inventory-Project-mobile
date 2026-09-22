/// دليل مستخدمين محلي يُبنى من ردود الباك اند.
/// الباك بلا /users، فنتعلم {id,name} من النقل والأوامر والتدقيق
/// لعرض الأسماء بدل UUID ولملء dropdowns الفني/الأمين.
class DirectoryUser {
  final String id;
  final String name;
  final String? email;

  const DirectoryUser({required this.id, required this.name, this.email});
}

class UserDirectory {
  UserDirectory._();
  static final UserDirectory instance = UserDirectory._();

  final Map<String, DirectoryUser> _users = {};

  void learn(String? id, String? name, [String? email]) {
    if (id == null || id.isEmpty) return;
    final label = (name == null || name.isEmpty) ? shortId(id) : name;
    _users[id] = DirectoryUser(id: id, name: label, email: email);
  }

  void learnMap(Map? m) {
    if (m == null) return;
    learn(m['id']?.toString(), m['name']?.toString(),
        m['email']?.toString());
  }

  List<DirectoryUser> get all => _users.values.toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  String name(String? id) {
    if (id == null || id.isEmpty) return '-';
    return _users[id]?.name ?? shortId(id);
  }

  static String shortId(String id) =>
      id.length <= 8 ? id : '${id.substring(0, 8)}…';
}
