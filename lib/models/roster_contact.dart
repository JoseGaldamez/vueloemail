class RosterContact {
  final String jid;
  final String name;
  bool isOnline;

  RosterContact({
    required this.jid,
    required this.name,
    this.isOnline = false,
  });

  /// Returns the local part of the JID as display name fallback.
  String get displayName => name.isNotEmpty ? name : jid.split('@').first;
}
