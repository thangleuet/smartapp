import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phonekit_manager/screen/home.dart';
import 'package:phonekit_manager/screen/login.dart';

class MyDrawer extends StatefulWidget {
  final String current_email;
  final String current_name;
  final List<String> list_shop;
  final String current_shop;

  const MyDrawer({
    required this.current_email,
    required this.current_name,
    required this.list_shop,
    required this.current_shop,
    Key? key,
  }) : super(key: key);

  @override
  MyDrawerState createState() => MyDrawerState();
}

class MyDrawerState extends State<MyDrawer> {
  Future<void> clearLoginCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('isLoggedIn');
    prefs.remove('username');
    prefs.remove('password');
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LogIN_Screen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = const Color.fromARGB(255, 29, 39, 230);
    final Color softPurple = const Color.fromRGBO(143, 148, 251, 0.15);

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Drawer(
        elevation: 8,
        backgroundColor: Colors.grey[100],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // HEADER
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.8),
                    primaryColor.withOpacity(0.6)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: primaryColor, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.current_name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.current_email,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white70),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),

            // DANH SÁCH CỬA HÀNG
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: widget.list_shop.length,
                itemBuilder: (context, index) {
                  final isSelected =
                      widget.list_shop[index] == widget.current_shop;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          if (isSelected)
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                        ],
                      ),
                      child: ListTile(
                        leading: Icon(Icons.storefront_rounded,
                            color: isSelected
                                ? Colors.white
                                : Colors.deepPurpleAccent),
                        title: Text(
                          widget.list_shop[index],
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                        ),
                        onTap: isSelected
                            ? null
                            : () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => Home(
                                      widget.current_email,
                                      widget.list_shop[index],
                                    ),
                                  ),
                                );
                              },
                      ),
                    ),
                  );
                },
              ),
            ),

            const Divider(thickness: 0.5),

            // NÚT ĐĂNG XUẤT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: primaryColor.withOpacity(0.4)),
                  ),
                ),
                icon: const Icon(Icons.exit_to_app),
                label: const Text(
                  "Đăng xuất",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () async {
                  await clearLoginCredentials();
                  await _signOut();
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
