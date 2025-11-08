import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  String id;
  String title;
  DateTime date;
  String price;
  String status; // 0 - Incomplete, 1 - Complete
  String shop;
  String tprice;
  String numberSell;
  String giamgia = "0";

  Task(
      {required this.id,
      required this.title,
      required this.date,
      required this.price,
      required this.status,
      required this.shop,
      required this.tprice,
      required this.numberSell,
      required this.giamgia});

  Task.withId(
      {required this.id,
      required this.title,
      required this.date,
      required this.price,
      required this.status,
      required this.shop,
      required this.tprice,
      required this.numberSell,
      required this.giamgia});

  Map<String, dynamic> toMap() {
    final map = Map<String, dynamic>();
    map['id'] = id;
    map['title'] = title;
    map['date'] = Timestamp.fromDate(date);
    map['price'] = price;
    map['status'] = status;
    map['shop'] = shop;
    map['tprice'] = tprice;
    map['numberSell'] = numberSell;
    map['giamgia'] = giamgia;
    return map;
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task.withId(
      id: map['id'],
      title: map['title'],
      date: map['date'].toDate(),
      price: map['price'],
      status: map['status'],
      shop: map['shop'],
      tprice: map['tprice'],
      giamgia: map['giamgia'],
      numberSell: map['numberSell'],
    );
  }
}
