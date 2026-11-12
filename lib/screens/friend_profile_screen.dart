import 'package:flutter/material.dart';
import '../models/friend_profile.dart';
import '../services/api_service.dart';
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
  final ApiService _api = ApiService();

  static const int _maxLikes = 3;
  static const int _maxLikeLen = 40;

  final List<String> _likes = [];
  String _relationship = "Best friend";
  String _birthdayIso = ''; // yyyy-MM-dd, '' when not set
  bool _saving = false;

  List<FriendProfile> _saved = [];
  bool _loadingSaved = true;
  String? _loadError;
  String? _editingName; // non-null while editing an existing contact

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
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    setState(() {
      _loadingSaved = true;
      _loadError = null;
    });
    try {
      final raw = await _api.getFriends();
      final list = raw
          .map((e) => FriendProfile.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      if (!mounted) return;
      setState(() {
        _saved = list;
        _loadingSaved = false;
      });
    } catch (e) {
      debugPrint('LOAD FRIENDS FAILED: $e');
      if (!mounted) return;
      setState(() {
        _loadingSaved = false;
        _loadError = 'Could not load your saved people. Check your connection and retry.';
      });
    }
  }

  void _toast(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetForm() {
    _nameCtrl.clear();
    _notesCtrl.clear();
    _birthdayCtrl.clear();
    _birthdayIso = '';
    _likes.clear();
    _relationship = _relationshipOptions.first;
    _editingName = null;
  }

  void _startEdit(FriendProfile f) {
    setState(() {
      _editingName = f.name;
      _nameCtrl.text = f.name;
      _notesCtrl.text = f.notes;
      _birthdayIso = f.birthday;
      _birthdayCtrl.text = f.birthday;
      _likes
        ..clear()
        ..addAll(f.likes.take(_maxLikes));
      _relationship = _relationshipOptions.contains(f.relationship)
          ? f.relationship
          : _relationshipOptions.first;
    });
  }

  Future<void> _confirmDelete(FriendProfile f) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete ${f.name}?', style: const TextStyle(color: AppColors.textPrimary)),
        content: const Text('This removes their profile and likes. It cannot be undone.',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (yes != true) return;
    try {
      final result = await _api.deleteFriend(f.name);
      if (!mounted) return;
      if (result.ok) {
        if (_editingName == f.name) setState(_resetForm);
        _toast('${f.name} deleted.', ok: true);
        _loadSaved();
      } else {
        _toast(result.message);
      }
    } catch (e) {
      if (mounted) _toast('Could not delete. Try again.');
    }
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    DateTime initial = DateTime(now.year - 20, now.month, now.day);
    if (_birthdayIso.isNotEmpty) {
      initial = DateTime.tryParse(_birthdayIso) ?? initial;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked == null) return;
    final iso =
        '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() {
      _birthdayIso = iso;
      _birthdayCtrl.text = iso;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthdayCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _toast('Add a name before saving.');
      return;
    }
    if (name.length > 60) {
      _toast('Name must be at most 60 characters.');
      return;
    }
    if (_likes.length > _maxLikes) {
      _toast('At most $_maxLikes interests.');
      return;
    }

    setState(() => _saving = true);
    try {
      // No ownerId in the body: the server takes the owner from the verified token.
      final result = await _api.saveFriendProfile({
        "name": name,
        "birthday": _birthdayIso,
        "relationship": _relationship,
        "interests": _likes,
        "notes": _notesCtrl.text.trim(),
      });

      if (!mounted) return;
      setState(() => _saving = false);
      FocusScope.of(context).unfocus();

      if (result.ok) {
        // Renaming = new contact on the server (name is the key): remove the old one.
        final old = _editingName;
        if (old != null && old.toLowerCase() != name.toLowerCase()) {
          try {
            await _api.deleteFriend(old);
          } catch (_) {}
        }
        if (!mounted) return;
        setState(_resetForm);
        _toast('Profile saved.', ok: true);
        _loadSaved();
      } else {
        _toast(result.message.replaceFirst('ERROR: ', ''));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _toast('Could not save. Check your connection and try again.');
    }
  }

  void _openAddInterestSheet() {
    final customInputCtrl = TextEditingController();
    String? sheetError;

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
                            final text = customInputCtrl.text.trim();
                            if (text.isEmpty) return;
                            if (text.length > _maxLikeLen) {
                              setSheetState(() => sheetError = 'Keep it under $_maxLikeLen characters.');
                              return;
                            }
                            if (_likes.length >= _maxLikes) {
                              setSheetState(() => sheetError = 'Maximum $_maxLikes interests. Remove one first.');
                              return;
                            }
                            if (_likes.any((l) => l.toLowerCase() == text.toLowerCase())) {
                              setSheetState(() => sheetError = 'Already added.');
                              return;
                            }
                            setState(() => _likes.add(text));
                            Navigator.pop(context);
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
                    if (sheetError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(sheetError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                      ),
                    const SizedBox(height: 8),
                    Text('${_likes.length}/$_maxLikes selected',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 12),
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
                                onSelected: (!isSelected && _likes.length >= _maxLikes)
                                    ? null
                                    : (bool selected) {
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
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSavedSection(),
            const SizedBox(height: 16),

            if (_editingName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Editing $_editingName',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    ),
                    TextButton(onPressed: () => setState(_resetForm), child: const Text('Cancel edit')),
                  ],
                ),
              ),

            _buildSectionCard(
              title: 'About them',
              icon: Icons.badge_outlined,
              children: [
                _buildInputField(controller: _nameCtrl, label: 'Full name', icon: Icons.person_outline),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(color: AppColors.border, thickness: 1),
                ),
                GestureDetector(
                  onTap: _pickBirthday,
                  behavior: HitTestBehavior.opaque,
                  child: AbsorbPointer(
                    child: _buildInputField(
                        controller: _birthdayCtrl, label: 'Birthday (optional, tap to pick)', icon: Icons.cake_outlined),
                  ),
                ),
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
              actionWidget: _likes.length >= _maxLikes
                  ? Text('$_maxLikes/$_maxLikes', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
                  : GestureDetector(
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
                    : Text(
                  _editingName == null ? 'Save profile' : 'Update profile',
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

  Widget _buildSavedSection() {
    Widget body;
    if (_loadingSaved) {
      body = const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator(strokeWidth: 2)));
    } else if (_loadError != null) {
      body = Row(
        children: [
          Expanded(child: Text(_loadError!, style: const TextStyle(color: AppColors.danger, fontSize: 13))),
          TextButton(onPressed: _loadSaved, child: const Text('Retry')),
        ],
      );
    } else if (_saved.isEmpty) {
      body = const Text('No one saved yet. Add a friend below.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13));
    } else {
      body = Column(
        children: _saved.map((f) {
          String when = '';
          if (f.daysUntilBirthday == 0) {
            when = 'Birthday today';
          } else if (f.daysUntilBirthday > 0 && f.reminderDue) {
            when = 'Birthday in ${f.daysUntilBirthday} day(s)';
          }
          return ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => _startEdit(f),
            title: Text(f.name, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            subtitle: Text(
              [f.relationship, if (f.likes.isNotEmpty) f.likes.join(', '), if (when.isNotEmpty) when].join(' · '),
              style: TextStyle(color: f.reminderDue ? AppColors.primary : AppColors.textSecondary, fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.textSecondary),
              onPressed: () => _confirmDelete(f),
            ),
          );
        }).toList(),
      );
    }
    return _buildSectionCard(title: 'Saved people', icon: Icons.people_alt_outlined, children: [body]);
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