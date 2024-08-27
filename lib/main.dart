import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:rdp_todolist/screens/home_page.dart';

void main() async {
  //Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  //Initialize Firebase with the current platform's default options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),

      // Test Code Below
      // home: const Scaffold(
      //   body: Center(
      //     child: Text(
      //       'Hello, The app is working',
      //       style: TextStyle(
      //           color: Colors.brown, fontSize: 30, fontFamily: 'Caveat'),
      //     ),
      //   ),
      // ),
    );
  }
}
