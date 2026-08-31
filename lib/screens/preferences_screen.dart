import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../models/preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late UserPreferences _draft;

  late final TextEditingController _dishCtrl;
  late final TextEditingController _brandCtrl;
  late final TextEditingController _budgetCtrl;
  late final TextEditingController _placeCtrl;

  @override
  void initState() {
    super.initState();
    final current = AppState.instance.preferences;
    // Work on a copy so edits don't apply until "Save changes" is pressed.
    _draft = UserPreferences(
      cuisine: current.cuisine,
      favoriteDish: current.favoriteDish,
      favoriteBrand: current.favoriteBrand,
      spiceLevel: current.spiceLevel,
      dietaryRestriction: current.dietaryRestriction,
      orderBudget: current.orderBudget,
      placeName: current.placeName,
      placeReason: current.placeReason,
      travelStyle: current.travelStyle,
    );
    _dishCtrl = TextEditingController(text: _draft.favoriteDish);
    _brandCtrl = TextEditingController(text: _draft.favoriteBrand);
    _budgetCtrl = TextEditingController(text: _draft.orderBudget);
    _placeCtrl = TextEditingController(text: _draft.placeName);
  }

  @override
  void dispose() {
    _dishCtrl.dispose();
    _brandCtrl.dispose();
    _budgetCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  void _save() {
    _draft.favoriteDish = _dishCtrl.text.trim().isEmpty ? _draft.favoriteDish : _dishCtrl.text.trim();
    _draft.favoriteBrand = _brandCtrl.text.trim().isEmpty ? _draft.favoriteBrand : _brandCtrl.text.trim();
    _draft.orderBudget = _budgetCtrl.text.trim().isEmpty ? _draft.orderBudget : _budgetCtrl.text.trim();
    _draft.placeName = _placeCtrl.text.trim().isEmpty ? _draft.placeName : _placeCtrl.text.trim();

    AppState.instance.updatePreferences(_draft);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferences updated — Buddy will use these going forward.')),
    );
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BuddyAppBar(title: 'Preferences'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          const Text(
            'These are the same answers from "Tell Buddy About You" — update them any time.',
            style: TextStyle(color: AppColors.grey, fontSize: 12.5),
          ),
          const SizedBox(height: 18),

          FormCard(
            children: [
              const SectionHeader(icon: Icons.restaurant_rounded, title: 'Food preferences'),
              const SizedBox(height: 4),
              _LabeledDropdown(
                icon: Icons.set_meal_outlined,
                label: 'Favorite cuisine',
                value: _draft.cuisine,
                options: const ['Pakistani', 'Fast Food', 'Chinese', 'Italian', 'BBQ'],
                onChanged: (v) => setState(() => _draft.cuisine = v ?? _draft.cuisine),
              ),
              _LabeledTextField(icon: Icons.fastfood_outlined, label: 'Favorite dish', controller: _dishCtrl),
              _LabeledTextField(icon: Icons.storefront_outlined, label: 'Favorite brand / restaurant', controller: _brandCtrl),
              _LabeledDropdown(
                icon: Icons.local_fire_department_outlined,
                label: 'Spice level',
                value: _draft.spiceLevel,
                options: const ['Mild', 'Medium', 'Hot', 'Extra Hot'],
                onChanged: (v) => setState(() => _draft.spiceLevel = v ?? _draft.spiceLevel),
              ),
              _LabeledDropdown(
                icon: Icons.no_food_outlined,
                label: 'Dietary restriction',
                value: _draft.dietaryRestriction,
                options: const ['None', 'Vegetarian', 'Halal only', 'No dairy'],
                onChanged: (v) => setState(() => _draft.dietaryRestriction = v ?? _draft.dietaryRestriction),
              ),
              _LabeledTextField(
                icon: Icons.payments_outlined,
                label: 'Typical order budget (Rs)',
                controller: _budgetCtrl,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          const SizedBox(height: 18),

          FormCard(
            children: [
              const SectionHeader(icon: Icons.travel_explore_rounded, title: "Places you'd love to visit"),
              const SizedBox(height: 4),
              _LabeledTextField(icon: Icons.place_outlined, label: 'Place name', controller: _placeCtrl),
              _LabeledDropdown(
                icon: Icons.explore_outlined,
                label: 'Why this place?',
                value: _draft.placeReason,
                options: const ['Relaxation', 'Adventure', 'Food', 'Culture'],
                onChanged: (v) => setState(() => _draft.placeReason = v ?? _draft.placeReason),
              ),
              _LabeledDropdown(
                icon: Icons.hiking_outlined,
                label: 'Travel style',
                value: _draft.travelStyle,
                options: const ['Budget', 'Comfort', 'Luxury'],
                onChanged: (v) => setState(() => _draft.travelStyle = v ?? _draft.travelStyle),
              ),
            ],
          ),
          const SizedBox(height: 24),

          PrimaryButton(label: 'Save changes', icon: Icons.check_rounded, onPressed: _save),
        ],
      ),
    );
  }
}

/// A field row with a small caption above it, so the Preferences screen
/// (unlike onboarding) makes clear what value is currently saved.
class _LabeledTextField extends StatelessWidget {
  final IconData icon;
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _LabeledTextField({
    required this.icon,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.grey)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(prefixIcon: Icon(icon, size: 19)),
          ),
        ],
      ),
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _LabeledDropdown({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Guard against a saved value that isn't in the option list.
    final safeValue = options.contains(value) ? value : options.first;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: AppColors.grey)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: safeValue,
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            decoration: InputDecoration(prefixIcon: Icon(icon, size: 19)),
            items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
