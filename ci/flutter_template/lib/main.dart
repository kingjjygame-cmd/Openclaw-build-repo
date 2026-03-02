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

enum DifficultyStage { easy, medium, hard }

int secondsForStage(DifficultyStage stage) {
  switch (stage) {
    case DifficultyStage.easy:
      return 15;
    case DifficultyStage.medium:
      return 10;
    case DifficultyStage.hard:
      return 5;
  }
}

String stageLabel(DifficultyStage stage) {
  switch (stage) {
    case DifficultyStage.easy:
      return 'Easy';
    case DifficultyStage.medium:
      return 'Medium';
    case DifficultyStage.hard:
      return 'Hard';
  }
}

DifficultyStage stageForQuestion(int index) {
  if (index < 3) return DifficultyStage.easy;
  if (index < 6) return DifficultyStage.medium;
  return DifficultyStage.hard;
}

final List<Character> characters = [
  const Character(name: '프린세스 하츄핑', assetPath: 'assets/images/hachuping.webp'),
  const Character(name: '사뿐핑', assetPath: 'assets/images/claireping.png'),
  const Character(name: '아름핑', assetPath: 'assets/images/graceping.png'),
  const Character(name: '뽀니핑', assetPath: 'assets/images/bonnyping.png'),
  const Character(name: '이클립스핑', assetPath: 'assets/images/eclipseping.png'),
  const Character(name: '다이아나핑', assetPath: 'assets/images/dianaping.png'),
  const Character(name: '뽀득핑', assetPath: 'assets/images/scrubping.png'),
  const Character(name: '차밍핑', assetPath: 'assets/images/charmingping.png'),
  const Character(name: '나비핑', assetPath: 'assets/images/flitterping.png'),
  const Character(name: '실크핑', assetPath: 'assets/images/silkyping.png'),
  const Character(name: '스노우핑', assetPath: 'assets/images/snowping.png'),
  const Character(name: '이슬핑', assetPath: 'assets/images/dewping.png'),
  const Character(name: '쿨쿨핑', assetPath: 'assets/images/dozyping.png'),
  const Character(name: '롱롱핑', assetPath: 'assets/images/glossyping.png'),
  const Character(name: '슈슈핑', assetPath: 'assets/images/rellaping.png'),
  const Character(name: '큐핑', assetPath: 'assets/images/cupidping.png'),
  const Character(name: '야옹핑', assetPath: 'assets/images/kittyping.png'),
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
  DifficultyStage _stage = DifficultyStage.easy;
  int _timeLeft = secondsForStage(DifficultyStage.easy);
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
    _stage = DifficultyStage.easy;
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
    _stage = stageForQuestion(_q);
    _timeLeft = secondsForStage(_stage);
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
        _handleTimeout();
      }
    });

    setState(() {});
  }

  void _handleTimeout() {
    if (_answered) return;
    final answer = characters[_questionIndices[_q]].name;
    setState(() {
      _answered = true;
      _selectedChoice = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF455A64),
        content: Row(
          children: [
            const Text('⏰⚡', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text('시간 초과! 정답은 $answer')),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 950), _goNext);
  }

  Future<void> _showStageCountdown(DifficultyStage nextStage) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 850),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF283593),
          content: Text('다음 단계 ${stageLabel(nextStage)} 시작까지 $i...'),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
    }
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
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isCorrect ? const Color(0xFF6A1B9A) : const Color(0xFFD81B60),
        content: Row(
          children: [
            Text(isCorrect ? '🌈🎉✨' : '💣😵‍💫❌', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isCorrect ? '정답 대폭발! 퍼펙트~!' : '아쉽다! 정답은 $answer',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(milliseconds: 750), _goNext);
  }

  Future<void> _goNext() async {
    if (!mounted) return;
    if (_q >= questionCount - 1) {
      _timer?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultPage(
            score: _score,
            total: questionCount,
          ),
        ),
      );
      return;
    }

    final currentStage = stageForQuestion(_q);
    final nextQuestion = _q + 1;
    final nextStage = stageForQuestion(nextQuestion);

    setState(() {
      _q = nextQuestion;
    });

    if (currentStage != nextStage) {
      await _showStageCountdown(nextStage);
      if (!mounted) return;
    }

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
                        Text('난이도: ${stageLabel(_stage)} · $_timeLeft초'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: imageHeight,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          color: Colors.pink.shade50,
                          alignment: Alignment.center,
                          child: Image.asset(
                            current.assetPath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Column(
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

  const ResultPage({super.key, required this.score, required this.total});

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
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const QuizPage()),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4FB0),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                ),
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
