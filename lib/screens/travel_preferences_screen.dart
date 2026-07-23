import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/user_preferences.dart';

class TravelPreferencesScreen extends StatefulWidget {
  final List<TravelPlace> initial;
  final void Function(List<TravelPlace> places)? onSave;

  const TravelPreferencesScreen({super.key, required this.initial, this.onSave});

  @override
  State<TravelPreferencesScreen> createState() => _TravelPreferencesScreenState();
}

class _TravelPreferencesScreenState extends State<TravelPreferencesScreen> {
  late List<TravelPlace> _places;
  final _nameCtrl = TextEditingController();
  String? _reason;
  String? _style;

  final _reasonOptions = ['Mountains', 'Beach', 'City', 'Adventure', 'Relaxation'];
  final _styleOptions = ['Budget', 'Mid-range', 'Luxury'];

  @override
  void initState() {
    super.initState();
    _places = List.of(widget.initial);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _addPlace() {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() {
      _places.add(TravelPlace(name: _nameCtrl.text.trim(), reason: _reason, style: _style));
      _nameCtrl.clear();
      _reason = null;
      _style = null;
    });
  }

  void _save() {
    widget.onSave?.call(_places);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Travel preferences saved'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Travel Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Add a place', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Place name',
                      hintText: 'e.g. Hunza Valley',
                      prefixIcon: Icon(Icons.place_outlined, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _dropdownField('Why this place?', Icons.explore_outlined, _reasonOptions, _reason,
                          (v) => setState(() => _reason = v)),
                  const SizedBox(height: 16),
                  _dropdownField('Travel style', Icons.style_outlined, _styleOptions, _style,
                          (v) => setState(() => _style = v)),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _addPlace,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add place'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_places.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No places added yet', style: TextStyle(color: AppColors.textSecondary)),
              ),
            )
          else
            ..._places.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.travel_explore_outlined, color: AppColors.primary, size: 20),
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text(
                  [p.reason, p.style].where((e) => e != null).join(' · '),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
                  onPressed: () => setState(() => _places.remove(p)),
                ),
              ),
            )),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _save, child: const Text('Save')),
        ],
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