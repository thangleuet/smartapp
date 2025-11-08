import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:phonekit_manager/model/shop_model.dart';
import 'package:phonekit_manager/screen/add_device.dart';
import 'package:phonekit_manager/model/device_model.dart';

class SettingsScreen extends StatefulWidget {
  final current_shop;
  final current_email;
  final String current_role;
  SettingsScreen(this.current_shop, this.current_email, this.current_role);
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<SettingsScreen> {
  late Future<List<Device>> _taskList;
  late Future<List<Shop>> _shopList;
  late Future<List<String>> _shopNameList;
  late Future<List<String>> _shopIdList;
  List<Device> _tasks = [];
  String _searchQuery = '';
  int taskIndex = 0;
  String title = "";
  List<String> todos = <String>[];
  TextEditingController controller = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy hh:mm a');
  List<Device> data = [];
  String totalPriority = "";
  String total1 = "";
  String _scanBarcode = 'Unknown';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateTaskList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2021),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
    _updateTaskList();
  }

  Future<List<Device>> getDataJsonfireStore() async {
    List<Device> taskList = [];

    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection('device');
    // Get docs from collection reference
    QuerySnapshot querySnapshot = await collectionRef.get();
    // Get data from docs and convert map to List
    final allData = querySnapshot.docs.map((doc) => doc.data()).toList();
    for (var document in allData) {
      Device task = Device.fromMap(document as Map<String, dynamic>);
      // int resultday = _selectedDate.day.compareTo(task.date.day);
      // int resultmonth = _selectedDate.month.compareTo(task.date.month);
      // int resultyear = _selectedDate.year.compareTo(task.date.year);
      // if (resultday == 0 && resultmonth == 0 && resultyear == 0)
      taskList.add(task);
    }
    // Check task_list is empty or not
    return taskList;
  }

  Future<void> deleteTask(Device task) async {
    var collection = FirebaseFirestore.instance.collection('device');
    collection
        .doc(task.id) // <-- Doc ID to be deleted.
        .delete();
  }

  _updateTaskList() {
    setState(() {
      _taskList = getDataJsonfireStore();
    });
  }

  Future<void> onBackPressed() {
    return SystemNavigator.pop();
  }

  Future<void> _pullRefresh() async {
    Duration(seconds: 1);
    await _updateTaskList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text(
          'Thêm phụ kiện',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF7C4DFF),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DeviceScreen(
              updateTaskList: _updateTaskList,
              name_shop: widget.current_shop,
              current_email: widget.current_email,
              current_role: widget.current_role,
              device: Device(
                id: '',
                name: '',
                bprice: '',
                nprice: '',
                number: ["0", "0", "0"],
                date: DateTime.now(),
                status: '',
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        elevation: 6,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF8F94FB), Color(0xFF4E54C8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.current_shop,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<Device>>(
        future: _taskList,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredData = snapshot.data!
              .where((d) =>
                  d.name.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          return RefreshIndicator(
            onRefresh: _pullRefresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 🔍 Thanh tìm kiếm
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: '🔍  Tìm kiếm phụ kiện...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 📱 Danh sách phụ kiện
                if (filteredData.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(
                      child: Text(
                        'Không có phụ kiện nào',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  ...List.generate(filteredData.length, (i) {
                    final task = filteredData[i];
                    final shopIndex =
                        widget.current_shop == "Cửa hàng Quang Tèo 1"
                            ? 0
                            : widget.current_shop == "Cửa hàng Quang Tèo 2"
                                ? 1
                                : 2;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              const Color(0xFF7C4DFF).withOpacity(0.1),
                          child: const Icon(Icons.devices_other,
                              color: Color(0xFF7C4DFF)),
                        ),
                        title: Text(
                          task.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Giá bán: ${task.bprice}.000đ',
                              style: const TextStyle(color: Colors.deepOrange),
                            ),
                            if (widget.current_role == 'admin')
                              Text('Giá nhập: ${task.nprice}.000đ',
                                  style:
                                      const TextStyle(color: Colors.blueGrey)),
                            Text(
                              'Số lượng: ${task.number[shopIndex]}',
                              style: const TextStyle(color: Colors.black54),
                            ),
                            Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(task.date),
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: widget.current_role == "admin"
                            ? IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteDialog(task),
                              )
                            : null,
                        onTap: () {
                          if (widget.current_role == "admin") {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DeviceScreen(
                                  updateTaskList: _updateTaskList,
                                  device: task,
                                  name_shop: widget.current_shop,
                                  current_email: widget.current_email,
                                  current_role: widget.current_role,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteDialog(Device task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phụ kiện'),
        content: const Text('Bạn có chắc muốn xóa phụ kiện này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await deleteTask(task);
              _updateTaskList();
              Navigator.pop(ctx);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
