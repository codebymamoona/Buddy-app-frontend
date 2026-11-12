/// Mirrors the backend contact JSON (GET /api/friends). No dislikes/budget: the backend does not store them.
class FriendProfile {
  final String name;
  final String relationship;
  final String birthday; // ISO yyyy-MM-dd or ''
  final String notes;
  final List<String> likes;
  final int daysUntilBirthday; // -1 when no/invalid birthday
  final bool reminderDue;

  const FriendProfile({
    required this.name,
    this.relationship = 'Friend',
    this.birthday = '',
    this.notes = '',
    this.likes = const [],
    this.daysUntilBirthday = -1,
    this.reminderDue = false,
  });

  factory FriendProfile.fromJson(Map<String, dynamic> j) {
    final rawLikes = j['interests'];
    return FriendProfile(
      name: (j['name'] ?? '').toString(),
      relationship: (j['relationship'] ?? 'Friend').toString(),
      birthday: (j['birthday'] ?? '').toString(),
      notes: (j['notes'] ?? '').toString(),
      likes: rawLikes is List ? rawLikes.map((e) => e.toString()).toList() : <String>[],
      daysUntilBirthday: j['daysUntilBirthday'] is num ? (j['daysUntilBirthday'] as num).toInt() : -1,
      reminderDue: j['reminderDue'] == true,
    );
  }
}