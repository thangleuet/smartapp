import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phonekit_manager/model/device_model.dart';
import 'package:phonekit_manager/model/money_model.dart';
import 'package:phonekit_manager/model/shop_model.dart';
import 'package:phonekit_manager/model/task_model.dart';
import 'package:phonekit_manager/screen/money_screen.dart';
import 'package:phonekit_manager/screen/navigator_draw.dart';
import 'package:phonekit_manager/screen/add_task_screen.dart';
import 'package:phonekit_manager/screen/setting_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:phonekit_manager/screen/consum_screen.dart';
import 'package:phonekit_manager/screen/phone_manage_screen.dart';
import 'dart:async';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class HomeScreen extends StatefulWidget {
  final String name_shop;
  final String current_email;
  final List<String> shopList;
  final String current_name;
  final String current_role;
  HomeScreen(this.name_shop, this.current_email, this.shopList,
      this.current_name, this.current_role);
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Task>> _taskList;
  late Future<List<Device>> _taskDevice;
  String title = "";
  List<String> todos = <String>[];
  TextEditingController controller = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy hh:mm a');
  List<Task> data = [];
  String tongBanDB = "";
  String tongNhapDB = "";
  String number = "";
  String _scanBarcode = 'Unknown';
  DateTime _selectedDate = DateTime.now();
  List<String> _gia_nhap = ["0", "0", "0"];
  List<String> _gia_ban = ["0", "0", "0"];

  @override
  void initState() {
    _updateTaskList();
    super.initState();
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

  Future<List<Task>> getDataJsonfireStore() async {
    List<Task> taskList = [];
    List<Task> data = [];
    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection('phone');

    DateTime startDate =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    DateTime endDate = startDate.add(const Duration(days: 1));

    QuerySnapshot querySnapshot = await collectionRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThan: Timestamp.fromDate(endDate))
        .orderBy('date')
        .get();

    taskList = querySnapshot.docs
        .map((doc) => Task.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    for (var document in taskList) {
      if (document.shop == widget.name_shop) {
        data.add(document);
      }
    }
    return data;
  }

  Future<List<Device>> getDataDeviceJsonfireStore(String id) async {
    List<Device> taskList = [];

    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection('device');
    QuerySnapshot querySnapshot =
        await collectionRef.where('id', isEqualTo: id).get();
    final allData = querySnapshot.docs.map((doc) => doc.data()).toList();
    for (var document in allData) {
      Device task = Device.fromMap(document as Map<String, dynamic>);
      taskList.add(task);
    }
    taskList.sort((taskA, taskB) => taskA.date.compareTo(taskB.date));
    return taskList;
  }

  // Get number shop
  Future<List<Shop>> getShopfireStore() async {
    List<Shop> shopList = [];
    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection('shop');
    QuerySnapshot querySnapshot = await collectionRef.get();
    final allData = querySnapshot.docs.map((doc) => doc.data()).toList();
    for (var document in allData) {
      Shop shop = Shop.fromMap(document as Map<String, dynamic>);
      shopList.add(shop);
    }
    return shopList;
  }

  Future<void> sendDataMoneyFireStore(MoneyModel task) async {
    String unique_id = UniqueKey().toString();
    Map<String, dynamic> todoList = {
      "id": unique_id,
      "date": Timestamp.fromDate(task.date),
      "gia_nhap": task.gia_nhap,
      "gia_ban": task.gia_ban,
    };

    await FirebaseFirestore.instance
        .collection('money')
        .doc(unique_id)
        .set(todoList);
  }

  void updateDataMoneyFireStore(String idSelect, MoneyModel task) async {
    final docUser = FirebaseFirestore.instance.collection('money');
    docUser.doc(idSelect).update(task.toMap());
  }

  Future<void> check_money_model() async {
    try {
      DateTime startDate =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      DateTime endDate = startDate.add(const Duration(days: 1));

      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('money')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThan: Timestamp.fromDate(endDate))
          .get();

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          await FirebaseFirestore.instance
              .collection('money')
              .doc(doc.id)
              .delete();
        }
      }

      if (_gia_nhap.length < 3) _gia_nhap = ["0", "0", "0"];
      if (_gia_ban.length < 3) _gia_ban = ["0", "0", "0"];

      if (widget.name_shop == "Cửa hàng Quang Tèo 1") {
        _gia_nhap[0] = tongNhapDB;
        _gia_ban[0] = tongBanDB;
      } else if (widget.name_shop == "Cửa hàng Quang Tèo 2") {
        _gia_nhap[1] = tongNhapDB;
        _gia_ban[1] = tongBanDB;
      } else {
        _gia_nhap[2] = tongNhapDB;
        _gia_ban[2] = tongBanDB;
      }
      MoneyModel moneySend = MoneyModel(
        date: _selectedDate,
        gia_nhap: _gia_nhap,
        gia_ban: _gia_ban,
        id: '',
      );

      String docId = DateFormat('yyyyMMdd').format(_selectedDate);
      await FirebaseFirestore.instance
          .collection('money')
          .doc(docId)
          .set(moneySend.toMap());

      // DocumentReference docRef = await FirebaseFirestore.instance
      //     .collection('money')
      //     .add(moneySend.toMap());

      // await docRef.update({'id': docRef.id});
    } catch (e) {
      print('check_money_model error: $e');
    }
  }

  void deleteTask(Task task) async {
    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection('phone');

    final snapshot = await collectionRef
        .where('title', isEqualTo: task.title)
        .where('shop', isEqualTo: task.shop)
        .get();

    final snapshotDevice = await FirebaseFirestore.instance
        .collection('device')
        .where('name', isEqualTo: task.title)
        .get();

    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        DateTime dateDevice = doc['date'].toDate();
        int resultday = dateDevice.day.compareTo(task.date.day);
        int resultmonth = dateDevice.month.compareTo(task.date.month);
        int resultyear = dateDevice.year.compareTo(task.date.year);
        if (resultday == 0 &&
            resultmonth == 0 &&
            resultyear == 0 &&
            doc['shop'] == task.shop) {
          final updatedNumberSell =
              (int.parse(doc['numberSell']) - 1).toString();
          if (updatedNumberSell == '0') {
            await doc.reference.delete();
          } else {
            await doc.reference.update({'numberSell': updatedNumberSell});
          }
        }
        if (snapshotDevice.docs.isNotEmpty) {
          final doc = snapshotDevice.docs.first;
          List<String> numberList = doc['number'].cast<String>();
          if (widget.name_shop == "Cửa hàng Quang Tèo 1") {
            numberList[0] = (int.parse(numberList[0]) + 1).toString();
          } else if (widget.name_shop == "Cửa hàng Quang Tèo 2") {
            numberList[1] = (int.parse(numberList[1]) + 1).toString();
          } else if (widget.name_shop == "Cửa hàng Quang Tèo 3") {
            numberList[2] = (int.parse(numberList[2]) + 1).toString();
          }
          await doc.reference.update({'number': numberList});
        }
      }
    }
  }

  void _updateTaskList() {
    setState(() {
      _taskList = getDataJsonfireStore().then((fetchedData) {
        for (var i = 0; i < data.length; i++) {
          fetchedData.add(data[i]);
        }
        fetchedData.sort((taskA, taskB) => taskA.date.compareTo(taskB.date));
        return fetchedData;
      });
    });
  }

  void updateListTask(Task task, bool isAdd) {
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

  void _updateDeviceList(String id) {
    setState(() {
      _taskDevice = getDataDeviceJsonfireStore(id);
    });
  }

  Future<void> onBackPressed() {
    return SystemNavigator.pop();
  }

  Future<void> _pullRefresh() async {
    Duration(seconds: 1);
  }

  void updateDataDeviceFireStore(String idSelect, Device task) async {
    final docUser = FirebaseFirestore.instance.collection('device');
    docUser.doc(idSelect).update(task.toMap());
  }

  void updateDataFireStore(String idSelect, Task task) async {
    final docUser = FirebaseFirestore.instance.collection('phone');
    docUser.doc(idSelect).update(task.toMap());
  }

  Future<void> sendDataFireStore(Task task) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('phone')
        .where('title', isEqualTo: task.title)
        .where('shop', isEqualTo: task.shop)
        .get();
    final snapshotDevice = await FirebaseFirestore.instance
        .collection('device')
        .where('name', isEqualTo: task.title)
        .get();

    if (snapshotDevice.docs.isNotEmpty) {
      final docDevice = snapshotDevice.docs.first;
      if (widget.name_shop == "Cửa hàng Quang Tèo 1") {
        final updatedNumber =
            (int.parse(docDevice['number'][0]) - 1).toString();
        final number = [
          updatedNumber,
          docDevice['number'][1],
          docDevice['number'][2]
        ];
        await docDevice.reference.update({'number': number});
      } else if (widget.name_shop == "Cửa hàng Quang Tèo 2") {
        final updatedNumber =
            (int.parse(docDevice['number'][1]) - 1).toString();
        final number = [
          docDevice['number'][0],
          updatedNumber,
          docDevice['number'][2]
        ];
        await docDevice.reference.update({'number': number});
      } else {
        final updatedNumber =
            (int.parse(docDevice['number'][2]) - 1).toString();
        final number = [
          docDevice['number'][0],
          docDevice['number'][1],
          updatedNumber
        ];
        await docDevice.reference.update({'number': number});
      }
    }
    var docResult = null;
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs;
      for (var i = 0; i < doc.length; i++) {
        DateTime dateDoc = doc[i]['date'].toDate();
        int resultday = dateDoc.day.compareTo(task.date.day);
        int resultmonth = dateDoc.month.compareTo(task.date.month);
        int resultyear = dateDoc.year.compareTo(task.date.year);
        if (resultday == 0 && resultmonth == 0 && resultyear == 0) {
          docResult = doc[i];
        }
      }
      if (docResult != null) {
        if (snapshot.docs.isNotEmpty && docResult['shop'] == widget.name_shop) {
          final updatedNumberSell =
              (int.parse(docResult['numberSell'] ?? '0') + 1).toString();
          await docResult.reference.update({'numberSell': updatedNumberSell});
        } else {
          String unique_id = UniqueKey().toString();
          Map<String, dynamic> todoList = {
            "id": unique_id,
            "title": task.title,
            "date": Timestamp.fromDate(task.date),
            "price": task.price,
            "status": task.status,
            "shop": task.shop,
            "tprice": task.tprice,
            "numberSell": task.numberSell,
            "giamgia": "0"
          };
          await FirebaseFirestore.instance
              .collection('phone')
              .doc(unique_id)
              .set(todoList);
        }
      } else {
        String unique_id = UniqueKey().toString();
        Map<String, dynamic> todoList = {
          "id": unique_id,
          "title": task.title,
          "date": Timestamp.fromDate(task.date),
          "price": task.price,
          "status": task.status,
          "shop": task.shop,
          "tprice": task.tprice,
          "numberSell": task.numberSell,
          "giamgia": "0"
        };
        await FirebaseFirestore.instance
            .collection('phone')
            .doc(unique_id)
            .set(todoList);
      }
    } else {
      String unique_id = UniqueKey().toString();
      Map<String, dynamic> todoList = {
        "id": unique_id,
        "title": task.title,
        "date": Timestamp.fromDate(task.date),
        "price": task.price,
        "status": task.status,
        "shop": task.shop,
        "tprice": task.tprice,
        "numberSell": task.numberSell,
        "giamgia": "0"
      };
      await FirebaseFirestore.instance
          .collection('phone')
          .doc(unique_id)
          .set(todoList);
    }
  }

  // Scan qrCode
  Future<void> scanQR() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.QR);
      print(barcodeScanRes);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
    _scanBarcode = barcodeScanRes;
    _updateDeviceList(_scanBarcode);
    final taskList = await _taskDevice;
    Device matchedDevice = taskList.firstWhere(
      (task) => task.id == _scanBarcode,
    );

    Task task = Task(
      id: matchedDevice.id,
      title: matchedDevice.name,
      date: DateTime.now(),
      price: matchedDevice.bprice,
      status: '0',
      shop: widget.name_shop,
      tprice: matchedDevice.nprice,
      numberSell: "1",
      giamgia: "0",
    );

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Đã thêm vào giỏ hàng:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(matchedDevice.name),
              SizedBox(height: 4),
              Text("Giá: " + matchedDevice.bprice + ".000đ"),
            ],
          ),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    updateListTask(task, true);
    await sendDataFireStore(task);
  }

  void _showDialog(BuildContext context, Task task) {
    String textValue = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Text('Nhập số tiền giảm giá'),
          content: TextField(
            keyboardType: TextInputType.number,
            onChanged: (value) {
              textValue = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy bỏ'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Xác nhận'),
              onPressed: () {
                if (textValue != "") {
                  task.giamgia = textValue;
                } else {
                  task.giamgia = "0";
                }
                updateDataFireStore(task.id, task);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ----- NEW: polished list item -----
  Widget _buildTask(Task task) {
    final currency =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final price = double.tryParse(task.price) ?? 0;
    final tprice = double.tryParse(task.tprice) ?? 0;
    final discount = double.tryParse(task.giamgia) ?? 0;
    final qty = int.tryParse(task.numberSell) ?? 1;
    final totalItem = (price * qty - discount) * 1000; // display in VND

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 3))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDialog(context, task),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // icon / avatar
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.phone_iphone,
                      color: Colors.deepPurpleAccent, size: 30),
                ),

                const SizedBox(width: 12),

                // main info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // title + qty
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(task.title,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Text('x${task.numberSell}',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.green[700])),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // price row
                      Row(
                        children: [
                          Text('${currency.format(price * 1000)}',
                              style: TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 10),
                          if (discount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                  '-${currency.format(discount * 1000)}',
                                  style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // date
                      Text(_dateFormatter.format(task.date),
                          style:
                              TextStyle(fontSize: 13, color: Colors.blueGrey)),
                    ],
                  ),
                ),

                // total & delete
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(currency.format(totalItem),
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                content:
                                    Text("Bạn có đồng ý xóa phụ kiện này?"),
                                actions: [
                                  TextButton(
                                    child: Text("Cancel"),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text("Delete"),
                                    onPressed: () async {
                                      updateListTask(task, false);
                                      deleteTask(task);
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ],
                              );
                            });
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red.withOpacity(0.08),
                        ),
                        child: Icon(Icons.delete,
                            color: Colors.red[700], size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double tongBan, double tongNhap, double tongLai) {
    final currency =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    Widget card(String title, double value, Color color, IconData icon) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: Offset(0, 3))
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Text(title,
                      style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              Text(currency.format(value),
                  style: TextStyle(
                      color: color, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Row(
        children: [
          card('Tổng bán', tongBan, Colors.deepOrange,
              Icons.attach_money_rounded),
          card('Nhập hàng', tongNhap, Colors.blueGrey,
              Icons.shopping_cart_outlined),
          card('Lợi nhuận', tongLai, tongLai >= 0 ? Colors.green : Colors.red,
              Icons.trending_up),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Color(0xfff4f5fa),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        child: Icon(Icons.add_outlined),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddTaskScreen(
              updateTaskList: _updateTaskList,
              name_shop: widget.name_shop,
              current_email: widget.current_email,
            ),
          ),
        ),
      ),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(143, 148, 251, 1),
                Color.fromRGBO(143, 148, 251, .8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ---- Cột trái: tiêu đề & cửa hàng ----
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(15),
                        child: const Icon(Icons.store_rounded,
                            color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 15),
                    ],
                  ),

                  // ---- Cột phải: các nút hành động ----
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.qr_code_scanner_rounded,
                            color: Colors.white, size: 30),
                        iconSize: 40.0,
                        onPressed: () {
                          scanQR();
                        },
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.money_outlined,
                            color: Colors.white, size: 30),
                        iconSize: 40.0,
                        color: Colors.white,
                        onPressed: () => {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Consumer(widget.name_shop,
                                    widget.current_email, widget.current_role),
                              ))
                        },
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Icon(Icons.phone_android_rounded,
                            color: Colors.white, size: 30),
                        iconSize: 40.0,
                        color: Colors.white,
                        onPressed: () => {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PhoneManager(widget.name_shop,
                                    widget.current_email, widget.current_role),
                              ))
                        },
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.bar_chart_rounded,
                            color: Colors.white, size: 30),
                        iconSize: 40.0,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MoneyPage(widget.name_shop,
                                  widget.current_email, widget.current_role),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.receipt_long_rounded,
                            color: Colors.white, size: 30),
                        iconSize: 40.0,
                        onPressed: () {
                          // logic gốc báo cáo
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SettingsScreen(widget.name_shop,
                                  widget.current_email, widget.current_role),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: MyDrawer(
          current_email: widget.current_email,
          current_name: widget.current_name,
          list_shop: widget.shopList,
          current_shop: widget.name_shop),
      body: FutureBuilder<List<Task>>(
        future: _taskList,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final tasks = snapshot.data!;
          // compute totals (values stored as thousands in DB, consistent with prior code)
          double tongBanThousands = 0;
          double tongNhapThousands = 0;
          double tongLaiThousands = 0;
          int totalCount = 0;

          if (tasks.isNotEmpty) {
            tongBanThousands = tasks
                .map((t) =>
                    (double.tryParse(t.price) ?? 0) *
                        (int.tryParse(t.numberSell) ?? 1) -
                    (double.tryParse(t.giamgia) ?? 0))
                .reduce((a, b) => a + b);
            tongNhapThousands = tasks
                .map((t) =>
                    (double.tryParse(t.tprice) ?? 0) *
                    (int.tryParse(t.numberSell) ?? 1))
                .reduce((a, b) => a + b);
            tongLaiThousands = tongBanThousands - tongNhapThousands;
            totalCount = tasks
                .map((t) => int.tryParse(t.numberSell) ?? 0)
                .fold(0, (a, b) => a + b);
          }

          // convert to VND for display/chart (multiply by 1000)
          final tongBan = tongBanThousands * 1000;
          final tongNhap = tongNhapThousands * 1000;
          final tongLai = tongLaiThousands * 1000;
          tongBanDB = tongBanThousands.toString();
          tongNhapDB = tongNhapThousands.toString();
          check_money_model();

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 500));
              _updateTaskList();
            },
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              itemCount: 1 + tasks.length,
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  // Header with date, summary cards and chart
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // Date selector row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => _selectDate(context),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      color: Colors.blueGrey),
                                  SizedBox(width: 8),
                                  Text(
                                    DateFormat('EEE, MMM d, y')
                                        .format(_selectedDate),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey),
                                  ),
                                ],
                              ),
                            ),
                            // quick stats count
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    Colors.deepPurpleAccent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.shopping_bag_outlined,
                                      color: Colors.deepPurpleAccent),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$totalCount SP',
                                    style: TextStyle(
                                        color: Colors.deepPurpleAccent,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Summary cards
                      _buildSummaryCards(tongBan, tongNhap, tongLai),

                      const SizedBox(height: 8),
                    ],
                  );
                }

                final task = tasks[index - 1];
                return _buildTask(task);
              },
            ),
          );
        },
      ),
    );
  }
}
