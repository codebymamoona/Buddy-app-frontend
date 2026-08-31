import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FriendProfileScreen extends StatefulWidget {
  const FriendProfileScreen({super.key});

  @override
  State<FriendProfileScreen> createState() => _FriendProfileScreenState();
}

class _FriendProfileScreenState extends State<FriendProfileScreen> {
  final _nameCtrl = TextEditingController(text: "Alex Johnson");
  final _birthdayCtrl = TextEditingController(text: "14 Oct 1998");
  final _notesCtrl = TextEditingController(text: "Type here");

  final List<String> _likes = ["Board Games", "AI Tech", "Sci-Fi Movies"];
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
      backgroundColor: const Color(0xFF181818),
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
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Add Interests & Passions',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Custom Input Field
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: customInputCtrl,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Type custom interest...',
                              hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                              fillColor: const Color(0xFF262626),
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
                            backgroundColor: const Color(0xFFE50914),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Categorized Suggestions
                    ..._suggestedInterests.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(color: Color(0xFFE50914), fontSize: 13, fontWeight: FontWeight.bold),
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
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                selectedColor: const Color(0xFFE50914),
                                backgroundColor: const Color(0xFF262626),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFFE50914) : Colors.transparent,
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
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Friend Profile',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header with Glowing Avatar
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE50914), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE50914).withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      backgroundColor: Color(0xFF1E1E1E),
                      child: Icon(Icons.person_rounded, size: 52, color: Colors.white70),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE50914),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Card 1: Basic Information
            _buildSectionCard(
              title: 'Basic Info',
              icon: Icons.person_outline,
              children: [
                _buildInputField(
                  controller: _nameCtrl,
                  label: 'Name',
                  icon: Icons.badge_outlined,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: Color(0xFF2A2A2A), thickness: 1),
                ),
                _buildInputField(
                  controller: _birthdayCtrl,
                  label: 'Birthday (optional)',
                  icon: Icons.cake_outlined,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Card 2: Relationship & Communication Preferences
            _buildSectionCard(
              title: 'Relationship ',
              icon: Icons.people_outline,
              children: [
                _buildDropdownRow(
                  label: 'Relationship',
                  icon: Icons.favorite_border,
                  value: _relationship,
                  options: _relationshipOptions,
                  onChanged: (val) => setState(() => _relationship = val!),
                ),

              ],
            ),
            const SizedBox(height: 16),

            // Card 3: Likes & Interests (Interactive Bottom Sheet Trigger)
            _buildSectionCard(
              title: 'Likes & Interests',
              icon: Icons.local_fire_department_outlined,
              actionWidget: GestureDetector(
                onTap: _openAddInterestSheet,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE50914),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ),
              children: [
                if (_likes.isEmpty)
                  const Text(
                    'No interests added yet. Tap + to add.',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _likes
                        .map(
                          (item) => Chip(
                        backgroundColor: const Color(0xFF280B0D),
                        side: const BorderSide(color: Color(0xFFE50914), width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        label: Text(
                          item,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        deleteIcon: const Icon(Icons.close, size: 14, color: Colors.white70),
                        onDeleted: () => setState(() => _likes.remove(item)),
                      ),
                    )
                        .toList(),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Card 4: Gift Ideas & Personal Notes
            _buildSectionCard(
              title: 'Gift Ideas & Notes',
              icon: Icons.card_giftcard_outlined,
              children: [
                TextField(
                  controller: _notesCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'Gift ideas, favorite foods, key context...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Privacy Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE50914).withValues(alpha: 0.25)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined, color: Color(0xFFE50914), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Buddy only uses what you enter here. No profile scraping, ever.',
                      style: TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Save Action CTA
            Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE50914), Color(0xFF8B0000)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE50914).withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  // TODO: POST to Spring Boot Backend
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text(
                  'SAVE PROFILE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Generic Reusable Card Frame
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? actionWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2B2B2B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: const Color(0xFFE50914), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

  // Text Input Row Component
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  // Dropdown Selection Row Component
  Widget _buildDropdownRow({
    required String label,
    required IconData icon,
    required String value,
    required List<String> options,
    required void Function(String?) onChanged,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              DropdownButton<String>(
                value: value,
                isExpanded: true,
                dropdownColor: const Color(0xFF262626),
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFE50914)),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                items: options.map((String opt) {
                  return DropdownMenuItem<String>(
                    value: opt,
                    child: Text(opt),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}