import 'package:cloud_firestore/cloud_firestore.dart';

class PhoneModel {
  String id;
  String thu;
  String chi;
  DateTime date;
  String shop;
  String name;

  PhoneModel({required this.id, required this.thu, required this.chi, required this.date, required this.shop, required this.name});

  PhoneModel.withId(
      {required this.id, required this.thu, required this.chi, required this.date, required this.shop, required this.name});

  Map<String, dynamic> toMap() {
    final map = Map<String, dynamic>();
    map['id'] = id;
    map['thu'] = thu;
    map['chi'] = chi;
    map['date'] = Timestamp.fromDate(date);
    map['shop'] = shop;
    map['name'] = name;
    return map;
  }

  factory PhoneModel.fromMap(Map<String, dynamic> map) {
    return PhoneModel.withId(
      id: map['id'],
      thu: map['thu'],
      chi: map['chi'],
      date: map['date'].toDate(),
      shop: map['shop'],
      name: map['name'],
    );
  }
}
