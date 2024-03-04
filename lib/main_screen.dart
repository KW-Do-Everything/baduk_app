import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';

// =============== 메인 ===============
class MainScreen extends StatefulWidget {
  final String robotNum;
  const MainScreen({super.key, required this.robotNum});

  @override
  // ignore: library_private_types_in_public_api
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  String? gameState;
  var recommended;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    loadGameState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void loadGameState() async {
    String robotNum = widget.robotNum;
    DatabaseReference ref =
        FirebaseDatabase.instance.ref('Robots/$robotNum/state');
    ref.onValue.listen((DatabaseEvent event) {
      print(event);
      String newState = event.snapshot.value.toString();
      setState(() {
        gameState = newState;
      });
      context.read<GameInfo>().updateGameState(newState);
    });
    // Todo: 서버에서 추천수 가져오기
  }

  @override
  Widget build(BuildContext context) {
    double boardSize = min(MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.height) *
        0.8;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()));
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text('Baduk Robot'),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '현재 상태 확인'),
              Tab(text: '추천 수 확인'),
            ],
          ),
        ),
        body: Center(
          child: TabBarView(controller: _tabController, children: [
            // 현재 상황탭
            Center(
              child: CustomPaint(
                size: Size(boardSize, boardSize),
                painter: GoGamePainter(gameState, null),
              ),
            ),

            // 추천 수 탭
            Column(children: <Widget>[
              CustomPaint(
                size: Size(boardSize * 0.8, boardSize * 0.8),
                painter: GoGamePainter(gameState, recommended),
              ),
              SizedBox(height: boardSize * 0.05),
              GameInfoWidget(),
            ]),
          ]),
        ),
      ),
    );
  }
}

// =============== 그리기 ===============
class GoGamePainter extends CustomPainter {
  String? gameState;
  var recommended;
  GoGamePainter(this.gameState, this.recommended);

  @override
  void paint(Canvas canvas, Size size) {
    double cellSize = size.width / 20;
    double stoneSize = cellSize * 0.7; // 돌의 크기
    double dotSize = cellSize / 10; // 점의 크기

    var backgroundPaint = Paint()..color = Color(0xfff2c160);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // 바둑판 선 그리기
    var linePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7;
    for (int i = 0; i < 19; i++) {
      double offset = cellSize * i;
      canvas.drawLine(Offset(offset + cellSize, cellSize),
          Offset(offset + cellSize, size.height - cellSize), linePaint);
      canvas.drawLine(Offset(cellSize, offset + cellSize),
          Offset(size.width - cellSize, offset + cellSize), linePaint);
    }

    // 점 위치 정의
    List<Offset> dots = [
      Offset(4 * cellSize, 4 * cellSize),
      Offset(4 * cellSize, 10 * cellSize),
      Offset(4 * cellSize, 16 * cellSize),
      Offset(10 * cellSize, 4 * cellSize),
      Offset(10 * cellSize, 10 * cellSize),
      Offset(10 * cellSize, 16 * cellSize),
      Offset(16 * cellSize, 4 * cellSize),
      Offset(16 * cellSize, 10 * cellSize),
      Offset(16 * cellSize, 16 * cellSize),
    ];

    // 점 그리기
    var dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    for (Offset dot in dots) {
      canvas.drawCircle(dot, dotSize, dotPaint);
    }

    if (gameState != null && gameState!.length == 19 * 19) {
      // 바둑돌 그리기
      for (int i = 0; i < gameState!.length; i++) {
        int x = i % 19;
        int y = i ~/ 19;

        String stone = gameState![i];
        if (stone == '.') continue; // 빈 칸은 건너뛰기

        Color stoneColor = (stone == 'b') ? Color(0xFF404040) : Colors.white;
        Color borderColor = Colors.black;

        // 돌의 중심을 교차점에 맞추기
        double xPos = (x + 1) * cellSize;
        double yPos = (y + 1) * cellSize;

        var stonePaint = Paint()
          ..color = stoneColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(xPos, yPos), stoneSize / 2, stonePaint);

        var borderPaint = Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(xPos, yPos), stoneSize / 2, borderPaint);
      }
    }

    // 텍스트 스타일 정의
    var textStyle = TextStyle(
      color: Colors.black,
      fontSize: cellSize / 2, // 적절한 텍스트 크기로 조절
    );

    var textSpan;
    var textPainter;

    // 세로쪽 숫자 표시 (1~19)
    for (int i = 19; i >= 1; i--) {
      textSpan = TextSpan(style: textStyle, text: i.toString());
      textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(cellSize * 0.2, cellSize * (20 - i) - textPainter.height / 2));
    }

    // 가로쪽 알파벳 표시 (A~H, J~T)
    for (int i = 0; i < 19; i++) {
      // 'I'는 건너뛰고 알파벳 레이블을 생성합니다.
      String label =
          String.fromCharCode('A'.codeUnitAt(0) + i + (i >= 8 ? 1 : 0));
      textSpan = TextSpan(style: textStyle, text: label);
      textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(cellSize * (i + 1) - textPainter.width / 2, cellSize * 0.2));
    }

    // Todo: if recommeded is not null, draw recommend stones
  }

  @override
  bool shouldRepaint(covariant GoGamePainter oldDelegate) {
    return oldDelegate.gameState != gameState;
  }
}

// =============== 정보 관리 클래스 ===============
class GameInfo extends ChangeNotifier {
  String? _gameState;
  dynamic _recommended;

  String? get gameState => _gameState;
  get recommended => _recommended;

  void updateGameState(String newState) {
    _gameState = newState;
    notifyListeners();
  }
}

// =============== 각종 정보 위젯 ===============
class GameInfoWidget extends StatelessWidget {
  const GameInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final gameInfo = Provider.of<GameInfo>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          '현재 게임 상태: ${gameInfo.gameState ?? "로딩 중..."}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          '추천 수: ${gameInfo.recommended}',
          style: TextStyle(fontSize: 16),
        ),
        Text('승률'),
      ],
    );
  }
}
