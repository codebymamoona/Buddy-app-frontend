import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_preferences.dart';

class PreferencesScreen extends StatefulWidget {
  final void Function(UserPreferences prefs) onComplete;
  const PreferencesScreen({super.key, required this.onComplete});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  // Food
  String? _cuisine;
  final _dishCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  String? _spiceLevel;
  String? _dietary;
  final _budgetCtrl = TextEditingController();

  // Travel
  final _travelNameCtrl = TextEditingController();
  String? _travelReason;
  String? _travelStyle;
  final List<TravelPlace> _travelPlaces = [];

  final _cuisineOptions = ['Fast Food', 'Desi / Pakistani', 'Chinese', 'Italian', 'BBQ', 'Continental'];
  final _spiceOptions = ['Mild', 'Medium', 'Hot'];
  final _dietaryOptions = ['None', 'Vegetarian', 'Halal-only', 'No beef', 'No seafood'];
  final _travelReasonOptions = ['Mountains', 'Beach', 'City', 'Adventure', 'Relaxation'];
  final _travelStyleOptions = ['Budget', 'Mid-range', 'Luxury'];

  @override
  void dispose() {
    _dishCtrl.dispose();
    _brandCtrl.dispose();
    _budgetCtrl.dispose();
    _travelNameCtrl.dispose();
    super.dispose();
  }

  void _addTravelPlace() {
    if (_travelNameCtrl.text.trim().isEmpty) return;
    setState(() {
      _travelPlaces.add(TravelPlace(
        name: _travelNameCtrl.text.trim(),
        reason: _travelReason,
        style: _travelStyle,
      ));
      _travelNameCtrl.clear();
      _travelReason = null;
      _travelStyle = null;
    });
  }

  void _removeTravelPlace(TravelPlace place) {
    setState(() => _travelPlaces.remove(place));
  }

  void _submit() {
    widget.onComplete(
      UserPreferences(
        food: FoodPreferences(
          favoriteCuisine: _cuisine,
          favoriteDish: _dishCtrl.text.trim().isEmpty ? null : _dishCtrl.text.trim(),
          favoriteBrand: _brandCtrl.text.trim().isEmpty ? null : _brandCtrl.text.trim(),
          spiceLevel: _spiceLevel,
          dietaryRestriction: _dietary,
          typicalBudget: double.tryParse(_budgetCtrl.text.trim()),
        ),
        travelPlaces: _travelPlaces,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Tell Buddy About You'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "Buddy's suggestions — food orders, travel, and reminders. ",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),

            _SectionCard(
              icon: Icons.restaurant_outlined,
              title: 'Food preferences',
              children: [
                _dropdownField('Favorite cuisine', Icons.restaurant_menu_outlined, _cuisineOptions, _cuisine,
                        (v) => setState(() => _cuisine = v)),
                const SizedBox(height: 14),
                TextField(
                  controller: _dishCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Favorite dish (e.g. Zinger Burger, Chicken Karahi)',
                    prefixIcon: Icon(Icons.fastfood_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _brandCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Favorite brand / restaurant (e.g. McDonald\'s, KFC)',
                    prefixIcon: Icon(Icons.storefront_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                _dropdownField('Spice level', Icons.local_fire_department_outlined, _spiceOptions, _spiceLevel,
                        (v) => setState(() => _spiceLevel = v)),
                const SizedBox(height: 14),
                _dropdownField('Dietary restriction', Icons.no_food_outlined, _dietaryOptions, _dietary,
                        (v) => setState(() => _dietary = v)),
                const SizedBox(height: 14),
                TextField(
                  controller: _budgetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Typical order budget (Rs)',
                    prefixIcon: Icon(Icons.payments_outlined, size: 20),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _SectionCard(
              icon: Icons.travel_explore_outlined,
              title: 'Places you\'d love to visit',
              children: [
                TextField(
                  controller: _travelNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Place name',
                    hintText: 'e.g. Hunza Valley',
                    prefixIcon: Icon(Icons.place_outlined, size: 20),
                  ),
                ),
                const SizedBox(height: 14),
                _dropdownField('Why this place?', Icons.explore_outlined, _travelReasonOptions, _travelReason,
                        (v) => setState(() => _travelReason = v)),
                const SizedBox(height: 14),
                _dropdownField('Travel style', Icons.style_outlined, _travelStyleOptions, _travelStyle,
                        (v) => setState(() => _travelStyle = v)),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _addTravelPlace,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add place'),
                  ),
                ),
                if (_travelPlaces.isNotEmpty) ...[
                  const Divider(height: 20),
                  ..._travelPlaces.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                                if (p.reason != null || p.style != null)
                                  TextSpan(
                                    text: '  •  ${[p.reason, p.style].where((e) => e != null).join(' · ')}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                          onPressed: () => _removeTravelPlace(p),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),

            const SizedBox(height: 28),
            ElevatedButton(onPressed: _submit, child: const Text('Continue to Buddy')),
            const SizedBox(height: 8),
            const Center(
              child: Text('You can update these anytime later', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField(
      String label,
      IconData icon,
      List<String> options,
      String? selected,
      void Function(String?) onSelect,
      ) {
    return DropdownButtonFormField<String>(
      initialValue: selected,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
      icon: const Icon(Icons.keyboard_arrow_down, size: 20),
      isExpanded: true,
      items: options
          .map((o) => DropdownMenuItem(
        value: o,
        child: Text(o, style: const TextStyle(fontSize: 14)),
      ))
          .toList(),
      onChanged: onSelect,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.icon, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}