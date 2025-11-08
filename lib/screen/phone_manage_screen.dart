import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:phonekit_manager/model/phone_manage_model.dart';

class PhoneManager extends StatefulWidget {
  final String current_shop;
  final String current_email;
  final String current_role;

  const PhoneManager(this.current_shop, this.current_email, this.current_role,
      {Key? key})
      : super(key: key);

  @override
  _PhoneManagerState createState() => _PhoneManagerState();
}

class _PhoneManagerState extends State<PhoneManager> {
  late Future<List<PhoneModel>> _taskList;
  List<PhoneModel> _filteredData = [];
  List<PhoneModel> _taskListData = [];
  List<PhoneModel> _monthDataList = [];
  bool isDay = true;
  DateTime _selectedDate = DateTime.now();
  double existingGiaNhap = 0.0;
  double existingGiaBan = 0.0;

  // Dialog state
  String _name = "";
  String _thu = "0";
  String _chi = "0";

  @override
  void initState() {
    super.initState();
    _updateTaskList();
  }

  // ───────────── FIRESTORE ─────────────
  Future<void> sendDataFireStore(PhoneModel task) async {
    String unique_id = UniqueKey().toString();
    PhoneModel newTask = PhoneModel(
      id: unique_id,
      name: task.name,
      thu: task.thu,
      chi: task.chi,
      date: task.date,
      shop: task.shop,
    );

    await FirebaseFirestore.instance
        .collection('phonedevice')
        .doc(unique_id)
        .set(newTask.toMap());
  }

  Future<void> updateDataphonedeviceFireStore(
      String id, PhoneModel task) async {
    await FirebaseFirestore.instance
        .collection('phonedevice')
        .doc(id)
        .update(task.toMap());
  }

  Future<void> deleteTask(PhoneModel task) async {
    await FirebaseFirestore.instance
        .collection('phonedevice')
        .doc(task.id)
        .delete();
  }

  Future<List<PhoneModel>> getDataphonedevicefireStore() async {
    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection('phonedevice');

    DateTime startDate =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime endDate = startDate.add(const Duration(days: 1));

    QuerySnapshot querySnapshot = await collectionRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThan: Timestamp.fromDate(endDate))
        .orderBy('date')
        .get();

    List<PhoneModel> dataDay = querySnapshot.docs
        .map((doc) => PhoneModel.fromMap(doc.data() as Map<String, dynamic>))
        .where((task) => task.shop == widget.current_shop)
        .toList();

    _taskListData = dataDay;
    _filteredData = dataDay;
    return dataDay;
  }

  Future<List<PhoneModel>> getDataphonedevicefireStoreMonth() async {
    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection('phonedevice');

    DateTime startMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    DateTime endMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 1);

    QuerySnapshot querySnapshot = await collectionRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startMonth))
        .where('date', isLessThan: Timestamp.fromDate(endMonth))
        .orderBy('date')
        .get();

    List<PhoneModel> dataMonth = querySnapshot.docs
        .map((doc) => PhoneModel.fromMap(doc.data() as Map<String, dynamic>))
        .where((task) => task.shop == widget.current_shop)
        .toList();

    _monthDataList = sumMoneyMonth(dataMonth);
    return _monthDataList;
  }

  List<PhoneModel> sumMoneyMonth(List<PhoneModel> filteredData) {
    Map<String, PhoneModel> monthDataMap = {};
    for (PhoneModel t in filteredData) {
      String monthKey = '${t.date.year}-${t.date.month}';
      if (monthDataMap.containsKey(monthKey)) {
        PhoneModel? existingMonthData = monthDataMap[monthKey];
        existingGiaNhap = double.tryParse(existingMonthData?.chi ?? "0") ?? 0;
        existingGiaBan = double.tryParse(existingMonthData?.thu ?? "0") ?? 0;
        double giaNhap = double.tryParse(t.chi) ?? 0;
        double giaBan = double.tryParse(t.thu) ?? 0;
        existingMonthData?.chi = (existingGiaNhap + giaNhap).toStringAsFixed(2);
        existingMonthData?.thu = (existingGiaBan + giaBan).toStringAsFixed(2);
      } else {
        monthDataMap[monthKey] = PhoneModel(
          id: monthKey,
          chi: t.chi,
          thu: t.thu,
          date: DateTime(t.date.year, t.date.month),
          shop: '',
          name: '',
        );
      }
    }
    return monthDataMap.values.toList();
  }

  // ───────────── UPDATE LIST ─────────────
  Future<void> _updateTaskList() async {
    if (isDay) {
      await getDataphonedevicefireStore();
    } else {
      await getDataphonedevicefireStoreMonth();
    }
    setState(() {});
  }

  void updateFilteredData(bool dayMode) async {
    isDay = dayMode;
    if (!isDay) {
      await getDataphonedevicefireStoreMonth();
      _filteredData = _monthDataList
          .where((task) => task.date.month == _selectedDate.month)
          .toList();
    } else {
      _filteredData = _taskListData
          .where((task) => task.date.day == _selectedDate.day)
          .toList();
    }
    setState(() {});
  }

  // ───────────── DIALOG ADD/EDIT ─────────────
  void _showDialogDaily(BuildContext context, bool isEdit, PhoneModel task) {
    _name = isEdit ? task.name : "";
    _thu = isEdit ? task.thu : "0";
    _chi = isEdit ? task.chi : "0";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Giao dịch điện thoại",
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.purple)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField("Tên", _name, (v) => _name = v),
              const SizedBox(height: 12),
              _buildTextField("Giá nhập", _chi, (v) => _chi = v,
                  isNumber: true),
              const SizedBox(height: 12),
              _buildTextField("Giá bán", _thu, (v) => _thu = v,
                  isNumber: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Hủy bỏ",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              PhoneModel newTask = PhoneModel(
                id: isEdit ? task.id : '',
                name: _name,
                thu: _thu,
                chi: _chi,
                date: isEdit ? task.date : _selectedDate,
                shop: widget.current_shop,
              );
              if (isEdit) {
                await updateDataphonedeviceFireStore(task.id, newTask);
              } else {
                await sendDataFireStore(newTask);
              }
              await _updateTaskList();
              Navigator.of(context).pop();
            },
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.blue),
              shape: MaterialStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
            ),
            child: const Text("Xác nhận",
                style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, String initialValue, ValueChanged<String> onChanged,
      {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: initialValue,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
              prefixIcon: const Icon(Icons.money),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // ───────────── DATE PICKER ─────────────
  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2021),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _updateTaskList();
    }
  }

  // ───────────── BUILD UI ─────────────
  @override
  Widget build(BuildContext context) {
    double totalThu =
        _filteredData.fold(0, (sum, e) => sum + (double.tryParse(e.thu) ?? 0));
    double totalChi =
        _filteredData.fold(0, (sum, e) => sum + (double.tryParse(e.chi) ?? 0));
    double totalLai = totalThu - totalChi;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialogDaily(
          context,
          false,
          PhoneModel(
              id: '',
              name: '',
              thu: '0',
              chi: '0',
              date: DateTime.now(),
              shop: widget.current_shop),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text("Thêm giao dịch"),
      ),
      body: RefreshIndicator(
        onRefresh: _updateTaskList,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummarySection(totalThu, totalChi, totalLai),
            const SizedBox(height: 20),
            _buildChartSection(totalThu, totalChi, totalLai),
            const SizedBox(height: 20),
            _buildFilterSection(),
            const SizedBox(height: 20),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      toolbarHeight: 90,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF9575CD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24)),
        ),
      ),
      title: Row(
        children: [
          const Icon(Icons.store_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Text(widget.current_shop,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22)),
        ],
      ),
      actions: [
        IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: Colors.white),
            onPressed: () => _selectDate(context)),
      ],
    );
  }

  Widget _buildSummarySection(double thu, double chi, double lai) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryCard("Doanh thu", thu, Colors.green),
        _buildSummaryCard("Chi phí", chi, Colors.red),
        _buildSummaryCard("Lợi nhuận", lai, Colors.blue),
      ],
    );
  }

  Widget _buildSummaryCard(String title, double value, Color color) {
    final formatted = NumberFormat("#,##0", "vi_VN").format(value);
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Column(children: [
          Text(title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("$formatted đ",
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))
        ]),
      ),
    );
  }

  Widget _buildChartSection(double thu, double chi, double lai) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Doanh số mua bán điện thoại",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                barGroups: [
                  _barGroup(1, thu, Colors.greenAccent),
                  _barGroup(2, chi, Colors.redAccent),
                  _barGroup(3, lai, Colors.blueAccent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double value, Color color) {
    return BarChartGroupData(x: x, barRods: [
      BarChartRodData(
          toY: value,
          color: color,
          width: 18,
          borderRadius: BorderRadius.circular(6))
    ]);
  }

  Widget _buildFilterSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFilterChip("Ngày", isDay, () => updateFilteredData(true)),
        const SizedBox(width: 12),
        _buildFilterChip("Tháng", !isDay, () => updateFilteredData(false)),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(label,
          style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w500)),
      selected: selected,
      selectedColor: const Color(0xFF7C4DFF),
      backgroundColor: Colors.grey[200],
      onSelected: (_) => onTap(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    );
  }

  Widget _buildTransactionList() {
    if (_filteredData.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.only(top: 50),
              child: Text("Chưa có giao dịch nào",
                  style: TextStyle(color: Colors.grey))));
    }

    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 400),
          childAnimationBuilder: (widget) => SlideAnimation(
              horizontalOffset: 60, child: FadeInAnimation(child: widget)),
          children: _filteredData.map((e) => _buildTransactionCard(e)).toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(PhoneModel task) {
    return GestureDetector(
      onTap: () => _showDialogDaily(context, true, task),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Row(
          children: [
            Icon(Icons.attach_money_rounded,
                color: double.tryParse(task.thu) != null &&
                        double.parse(task.thu) > 0
                    ? Colors.green
                    : Colors.red,
                size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(DateFormat('dd/MM/yyyy').format(task.date),
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("+${task.thu}đ",
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
                Text("-${task.chi}đ",
                    style: const TextStyle(
                        color: Colors.redAccent, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
