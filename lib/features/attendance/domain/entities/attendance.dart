class Attendance {
  final String id;
  final String? studentId;
  final String? studentName;
  final DateTime? date;
  final String? status;
  final String? remarks;

  const Attendance({
    required this.id,
    this.studentId,
    this.studentName,
    this.date,
    this.status,
    this.remarks,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      studentId: json['studentId'] as String?,
      studentName: json['studentName'] as String?,
      date: json['date'] != null ? DateTime.tryParse(json['date'] as String) : null,
      status: json['status'] as String?,
      remarks: json['remarks'] as String?,
    );
  }
}
