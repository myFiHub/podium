/// Information about the local user. It will be used in absence of a token.
class JitsiMeetUserInfo {
  /// User display name.
  final String? displayName;

  /// User email.
  final String? email;

  final String id;

  /// URL for the user avatar.
  final String? avatar;

  JitsiMeetUserInfo({
    required this.id,
    this.displayName,
    this.email,
    this.avatar,
  });
}
