import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_screen.dart';

// =============== 로그인 ===============
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
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
        child: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          const Text(
            'Baduk Robot',
            style: TextStyle(
              color: Colors.lightBlue,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            width: 200,
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                  labelText: 'Enter Robot Number', alignLabelWithHint: true),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              var robotNum = _controller.text;
              var exists = await checkIfPathExists('Robots/$robotNum');
              if (exists) {
                _navigateToMainScreen(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('존재하지 않는 로봇 번호입니다.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Enter'),
          ),
        ]),
      ),
    );
  }
}

Future<bool> checkIfPathExists(String path) async {
  DatabaseReference ref = FirebaseDatabase.instance.ref(path);
  DatabaseEvent event = await ref.once();

  return event.snapshot.value != null;
}
