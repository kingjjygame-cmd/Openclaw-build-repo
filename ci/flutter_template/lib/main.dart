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
      home: const StartPage(),
    );
  }
}

class Character {
  final String name;
  final String assetPath;

  const Character({required this.name, required this.assetPath});
}

const int questionsPerStage = 10;

enum QuizMode { unlimited, timed }

enum DifficultyStage { easy, medium, hard }

int secondsForStage(DifficultyStage stage) {
  switch (stage) {
    case DifficultyStage.easy:
      return 10;
    case DifficultyStage.medium:
      return 5;
    case DifficultyStage.hard:
      return 3;
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

DifficultyStage? nextStage(DifficultyStage stage) {
  switch (stage) {
    case DifficultyStage.easy:
      return DifficultyStage.medium;
    case DifficultyStage.medium:
      return DifficultyStage.hard;
    case DifficultyStage.hard:
      return null;
  }
}

double revealFractionForStage(DifficultyStage stage) {
  switch (stage) {
    case DifficultyStage.easy:
      return 0.24;
    case DifficultyStage.medium:
      return 0.16;
    case DifficultyStage.hard:
      return 0.11;
  }
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

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF9ED2), Color(0xFFB39DDB)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🩷 티니핑 퀴즈', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 12),
                const Text(
                  '원하는 모드를 선택해 주세요\n(무제한 모드: 일부 공개 후 정답 선택 시 전체 공개)',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 26),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const QuizPage(mode: QuizMode.unlimited)),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF5E35B1),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  icon: const Icon(Icons.all_inclusive),
                  label: const Text('시간 무제한 모드', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const QuizPage(mode: QuizMode.timed)),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFEC407A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  icon: const Icon(Icons.timer),
                  label: const Text('시간 제한 모드 (10/5/3초)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final QuizMode mode;

  const QuizPage({super.key, required this.mode});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final _rand = Random();
  late List<int> _questionIndices;

  DifficultyStage _stage = DifficultyStage.easy;
  int _qInStage = 0;
  int _totalScore = 0;

  int _timeLeft = secondsForStage(DifficultyStage.easy);
  Timer? _timer;
  bool _answered = false;
  String? _selectedChoice;
  List<String> _choices = [];

  bool _showReaction = false;
  Color _reactionColor = Colors.purple;
  String _reactionEmoji = '';
  String _reactionText = '';

  bool _showInlineResult = false;
  Color _inlineResultColor = Colors.green;
  String _inlineResultText = '';

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

  void _prepareStageQuestions() {
    _questionIndices = List.generate(characters.length, (i) => i)..shuffle(_rand);
    if (_questionIndices.length > questionsPerStage) {
      _questionIndices = _questionIndices.take(questionsPerStage).toList();
    }
    while (_questionIndices.length < questionsPerStage) {
      _questionIndices.add(_rand.nextInt(characters.length));
    }
  }

  void _startNewGame() {
    _timer?.cancel();
    _stage = DifficultyStage.easy;
    _qInStage = 0;
    _totalScore = 0;
    _prepareStageQuestions();
    _loadQuestion();
  }

  void _loadQuestion() {
    _answered = false;
    _selectedChoice = null;
    _showInlineResult = false;
    _inlineResultText = '';
    _timeLeft = widget.mode == QuizMode.timed ? secondsForStage(_stage) : -1;

    final target = characters[_questionIndices[_qInStage]];
    final wrongNames = characters.where((c) => c.name != target.name).map((c) => c.name).toList()..shuffle(_rand);
    _choices = [target.name, wrongNames[0], wrongNames[1]]..shuffle(_rand);

    _timer?.cancel();
    if (widget.mode == QuizMode.timed) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() => _timeLeft--);
        if (_timeLeft <= 0) {
          timer.cancel();
          _handleTimeout();
        }
      });
    }

    setState(() {});
  }

  Future<void> _showFullscreenReaction({
    required bool isCorrect,
    String? answer,
    bool isTimeout = false,
  }) async {
    setState(() {
      _showReaction = true;
      if (isTimeout) {
        _reactionColor = const Color(0xFF37474F);
        _reactionEmoji = '⏰⚡';
        _reactionText = '시간 초과! 정답은 $answer';
      } else if (isCorrect) {
        _reactionColor = const Color(0xFF7B1FA2);
        _reactionEmoji = '🌈🎉✨';
        _reactionText = '정답!';
      } else {
        _reactionColor = const Color(0xFFC2185B);
        _reactionEmoji = '💣😵‍💫❌';
        _reactionText = '아쉽다! 정답은 $answer';
      }
    });

    await Future.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;
    setState(() => _showReaction = false);
  }

  Future<void> _handleTimeout() async {
    if (_answered) return;
    final answer = characters[_questionIndices[_qInStage]].name;
    setState(() {
      _answered = true;
      _selectedChoice = null;
    });

    await _showFullscreenReaction(isCorrect: false, answer: answer, isTimeout: true);
    await _goNext();
  }

  Future<void> _pick(String selected) async {
    if (_answered) return;
    final answer = characters[_questionIndices[_qInStage]].name;
    final isCorrect = selected == answer;

    setState(() {
      _answered = true;
      _selectedChoice = selected;
      if (isCorrect) _totalScore++;
    });

    _timer?.cancel();

    if (widget.mode == QuizMode.unlimited) {
      setState(() {
        _showInlineResult = true;
        _inlineResultColor = isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFC2185B);
        _inlineResultText = isCorrect ? '정답!' : '오답! 정답은 $answer';
      });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      setState(() => _showInlineResult = false);
      await _goNext();
      return;
    }

    await _showFullscreenReaction(isCorrect: isCorrect, answer: answer);
    await _goNext();
  }

  Future<void> _goNext() async {
    if (!mounted) return;

    if (_qInStage >= questionsPerStage - 1) {
      final upcoming = nextStage(_stage);
      if (upcoming == null) {
        _timer?.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultPage(
              score: _totalScore,
              total: questionsPerStage * 3,
              mode: widget.mode,
            ),
          ),
        );
        return;
      }

      final proceed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => StageTransitionPage(from: _stage, to: upcoming),
        ),
      );

      if (!mounted || proceed != true) return;

      setState(() {
        _stage = upcoming;
        _qInStage = 0;
      });
      _prepareStageQuestions();
      _loadQuestion();
      return;
    }

    setState(() => _qInStage++);
    _loadQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final current = characters[_questionIndices[_qInStage]];
    final answer = current.name;

    Color? buttonBg(String choice) {
      if (!_answered || _selectedChoice == null) return null;
      if (choice == answer) return Colors.green;
      if (choice == _selectedChoice) return Colors.red;
      return Colors.grey.shade500;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mode == QuizMode.timed ? '티니핑 이름 맞추기 · 시간 제한' : '티니핑 이름 맞추기 · 무제한'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SafeArea(
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
                        Text(
                          '${stageLabel(_stage)} · 문제 ${_qInStage + 1} / $questionsPerStage',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('총점: $_totalScore'),
                            Text(widget.mode == QuizMode.timed ? '제한 시간: $_timeLeft초' : '제한 시간: 무제한'),
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
                              child: LayoutBuilder(
                                builder: (context, constraints2) {
                                  final isUnlimited = widget.mode == QuizMode.unlimited;
                                  final baseFraction = revealFractionForStage(_stage);
                                  final targetFraction = (!isUnlimited || _answered) ? 1.0 : baseFraction;

                                  final image = Image.asset(
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
                                  );

                                  if (!isUnlimited) return image;

                                  final minSide = min(constraints2.maxWidth, constraints2.maxHeight);

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween<double>(end: targetFraction),
                                    duration: const Duration(milliseconds: 700),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, animatedFraction, child) {
                                      final diameter = (minSide * animatedFraction).clamp(40.0, minSide);
                                      return Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(color: Colors.black87),
                                          ClipOval(
                                            child: SizedBox(
                                              width: diameter,
                                              height: diameter,
                                              child: child,
                                            ),
                                          ),
                                          if (!_answered)
                                            Positioned(
                                              top: 10,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius: BorderRadius.circular(20),
                                                ),
                                                child: Text(
                                                  '원형 공개 ${(baseFraction * 100).round()}%',
                                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                    child: image,
                                  );
                                },
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
          if (_showInlineResult)
            Positioned(
              top: 18,
              left: 16,
              right: 16,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: _inlineResultColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: Text(
                  _inlineResultText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          AnimatedOpacity(
            opacity: _showReaction ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: !_showReaction,
              child: Container(
                color: _reactionColor.withOpacity(0.82),
                width: double.infinity,
                height: double.infinity,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_reactionEmoji, style: const TextStyle(fontSize: 56)),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          _reactionText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StageTransitionPage extends StatefulWidget {
  final DifficultyStage from;
  final DifficultyStage to;

  const StageTransitionPage({super.key, required this.from, required this.to});

  @override
  State<StageTransitionPage> createState() => _StageTransitionPageState();
}

class _StageTransitionPageState extends State<StageTransitionPage> {
  int _count = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_count == 1) {
        timer.cancel();
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _count--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7E57C2), Color(0xFFEC407A)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('LEVEL UP!', style: TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Text(
                '${stageLabel(widget.from)} 완료\n${stageLabel(widget.to)} 시작!',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 24),
              Text('$_count', style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  final int score;
  final int total;
  final QuizMode mode;

  const ResultPage({super.key, required this.score, required this.total, required this.mode});

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
              Text('최종 점수: $score / $total', style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => QuizPage(mode: mode)),
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
