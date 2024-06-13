import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';

import 'main_screen.dart';

//// 로그인 화면
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _controller = TextEditingController();

  void _navigateToMainScreen(BuildContext context) {
    final robotNum = _controller.text;
    if (robotNum.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainScreen(robotNum: robotNum),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text(
              'GoBot',
              style: TextStyle(
                color: Colors.lightBlue,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
              SizedBox(
                width: 200,
                  child: TextField(
                textInputAction: TextInputAction.go,
                controller: _controller,
                decoration: const InputDecoration(
                    labelText: 'Enter Robot Number', alignLabelWithHint: true),
                keyboardType: TextInputType.number,
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.digitsOnly
                ],
                onSubmitted: (value) async {
                  if (await _onPressed(_controller.text)) {
                    // ignore: use_build_context_synchronously
                    _navigateToMainScreen(context);
                  }
                },
              )),
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ElevatedButton(
                    child: Text("GO!"),
                    onPressed: () async => {
                      if (await _onPressed(_controller.text))
                        _navigateToMainScreen(context)
                    },
                  ))
            ]),
          ],
        ),
      ),
    );
  }
}

Future<bool> _onPressed(var robotNum) async {
  DatabaseReference database =
      FirebaseDatabase.instance.ref('Robots/$robotNum');
  final snapshot = await database.get();

  if (snapshot.exists) {
    return true;
  } else {
    return false;
  }
}
