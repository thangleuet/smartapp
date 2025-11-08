import 'package:cloud_firestore/cloud_firestore.dart';

class MoneyModel {
  String id;
  List<String> gia_nhap;
  List<String> gia_ban;
  DateTime date;

  MoneyModel({required this.id, required this.gia_nhap, required this.gia_ban, required this.date});

  MoneyModel.withId({required this.id, required this.gia_nhap, required this.gia_ban, required this.date});

  Map<String, dynamic> toMap() {
    final map = Map<String, dynamic>();
    map['id'] = id;
      map['gia_nhap'] = gia_nhap;
    map['gia_ban'] = gia_ban;
    map['date'] = Timestamp.fromDate(date);
    return map;
  }

  factory MoneyModel.fromMap(Map<String, dynamic> map) {
    return MoneyModel.withId(
      id: map['id'],
      gia_nhap: List<String>.from(map['gia_nhap']),
      gia_ban: List<String>.from(map['gia_ban']),
      date: map['date'].toDate(),
    );
  }
}
