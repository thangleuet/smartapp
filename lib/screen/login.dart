import 'package:flutter/material.dart';
import 'package:phonekit_manager/const/colors.dart';
import 'package:phonekit_manager/data/auth_data.dart';
import 'package:phonekit_manager/Animation/FadeAnimation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phonekit_manager/model/user_model.dart';

class LogIN_Screen extends StatefulWidget {
  LogIN_Screen();

  @override
  State<LogIN_Screen> createState() => _LogIN_ScreenState();
}

class _LogIN_ScreenState extends State<LogIN_Screen> {
  FocusNode _focusNode1 = FocusNode();
  FocusNode _focusNode2 = FocusNode();
  String _password = "";
  String _email = "";
  bool _passwordVisible = false;
  bool _rememberMe = false;
  bool isSelect = false;
  String message = "";
  String _current_shop = "";
  late final UserModel user;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusNode1.addListener(() {
      setState(() {});
    });
    super.initState();
    _focusNode2.addListener(() {
      setState(() {});
    });
  }

  Future<void> saveLoginStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', isLoggedIn);
  }

  Future<void> saveLoginCredentials(String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('username', username);
    prefs.setString('password', password);
  }

  void _showDialog(String message, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Đăng nhập thất bại'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> getLoginCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? '';
    final password = prefs.getString('password') ?? '';
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    return {
      'username': username,
      'password': password,
      'isLoggedIn': isLoggedIn,
    };
  }

  Future<void> signIn(BuildContext context) async {
    try {
      if (_rememberMe) {
        await saveLoginCredentials(_emailController.text, _password);
        await saveLoginStatus(true);
      }
      if (_email == "" || _password == "") {
        await getLoginCredentials().then((credentials) {
          setState(() {
            _rememberMe = credentials['isLoggedIn'];
            _emailController.text = credentials['username'];
            _passwordController.text = credentials['password'];
            _email = credentials['username'];
            _password = credentials['password'];
          });
        });
      }
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.trim(),
        password: _password.trim(),
      );
      // await _initDataShop(_email);

      // Navigator.push(context,
      // MaterialPageRoute(builder: (_) => Home(_email, _current_shop)));
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        message = 'Không tìm thấy tài khoản với email này.';
        print('Không tìm thấy tài khoản với email này.');
      } else if (e.code == 'wrong-password') {
        message = 'Mật khẩu không đúng.';
        print('Mật khẩu không đúng.');
      } else if (e.code == 'user-not-found') {
        message = 'Không tìm thấy email này';
        print('Không tìm thấy email này');
      }
      _showDialog(message, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Container(
            child: Column(
              children: <Widget>[
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage('assets/images/background.png'),
                          fit: BoxFit.fill)),
                  child: Stack(
                    children: <Widget>[
                      Positioned(
                        left: 30,
                        width: 80,
                        height: 200,
                        child: FadeAnimation(
                            1,
                            Container(
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: AssetImage(
                                          'assets/images/light-1.png'))),
                            )),
                      ),
                      Positioned(
                        left: 140,
                        width: 80,
                        height: 150,
                        child: FadeAnimation(
                            1.3,
                            Container(
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: AssetImage(
                                          'assets/images/light-2.png'))),
                            )),
                      ),
                      Positioned(
                        right: 40,
                        top: 40,
                        width: 80,
                        height: 150,
                        child: FadeAnimation(
                            1.5,
                            Container(
                              decoration: BoxDecoration(
                                  image: DecorationImage(
                                      image: AssetImage(
                                          'assets/images/clock.png'))),
                            )),
                      ),
                      Positioned(
                        child: FadeAnimation(
                            1.6,
                            Container(
                              margin: EdgeInsets.only(top: 70),
                              child: Center(
                                child: Text(
                                  "Đăng nhập",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            )),
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    children: <Widget>[
                      FadeAnimation(
                          1.8,
                          Container(
                            padding: EdgeInsets.all(5),
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                      color: Color.fromRGBO(143, 148, 251, .2),
                                      blurRadius: 20.0,
                                      offset: Offset(0, 10))
                                ]),
                            child: Column(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.all(8.0),
                                  decoration: BoxDecoration(
                                      border: Border(
                                          bottom: BorderSide(
                                              color: const Color.fromARGB(
                                                  255, 177, 171, 171)))),
                                  child: TextFormField(
                                    controller: _emailController,
                                    onChanged: (value) => _email = value,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "Email hoặc số điện thoại",
                                        hintStyle:
                                            TextStyle(color: Colors.grey[400])),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.all(8.0),
                                  child: TextFormField(
                                    controller: _passwordController,
                                    onChanged: (value) => _password = value,
                                    obscureText: !_passwordVisible,
                                    decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "Mật khẩu",
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            // Based on passwordVisible state choose the icon
                                            _passwordVisible
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            color: Theme.of(context)
                                                .primaryColorDark,
                                          ),
                                          onPressed: () {
                                            // Update the state i.e. toogle the state of passwordVisible variable
                                            setState(() {
                                              _passwordVisible =
                                                  !_passwordVisible;
                                            });
                                          },
                                        ),
                                        hintStyle:
                                            TextStyle(color: Colors.grey[400])),
                                  ),
                                ),
                                CheckboxListTile(
                                  title: Text("Nhớ mật khẩu"),
                                  value: _rememberMe,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _rememberMe = newValue!;
                                    });
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                ),
                              ],
                            ),
                          )),
                      SizedBox(
                        height: 30,
                      ),
                      Ink(
                        color: isSelect ? Colors.green : null,
                        child: InkWell(
                          splashColor: Colors.blue.withAlpha(30),
                          highlightColor: Colors.transparent,
                          onTap: () {
                            setState(() {
                              isSelect =
                                  !isSelect; // đảo ngược trạng thái của Card khi tap vào
                            });
                            signIn(context);
                          },
                          child: FadeAnimation(
                            2,
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  gradient: LinearGradient(colors: [
                                    Color.fromRGBO(143, 148, 251, 1),
                                    Color.fromRGBO(143, 148, 251, .6),
                                  ])),
                              child: Center(
                                child: TextButton(
                                    child: Text(
                                      "Đăng nhập",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22),
                                    ),
                                    onPressed: null),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
