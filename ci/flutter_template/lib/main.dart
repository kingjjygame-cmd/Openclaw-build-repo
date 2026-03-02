// build: asset-bundle-verify-v2
import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const TinyPingQuizApp());
}

class TinyPingQuizApp extends StatelessWidget {
  const TinyPingQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '티니핑 이름 맞추기',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6FB7)),
        useMaterial3: true,
      ),
      home: const QuizPage(),
    );
  }
}

class Character {
  final String name;
  final String assetPath;

  const Character({required this.name, required this.assetPath});
}

const int questionCount = 10;
const int secondsPerQuestion = 15;

final List<Character> characters = [
  const Character(name: '하츄핑', assetPath: 'assets/images/hachuping.webp'),
  const Character(name: '차차핑', assetPath: 'assets/images/chachaping.webp'),
  const Character(name: '라라핑', assetPath: 'assets/images/raraping.webp'),
  const Character(name: '아자핑', assetPath: 'assets/images/ajaping.webp'),
  const Character(name: '해핑', assetPath: 'assets/images/haeping.webp'),
  const Character(name: '조아핑', assetPath: 'assets/images/joaping.webp'),
];

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final _rand = Random();
  late List<int> _questionIndices;
  int _q = 0;
  int _score = 0;
  int _timeLeft = secondsPerQuestion;
  Timer? _timer;
  bool _answered = false;
  String? _selectedChoice;
  List<String> _choices = [];

  @override
  void initState() {
    super.initState();
    _startNewGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startNewGame() {
    _timer?.cancel();
    _score = 0;
    _q = 0;
    _questionIndices = List.generate(characters.length, (i) => i)..shuffle(_rand);
    if (_questionIndices.length > questionCount) {
      _questionIndices = _questionIndices.take(questionCount).toList();
    }
    while (_questionIndices.length < questionCount) {
      _questionIndices.add(_rand.nextInt(characters.length));
    }
    _loadQuestion();
  }

  void _loadQuestion() {
    _answered = false;
    _selectedChoice = null;
    _timeLeft = secondsPerQuestion;
    final target = characters[_questionIndices[_q]];
    final wrongNames = characters
        .where((c) => c.name != target.name)
        .map((c) => c.name)
        .toList()
      ..shuffle(_rand);

    _choices = [target.name, wrongNames[0], wrongNames[1]]..shuffle(_rand);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _timeLeft--;
      });
      if (_timeLeft <= 0) {
        timer.cancel();
        _goNext();
      }
    });

    setState(() {});
  }

  void _pick(String selected) {
    if (_answered) return;
    final answer = characters[_questionIndices[_q]].name;
    final isCorrect = selected == answer;

    setState(() {
      _answered = true;
      _selectedChoice = selected;
      if (isCorrect) {
        _score++;
      }
    });

    _timer?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 700),
        content: Text(isCorrect ? '정답! 🎉' : '오답! 정답은 $answer'),
      ),
    );

    Future.delayed(const Duration(milliseconds: 750), _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    if (_q >= questionCount - 1) {
      _timer?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultPage(
            score: _score,
            total: questionCount,
            onRestart: _startNewGame,
          ),
        ),
      );
      return;
    }
    setState(() {
      _q++;
    });
    _loadQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final current = characters[_questionIndices[_q]];
    final answer = current.name;

    Color? buttonBg(String choice) {
      if (!_answered || _selectedChoice == null) return null;
      if (choice == answer) return Colors.green;
      if (choice == _selectedChoice) return Colors.red;
      return Colors.grey.shade500;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('티니핑 이름 맞추기'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final imageHeight = (constraints.maxHeight * 0.38).clamp(180.0, 280.0);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('문제 ${_q + 1} / $questionCount', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('점수: $_score'),
                        Text('남은 시간: $_timeLeft초'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: imageHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          current.assetPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.pink.shade50,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image_not_supported, size: 36),
                                const SizedBox(height: 8),
                                Text('${current.name} (이미지 로드 실패)'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._choices.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: FilledButton(
                          onPressed: _answered ? null : () => _pick(c),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            backgroundColor: buttonBg(c),
                          ),
                          child: Text(c),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final int score;
  final int total;
  final VoidCallback onRestart;

  const ResultPage({super.key, required this.score, required this.total, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('게임 종료!', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              Text('점수: $score / $total', style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  onRestart();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const QuizPage()),
                  );
                },
                icon: const Icon(Icons.replay),
                label: const Text('다시 하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
