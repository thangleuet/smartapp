class Device {
  String id;
  String name;
  String bprice;
  String nprice;
  List<String> number;
  DateTime date;
  String status;

  Device({
    required this.id,
    required this.name,
    required this.bprice,
    required this.nprice,
    required this.number,
    required this.date,
    required this.status,
  });

  Device.withId({
    required this.id,
    required this.name,
    required this.bprice,
    required this.nprice,
    required this.number,
    required this.date,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    final map = Map<String, dynamic>();
    map['id'] = id;
      map['name'] = name;
    map['bprice'] = bprice;
    map['nprice'] = nprice;
    map['number'] = number;
    map['date'] = date.toIso8601String();
    map['status'] = status;
    return map;
  }

  factory Device.fromMap(Map<String, dynamic> map) {
    return Device.withId(
      id: map['id'],
      name: map['name'],
      bprice: map['bprice'],
      nprice: map['nprice'],
      date: DateTime.parse(map['date']),
      number: List<String>.from(map['number']), status: '',
    );
  }
}
