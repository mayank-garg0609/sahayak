class TeacherMemory {
  // Example: Map of preference keys to values
  Map<String, dynamic> _preferences = {};

  dynamic getPreference(String key) => _preferences[key];

  void setPreference(String key, dynamic value) {
    _preferences[key] = value;
  }

  // TODO: Add persistence (local/Firestore) in later priorities
} 