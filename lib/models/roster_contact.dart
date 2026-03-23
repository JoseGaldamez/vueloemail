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

  Map<String, dynamic> toMap() {
    return {
      'jid': jid,
      'name': name,
    };
  }

  factory RosterContact.fromMap(Map<String, dynamic> map) {
    return RosterContact(
      jid: map['jid'],
      name: map['name'],
      isOnline: false, // Online status is not persistent
    );
  }
}
