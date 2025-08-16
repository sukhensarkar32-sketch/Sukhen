import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'models/models.dart';
import 'services/db.dart';
import 'services/interest.dart';
import 'services/bangla_date.dart';

void main() {
  runApp(const BanglaLedgerApp());
}

class BanglaLedgerApp extends StatelessWidget {
  const BanglaLedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'বাংলা লেজার',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  List<Customer> _results = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh([String q = '']) async {
    final db = AppDatabase.instance;
    final data = await db.searchCustomersByName(q);
    setState(() => _results = data);
  }

  void _openAddCustomer() async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddCustomerScreen()));
    _refresh(_searchCtrl.text);
  }

  void _openCustomer(Customer c) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: c.id!)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('বাংলা লেজার'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddCustomer,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'নাম দিয়ে সার্চ করুন...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _refresh(_searchCtrl.text),
                ),
              ),
              onChanged: (v) => _refresh(v),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('কোন ডাটা নেই')) 
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (ctx, i) {
                        final c = _results[i];
                        final created = DateTime.parse(c.createdAtIso);
                        final banglaDate = BanglaDateConverter.formatBanglaDate(created);
                        return Card(
                          child: ListTile(
                            title: Text('${c.name}'),
                            subtitle: Text('বাবা/স্বামী: ${c.fatherOrSpouse}\nতারিখ: $banglaDate\nমাল: ${c.goods}'),
                            onTap: () => _openCustomer(c),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen> {
  final _name = TextEditingController();
  final _father = TextEditingController();
  final _goods = TextEditingController();
  DateTime _date = DateTime.now();
  final _firstAmount = TextEditingController();

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _father.text.trim().isEmpty || _goods.text.trim().isEmpty || _firstAmount.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('সব ঘর পূরণ করুন')));
      return;
    }
    final cust = Customer(
      name: _name.text.trim(),
      fatherOrSpouse: _father.text.trim(),
      goods: _goods.text.trim(),
      createdAtIso: _date.toIso8601String(),
    );
    final db = AppDatabase.instance;
    final custId = await db.insertCustomer(cust);

    final amt = double.tryParse(_firstAmount.text.trim()) ?? 0.0;
    await db.insertPayment(Payment(customerId: custId, amount: amt, paidAtIso: _date.toIso8601String()));

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final banglaDate = BanglaDateConverter.formatBanglaDate(_date);
    return Scaffold(
      appBar: AppBar(title: const Text('নতুন এন্ট্রি')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(decoration: const InputDecoration(labelText: 'নাম'), controller: _name),
          const SizedBox(height: 8),
          TextField(decoration: const InputDecoration(labelText: 'বাবা/স্বামী নাম'), controller: _father),
          const SizedBox(height: 8),
          TextField(decoration: const InputDecoration(labelText: 'মালের নাম'), controller: _goods),
          const SizedBox(height: 8),
          ListTile(
            title: Text('তারিখ: $banglaDate'),
            trailing: const Icon(Icons.calendar_month),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: const InputDecoration(labelText: 'টাকা (প্রথমবার)'),
            keyboardType: TextInputType.number,
            controller: _firstAmount,
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _save, child: const Text('সেভ')),
        ],
      ),
    );
  }
}

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Customer? _cust;
  List<Payment> _payments = [];
  bool _loading = true;

  Future<void> _load() async {
    final db = AppDatabase.instance;
    final c = await db.getCustomerById(widget.customerId);
    final p = await db.getPaymentsForCustomer(widget.customerId);
    setState(() {
      _cust = c;
      _payments = p;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _addPaymentDialog() async {
    final ctrl = TextEditingController();
    DateTime dt = DateTime.now();
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('নতুন টাকা যোগ করুন'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'টাকার পরিমাণ'),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text('তারিখ: ${BanglaDateConverter.formatBanglaDate(dt)}'),
                trailing: const Icon(Icons.calendar_month),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dt,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    dt = picked;
                    (ctx as Element).markNeedsBuild();
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('বাতিল')),
            ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(ctrl.text.trim()) ?? 0.0;
                if (amt <= 0) return;
                final db = AppDatabase.instance;
                await db.insertPayment(Payment(customerId: widget.customerId, amount: amt, paidAtIso: dt.toIso8601String()));
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('এড'),
            ),
          ],
        );
      },
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_cust == null) {
      return const Scaffold(body: Center(child: Text('কাস্টমার পাওয়া যায়নি')));
    }
    final totals = InterestService.computeTotals(_payments);
    return Scaffold(
      appBar: AppBar(title: Text(_cust!.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPaymentDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('বাবা/স্বামী: ${_cust!.fatherOrSpouse}'),
          Text('মাল: ${_cust!.goods}'),
          const SizedBox(height: 8),
          const Divider(),
          ListTile(
            title: const Text('মোট Principal'),
            trailing: Text(totals['principal']!.toStringAsFixed(2)),
          ),
          ListTile(
            title: const Text('মোট Interest (৩%/মাস)'),
            trailing: Text(totals['interest']!.toStringAsFixed(2)),
          ),
          ListTile(
            title: const Text('গ্র্যান্ড টোটাল'),
            trailing: Text(totals['total']!.toStringAsFixed(2)),
          ),
          const Divider(),
          const SizedBox(height: 8),
          const Text('পেমেন্ট হিস্টরি', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._payments.map((p) {
            final dt = DateTime.parse(p.paidAtIso);
            final bd = BanglaDateConverter.formatBanglaDate(dt);
            return Card(
              child: ListTile(
                title: Text('টাকা: ${p.amount.toStringAsFixed(2)}'),
                subtitle: Text('তারিখ: $bd'),
              ),
            );
          }).toList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}