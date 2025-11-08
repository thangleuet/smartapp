import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:phonekit_manager/model/shop_model.dart';
import 'package:phonekit_manager/model/task_model.dart';
import 'package:phonekit_manager/screen/home.dart';
import 'package:phonekit_manager/model/device_model.dart';
import 'package:intl/intl.dart';

class AddTaskScreen extends StatefulWidget {
  final Function updateTaskList;
  final String name_shop;
  final String current_email;

  AddTaskScreen(
      {required this.updateTaskList,
      required this.name_shop,
      required this.current_email});
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _searchController = TextEditingController();
  List<Device> _deviceList = [];
  List<Device> _filteredDeviceList = [];
  List<Device> data = [];
  String _title = '';
  String _numberSell = '';
  String _priority = '';
  String _tprice = '';
  String _searchText = '';
  DateTime _date = DateTime.now();
  int selectedCardIndex = -1;
  TextEditingController _dateController = TextEditingController();
  final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy hh:mm a');
  late Future<List<Task>> task_id;
  @override
  void initState() {
    Firebase.initializeApp().whenComplete(() {
      setState(() {});
    });
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
    super.initState();
    _dateController.text = _dateFormatter.format(_date);
    _initDeviceData();
  }

  @override
  void dispose() {
    _dateController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initDeviceData() async {
    List<Device> deviceList = await getDataDeviceFirestore();
    setState(() {
      _deviceList = deviceList;
      _filteredDeviceList = deviceList;
    });
    _filteredDeviceList.sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<String>> getDataShopFirestore() async {
    List<String> shopList = [];
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('shop').get();
      List<QueryDocumentSnapshot> documents = querySnapshot.docs;
      for (var document in documents) {
        Shop user = Shop.fromMap(document.data() as Map<String, dynamic>);
        shopList.add(user.name);
      }
    } catch (e) {
      print(e.toString());
    }
    return shopList;
  }

  _handleDatePicker() async {
    final DateTime date = DateTime.now();
    if (date != _date) {
      setState(() {
        _date = date;
      });
      _dateController.text = _dateFormatter.format(date);
    }
  }

  // Update ddataa JSON
  void updateDataDeviceFireStore(String idSelect, Device device) async {
    final docUser = FirebaseFirestore.instance.collection('device');
    docUser.doc(idSelect).update(device.toMap());
  }

  _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print('$_title, $_date, $_priority');

      Task task = Task(
          title: _title,
          date: _date,
          price: _priority,
          shop: widget.name_shop,
          tprice: _tprice,
          numberSell: _numberSell,
          id: UniqueKey().toString(),
          status: "0",
          giamgia: "0");

      await sendDataFireStore(task);
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => Home(widget.current_email, widget.name_shop)));
      await widget.updateTaskList();
    }
  }

  // Update ddataa JSON
  Future<void> updateDataFireStore(String idSelect, Task task) async {
    final docUser = FirebaseFirestore.instance.collection('phone');
    await docUser.doc(idSelect).update(task.toMap());
  }

  Future<void> sendDataFireStore(Task task) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('phone')
        .where('title', isEqualTo: task.title)
        .where('shop', isEqualTo: task.shop)
        .get();
    var docResult = null;
    if (snapshot.docs.isNotEmpty) {
      var doc = snapshot.docs;
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
        // Nếu tài liệu tồn tại, hãy cập nhật trường numberSell của tài liệu phù hợp đầu tiên
        final updatedNumberSell =
            (int.parse(docResult['numberSell'] ?? '0') + 1).toString();
        await docResult.reference.update({'numberSell': updatedNumberSell});
      } else {
        String unique_id = UniqueKey().toString();
        Map<String, dynamic> todoList = await {
          "id": unique_id,
          "title": task.title,
          "date": Timestamp.fromDate(task.date),
          "price": task.price,
          "status": task.status,
          "shop": task.shop,
          "tprice": task.tprice,
          "numberSell": task.numberSell,
          "giamgia": "0",
        };
        await FirebaseFirestore.instance
            .collection('phone')
            .doc(unique_id)
            .set(todoList);
      }
    } else {
      // Nếu không có tài liệu nào tồn tại, hãy tạo một tài liệu mới với dữ liệu được cung cấp
      String unique_id = UniqueKey().toString();
      Map<String, dynamic> todoList = await {
        "id": unique_id,
        "title": task.title,
        "date": Timestamp.fromDate(task.date),
        "price": task.price,
        "status": task.status,
        "shop": task.shop,
        "tprice": task.tprice,
        "numberSell": task.numberSell,
        "giamgia": "0",
      };
      await FirebaseFirestore.instance
          .collection('phone')
          .doc(unique_id)
          .set(todoList);
    }
  }

  Future<List<Device>> getDataDeviceFirestore() async {
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
    taskList.sort((taskA, taskB) => taskA.date.compareTo(taskB.date));
    return taskList;
  }

  void _updateDeviceList(String query) {
    List<Device> filteredList = _deviceList
        .where(
            (device) => device.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {
      _filteredDeviceList = filteredList;
    });
    _filteredDeviceList.sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        title: Text('Danh sách thiết bị', style: TextStyle(fontSize: 24)),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Container(
              color: Colors.grey[200],
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Tìm kiếm thiết bị',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search, color: Colors.grey),
                      onPressed: null,
                    ),
                  ),
                  onChanged: (value) {
                    _updateDeviceList(value);
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                physics: BouncingScrollPhysics(),
                itemCount: _filteredDeviceList.length,
                itemBuilder: (BuildContext context, int index) {
                  Device device = _filteredDeviceList[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCardIndex = index;
                      });
                      _title = device.name;
                      _priority = device.bprice;
                      _tprice = device.nprice;
                      _numberSell = '1';
                      if (widget.name_shop == "Cửa hàng Quang Tèo 1") {
                        device.number[0] =
                            (int.parse(device.number[0]) - 1).toString();
                      } else if (widget.name_shop == "Cửa hàng Quang Tèo 2") {
                        device.number[1] =
                            (int.parse(device.number[1]) - 1).toString();
                      } else {
                        device.number[2] =
                            (int.parse(device.number[2]) - 1).toString();
                      }
                      updateDataDeviceFireStore(device.id, device);
                      _handleDatePicker();
                      _submit();
                    },
                    child: Card(
                      color: selectedCardIndex == index ? Colors.purple : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: ListTile(
                        leading: Text('${index + 1}',
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 17.0,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Raleway')),
                        title: GestureDetector(
                          child: Text(device.name,
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        subtitle: Text("Giá bán: " + device.bprice + ".000 đ",
                            style: TextStyle(fontSize: 16)),
                        trailing: widget.name_shop == "Cửa hàng Quang Tèo 1"
                            ? Text(device.number[0].toString(),
                                style: TextStyle(fontSize: 16))
                            : widget.name_shop == "Cửa hàng Quang Tèo 2"
                                ? Text(device.number[1].toString(),
                                    style: TextStyle(fontSize: 16))
                                : Text(device.number[2].toString(),
                                    style: TextStyle(fontSize: 16)),
                      ),
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
