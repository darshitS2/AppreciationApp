// lib/app_user_model.dart
class AppUser {
  final String id;
  final String fullName;

  AppUser({required this.id, required this.fullName});

  // This helps the dropdown package know how to display this object as a string.
  @override
  String toString() {
    return fullName;
  }

  // These are needed for comparing two AppUser objects.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}