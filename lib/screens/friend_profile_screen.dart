import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FriendProfileScreen extends StatefulWidget {
  const FriendProfileScreen({super.key});
  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController();
  final List<String> _likes = [];
  final _likeInput = TextEditingController();

  void _addLike() {
    if (_likeInput.text.trim().isEmpty) return;
    setState(() {
      _likes.add(_likeInput.text.trim());
      _likeInput.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Friend details',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _birthdayCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Birthday (optional)',
                    prefixIcon: Icon(Icons.cake_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Likes & interests',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _likeInput,
                        decoration: const InputDecoration(hintText: 'e.g. board games'),
                        onSubmitted: (_) => _addLike(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _addLike,
                      ),
                    ),
                  ],
                ),
                if (_likes.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _likes
                        .map((l) => Chip(
                      label: Text(l),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _likes.remove(l)),
                    ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline, size: 18, color: AppColors.primaryDark),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Buddy only uses what you enter here. No profile scraping, ever.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.primaryDark, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ElevatedButton(
          onPressed: () {
            // TODO: POST to backend
          },
          child: const Text('Save Profile'),
        ),
      ],
    );
  }
}