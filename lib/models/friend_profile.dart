class FriendProfile {
  final String name;
  final String? birthday;
  final List<String> likes;
  final List<String> dislikes;
  final double? budgetHint;

  FriendProfile({
    required this.name,
    this.birthday,
    this.likes = const [],
    this.dislikes = const [],
    this.budgetHint,
  });
}