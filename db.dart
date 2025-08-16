import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/models.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  Database? _db;
  AppDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
    }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'bangla_ledger.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            father_or_spouse TEXT NOT NULL,
            goods TEXT NOT NULL,
            created_at_iso TEXT NOT NULL
          );
        ''');
        await db.execute('''
          CREATE TABLE payments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER NOT NULL,
            amount REAL NOT NULL,
            paid_at_iso TEXT NOT NULL,
            FOREIGN KEY(customer_id) REFERENCES customers(id) ON DELETE CASCADE
          );
        ''');
      },
    );
  }

  // Customers
  Future<int> insertCustomer(Customer c) async {
    final db = await database;
    return await db.insert('customers', c.toMap());
  }

  Future<List<Customer>> searchCustomersByName(String query) async {
    final db = await database;
    final res = await db.query(
      'customers',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return res.map((e) => Customer.fromMap(e)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await database;
    final res = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (res.isEmpty) return null;
    return Customer.fromMap(res.first);
  }

  // Payments
  Future<int> insertPayment(Payment pmt) async {
    final db = await database;
    return await db.insert('payments', pmt.toMap());
  }

  Future<List<Payment>> getPaymentsForCustomer(int customerId) async {
    final db = await database;
    final res = await db.query(
      'payments',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'paid_at_iso ASC',
    );
    return res.map((e) => Payment.fromMap(e)).toList();
  }
}