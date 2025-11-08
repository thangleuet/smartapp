class UserModel {
  String id;
  String email;
  String password;
  String role;
  String name;

  UserModel({required this.id, required this.email, required this.password, required this.role, required this.name});

  UserModel.withId({required this.id, required this.email, required this.password, required this.role, required this.name});

  Map<String, dynamic> toMap() {
    final map = Map<String, dynamic>();
    map['id'] = id;
      map['email'] = email;
    map['password'] = password;
    map['role'] = role;
    map['name'] = name;
    return map;
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel.withId(
        id: map['id'],
        email: map['email'],
        password: map['password'],
        role: map['role'],
        name: map['name']);
  }
}
