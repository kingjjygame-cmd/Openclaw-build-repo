import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() => runApp(const TinipingGameApp());

class TinipingGameApp extends StatelessWidget {
  const TinipingGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '티니핑 월드',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF66A6)),
      ),
      home: const TinipingGameScreen(),
    );
  }
}

class Tiniping {
  final String name;
  final Color color;
  final String emoji;

  const Tiniping(this.name, this.color, this.emoji);
}

class TinipingGameScreen extends StatefulWidget {
  const TinipingGameScreen({super.key});

  @override
  State<TinipingGameScreen> createState() => _TinipingGameScreenState();
}

class _TinipingGameScreenState extends State<TinipingGameScreen>
    with SingleTickerProviderStateMixin {
  final List<Tiniping> pings = const [
    Tiniping('하츄핑', Color(0xFFFF8FB8), '💖'),
    Tiniping('차밍핑', Color(0xFFFFB3D1), '✨'),
    Tiniping('깜빡핑', Color(0xFF9D8CFF), '🌙'),
    Tiniping('반짝핑', Color(0xFFFFD166), '⭐'),
  ];

  int selected = 0;
  int score = 0;
  int bestScore = 0;
  int hearts = 3;
  bool playing = false;

  late final AnimationController _controller;
  final math.Random _random = math.Random();

  double itemX = 0.5;
  double itemY = -0.15;
  double speed = 0.008;
  bool isGolden = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 16))
      ..addListener(_tick)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      playing = true;
      score = 0;
      hearts = 3;
      _spawnItem();
    });
  }

  void _spawnItem() {
    itemX = _random.nextDouble() * 0.8 + 0.1;
    itemY = -0.15;
    isGolden = _random.nextDouble() < 0.14;
    speed = 0.007 + (_random.nextDouble() * 0.004) + (score * 0.00006);
  }

  void _tick() {
    if (!playing) return;
    setState(() {
      itemY += speed;
      if (itemY > 1.15) {
        hearts -= 1;
        if (hearts <= 0) {
          playing = false;
          bestScore = math.max(bestScore, score);
        }
        _spawnItem();
      }
    });
  }

  void _tapItem() {
    if (!playing) return;
    setState(() {
      score += isGolden ? 5 : 1;
      if (score % 10 == 0 && hearts < 5) hearts += 1;
      _spawnItem();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ping = pings[selected];

    return Scaffold(
      appBar: AppBar(
        title: const Text('티니핑 월드'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              _buildTopPanel(ping),
              const SizedBox(height: 10),
              _buildCharacterPicker(),
              const SizedBox(height: 10),
              Expanded(child: _buildGameField(ping)),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _startGame,
                  icon: Icon(playing ? Icons.refresh : Icons.play_arrow),
                  label: Text(playing ? '다시 시작' : '게임 시작'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopPanel(Tiniping ping) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ping.color.withOpacity(0.22),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: ping.color,
            child: Text(ping.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${ping.name}와 하트를 모아 보세요',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('점수 $score', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('최고 $bestScore'),
              Text('목숨 $hearts'),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCharacterPicker() {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final ping = pings[i];
          final active = i == selected;
          return ChoiceChip(
            label: Text('${ping.emoji} ${ping.name}'),
            selected: active,
            onSelected: (_) => setState(() => selected = i),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: pings.length,
      ),
    );
  }

  Widget _buildGameField(Tiniping ping) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ping.color.withOpacity(0.35),
            const Color(0xFFFFF2FA),
          ],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final px = w * itemX;
          final py = h * itemY;

          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: h * 0.23,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0F0),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.8), width: 2)),
                  ),
                ),
              ),
              Positioned(
                left: w * 0.5 - 44,
                bottom: h * 0.06,
                child: _heroAvatar(ping),
              ),
              Positioned(
                left: px - 24,
                top: py,
                child: GestureDetector(
                  onTap: _tapItem,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: isGolden ? 52 : 48,
                    height: isGolden ? 52 : 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isGolden ? const Color(0xFFFFD54F) : const Color(0xFFFF6FAE),
                      boxShadow: [
                        BoxShadow(
                          color: (isGolden ? Colors.amber : Colors.pink).withOpacity(0.45),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(isGolden ? '✨' : '💗', style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ),
              ),
              if (!playing)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.86),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      hearts <= 0 ? '게임 종료\n다시 시작해 주세요' : '시작 버튼을 눌러 플레이해 주세요',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _heroAvatar(Tiniping ping) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ping.color,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10),
        ],
      ),
      child: Center(
        child: Text(
          ping.emoji,
          style: const TextStyle(fontSize: 38),
        ),
      ),
    );
  }
}
