import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';

double PI = 3.141592;

// =============== 메인 ===============
class MainScreen extends StatefulWidget {
  final String robotNum;
  const MainScreen({super.key, required this.robotNum});

  @override
  // ignore: library_private_types_in_public_api
  _MainScreenState createState()  => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  String? gameState;
  var recommend = [];
  var territory = "";
  var winRate = [];
  late TabController _tabController;
  String buttonString = "대국 시작";
  Color buttonColor = Colors.green;
  bool buttonStart = true;
  int _seconds = 0;
  late Timer _timer;

  bool finish = false;

  @override
  void initState() {
    super.initState();
    loadGameState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void loadGameState() async {
    String robotNum = widget.robotNum;
    DatabaseReference refState =
        FirebaseDatabase.instance.ref('Robots/$robotNum');
    refState.onValue.listen((DatabaseEvent event) {
      Map<String, dynamic> serverData =
          jsonDecode(jsonEncode((event.snapshot.value)))
              as Map<String, dynamic>;

      setState(() {
        gameState = serverData['state'];
        recommend = serverData['AI']['recommend'];
        territory = serverData['AI']['territory'];
        winRate = serverData['AI']['winRate'];
        finish = serverData['finish'];
        if (finish) {
          btnOnpress();
        }
      });
      context.read<GameInfo>().updateGameState(serverData['state']);
    });
    // Todo: 서버에서 추천수 가져오기
  }

  // ============= onpress ==============
  void btnOnpress() {
    String btnstring;
    bool btnstart;
    Color btncolor;

    String robotNum = widget.robotNum;
    DatabaseReference ref = FirebaseDatabase.instance.ref('Robots/$robotNum/');

    if (buttonStart) {
      btnstring = "대국 종료";
      btnstart = false;
      btncolor = Colors.red;
      _seconds = 0;
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("대국 시작 안내"),
            content: const Text("시작을 위해 바둑판의 위치를 확인해주세요."),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
                      setState(() {
                        _seconds++;
                      });
                    });
                    Navigator.pop(context);
                    // Todo: 데이터베이스 Robotnum/init을 false로 바꾸기
                    ref.update({'init': true});
                  },
                  child: const Text('확인'))
            ],
          );
        },
      );
    } else {
      btnstring = "대국 시작";
      btnstart = true;
      finish = false;
      ref.update({'finish':finish});
      btncolor = Colors.green;
      _timer.cancel();

      ref.child('AI/territory').once().then((DatabaseEvent event) {
        String resultData =
            jsonDecode(jsonEncode(event.snapshot.value)) as String;
        String resultMessage = resultData[0] == 'B' ? 'You Win!' : 'You Lose...';
        Icon resultIcon = resultData[0] == 'B'
            ? Icon(Icons.emoji_events, size: 50, color: Colors.yellow)
            : Icon(Icons.sentiment_very_dissatisfied, size: 50, color: Colors.red);

        Color backgroundColor = resultData[0] == 'B' ? Colors.green : Colors.red;

        String formattedTime = '${((_seconds ~/ 60) ~/ 60).toString().padLeft(2, '0')} : ${((_seconds ~/ 60) % 60).toString().padLeft(2, '0')} : ${(_seconds % 60).toString().padLeft(2, '0')}';

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: backgroundColor,
              title: Row(
                children: [
                  resultIcon,
                  SizedBox(width: 10),
                  Text(
                    "대국 결과",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    resultMessage,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '대국 시간: $formattedTime',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: backgroundColor,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('확인'),
                )
              ],
            );
          },
        );
      });

      ref.update({'init': false});
    }

    setState(() {
      buttonString = btnstring;
      buttonStart = btnstart;
      buttonColor = btncolor;
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    double boardSize = min(width, height) * 0.8;

    double widgetHeightSize = width > height ? (height * 0.3) : (height * 0.2);
    double widgetWidthSize = MediaQuery.of(context).size.width / 2;

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
              Tab(text: 'AI 분석'),
            ],
          ),
        ),
        body: Center(
          child: TabBarView(controller: _tabController, children: [
            // 현재 상황탭
            Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(width: boardSize * 0.2, height: boardSize * 0.05),
                  Text(
                    '${((_seconds ~/ 60) ~/ 60).toString().padLeft(2, '0')} : ${((_seconds ~/ 60) % 60).toString().padLeft(2, '0')} : ${(_seconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Container(
                      padding: const EdgeInsets.all(3),
                      child: SizedBox(
                          width: boardSize * 0.2,
                          height: boardSize * 0.05,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: buttonColor,
                                  foregroundColor: Colors.white),
                              onPressed: btnOnpress,
                              child: Text(buttonString)))),
                ]),
                Center(
                  child: CustomPaint(
                    size: Size(boardSize, boardSize),
                    painter: GoGamePainter(gameState, null),
                  ),
                ),
              ],
            ),

            // 추천 수 탭
            Container(
                padding: EdgeInsets.fromLTRB(30, 10, 30, 10),
                child: SingleChildScrollView(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        CustomPaint(
                          size: Size(boardSize * 0.8, boardSize * 0.8),
                          painter: GoGamePainter(gameState, recommend),
                        ),
                        SizedBox(height: boardSize * 0.01),
                        //GameInfoWidget(),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                child: CustomPaint(
                                    size:
                                        Size(widgetWidthSize, widgetHeightSize),
                                    painter: winratePainter(winRate)),
                              ),
                              Container(
                                margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                child: Column(
                                  children: <Widget>[
                                    Container(
                                        margin: EdgeInsets.fromLTRB(0, 0, 0, 5),
                                        child: CustomPaint(
                                            size: Size(widgetWidthSize * 0.6,
                                                widgetHeightSize / 2),
                                            painter: housePainter(territory))),
                                    Container(
                                        margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
                                        child: CustomPaint(
                                            size: Size(widgetWidthSize * 0.6,
                                                widgetHeightSize / 2),
                                            painter: recommendPainter(
                                                recommend[0]))),
                                  ],
                                ),
                              ),
                            ]),
                      ]),
                ))
          ]),
        ),
      ),
    );
  }
}

// =============== 그리기 ===============
class GoGamePainter extends CustomPainter {
  String? gameState;
  var recommend;
  var color = [
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.orange,
    Colors.red,
  ];

  GoGamePainter(this.gameState, this.recommend);

  @override
  void paint(Canvas canvas, Size size) {
    // double cellSize = size.width / 20;
    // double stoneSize = cellSize * 0.7; // 돌의 크기
    // double dotSize = cellSize / 10; // 점의 크기


    double cellSize = size.width / 10;
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
    for (int i = 0; i < 9; i++) {
    // for (int i = 0; i < 19; i++) {
      double offset = cellSize * i;
      canvas.drawLine(Offset(offset + cellSize, cellSize),
          Offset(offset + cellSize, size.height - cellSize), linePaint);
      canvas.drawLine(Offset(cellSize, offset + cellSize),
          Offset(size.width - cellSize, offset + cellSize), linePaint);
    }

    // 점 위치 정의
    List<Offset> dots = [
      Offset(5 * cellSize, 5 * cellSize)

      // Offset(4 * cellSize, 4 * cellSize),
      // Offset(4 * cellSize, 10 * cellSize),
      // Offset(4 * cellSize, 16 * cellSize),
      // Offset(10 * cellSize, 4 * cellSize),
      // Offset(10 * cellSize, 10 * cellSize),
      // Offset(10 * cellSize, 16 * cellSize),
      // Offset(16 * cellSize, 4 * cellSize),
      // Offset(16 * cellSize, 10 * cellSize),
      // Offset(16 * cellSize, 16 * cellSize),
    ];

    // 점 그리기
    var dotPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    for (Offset dot in dots) {
      canvas.drawCircle(dot, dotSize, dotPaint);
    }

    if (true) {
      // 바둑돌 그리기
      for (int i = 0; i < gameState!.length; i++) {
        // int x = i % 19;
        // int y = i ~/ 19;

        int x = i % 9;
        int y = i ~/ 9;

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
    for (int i = 9; i >= 1; i--) {
    // for (int i = 19; i >= 1; i--) {
      textSpan = TextSpan(style: textStyle, text: i.toString());
      textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          // Offset(cellSize * 0.2, cellSize * (20 - i) - textPainter.height / 2));
          Offset(cellSize * 0.2, cellSize * (10 - i) - textPainter.height / 2));
    }

    // 가로쪽 알파벳 표시 (A~H, J~T)
    for (int i = 0; i < 9; i++) {
    // for (int i = 0; i < 19; i++) {
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
    RegExp regex = RegExp(r'([A-Za-z]+)(\d+)');
    Map atoi = {
      'A': 1,
      'B': 2,
      'C': 3,
      'D': 4,
      'E': 5,
      'F': 6,
      'G': 7,
      'H': 8,
      'J': 9,
      'K': 10,
      'L': 11,
      'M': 12,
      'N': 13,
      'O': 14,
      'P': 15,
      'Q': 16,
      'R': 17,
      'S': 18,
      'T': 19
    };

    // String init_string = '*' * 361;
    String init_string = '*' * 81;
    if ((recommend != null) &&(recommend != init_string)) {
      for (int i = 0; i < recommend.length; i += 2) {
        Match match = regex.firstMatch(recommend[i]) as Match;
        String? letter = match.group(1);
        String? num = match.group(2);

        // int x = atoi[letter] - 1;
        // int y = 19 - int.parse(num!);

        int x = atoi[letter] - 1;
        int y = 9 - int.parse(num!);

        double xPos = (x + 1) * cellSize;
        double yPos = (y + 1) * cellSize;

        var stonePaint = Paint()
          ..color = color[i ~/ 2]
          ..style = PaintingStyle.fill;

        stonePaint.color = Color.fromRGBO(stonePaint.color.red, stonePaint.color.green, stonePaint.color.blue, 0.7);
        canvas.drawCircle(Offset(xPos, yPos), stoneSize / 2, stonePaint);

        var borderPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        borderPaint.color = Color.fromRGBO(borderPaint.color.red, borderPaint.color.green, borderPaint.color.blue, 0.7);
        canvas.drawCircle(Offset(xPos, yPos), stoneSize / 2, borderPaint);

        // xPos = (20 + 1) * cellSize;
        // yPos = (i ~/ 2 + 1) * cellSize;

        xPos = (10 + 1) * cellSize;
        yPos = (i ~/ 2 + 1) * cellSize;

        textSpan = TextSpan(style: textStyle, text: "${i ~/ 2 + 1}. ");
        textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();
        textPainter.paint(
            canvas,
            Offset(
                xPos - textPainter.width / 2, yPos - textPainter.height / 2));

        stonePaint = Paint()
          ..color = color[i ~/ 2]
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
            Offset(xPos + cellSize, yPos), stoneSize / 2, stonePaint);

        borderPaint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(
            Offset(xPos + cellSize, yPos), stoneSize / 2, borderPaint);

        textSpan =
            TextSpan(style: textStyle, text: "${(recommend[i + 1] * 0.01).toStringAsFixed(2)}%");
        textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();
        textPainter.paint(
            canvas,
            Offset(xPos + cellSize * 2 - textPainter.width / 3,
                yPos - textPainter.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant GoGamePainter oldDelegate) {
    return oldDelegate.gameState != gameState;
  }
}

// =============== 정보 관리 클래스 ===============
class GameInfo extends ChangeNotifier {
  String? _gameState;
  dynamic _recommend;

  String? get gameState => _gameState;
  get recommend => _recommend;

  void updateGameState(String newState) {
    _gameState = newState;
    notifyListeners();
  }
}

// =============== 각종 정보 위젯 ===============
class winratePainter extends CustomPainter {
  var winrate;

  winratePainter(this.winrate);

  @override
  void paint(Canvas canvas, Size size) {
    var widgetPaint = Paint()..color = Color(0xff999966);
    BorderRadius borderRadius = BorderRadius.circular(20);
    Rect winrateRect = Rect.fromLTWH(0, 0, size.width, size.height);
    RRect winrateOutter = borderRadius.toRRect(winrateRect);
    canvas.drawRRect(winrateOutter, widgetPaint);

    var textStyle = TextStyle(
        color: Colors.black,
        fontSize: size.height * 0.12,
        fontWeight: FontWeight.bold);
    var textSpan = TextSpan(style: textStyle, text: "승률");
    var textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(canvas,
        Offset((size.width - textPainter.width) * 0.5, size.height * 0.1));

    var winBlackPaint = Paint()
      ..color = Color(0xff333333)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.6),
        size.width * 0.09, winBlackPaint);
    var borderPaint = Paint()
      ..color = Color(0xff000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.6),
        size.width * 0.09, borderPaint);

    textStyle = TextStyle(color: Colors.white, fontSize: size.width * 0.05);
    textSpan =
        TextSpan(style: textStyle, text: "${(winrate[1] * 0.01).toStringAsFixed(2)}%"); // winrate Black
    textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(size.width * 0.15 - textPainter.width / 2,
            size.height * 0.6 - textPainter.height / 2));

    textStyle = TextStyle(color: Colors.black, fontSize: size.width * 0.05);
    textSpan = TextSpan(style: textStyle, text: "vs");
    textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(size.width * 0.29 - textPainter.width / 2,
            size.height * 0.6 - textPainter.height / 2));

    var winWhitePaint = Paint()
      ..color = Color(0xffffffff)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.43, size.height * 0.6),
        size.width * 0.09, winWhitePaint);
    borderPaint = Paint()
      ..color = Color(0xff000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width * 0.43, size.height * 0.6),
        size.width * 0.09, borderPaint);

    textStyle = TextStyle(color: Colors.black, fontSize: size.width * 0.05);
    textSpan =
        TextSpan(style: textStyle, text: "${(winrate[0] * 0.01).toStringAsFixed(2)}%"); // winrate White
    textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(
        canvas,
        Offset(size.width * 0.43 - textPainter.width / 2,
            size.height * 0.6 - textPainter.height / 2));

    var winrateStonePaint = Paint()
      ..color = Color(0xff333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20.0;
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width * 0.8, size.height * 0.6),
            width: size.width * 0.2,
            height: size.width * 0.2),
        0,
        PI * 2 * (winrate[1] / 100), // black winrate
        false,
        winrateStonePaint);

    winrateStonePaint.color = Color(0xffffffff);
    canvas.drawArc(
        Rect.fromCenter(
            center: Offset(size.width * 0.8, size.height * 0.6),
            width: size.width * 0.2,
            height: size.width * 0.2),
        PI * 2 * (winrate[1] / 10000),
        PI * 2 * (winrate[0] / 10000),
        false,
        winrateStonePaint);
  }

  @override
  bool shouldRepaint(covariant winratePainter oldDelegate) {
    return (oldDelegate.winrate != winrate);
  }
}

class housePainter extends CustomPainter {
  var house;

  housePainter(this.house);

  @override
  void paint(Canvas canvas, Size size) {
    var widgetPaint = Paint()..color = Color(0xff999966);
    BorderRadius borderRadius = BorderRadius.circular(20);
    Rect winrateRect = Rect.fromLTWH(0, 0, size.width, size.height);
    RRect winrateOutter = borderRadius.toRRect(winrateRect);
    canvas.drawRRect(winrateOutter, widgetPaint);

    var textStyle = TextStyle(
        color: Colors.black,
        fontSize: size.height * 0.2,
        fontWeight: FontWeight.bold);
    var textSpan = TextSpan(style: textStyle, text: "예상 집차이");
    var textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(canvas,
        Offset((size.width - textPainter.width) * 0.5, size.height * 0.1));

    textStyle = TextStyle(color: Colors.black, fontSize: size.height * 0.2);
    textSpan = TextSpan(style: textStyle, text: house); // 집차이 변수로 넣기
    textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    textPainter.paint(canvas,
        Offset((size.width - textPainter.width) * 0.5, size.height * 0.5));
  }

  @override
  bool shouldRepaint(covariant housePainter oldDelegate) {
    return oldDelegate.house != house;
  }
}

class recommendPainter extends CustomPainter {
  var best;

  recommendPainter(this.best);

  @override
  void paint(Canvas canvas, Size size) {
    var widgetPaint = Paint()..color = Color(0xff999966);
    BorderRadius borderRadius = BorderRadius.circular(20);
    Rect winrateRect = Rect.fromLTWH(0, 0, size.width, size.height);
    RRect winrateOutter = borderRadius.toRRect(winrateRect);
    canvas.drawRRect(winrateOutter, widgetPaint);

    if (best != null) {
      var textStyle = TextStyle(
          color: Colors.black,
          fontSize: size.height * 0.2,
          fontWeight: FontWeight.bold);
      var textSpan = TextSpan(style: textStyle, text: "추천 수");
      var textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset((size.width - textPainter.width) * 0.5, size.height * 0.1));

      textStyle = TextStyle(color: Colors.black, fontSize: size.height * 0.2);
      textSpan = TextSpan(style: textStyle, text: best);
      textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width * 0.45, size.height * 0.5));

      var recommendPaint = Paint()
        ..color = Color(0xff333333)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
          Offset(
              size.width * 0.35, size.height * 0.5 + textPainter.height * 0.5),
          size.height * 0.12,
          recommendPaint);
      var borderPaint = Paint()
        ..color = Color(0xff000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(
          Offset(
              size.width * 0.35, size.height * 0.5 + textPainter.height * 0.5),
          size.height * 0.12,
          borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant recommendPainter oldDelegate) {
    return oldDelegate.best != best;
  }
}
