import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phonekit_manager/model/shop_model.dart';
import 'package:phonekit_manager/model/user_model.dart';
import 'package:phonekit_manager/screen/home_screen.dart';
import 'package:phonekit_manager/screen/navigator_draw.dart';

class Home extends StatefulWidget {
  final String current_email;
  final String current_shop;
  Home(this.current_email, this.current_shop);
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _current_name = "";
  String _current_shop = "";
  String _current_role = "";
  List<String> _shopList = [];
  @override
  void initState() {
    super.initState();
    _initDataShop();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _initDataShop() async {
    UserModel user = await await getNameFirestore();
    if (user.role == "admin") {
      await _initDataUser(user.role);
      _current_name = user.name;
      _current_shop = widget.current_shop;
      _current_role = user.role;
    } else {
      await _initDataUser(user.role);
      _current_name = user.name;
      _current_shop = user.role;
      _current_role = user.role;
    }
  }

  Future<void> _initDataUser(String role) async {
    List<String> sList = await getListShop();
    setState(() {
      if (role == "admin") {
        _shopList.addAll(sList);
      } else {
        _shopList.add(role);
      }
    });
  }

  Future<List<String>> getListShop() async {
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

  Future<UserModel> getNameFirestore() async {
    List<UserModel> emailList = [];
    UserModel? currentUser;
    try {
      QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance.collection('user').get();
      List<QueryDocumentSnapshot> documents = querySnapshot.docs;
      for (var document in documents) {
        UserModel user =
            UserModel.fromMap(document.data() as Map<String, dynamic>);
        emailList.add(user);
      }
      for (var user in emailList) {
        if (user.email == widget.current_email) {
          currentUser = user;
        }
      }
      if (currentUser != null) {
        return currentUser;
      } else {
        throw Exception("User not found");
      }
    } catch (e) {
      print('Error fetching user data: $e');
      rethrow;
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('Bạn có muốn thoát ứng dụng?'),
              actions: <Widget>[
                TextButton(
                  child: Text('Không'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text('Có'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false; // Trường hợp dialog trả về null.
  }

  int index = 0;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: WillPopScope(
          onWillPop: () {
            return _onWillPop();
          },
          child: Scaffold(
              appBar: AppBar(
                backgroundColor: Color.fromRGBO(143, 148, 251, .6),
                title: Text(_current_shop),
              ),
              body: HomeScreen(widget.current_shop, widget.current_email,
                  _shopList, _current_name, _current_role),
              drawer: MyDrawer(
                current_email: widget.current_email,
                current_name: _current_name,
                list_shop: _shopList,
                current_shop: _current_shop,
              )),
        ));
  }
}
