// build: asset-bundle-verify-v2
import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

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
enum StageFlow { singleDifficulty, allDifficulties }

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
      return 0.34;
    case DifficultyStage.medium:
      return 0.24;
    case DifficultyStage.hard:
      return 0.16;
  }
}

final List<Character> characters = [
  const Character(name: '하츄핑', assetPath: 'assets/images/hachuping.webp'),
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

  Future<void> _startSingleDifficulty(BuildContext context, QuizMode mode) async {
    final selected = await showModalBottomSheet<DifficultyStage>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: DifficultyStage.values
              .map(
                (stage) => ListTile(
                  leading: const Icon(Icons.adjust),
                  title: Text('${stageLabel(stage)}만 플레이'),
                  onTap: () => Navigator.of(context).pop(stage),
                ),
              )
              .toList(),
        ),
      ),
    );

    if (selected == null || !context.mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizPage(
          mode: mode,
          flow: StageFlow.singleDifficulty,
          fixedStage: selected,
        ),
      ),
    );
  }

  void _startAllDifficulties(BuildContext context, QuizMode mode) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuizPage(
          mode: mode,
          flow: StageFlow.allDifficulties,
          fixedStage: null,
        ),
      ),
    );
  }

  Widget _modeCard(BuildContext context, {required QuizMode mode, required Color color, required IconData icon, required String title, required String subtitle}) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _startSingleDifficulty(context, mode),
              icon: const Icon(Icons.tune),
              label: const Text('난이도 하나만 플레이'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => _startAllDifficulties(context, mode),
              style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Easy → Hard 전체 플레이'),
            ),
          ],
        ),
      ),
    );
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
            colors: [Color(0xFFFF9ED2), Color(0xFFB39DDB)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  const Text('🩷 티니핑 퀴즈', style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Colors.white)),
                  const SizedBox(height: 10),
                  const Text(
                    '플레이 방식과 진행 모드를 골라주세요',
                    style: TextStyle(fontSize: 17, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  _modeCard(
                    context,
                    mode: QuizMode.unlimited,
                    color: const Color(0xFF5E35B1),
                    icon: Icons.visibility,
                    title: '일부만 보고 맞추기',
                    subtitle: '원형으로 일부만 보여주고 맞히는 모드',
                  ),
                  _modeCard(
                    context,
                    mode: QuizMode.timed,
                    color: const Color(0xFFEC407A),
                    icon: Icons.timer,
                    title: '빨리 맞추기',
                    subtitle: '시간(10/5/3초) 안에 빠르게 맞히는 모드',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final QuizMode mode;
  final StageFlow flow;
  final DifficultyStage? fixedStage;

  const QuizPage({
    super.key,
    required this.mode,
    required this.flow,
    required this.fixedStage,
  });

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
  Offset _spotlightCenterFactor = const Offset(0.5, 0.5);

  Offset _pickSpotlightCenterFactor() {
    // 배경만 보이는 경우를 줄이기 위해, 캐릭터가 주로 배치되는 중앙 영역에서만 샘플링합니다.
    // (요청사항: 공개 원형의 80% 이상이 캐릭터 영역에 오도록 하는 휴리스틱)
    final maxDist = switch (_stage) {
      DifficultyStage.easy => 0.15,
      DifficultyStage.medium => 0.12,
      DifficultyStage.hard => 0.10,
    };

    for (int i = 0; i < 40; i++) {
      final angle = _rand.nextDouble() * pi * 2;
      final dist = _rand.nextDouble() * maxDist;
      final x = 0.5 + cos(angle) * dist;
      final y = 0.5 + sin(angle) * dist;
      if (x >= 0.25 && x <= 0.75 && y >= 0.2 && y <= 0.8) {
        return Offset(x, y);
      }
    }
    return const Offset(0.5, 0.5);
  }

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
    _stage = widget.fixedStage ?? DifficultyStage.easy;
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
    _spotlightCenterFactor = _pickSpotlightCenterFactor();
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
      final isSingleFlow = widget.flow == StageFlow.singleDifficulty;
      final upcoming = isSingleFlow ? null : nextStage(_stage);
      if (upcoming == null) {
        _timer?.cancel();
        final totalQuestions = isSingleFlow ? questionsPerStage : questionsPerStage * 3;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultPage(
              score: _totalScore,
              total: totalQuestions,
              mode: widget.mode,
              flow: widget.flow,
              fixedStage: widget.fixedStage,
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

  String _modeTitle() {
    return widget.mode == QuizMode.timed ? '빨리 맞추기' : '일부만 보고 맞추기';
  }

  String _flowTitle() {
    if (widget.flow == StageFlow.singleDifficulty) {
      return '${stageLabel(widget.fixedStage!)} 단일';
    }
    return 'Easy→Hard 전체';
  }

  Future<void> _goHome() async {
    final shouldGo = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초기 화면으로 이동할까요?'),
        content: const Text('현재 진행 중인 게임은 종료됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('이동')),
        ],
      ),
    );

    if (shouldGo == true && mounted) {
      _timer?.cancel();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StartPage()),
        (route) => false,
      );
    }
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
        title: Text('티니핑 이름 맞추기 · ${_modeTitle()}'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '처음으로',
            onPressed: _goHome,
            icon: const Icon(Icons.home_rounded),
          ),
        ],
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
                            Text(widget.mode == QuizMode.timed ? '제한 시간: $_timeLeft초' : _flowTitle()),
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

                                  Widget masked(double fraction) {
                                    final radius = (minSide * fraction / 2).clamp(20.0, minSide * 2);
                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        image,
                                        IgnorePointer(
                                          child: CustomPaint(
                                            painter: SpotlightMaskPainter(
                                              center: Offset(
                                                constraints2.maxWidth * _spotlightCenterFactor.dx,
                                                constraints2.maxHeight * _spotlightCenterFactor.dy,
                                              ),
                                              radius: radius,
                                            ),
                                          ),
                                        ),
                                        if (!_answered)
                                          Positioned(
                                            top: 10,
                                            left: 0,
                                            right: 0,
                                            child: Center(
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
                                          ),
                                      ],
                                    );
                                  }

                                  if (!_answered) {
                                    return masked(baseFraction);
                                  }

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: baseFraction, end: 2.2),
                                    duration: const Duration(milliseconds: 700),
                                    curve: Curves.easeOutCubic,
                                    builder: (context, animatedFraction, _) => masked(animatedFraction),
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

class SpotlightMaskPainter extends CustomPainter {
  final Offset center;
  final double radius;

  SpotlightMaskPainter({required this.center, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final layerRect = Offset.zero & size;
    canvas.saveLayer(layerRect, Paint());

    final overlay = Paint()..color = Colors.white;
    canvas.drawRect(layerRect, overlay);

    final clearPaint = Paint()..blendMode = ui.BlendMode.clear;
    canvas.drawCircle(center, radius, clearPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SpotlightMaskPainter oldDelegate) {
    return oldDelegate.center != center || oldDelegate.radius != radius;
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
  final StageFlow flow;
  final DifficultyStage? fixedStage;

  const ResultPage({
    super.key,
    required this.score,
    required this.total,
    required this.mode,
    required this.flow,
    required this.fixedStage,
  });

  @override
  Widget build(BuildContext context) {
    final rate = score / total;
    final grade = rate >= 0.9
        ? 'S'
        : rate >= 0.75
            ? 'A'
            : rate >= 0.6
                ? 'B'
                : 'C';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7E57C2), Color(0xFFFF5DA2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎊 게임 완료! 🎊', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
                  ),
                  child: Column(
                    children: [
                      Text('최종 점수 $score / $total', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text('등급 $grade', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF6A1B9A))),
                      const SizedBox(height: 8),
                      Text('정답률 ${(rate * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 18, color: Colors.black87)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => QuizPage(mode: mode, flow: flow, fixedStage: fixedStage),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4FB0),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  icon: const Icon(Icons.replay),
                  label: const Text('같은 설정으로 다시 하기', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const StartPage()),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    minimumSize: const Size.fromHeight(50),
                  ),
                  icon: const Icon(Icons.home),
                  label: const Text('모드 선택으로 돌아가기'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
