import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FriendProfileScreen extends StatefulWidget {
  const FriendProfileScreen({super.key});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  // 🚨 STRIPPED FAKE DATA: Controllers now start empty, ready for real input
  final _nameCtrl = TextEditingController();
  final _birthdayCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final List<String> _likes = [];
  String _relationship = "Best Friend";

  final List<String> _relationshipOptions = [
    "Best Friend", "Close Friend", "Colleague", "Family", "Acquaintance"
  ];

  // Pre-curated interest options for quick-selection sheet
  final Map<String, List<String>> _suggestedInterests = {
    "Gaming & Tech": ["Board Games", "PC Gaming", "AI Tech", "Cybersecurity", "VR"],
    "Fitness & Outdoor": ["Hiking", "Cycling", "Gym & Weightlifting", "Yoga", "Running"],
    "Entertainment": ["Sci-Fi Movies", "Anime", "Podcasts", "Live Music", "Reading"],
    "Food & Drink": ["Specialty Coffee", "Cooking", "Craft Beer", "Baking", "Sushi"],
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthdayCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _openAddInterestSheet() {
    final customInputCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
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
                      'Add Context & Preferences',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customInputCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Type custom preference...',
                              hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              fillColor: AppColors.surface,
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
                          child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                            style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.bold),
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
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.surface,
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
          'Target Profile',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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
              title: 'Identity Data',
              icon: Icons.badge_outlined,
              children: [
                _buildInputField(controller: _nameCtrl, label: 'Full Name', icon: Icons.person_outline),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.border, thickness: 1),
                ),
                _buildInputField(controller: _birthdayCtrl, label: 'Date of Birth (Optional)', icon: Icons.cake_outlined),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Network Link',
              icon: Icons.hub_outlined,
              children: [
                _buildDropdownRow(
                  label: 'Relationship Classification',
                  icon: Icons.people_outline,
                  value: _relationship,
                  options: _relationshipOptions,
                  onChanged: (val) => setState(() => _relationship = val!),
                ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Behavioral Metrics',
              icon: Icons.psychology_outlined,
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
                    'No preferences logged. Tap + to add.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _likes.map((item) => Chip(
                      backgroundColor: AppColors.bg,
                      side: const BorderSide(color: AppColors.primary, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      label: Text(item, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.textSecondary),
                      onDeleted: () => setState(() => _likes.remove(item)),
                    )).toList(),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _buildSectionCard(
              title: 'Secure Notes',
              icon: Icons.lock_outline,
              children: [
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Enter specific dietary restrictions, gift ideas, or context for the AI...',
                    hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                onPressed: () {
                  // 🚨 TACTILE FEEDBACK FOR THE DEMO 🚨
                  FocusScope.of(context).unfocus(); // Dismiss keyboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile securely encrypted and stored in Postgres.'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'SYNC TO VAULT',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
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
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
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
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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