import 'dart:math' as math;
import 'package:flutter/material.dart';

void main() {
  // Layout-safe build (status/navigation bar overlap fix)
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
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
    bond: 5,
    hunger: 40,
    mood: 60,
    energy: 70,
    care7d: 0.5,
    care14d: 0.4,
  );

  GrowthStage _getGrowthStage(PetState s) {
    if (s.bond >= 50 && s.care14d >= 0.7) return GrowthStage.adult;
    if (s.bond >= 20 && s.care7d >= 0.6) return GrowthStage.junior;
    return GrowthStage.baby;
  }

  MoodFace _getMoodFace(PetState s) {
    if (s.mood >= 75 && s.energy >= 40 && s.hunger <= 50) return MoodFace.happy;
    if (s.mood < 35 || s.energy < 25 || s.hunger > 80) return MoodFace.sad;
    if (s.energy < 40 || s.hunger > 65) return MoodFace.tired;
    return MoodFace.normal;
  }

  void _applyAction(PetAction action) {
    final beforeStage = _getGrowthStage(pet);

    setState(() {
      switch (action) {
        case PetAction.feed:
          pet.hunger = (pet.hunger - 25).clamp(0, 100);
          pet.mood = (pet.mood + 5).clamp(0, 100);
          pet.bond = (pet.bond + 2).clamp(0, 100);
          break;
        case PetAction.walk:
          pet.energy = (pet.energy - 15).clamp(0, 100);
          pet.mood = (pet.mood + 15).clamp(0, 100);
          pet.bond = (pet.bond + 5).clamp(0, 100);
          break;
        case PetAction.play:
          pet.energy = (pet.energy - 10).clamp(0, 100);
          pet.mood = (pet.mood + 12).clamp(0, 100);
          pet.bond = (pet.bond + 4).clamp(0, 100);
          break;
        case PetAction.rest:
          pet.energy = (pet.energy + 20).clamp(0, 100);
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
          content: Text('우리 버디가 성장했어요! (${afterStage.name}) 🐾'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(
            12,
            0,
            12,
            20 + MediaQuery.of(context).padding.bottom,
          ),
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
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: AnimatedDog(stage: stage, mood: mood),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stage: ${stage.name} | Mood: ${mood.name}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
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

class _IsoEntity {
  final Offset world;
  final double size;
  final Color color;

  const _IsoEntity(this.world, this.size, this.color);
}

class _AnimatedDogState extends State<AnimatedDog> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final List<Offset> _path = const [
    Offset(1.2, 2.2),
    Offset(4.6, 2.8),
    Offset(6.1, 5.2),
    Offset(3.4, 6.4),
    Offset(1.4, 4.8),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 6400))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _stageScale(GrowthStage s) => switch (s) {
        GrowthStage.baby => 0.88,
        GrowthStage.junior => 1.0,
        GrowthStage.adult => 1.14,
      };

  String _face(MoodFace m) => switch (m) {
        MoodFace.happy => '^ᴥ^',
        MoodFace.normal => '•ᴥ•',
        MoodFace.tired => '-ᴥ-',
        MoodFace.sad => 'TᴥT',
      };

  Offset _lerpPath(double t) {
    final seg = t * _path.length;
    final i = seg.floor() % _path.length;
    final j = (i + 1) % _path.length;
    final local = seg - seg.floor();
    return Offset.lerp(_path[i], _path[j], Curves.easeInOut.transform(local))!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const tileW = 56.0;
        const tileH = 28.0;
        final origin = Offset(c.maxWidth / 2, 54);

        Offset isoToScreen(Offset w) => Offset(
              origin.dx + (w.dx - w.dy) * (tileW / 2),
              origin.dy + (w.dx + w.dy) * (tileH / 2),
            );

        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value;
            final dogWorld = _lerpPath(t);
            final prevWorld = _lerpPath((t - 0.01) % 1.0);
            final facingRight = (dogWorld.dx - prevWorld.dx) >= 0;
            final dogScreen = isoToScreen(dogWorld);
            final step = math.sin(t * math.pi * 16);
            final stageScale = _stageScale(widget.stage);

            final props = <_IsoEntity>[
              const _IsoEntity(Offset(5.8, 1.2), 34, Color(0xFF8D6E63)),
              const _IsoEntity(Offset(2.0, 5.8), 30, Color(0xFF6D4C41)),
              const _IsoEntity(Offset(6.7, 4.9), 26, Color(0xFF795548)),
            ];

            final sortedProps = [...props]..sort((a, b) => a.world.dy.compareTo(b.world.dy));

            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _IsoGroundPainter(tileW: tileW, tileH: tileH, origin: origin),
                  ),
                ),
                ...sortedProps.map((e) {
                  final p = isoToScreen(e.world);
                  return Positioned(
                    left: p.dx - e.size / 2,
                    top: p.dy - e.size,
                    child: Container(
                      width: e.size,
                      height: e.size,
                      decoration: BoxDecoration(color: e.color, borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }),
                Positioned(
                  left: dogScreen.dx - (58 * stageScale),
                  top: dogScreen.dy - (94 * stageScale),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(facingRight ? 1.0 : -1.0, 1.0),
                    child: Transform.scale(
                      scale: stageScale,
                      child: SizedBox(
                        width: 116,
                        height: 112,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 18,
                              top: 86,
                              child: Container(
                                width: 78,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 48,
                              top: 60,
                              child: Transform.translate(
                                offset: Offset(0, step * 3),
                                child: _leg(),
                              ),
                            ),
                            Positioned(
                              left: 66,
                              top: 60,
                              child: Transform.translate(
                                offset: Offset(0, -step * 3),
                                child: _leg(),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              top: 36,
                              child: Container(
                                width: 74,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD89A5B),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 73,
                              top: 46,
                              child: Transform.rotate(
                                angle: math.sin(t * math.pi * 8) * 0.28,
                                child: Container(
                                  width: 30,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC68642),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              top: 2,
                              child: Container(
                                width: 72,
                                height: 66,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE7B27A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              top: 23,
                              child: Text(_face(widget.mood), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ],
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

  Widget _leg() => Container(
        width: 8,
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFFC68642),
          borderRadius: BorderRadius.circular(8),
        ),
      );
}

class _IsoGroundPainter extends CustomPainter {
  final double tileW;
  final double tileH;
  final Offset origin;

  _IsoGroundPainter({required this.tileW, required this.tileH, required this.origin});

  @override
  void paint(Canvas canvas, Size size) {
    final light = Paint()..color = const Color(0xFFBCAAA4);
    final dark = Paint()..color = const Color(0xFFA1887F);

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
        canvas.drawPath(diamond(c), (x + y).isEven ? light : dark);
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
