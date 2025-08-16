class Customer {
  int? id;
  String name;
  String fatherOrSpouse;
  String goods;
  String createdAtIso; // ISO8601

  Customer({
    this.id,
    required this.name,
    required this.fatherOrSpouse,
    required this.goods,
    required this.createdAtIso,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'father_or_spouse': fatherOrSpouse,
        'goods': goods,
        'created_at_iso': createdAtIso,
      };

  static Customer fromMap(Map<String, dynamic> m) => Customer(
        id: m['id'] as int?,
        name: m['name'] as String,
        fatherOrSpouse: m['father_or_spouse'] as String,
        goods: m['goods'] as String,
        createdAtIso: m['created_at_iso'] as String,
      );
}

class Payment {
  int? id;
  int customerId;
  double amount;
  String paidAtIso;

  Payment({
    this.id,
    required this.customerId,
    required this.amount,
    required this.paidAtIso,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'customer_id': customerId,
        'amount': amount,
        'paid_at_iso': paidAtIso,
      };

  static Payment fromMap(Map<String, dynamic> m) => Payment(
        id: m['id'] as int?,
        customerId: m['customer_id'] as int,
        amount: (m['amount'] as num).toDouble(),
        paidAtIso: m['paid_at_iso'] as String,
      );
}