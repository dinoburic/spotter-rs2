import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/auth_provider.dart';
import '../utils/utils_widgets.dart';

class MasterScreen extends StatefulWidget {
  const MasterScreen({super.key, required this.child, required this.title});
  final Widget child;
  final String title;

  @override
  State<MasterScreen> createState() => _MasterScreenState();
}

class _MasterScreenState extends State<MasterScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                // Handle Home navigation
                Navigator.push(context, MaterialPageRoute(builder: (context)=> testScreen("Home", "TODO add home screen")));
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart),
              title: Text('Cart'),
              onTap: () {
                // Handle Cart navigation
                Navigator.push(context, MaterialPageRoute(builder: (context)=> testScreen("Cart", "TODO add cart screen")));
              },
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Profile'),
              onTap: () {
                // Handle Profile navigation
                Navigator.push(context, MaterialPageRoute(builder: (context)=> testScreen("Profile", "TODO add profile screen")));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                  showDialog(
                    context: context, builder: (BuildContext context) => AlertDialog(
                      title: Text("Logout"),
                      content: Text("Are you sure you want to logout?"),
                      actions: [
                        TextButton(
                          onPressed: (() {
                            Navigator.pop(context);
                          }),
                          child: Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () async {
                            try {
                              AuthProvider authProvider = context
                                  .read<AuthProvider>();

                              authProvider.logout();

                              //throw Exception("Logout successful");

                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => LoginPage()),
                                (route) => false,
                              );
                            } catch (e) {
                              alertBoxMoveBack(context, "Error", e.toString());
                            }
                          },
                          child: Text("Yes"),
                        ),
                      ],
                    ));
              },
            ),
          ],
        ),
      ),
      body: widget.child,
      );
  }

  MasterScreen testScreen(String title, String content) {
    return MasterScreen(
      title: title,
      child: Center(
                child: Text(content),
              ));
  }
}