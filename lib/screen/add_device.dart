import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:phonekit_manager/model/device_model.dart';
import 'package:phonekit_manager/screen/setting_screen.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class DeviceScreen extends StatefulWidget {
  final Function updateTaskList;
  final Device device;
  final String name_shop;
  final String current_email;
  final String current_role;

  DeviceScreen({
    required this.updateTaskList,
    required this.device,
    required this.name_shop,
    required this.current_email,
    required this.current_role,
  });

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _nprice = '';
  String _bprice = '';
  String numberInput = '';
  List<String> _number = ['0', '0', '0'];
  DateTime _date = DateTime.now();
  final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy');
  late TextEditingController _dateController;

  @override
  void initState() {
    Firebase.initializeApp();
    super.initState();

    _name = widget.device.name;
    _nprice = widget.device.nprice;
    _bprice = widget.device.bprice;
    _number = widget.device.number;
    if (widget.name_shop == "Cửa hàng Quang Tèo 1") numberInput = _number[0];
    if (widget.name_shop == "Cửa hàng Quang Tèo 2") numberInput = _number[1];
    if (widget.name_shop == "Cửa hàng Quang Tèo 3") numberInput = _number[2];

    _dateController = TextEditingController(text: _dateFormatter.format(_date));
  }

  Future<void> _handleDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2021),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8F94FB),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
        _dateController.text = _dateFormatter.format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState?.save();

      Device device = Device(
        id: widget.device.id.isNotEmpty ? widget.device.id : Uuid().v1(),
        name: _name,
        date: _date,
        bprice: _bprice,
        nprice: _nprice,
        number: _number,
        status: widget.device.status,
      );

      if (widget.device.id.isEmpty) {
        FirebaseFirestore.instance
            .collection('device')
            .doc(device.id)
            .set(device.toMap());
      } else {
        FirebaseFirestore.instance
            .collection('device')
            .doc(device.id)
            .update(device.toMap());
      }

      widget.updateTaskList();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SettingsScreen(
            widget.name_shop,
            widget.current_email,
            widget.current_role,
          ),
        ),
      );
    }
  }

  void _delete() {
    FirebaseFirestore.instance
        .collection('device')
        .doc(widget.device.id)
        .delete();
    widget.updateTaskList();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.device.id.isEmpty ? 'Thêm phụ kiện' : 'Sửa phụ kiện',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8F94FB), Color(0xFF4E54C8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 100),
            child: Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(Icons.phone_iphone_rounded,
                        size: 70, color: Colors.white),
                    const SizedBox(height: 10),
                    const Text(
                      "Thông tin phụ kiện",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 25),
                    _buildTextField(
                        label: "Tên phụ kiện",
                        icon: Icons.devices_other_outlined,
                        value: _name,
                        onSaved: (val) => _name = val!,
                        validatorText: "Nhập tên phụ kiện"),
                    _buildTextField(
                        label: "Giá bán (nghìn)",
                        icon: Icons.sell_outlined,
                        value: _bprice,
                        keyboardType: TextInputType.number,
                        onSaved: (val) => _bprice = val!,
                        validatorText: "Nhập giá bán"),
                    _buildTextField(
                        label: "Giá nhập (nghìn)",
                        icon: Icons.shopping_cart_outlined,
                        value: _nprice,
                        keyboardType: TextInputType.number,
                        onSaved: (val) => _nprice = val!,
                        validatorText: "Nhập giá nhập"),
                    _buildTextField(
                        label: "Số lượng",
                        icon: Icons.storage_rounded,
                        value: numberInput,
                        keyboardType: TextInputType.number,
                        onSaved: (val) {
                          if (widget.name_shop == "Cửa hàng Quang Tèo 1")
                            _number[0] = val!;
                          if (widget.name_shop == "Cửa hàng Quang Tèo 2")
                            _number[1] = val!;
                          if (widget.name_shop == "Cửa hàng Quang Tèo 3")
                            _number[2] = val!;
                        },
                        validatorText: "Nhập số lượng"),
                    GestureDetector(
                      onTap: _handleDatePicker,
                      child: AbsorbPointer(
                        child: _buildTextField(
                            label: "Ngày nhập hàng",
                            icon: Icons.calendar_today_outlined,
                            controller: _dateController),
                      ),
                    ),
                    _buildTextField(
                        label: "Cửa hàng",
                        icon: Icons.storefront_rounded,
                        value: widget.name_shop,
                        readOnly: true),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildGradientButton(
                            text: "Lưu",
                            icon: Icons.save_rounded,
                            color1: const Color(0xFF8F94FB),
                            color2: const Color(0xFF4E54C8),
                            onPressed: _submit),
                        const SizedBox(width: 15),
                        if (widget.device.id.isNotEmpty)
                          _buildGradientButton(
                              text: "Xóa",
                              icon: Icons.delete_forever_rounded,
                              color1: Colors.redAccent,
                              color2: Colors.deepOrange,
                              onPressed: _delete),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    String? value,
    String? validatorText,
    TextInputType? keyboardType,
    TextEditingController? controller,
    bool readOnly = false,
    Function(String?)? onSaved,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        initialValue: controller == null ? value : null,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white70),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70, fontSize: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide:
                BorderSide(color: Colors.white.withOpacity(0.4), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
        ),
        validator: (val) =>
            validatorText != null && val!.trim().isEmpty ? validatorText : null,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color1, color2]),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: color1.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        icon: Icon(icon, color: Colors.white),
        label: Text(text,
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        onPressed: onPressed,
      ),
    );
  }
}
