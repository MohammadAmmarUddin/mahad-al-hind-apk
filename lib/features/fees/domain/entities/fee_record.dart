class FeeRecord {
  final String id;
  final String? studentId;
  final String? feeType;
  final double? amount;
  final double? paidAmount;
  final String? status;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final String? invoiceNumber;

  const FeeRecord({
    required this.id,
    this.studentId,
    this.feeType,
    this.amount,
    this.paidAmount,
    this.status,
    this.dueDate,
    this.paidDate,
    this.invoiceNumber,
  });

  factory FeeRecord.fromJson(Map<String, dynamic> json) {
    return FeeRecord(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      studentId: json['studentId'] as String?,
      feeType: json['feeType'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      paidAmount: (json['paidAmount'] as num?)?.toDouble(),
      status: json['status'] as String?,
      dueDate: json['dueDate'] != null ? DateTime.tryParse(json['dueDate'] as String) : null,
      paidDate: json['paidDate'] != null ? DateTime.tryParse(json['paidDate'] as String) : null,
      invoiceNumber: json['invoiceNumber'] as String?,
    );
  }
}
