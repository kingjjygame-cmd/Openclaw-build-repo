import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  runApp(const BuddyPawApp());
}

class BuddyPawApp extends StatelessWidget {
  const BuddyPawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BuddyPaw',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7A4B28)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

enum GrowthStage { baby, junior, adult }
enum MoodFace { happy, normal, tired, sad }
enum PetAction { feed, walk, play, rest }

class PetState {
  int bond;
  int hunger;
  int mood;
  int energy;
  double care7d;
  double care14d;

  PetState({
    required this.bond,
    required this.hunger,
    required this.mood,
    required this.energy,
    required this.care7d,
    required this.care14d,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PetState pet = PetState(
    bond: 12,
    hunger: 38,
    mood: 68,
    energy: 74,
    care7d: 0.58,
    care14d: 0.45,
  );

  GrowthStage _getGrowthStage(PetState s) {
    if (s.bond >= 50 && s.care14d >= 0.7) return GrowthStage.adult;
    if (s.bond >= 20 && s.care7d >= 0.6) return GrowthStage.junior;
    return GrowthStage.baby;
  }

  MoodFace _getMoodFace(PetState s) {
    if (s.mood >= 76 && s.energy >= 40 && s.hunger <= 55) return MoodFace.happy;
    if (s.mood < 35 || s.energy < 25 || s.hunger > 82) return MoodFace.sad;
    if (s.energy < 40 || s.hunger > 66) return MoodFace.tired;
    return MoodFace.normal;
  }

  void _applyAction(PetAction action) {
    final beforeStage = _getGrowthStage(pet);

    setState(() {
      switch (action) {
        case PetAction.feed:
          pet.hunger = (pet.hunger - 24).clamp(0, 100);
          pet.mood = (pet.mood + 6).clamp(0, 100);
          pet.bond = (pet.bond + 2).clamp(0, 100);
          break;
        case PetAction.walk:
          pet.energy = (pet.energy - 15).clamp(0, 100);
          pet.mood = (pet.mood + 14).clamp(0, 100);
          pet.bond = (pet.bond + 5).clamp(0, 100);
          break;
        case PetAction.play:
          pet.energy = (pet.energy - 10).clamp(0, 100);
          pet.mood = (pet.mood + 12).clamp(0, 100);
          pet.bond = (pet.bond + 4).clamp(0, 100);
          break;
        case PetAction.rest:
          pet.energy = (pet.energy + 19).clamp(0, 100);
          pet.mood = (pet.mood + 3).clamp(0, 100);
          break;
      }
      pet.care7d = (pet.care7d + 0.03).clamp(0.0, 1.0);
      pet.care14d = (pet.care14d + 0.02).clamp(0.0, 1.0);
    });

    final afterStage = _getGrowthStage(pet);
    if (afterStage != beforeStage && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('우리 버디가 성장했어요! (${afterStage.name})'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(12, 0, 12, 20 + MediaQuery.of(context).padding.bottom),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = _getGrowthStage(pet);
    final mood = _getMoodFace(pet);

    return Scaffold(
      appBar: AppBar(title: const Text('BuddyPaw'), centerTitle: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF9F2E8), Color(0xFFECDCC7)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 230,
                        child: AnimatedDog(stage: stage, mood: mood),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '성장 단계: ${stage.name}   ·   현재 기분: ${mood.name}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _StatBar(label: '배고픔', value: pet.hunger, color: Colors.redAccent),
              _StatBar(label: '기분', value: pet.mood, color: Colors.pinkAccent),
              _StatBar(label: '에너지', value: pet.energy, color: Colors.blueAccent),
              _StatBar(label: '유대감', value: pet.bond, color: Colors.green),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton(onPressed: () => _applyAction(PetAction.feed), child: const Text('밥주기')),
                  FilledButton(onPressed: () => _applyAction(PetAction.walk), child: const Text('산책')),
                  FilledButton(onPressed: () => _applyAction(PetAction.play), child: const Text('놀아주기')),
                  FilledButton(onPressed: () => _applyAction(PetAction.rest), child: const Text('쉬기')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AnimatedDog extends StatefulWidget {
  final GrowthStage stage;
  final MoodFace mood;

  const AnimatedDog({super.key, required this.stage, required this.mood});

  @override
  State<AnimatedDog> createState() => _AnimatedDogState();
}

class _AnimatedDogState extends State<AnimatedDog> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<Offset> _path = const [
    Offset(1.2, 2.4),
    Offset(4.7, 2.1),
    Offset(6.2, 4.9),
    Offset(3.7, 6.7),
    Offset(1.1, 5.0),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 6200))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _stageScale(GrowthStage s) => switch (s) {
        GrowthStage.baby => 0.88,
        GrowthStage.junior => 1.0,
        GrowthStage.adult => 1.15,
      };

  Offset _pointAt(double t) {
    final seg = t * _path.length;
    final i = seg.floor() % _path.length;
    final j = (i + 1) % _path.length;
    final localT = Curves.easeInOut.transform(seg - seg.floor());
    return Offset.lerp(_path[i], _path[j], localT)!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        const tileW = 58.0;
        const tileH = 29.0;
        final origin = Offset(constraints.maxWidth / 2, 48);

        Offset isoToScreen(Offset w) {
          return Offset(
            origin.dx + (w.dx - w.dy) * (tileW / 2),
            origin.dy + (w.dx + w.dy) * (tileH / 2),
          );
        }

        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value;
            final now = _pointAt(t);
            final prev = _pointAt((t - 0.01) % 1.0);
            final dir = now - prev;
            final facingRight = dir.dx >= 0;
            final heading = math.atan2(dir.dy, dir.dx);

            final dogScreen = isoToScreen(now);
            final stageScale = _stageScale(widget.stage);
            final gait = math.sin(t * math.pi * 14);
            final breath = math.sin(t * math.pi * 2) * 1.2;

            final props = [
              _IsoProp(world: const Offset(5.9, 1.2), type: _PropType.tree),
              _IsoProp(world: const Offset(2.0, 5.8), type: _PropType.stone),
              _IsoProp(world: const Offset(6.6, 5.6), type: _PropType.tree),
            ]..sort((a, b) => a.world.dy.compareTo(b.world.dy));

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _IsoGroundPainter(tileW: tileW, tileH: tileH, origin: origin),
                  ),
                ),
                ...props.map((p) {
                  final s = isoToScreen(p.world);
                  return Positioned(
                    left: s.dx - 18,
                    top: s.dy - 38,
                    child: CustomPaint(
                      size: const Size(36, 40),
                      painter: _PropPainter(type: p.type),
                    ),
                  );
                }),
                Positioned(
                  left: dogScreen.dx - 72 * stageScale,
                  top: dogScreen.dy - 105 * stageScale,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(facingRight ? 1.0 : -1.0, 1.0),
                    child: Transform.scale(
                      scale: stageScale,
                      child: Transform.translate(
                        offset: Offset(0, breath),
                        child: CustomPaint(
                          size: const Size(146, 122),
                          painter: _DogPainter(
                            mood: widget.mood,
                            gait: gait,
                            heading: heading,
                            tail: math.sin(t * math.pi * 8) * 0.24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _IsoProp {
  final Offset world;
  final _PropType type;

  _IsoProp({required this.world, required this.type});
}

enum _PropType { tree, stone }

class _PropPainter extends CustomPainter {
  final _PropType type;

  _PropPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    if (type == _PropType.tree) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(14, 20, 8, 18), const Radius.circular(3)),
        Paint()..color = const Color(0xFF6D4C41),
      );
      canvas.drawCircle(const Offset(18, 12), 12, Paint()..color = const Color(0xFF4E7E43));
      canvas.drawCircle(const Offset(11, 15), 7, Paint()..color = const Color(0xFF5D8E4E));
      canvas.drawCircle(const Offset(25, 15), 7, Paint()..color = const Color(0xFF5D8E4E));
    } else {
      final rock = Path()
        ..moveTo(6, 30)
        ..lineTo(13, 19)
        ..lineTo(26, 18)
        ..lineTo(31, 28)
        ..lineTo(22, 35)
        ..lineTo(10, 35)
        ..close();
      canvas.drawPath(rock, Paint()..color = const Color(0xFF8D8D8D));
      canvas.drawPath(
        rock,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = const Color(0xFF6E6E6E),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PropPainter oldDelegate) => oldDelegate.type != type;
}

class _DogPainter extends CustomPainter {
  final MoodFace mood;
  final double gait;
  final double heading;
  final double tail;

  _DogPainter({required this.mood, required this.gait, required this.heading, required this.tail});

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = const Color(0xFFAD6C3B);
    final light = Paint()..color = const Color(0xFFD39A62);
    final dark = Paint()..color = const Color(0xFF3A2618);

    final shadow = RRect.fromRectAndRadius(const Rect.fromLTWH(30, 104, 84, 10), const Radius.circular(99));
    canvas.drawRRect(shadow, Paint()..color = Colors.black.withOpacity(0.24));

    void leg(double x, double phase, bool front) {
      final lift = math.sin(phase) * 3.4;
      final y = front ? 72.0 : 76.0;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y + lift, 11, 28), const Radius.circular(7)),
        body,
      );
      canvas.drawCircle(Offset(x + 5.5, 103 + lift), 4.2, dark);
    }

    leg(58, gait, true);
    leg(74, gait + math.pi, true);
    leg(90, gait + math.pi, false);
    leg(105, gait, false);

    final torso = RRect.fromRectAndRadius(const Rect.fromLTWH(44, 46, 76, 43), const Radius.circular(22));
    canvas.drawRRect(torso, body);
    canvas.drawOval(const Rect.fromLTWH(52, 58, 44, 24), light);

    final shoulder = Path()
      ..moveTo(73, 47)
      ..quadraticBezierTo(88, 37, 105, 41)
      ..lineTo(106, 58)
      ..lineTo(78, 58)
      ..close();
    canvas.drawPath(shoulder, Paint()..color = const Color(0xFF9B5F34));

    canvas.save();
    canvas.translate(118, 66);
    canvas.rotate(tail);
    final tailPath = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(18, -6, 28, -2)
      ..quadraticBezierTo(22, 6, 0, 6)
      ..close();
    canvas.drawPath(tailPath, body);
    canvas.restore();

    final head = Path()
      ..moveTo(20, 42)
      ..quadraticBezierTo(20, 18, 44, 14)
      ..quadraticBezierTo(70, 14, 75, 38)
      ..quadraticBezierTo(76, 61, 52, 66)
      ..quadraticBezierTo(28, 68, 20, 52)
      ..close();
    canvas.drawPath(head, light);

    final ear1 = Path()
      ..moveTo(34, 24)
      ..lineTo(30, 2)
      ..lineTo(46, 18)
      ..close();
    final ear2 = Path()
      ..moveTo(60, 25)
      ..lineTo(56, 5)
      ..lineTo(70, 21)
      ..close();
    canvas.drawPath(ear1, body);
    canvas.drawPath(ear2, body);

    final muzzle = RRect.fromRectAndRadius(const Rect.fromLTWH(40, 40, 22, 16), const Radius.circular(8));
    canvas.drawRRect(muzzle, Paint()..color = const Color(0xFFE9B98A));

    canvas.drawCircle(const Offset(44, 34), 3.4, dark);
    canvas.drawCircle(const Offset(58, 34), 3.4, dark);
    canvas.drawCircle(const Offset(51, 44), 3.5, Paint()..color = const Color(0xFF1E1712));

    final mouth = Path();
    switch (mood) {
      case MoodFace.happy:
        mouth
          ..moveTo(44, 50)
          ..quadraticBezierTo(51, 56, 59, 50);
        break;
      case MoodFace.sad:
        mouth
          ..moveTo(44, 54)
          ..quadraticBezierTo(51, 49, 59, 54);
        break;
      case MoodFace.tired:
        mouth
          ..moveTo(44, 52)
          ..lineTo(59, 52);
        break;
      case MoodFace.normal:
        mouth
          ..moveTo(44, 51)
          ..quadraticBezierTo(51, 53, 59, 51);
        break;
    }
    canvas.drawPath(
      mouth,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = dark.color,
    );

    final highlight = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0x55FFFFFF), Color(0x00FFFFFF)],
      ).createShader(const Rect.fromLTWH(24, 18, 96, 72));
    canvas.drawOval(const Rect.fromLTWH(34, 32, 74, 34), highlight);

    final collar = RRect.fromRectAndRadius(const Rect.fromLTWH(40, 63, 38, 8), const Radius.circular(4));
    canvas.drawRRect(collar, Paint()..color = const Color(0xFF2E7D32));
    canvas.drawCircle(const Offset(79, 67), 3.2, Paint()..color = const Color(0xFFFFD54F));

    final turnShade = (math.sin(heading) * 0.5 + 0.5) * 0.08;
    if (turnShade > 0.01) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(44, 46, 76, 43), const Radius.circular(22)),
        Paint()..color = Colors.black.withOpacity(turnShade),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DogPainter oldDelegate) {
    return oldDelegate.gait != gait || oldDelegate.tail != tail || oldDelegate.heading != heading || oldDelegate.mood != mood;
  }
}

class _IsoGroundPainter extends CustomPainter {
  final double tileW;
  final double tileH;
  final Offset origin;

  _IsoGroundPainter({required this.tileW, required this.tileH, required this.origin});

  @override
  void paint(Canvas canvas, Size size) {
    final tileA = Paint()..color = const Color(0xFFD2C2A9);
    final tileB = Paint()..color = const Color(0xFFC5B396);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..color = const Color(0x556E5B47);

    Path diamond(Offset c) => Path()
      ..moveTo(c.dx, c.dy - tileH / 2)
      ..lineTo(c.dx + tileW / 2, c.dy)
      ..lineTo(c.dx, c.dy + tileH / 2)
      ..lineTo(c.dx - tileW / 2, c.dy)
      ..close();

    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final c = Offset(
          origin.dx + (x - y) * (tileW / 2),
          origin.dy + (x + y) * (tileH / 2),
        );
        final p = diamond(c);
        canvas.drawPath(p, (x + y).isEven ? tileA : tileB);
        canvas.drawPath(p, stroke);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IsoGroundPainter oldDelegate) => false;
}

class _StatBar extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatBar({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: v / 100,
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
              color: color,
              backgroundColor: color.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 36, child: Text('$value')),
        ],
      ),
    );
  }
}
