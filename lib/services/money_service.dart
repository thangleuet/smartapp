import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phonekit_manager/model/money_model.dart';

class MoneyService {
  final CollectionReference _moneyRef =
      FirebaseFirestore.instance.collection('money');

  final Map<String, List<MoneyModel>> _cache = {};

  Future<List<MoneyModel>> getMoneyData(
      String shop, DateTime selectedDate) async {
    final key = '${shop}_${selectedDate.year}-${selectedDate.month}';
    if (_cache.containsKey(key)) return _cache[key]!;

    final start = DateTime(selectedDate.year, selectedDate.month, 1);
    final end = DateTime(selectedDate.year, selectedDate.month + 1, 1);

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('money')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();

    final data = snapshot.docs
        .map((doc) => MoneyModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();

    _cache[key] = data;
    return data;
  }

  Stream<List<MoneyModel>> streamMoneyData(String shop, DateTime selectedDate) {
    final start = DateTime(selectedDate.year, selectedDate.month, 1);
    final end = DateTime(selectedDate.year, selectedDate.month + 1, 1);

    return FirebaseFirestore.instance
        .collection('money')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(
                (doc) => MoneyModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  List<MoneyModel> sumMoneyByMonth(List<MoneyModel> items) {
    final Map<String, MoneyModel> result = {};

    for (var t in items) {
      final key = '${t.date.year}-${t.date.month}';
      if (!result.containsKey(key)) {
        result[key] = MoneyModel(
          id: key,
          gia_nhap: List<String>.from(t.gia_nhap),
          gia_ban: List<String>.from(t.gia_ban),
          date: DateTime(t.date.year, t.date.month),
        );
      } else {
        final existing = result[key]!;
        for (int i = 0; i < existing.gia_nhap.length; i++) {
          final nhapOld = double.tryParse(existing.gia_nhap[i]) ?? 0;
          final banOld = double.tryParse(existing.gia_ban[i]) ?? 0;
          final nhapNew = double.tryParse(t.gia_nhap[i]) ?? 0;
          final banNew = double.tryParse(t.gia_ban[i]) ?? 0;

          existing.gia_nhap[i] = (nhapOld + nhapNew).toString();
          existing.gia_ban[i] = (banOld + banNew).toString();
        }
      }
    }
    return result.values.toList();
  }
}
