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

class _AnimatedDogState extends State<AnimatedDog> with TickerProviderStateMixin {
  late final AnimationController _bobController;
  late final AnimationController _tailController;
  late final AnimationController _walkController;

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _tailController = AnimationController(vsync: this, duration: const Duration(milliseconds: 380))
      ..repeat(reverse: true);
    _walkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 5600))
      ..repeat();
  }

  @override
  void dispose() {
    _bobController.dispose();
    _tailController.dispose();
    _walkController.dispose();
    super.dispose();
  }

  double _stageScale(GrowthStage s) {
    switch (s) {
      case GrowthStage.baby:
        return 0.9;
      case GrowthStage.junior:
        return 1.05;
      case GrowthStage.adult:
        return 1.2;
    }
  }

  String _face(MoodFace m) {
    switch (m) {
      case MoodFace.happy:
        return '^ᴥ^';
      case MoodFace.normal:
        return '•ᴥ•';
      case MoodFace.tired:
        return '-ᴥ-';
      case MoodFace.sad:
        return 'TᴥT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = _stageScale(widget.stage);

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        const dogWidth = 190.0;
        final maxX = math.max(0.0, trackWidth - dogWidth);

        return AnimatedBuilder(
          animation: Listenable.merge([_bobController, _tailController, _walkController]),
          builder: (context, child) {
            final t = _walkController.value;
            final bob = math.sin(_bobController.value * math.pi) * 6;
            final tailAngle = (widget.mood == MoodFace.sad ? 0.05 : 0.22) * (1 - (_tailController.value * 2 - 1).abs());

            // 0.0~0.5: left->right, 0.5~1.0: right->left (ping-pong)
            final forward = t < 0.5;
            final p = forward ? (t / 0.5) : ((1 - t) / 0.5);
            final walkX = maxX * p;

            // pseudo-3D depth: center comes closer (bigger), sides farther (smaller)
            final depth = 1.0 - (2 * (p - 0.5)).abs(); // center=1, edges=0
            final depthScale = 0.88 + (0.22 * depth);
            final yDepthOffset = (1 - depth) * 26;
            final shadowWidth = 84 + (34 * depth);
            final shadowOpacity = 0.14 + (0.16 * depth);

            return Stack(
              children: [
                Positioned(
                  left: walkX + (dogWidth / 2) - (shadowWidth / 2),
                  top: 178 + yDepthOffset,
                  child: Container(
                    width: shadowWidth,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(shadowOpacity),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned(
                  left: walkX,
                  top: 20 + yDepthOffset,
                  child: Transform.translate(
                    offset: Offset(0, -bob),
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()..scale(forward ? 1.0 : -1.0, 1.0),
                      child: Transform.scale(
                        scale: scale * depthScale,
                        child: SizedBox(
                          width: dogWidth,
                          height: 170,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                right: 24,
                                top: 92,
                                child: Transform.rotate(
                                  angle: tailAngle,
                                  alignment: Alignment.topLeft,
                                  child: Container(
                                    width: 46,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFC68642),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 84,
                                child: Container(
                                  width: 110,
                                  height: 62,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD89A5B),
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 26,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 100,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE7B27A),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      left: 18,
                                      child: Transform.rotate(
                                        angle: -0.45,
                                        child: Container(
                                          width: 24,
                                          height: 34,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFC68642),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.circular(16),
                                              bottomLeft: Radius.circular(16),
                                              bottomRight: Radius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 18,
                                      child: Transform.rotate(
                                        angle: 0.45,
                                        child: Container(
                                          width: 24,
                                          height: 34,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFC68642),
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.circular(16),
                                              bottomLeft: Radius.circular(4),
                                              bottomRight: Radius.circular(16),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 38,
                                      child: Text(
                                        _face(widget.mood),
                                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
