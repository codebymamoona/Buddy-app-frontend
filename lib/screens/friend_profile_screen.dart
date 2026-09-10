import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class FriendProfileScreen extends StatefulWidget {
  // Owner of this friend profile — required, no hardcoded fallback.
  final String userId;

  const FriendProfileScreen({super.key, required this.userId});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final List<String> _likes = [];
  String _relationship = "Best friend";
  bool _saving = false;

  final List<String> _relationshipOptions = [
    "Best friend", "Close friend", "Colleague", "Family", "Acquaintance"
  ];

  final Map<String, List<String>> _suggestedInterests = {
    "Gaming & tech": ["Board games", "PC gaming", "AI & tech", "Cybersecurity", "VR"],
    "Fitness & outdoor": ["Hiking", "Cycling", "Gym & weightlifting", "Yoga", "Running"],
    "Entertainment": ["Sci-fi movies", "Anime", "Podcasts", "Live music", "Reading"],
    "Food & drink": ["Specialty coffee", "Cooking", "Craft beer", "Baking", "Sushi"],
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthdayCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // TODO: this endpoint and payload shape are a guess, matching the pattern
  // of the other screens' backend calls — confirm the real route and field
  // names in your Spring Boot controller before relying on this.
  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a name before saving.'), backgroundColor: AppColors.danger),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8080/api/friends'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "ownerId": widget.userId,
          "name": name,
          "birthday": _birthdayCtrl.text.trim(),
          "relationship": _relationship,
          "interests": _likes,
          "notes": _notesCtrl.text.trim(),
        }),
      );

      if (!mounted) return;
      setState(() => _saving = false);
      FocusScope.of(context).unfocus();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't save. Try again."),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error: cannot reach the server.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openAddInterestSheet() {
    final customInputCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Add an interest',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customInputCtrl,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Type something they like...',
                              hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              fillColor: AppColors.inputBg,
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (customInputCtrl.text.trim().isNotEmpty) {
                              setState(() => _likes.add(customInputCtrl.text.trim()));
                              customInputCtrl.clear();
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ..._suggestedInterests.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: entry.value.map((item) {
                              final isSelected = _likes.contains(item);
                              return FilterChip(
                                selected: isSelected,
                                label: Text(item),
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                ),
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.inputBg,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                  ),
                                ),
                                onSelected: (bool selected) {
                                  setSheetState(() {
                                    setState(() {
                                      if (selected) {
                                        _likes.add(item);
                                      } else {
                                        _likes.remove(item);
                                      }
                                    });
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Friend profile',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2.5),
                    ),
                    child: const CircleAvatar(
                      backgroundColor: AppColors.surface,
                      child: Icon(Icons.person_rounded, size: 52, color: AppColors.textSecondary),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionCard(
              title: 'About them',
              icon: Icons.badge_outlined,
              children: [
                _buildInputField(controller: _nameCtrl, label: 'Full name', icon: Icons.person_outline),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.border, thickness: 1),
                ),
                _buildInputField(controller: _birthdayCtrl, label: 'Birthday (optional)', icon: Icons.cake_outlined),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Relationship',
              icon: Icons.people_outline,
              children: [
                _buildDropdownRow(
                  label: 'How do you know them?',
                  icon: Icons.people_outline,
                  value: _relationship,
                  options: _relationshipOptions,
                  onChanged: (val) => setState(() => _relationship = val!),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Interests',
              icon: Icons.favorite_border_rounded,
              actionWidget: GestureDetector(
                onTap: _openAddInterestSheet,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ),
              children: [
                if (_likes.isEmpty)
                  const Text(
                    'Nothing added yet. Tap + to add an interest.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _likes.map((item) => Chip(
                      backgroundColor: AppColors.inputBg,
                      side: const BorderSide(color: AppColors.primary, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      label: Text(item, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                      deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
                      onDeleted: () => setState(() => _likes.remove(item)),
                    )).toList(),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Notes for Buddy',
              icon: Icons.sticky_note_2_outlined,
              children: [
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Dietary restrictions, gift ideas, anything else worth remembering...',
                    hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _saving
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text(
                  'Save profile',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children, Widget? actionWidget}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
                ],
              ),
              if (actionWidget != null) actionWidget,
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({required TextEditingController controller, required String label, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownRow({required String label, required IconData icon, required String value, required List<String> options, required void Function(String?) onChanged}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: AppColors.surface,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                items: options.map((String opt) => DropdownMenuItem<String>(value: opt, child: Text(opt))).toList(),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}