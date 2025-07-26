class StudentMemory {
  // Example: Map of studentId to activity data
  Map<String, dynamic> _studentData = {};

  dynamic getStudentData(String studentId) => _studentData[studentId];

  void setStudentData(String studentId, dynamic data) {
    _studentData[studentId] = data;
  }

  // TODO: Add persistence (local/Firestore) in later priorities
} 