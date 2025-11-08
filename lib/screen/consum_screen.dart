import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phonekit_manager/model/comsum_model.dart';
import 'package:phonekit_manager/model/shop_model.dart';
import 'package:phonekit_manager/model/task_model.dart';
import 'package:phonekit_manager/screen/add_device.dart';
import 'package:phonekit_manager/screen/add_task_screen.dart';
import 'package:phonekit_manager/screen/home.dart';
import 'package:phonekit_manager/model/device_model.dart';
import 'home_screen.dart';
import 'package:toast/toast.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart'; // Biểu đồ hiện đại
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class Consumer extends StatefulWidget {
  final current_shop;
  final current_email;
  final String current_role;
  Consumer(this.current_shop, this.current_email, this.current_role);
  @override
  _ConsumerState createState() => _ConsumerState();
}

class _ConsumerState extends State<Consumer> {
  late Future<List<ComsumModel>> _taskList;
  late ComsumModel default_consum;
  late Future<List<Shop>> _shopList;
  String _searchQuery = '';
  int taskIndex = 0;
  String title = "";
  List<String> todos = <String>[];
  TextEditingController controller = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy hh:mm a');
  List<ComsumModel> data = [];
  String totalPriority = "";
  String total1 = "";
  String _scanBarcode = 'Unknown';
  DateTime _selectedDate = DateTime.now();
  String _thu = "";
  String _chi = "";
  String _id = "";
  String _name = "";
  bool checkStatus = false;
  List<ComsumModel> _filteredData = [];
  List<ComsumModel> _monthDataList = [];
  List<ComsumModel> _taskListData = [];
  bool isDay = true;
  double existingGiaNhap = 0.0;
  double existingGiaBan = 0.0;

  @override
  void initState() {
    super.initState();
    _updateTaskList();
  }

  void updateDataConsumFireStore(String idSelect, ComsumModel task) async {
    final docUser = FirebaseFirestore.instance.collection('consum');
    docUser.doc(idSelect).update(task.toMap());
  }

  Future<void> sendDataFireStore(ComsumModel task) async {
    String unique_id = UniqueKey().toString();
    Map<String, dynamic> todoList = await {
      "id": unique_id,
      "thu": task.thu,
      "date": Timestamp.fromDate(task.date),
      "chi": task.chi,
      "shop": task.shop,
      "name": task.name,
    };
    await FirebaseFirestore.instance
        .collection('consum')
        .doc(unique_id)
        .set(todoList);
  }

  List<ComsumModel> sum_money_month(List<ComsumModel> filteredData) {
    Map<String, ComsumModel> monthDataMap = {};
    List<ComsumModel> monthDataList = [];
    for (ComsumModel t in filteredData) {
      String monthKey = '${t.date.year}-${t.date.month}';
      if (monthDataMap.containsKey(monthKey)) {
        ComsumModel? existingMonthData = monthDataMap[monthKey];

        // Tính tổng gia_nhap và gia_ban cho tháng hiện tại

        if (existingMonthData?.chi == "") {
          existingGiaNhap = 0;
        } else {
          existingGiaNhap = double.parse(existingMonthData!.chi);
        }
        // double existingGiaNhap = double.parse(existingMonthData.gia_nhap[i]);
        if (existingMonthData?.thu == "") {
          existingGiaBan = 0;
        } else {
          existingGiaBan = double.parse(existingMonthData!.thu);
        }
        if (t.chi == "") {
          t.chi = "0";
        } else {
          t.chi = t.chi;
        }
        double giaNhap = double.parse(t.chi);
        if (t.thu == "") {
          t.thu = "0";
        } else {
          t.thu = t.thu;
        }
        double giaBan = double.parse(t.thu);

        existingMonthData?.chi = (existingGiaNhap + giaNhap).toStringAsFixed(2);
        existingMonthData?.thu = (existingGiaBan + giaBan).toStringAsFixed(2);
      } else {
        // Khởi tạo một bản ghi mới cho tháng hiện tại
        ComsumModel newMonthData = ComsumModel(
          id: monthKey,
          chi: t.chi,
          thu: t.thu,
          date: DateTime(t.date.year, t.date.month),
          shop: '',
          name: '',
        );
        monthDataMap[monthKey] = newMonthData;
      }
    }
    monthDataMap.forEach((key, value) {
      monthDataList.add(value);
    });
    return monthDataList;
  }

  void updateFilteredData(bool isDay) async {
    if (!isDay) {
      await _updateTaskListMonth();
      _filteredData = _monthDataList
          .where((ComsumModel task) =>
              task.date.month.toString().contains(_searchQuery))
          .toList();
    } else {
      _filteredData = _taskListData
          .where((ComsumModel task) =>
              task.date.day.toString().contains(_searchQuery))
          .toList();
    }
  }

  void _showDialog_daily(
      BuildContext context, bool checkStatus, ComsumModel consum) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text(
            'Tiền thu chi',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
              letterSpacing: 1.2,
            ),
          ),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(height: 16.0),
              Text(
                'Tên',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(
                  hintText: 'Nhập tên khoản thu chi',
                  hintStyle: TextStyle(fontSize: 18.0),
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onChanged: (value) {
                  _name = value;
                },
              ),
              SizedBox(height: 16.0),
              Text(
                'Số tiền chi',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              TextFormField(
                initialValue: _chi,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Nhập số tiền chi',
                  hintStyle: TextStyle(fontSize: 18.0),
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onChanged: (value) {
                  _chi = value;
                },
              ),
              SizedBox(height: 16.0),
              Text(
                'Số tiền thu ngoài',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              TextFormField(
                initialValue: _thu,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Nhập số tiền thu ngoài',
                  hintStyle: TextStyle(fontSize: 18.0),
                  prefixIcon: Icon(Icons.money),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onChanged: (value) {
                  _thu = value;
                },
              )
            ])
          ]),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Hủy bỏ',
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'Xác nhận',
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
              onPressed: () {
                if (checkStatus == false) {
                  ComsumModel task = ComsumModel(
                    thu: _thu,
                    chi: _chi,
                    date: _selectedDate,
                    shop: widget.current_shop,
                    name: _name,
                    id: '',
                  );
                  sendDataFireStore(task);
                } else {
                  ComsumModel task = ComsumModel(
                      thu: _thu,
                      chi: _chi,
                      date: consum.date,
                      shop: widget.current_shop,
                      name: _name,
                      id: '');
                  updateDataConsumFireStore(consum.id, task);
                }
                _updateTaskList();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2021),
      lastDate: DateTime(2100),
      helpText: 'Chọn ngày giao dịch',
      confirmText: 'XÁC NHẬN',
      cancelText: 'HỦY',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF7C4DFF),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });

      // 🔁 Cập nhật lại dữ liệu theo ngày mới
      final newData = await getDataConsumfireStore();
      setState(() {
        _filteredData = newData;
      });
    }
  }

  Future<List<ComsumModel>> getDataConsumfireStore() async {
    List<ComsumModel> taskList = [];
    List<ComsumModel> dataDay = [];

    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection('consum');

    DateTime startDate =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime endDate = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day + 1);

    // Month
    if (isDay) {
      QuerySnapshot querySnapshot = await collectionRef
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThan: Timestamp.fromDate(endDate))
          .orderBy('date')
          // .where('shop', isEqualTo: widget.current_shop)
          .get();
      taskList = querySnapshot.docs
          .map((doc) => ComsumModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    }
    // Check task_list is empty or not
    taskList.sort((taskA, taskB) => taskA.date.compareTo(taskB.date));
    for (var document in taskList) {
      if (document.shop == widget.current_shop) dataDay.add(document);
    }
    //Month
    _filteredData = await dataDay;
    _taskListData = await dataDay;
    return dataDay;
  }

  Future<List<ComsumModel>> getDataConsumfireStoreMonth() async {
    List<ComsumModel> taskListMonth = [];
    List<ComsumModel> dataMonth = [];

    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection('consum');

    // Month
    DateTime startMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    DateTime endMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 1);

    // Check task_list is empty or not
    QuerySnapshot querySnapshotMonth = await collectionRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startMonth))
        .where('date', isLessThan: Timestamp.fromDate(endMonth))
        .orderBy('date')
        // .where('shop', isEqualTo: widget.current_shop)
        .get();
    taskListMonth = querySnapshotMonth.docs
        .map((doc) => ComsumModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    //Month
    for (var document in taskListMonth) {
      if (document.shop == widget.current_shop) dataMonth.add(document);
    }
    _monthDataList = await sum_money_month(dataMonth);
    return _monthDataList;
  }

  Future<void> deleteTask(ComsumModel task) async {
    var collection = FirebaseFirestore.instance.collection('consum');
    await collection.doc(task.id).delete();
  }

  _updateTaskList() {
    setState(() {
      _taskList = getDataConsumfireStore();
    });
  }

  void updateListTask(ComsumModel task, bool isAdd) {
    if (isAdd) {
      setState(() {
        _taskList.then((value) => value.add(task));

        _taskList.then((value) =>
            value.sort((taskA, taskB) => taskA.date.compareTo(taskB.date)));
      });
    } else {
      setState(() {
        _taskList.then((value) => value.remove(task));

        _taskList.then((value) =>
            value.sort((taskA, taskB) => taskA.date.compareTo(taskB.date)));
      });
    }
  }

  _updateTaskListMonth() async {
    List<dynamic> newDataList = await getDataConsumfireStoreMonth();
    setState(() {
      _monthDataList = newDataList.cast<ComsumModel>();
    });
  }

  Future<void> onBackPressed() {
    return SystemNavigator.pop();
  }

  Future<void> _pullRefresh() async {
    Duration(seconds: 1);
    await _updateTaskList();
    isDay = true;
  }

  Future<void> _pullRefreshMonth() async {
    Duration(seconds: 1);
    await _updateTaskListMonth();
    isDay = false;
  }

  @override
  Widget build(BuildContext context) {
    final totalThu = _filteredData.fold<double>(
      0,
      (sum, e) => sum + (double.tryParse(e.thu) ?? 0),
    );
    final totalChi = _filteredData.fold<double>(
        0, (sum, e) => sum + (double.tryParse(e.chi) ?? 0));
    final totalLai = totalThu - totalChi;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: _buildAppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDialog_daily(
          context,
          false,
          ComsumModel(
            id: '',
            name: '',
            thu: '0',
            chi: '0',
            date: DateTime.now(),
            shop: widget.current_shop,
          ),
        ),
        backgroundColor: const Color(0xFF7C4DFF),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Thêm giao dịch",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _pullRefresh,
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

  // ───────────────────────────────
  // 🔸 UI COMPONENTS
  // ───────────────────────────────

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
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
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
          onPressed: () => _selectDate(context),
        ),
        const SizedBox(width: 8),
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
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("$formatted đ",
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
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
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Biểu đồ tổng quan",
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
        borderRadius: BorderRadius.circular(6),
      )
    ]);
  }

  Widget _buildFilterSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildFilterChip("Ngày", isDay, () {
          setState(() {
            isDay = true;
            updateFilteredData(true);
          });
        }),
        const SizedBox(width: 12),
        _buildFilterChip("Tháng", !isDay, () {
          setState(() {
            isDay = false;
            updateFilteredData(false);
          });
        }),
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
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return AnimationLimiter(
      child: Column(
        children: AnimationConfiguration.toStaggeredList(
          duration: const Duration(milliseconds: 400),
          childAnimationBuilder: (widget) => SlideAnimation(
            horizontalOffset: 60,
            child: FadeInAnimation(child: widget),
          ),
          children: _filteredData.map((e) => _buildTransactionCard(e)).toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(ComsumModel task) {
    return GestureDetector(
      onTap: () {
        // Khi bấm vào 1 giao dịch => mở dialog chỉnh sửa
        setState(() {
          _name = task.name;
          _thu = task.thu;
          _chi = task.chi;
        });
        _showDialog_daily(context, true, task);
      },
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.attach_money_rounded,
              color: double.tryParse(task.thu) != null &&
                      double.parse(task.thu) > 0
                  ? Colors.green
                  : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(task.date),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "+${task.thu}đ",
                  style: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
                Text(
                  "-${task.chi}đ",
                  style: const TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
