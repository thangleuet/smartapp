class Shop {
  String id;
  String name;

  Shop({required this.id, required this.name});

  Shop.withId({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    final map = Map<String, dynamic>();
    map['id'] = id;
      map['name'] = name;
    return map;
  }

  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop.withId(
      id: map['id'],
      name: map['name'],
    );
  }
}
