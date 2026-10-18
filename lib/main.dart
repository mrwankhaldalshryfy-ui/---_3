import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SharafiWorkshopApp());
}

class AppTheme {
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceAlt = Color(0xFF21262D);
  static const Color border = Color(0xFF30363D);
  static const Color primary = Color(0xFF1F6FEB);
  static const Color primaryLight = Color(0xFF58A6FF);
  static const Color success = Color(0xFF2EA043);
  static const Color danger = Color(0xFFCF222E);
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textMuted = Color(0xFF8B949E);

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: primaryLight,
          surface: surface,
          error: danger,
          onPrimary: Colors.white,
          onSurface: textPrimary,
        ),
      );
}

class OrderModel {
  String id;
  String customerName;
  String phone;
  String workType; // باب، نافذة، بوابة، حماية، هانجر
  String width;
  String height;
  String arch; // العقد
  String direction; // يمين أو شمال
  double price;
  DateTime createdAt;

  OrderModel({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.workType,
    required this.width,
    required this.height,
    required this.arch,
    required this.direction,
    required this.price,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerName': customerName,
        'phone': phone,
        'workType': workType,
        'width': width,
        'height': height,
        'arch': arch,
        'direction': direction,
        'price': price,
        'createdAt': createdAt.toIso8601String(),
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'] as String,
        customerName: json['customerName'] as String,
        phone: json['phone'] as String,
        workType: json['workType'] as String,
        width: json['width'] as String,
        height: json['height'] as String,
        arch: json['arch'] as String,
        direction: json['direction'] as String,
        price: (json['price'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class SharafiWorkshopApp extends StatelessWidget {
  const SharafiWorkshopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ورشة الشريفي',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const OrdersHomePage(),
    );
  }
}

class OrdersHomePage extends StatefulWidget {
  const OrdersHomePage({super.key});

  @override
  State<OrdersHomePage> createState() => _OrdersHomePageState();
}

class _OrdersHomePageState extends State<OrdersHomePage> {
  final List<OrderModel> _orders = [];
  bool _loading = true;
  final String _storageKey = 'sharafi_orders_key';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null && data.isNotEmpty) {
        final list = jsonDecode(data) as List<dynamic>;
        _orders.clear();
        _orders.addAll(list.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _saveOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_orders.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (_) {}
  }

  void _addOrder(String name, String phone, String type, String w, String h, String arch, String dir, double price) {
    setState(() {
      _orders.insert(
        0,
        OrderModel(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          customerName: name,
          phone: phone,
          workType: type,
          width: w,
          height: h,
          arch: arch,
          direction: dir,
          price: price,
          createdAt: DateTime.now(),
        ),
      );
    });
    _saveOrders();
    HapticFeedback.lightImpact();
  }

  void _deleteOrder(OrderModel order) {
    final index = _orders.indexOf(order);
    if (index == -1) return;
    setState(() => _orders.removeAt(index));
    _saveOrders();
  }

  void _openAddDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final widthController = TextEditingController();
    final heightController = TextEditingController();
    final archController = TextEditingController();
    final priceController = TextEditingController();
    
    String selectedType = 'باب';
    String selectedDir = 'يمين';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('طلبيه جديدة - ورشة الشريفي', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'اسم الزبون'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  dropdownColor: AppTheme.surfaceAlt,
                  items: ['باب', 'نافذة', 'بوابة', 'حماية', 'هانجر']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                  decoration: const InputDecoration(labelText: 'نوع العمل'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: widthController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'العرض (سم/م)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'الطول (سم/م)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: archController,
                  decoration: const InputDecoration(labelText: 'العقد (إن وجد)'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedDir,
                  dropdownColor: AppTheme.surfaceAlt,
                  items: ['يمين', 'شمال', 'لايوجد']
                      .map((d) => DropdownMenuItem(value: d, child: Text('فتح: $d')))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedDir = val!),
                  decoration: const InputDecoration(labelText: 'اتجاه الفتح'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'إجمالي السعر'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: AppTheme.textMuted)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primary),
              onPressed: () {
                // تم إصلاح الخطأ هنا بإضافة الأقواس {}
                if (nameController.text.trim().isEmpty) return; 
                
                double price = double.tryParse(priceController.text) ?? 0.0;
                _addOrder(
                  nameController.text.trim(),
                  phoneController.text.trim(),
                  selectedType,
                  widthController.text.trim(),
                  heightController.text.trim(),
                  archController.text.trim(),
                  selectedDir,
                  price,
                );
                Navigator.pop(ctx);
              },
              child: const Text('حفظ الطلبية'),
            ),
          ],
        ),
      ),
    );
  }

  void _showInvoice(OrderModel order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('ورشة الشريفي للأبواب والهناجر', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.primaryLight, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('اسم الزبون: ${order.customerName}', style: const TextStyle(fontSize: 16)),
            Text('الهاتف: ${order.phone}', style: const TextStyle(fontSize: 16)),
            const Divider(color: AppTheme.border),
            Text('نوع العمل: ${order.workType}'),
            Text('المقاسات -> العرض: ${order.width} | الطول: ${order.height}'),
            if (order.arch.isNotEmpty) Text('العقد: ${order.arch}'),
            Text('اتجاه الفتح: ${order.direction}'),
            const Divider(color: AppTheme.border),
            // تم تنسيق السعر هنا ليظهر كرقم صحيح
            Text('السعر الإجمالي: ${order.price.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق', style: TextStyle(color: AppTheme.primaryLight)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ورشة الشريفي - إدارة الطلبيات'),
        backgroundColor: AppTheme.surface,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? const Center(child: Text('لا توجد طلبيات مسجلة بعد', style: TextStyle(color: AppTheme.textMuted, fontSize: 16)))
              : ListView.builder(
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final order = _orders[index];
                    return Card(
                      color: AppTheme.surface,
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 18)),
                        subtitle: Text('${order.workType} | المقاس: ${order.width} × ${order.height}\nالفتح: ${order.direction} | السعر: ${order.price.toStringAsFixed(0)} ريال/عملة', style: const TextStyle(color: AppTheme.textMuted, height: 1.4)),
                        isThreeLine: true,
                        
                        // هنا تم إضافة أزرار الفاتورة والحذف
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.receipt_long, color: AppTheme.primaryLight),
                              onPressed: () => _showInvoice(order),
                              tooltip: 'عرض الفاتورة',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
                              onPressed: () {
                                // نافذة تأكيد قبل الحذف
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppTheme.surface,
                                    title: const Text('تأكيد الحذف', style: TextStyle(color: AppTheme.textPrimary)),
                                    content: Text('هل أنت متأكد من حذف طلبية (${order.customerName})؟', style: const TextStyle(color: AppTheme.textMuted)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('إلغاء', style: TextStyle(color: AppTheme.textMuted)),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _deleteOrder(order);
                                          Navigator.pop(ctx);
                                        },
                                        child: const Text('حذف', style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              tooltip: 'حذف الطلبية',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: _openAddDialog,
        label: const Text('طلبيه جديدة', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}