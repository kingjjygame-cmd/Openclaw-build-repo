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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('우리 버디가 성장했어요! (${afterStage.name}) 🐾')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stage = _getGrowthStage(pet);
    final mood = _getMoodFace(pet);

    return Scaffold(
      appBar: AppBar(title: const Text('BuddyPaw'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
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
                    const Icon(Icons.pets, size: 120, color: Colors.brown),
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
