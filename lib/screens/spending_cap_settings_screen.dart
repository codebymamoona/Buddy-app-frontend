import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/wallet_service.dart';

class SpendingCapScreen extends StatefulWidget {
  const SpendingCapScreen({super.key});

  @override
  State<SpendingCapScreen> createState() => _SpendingCapScreenState();
}

class _SpendingCapScreenState extends State<SpendingCapScreen> {
  final ApiService _api = ApiService();
  final WalletService _walletApi = WalletService();
  double _dailyCap = 5000;
  double _travelCap = 300000;
  // What the server holds right now. Only a limit the user actually moved gets saved, so merely opening this
  // screen can never overwrite a value that sits outside the slider range.
  double _dailyLoaded = 5000;
  double _travelLoaded = 300000;
  bool _travelAvailable = false;

  static const double _dailyMin = 500, _dailyMax = 20000;
  static const double _travelMin = 50000, _travelMax = 1000000;
  bool _isSaving = false;
  bool _isLoading = true;

  final bool _autoApproveLocked = true;

  double _threshold = 200;
  bool _autoApproveDraft = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentCap();
  }

  Future<void> _fetchCurrentCap() async {
    try {
      final cap = await _api.getSpendingCap();
      final travel = await _walletApi.getTravelCap();
      if (!mounted) return;
      setState(() {
        if (cap != null) {
          _dailyCap = cap;
          _dailyLoaded = cap;
        }
        if (travel.ok && travel.data != null) {
          _travelCap = travel.data!;
          _travelLoaded = travel.data!;
          _travelAvailable = true;
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load your current limits. Showing defaults.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  /// Saves only the limits that changed. If one fails the screen stays open and says which.
  Future<void> _saveCap() async {
    final dailyChanged = _dailyCap != _dailyLoaded;
    final travelChanged = _travelAvailable && _travelCap != _travelLoaded;
    if (!dailyChanged && !travelChanged) {
      _snack('Nothing to save. Move a slider first.');
      return;
    }
    setState(() => _isSaving = true);
    final problems = <String>[];
    try {
      if (dailyChanged) {
        final ok = await _api.updateSpendingCap(_dailyCap);
        if (ok) {
          _dailyLoaded = _dailyCap;
        } else {
          problems.add('Could not update your daily limit.');
        }
      }
      if (travelChanged) {
        final r = await _walletApi.updateTravelCap(_travelCap);
        if (r.ok) {
          _travelLoaded = _travelCap;
        } else {
          problems.add(r.message);
        }
      }
    } catch (e) {
      problems.add('Network error: cannot reach the server.');
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (problems.isEmpty) {
      _snack('Spending limits updated.');
      Navigator.of(context).maybePop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(problems.join(' ')), backgroundColor: AppColors.danger),
      );
    }
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  static String _pkr(double v) {
    final s = v.round().abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text('Spending Controls',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          _buildConfigCard(
            title: 'Daily Limit',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Food, shopping and gifts',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              Text(
                'PKR ${_pkr(_dailyCap)} per day',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Slider(
                value: _dailyCap.clamp(_dailyMin, _dailyMax).toDouble(),
                min: _dailyMin,
                max: _dailyMax,
                divisions: 39,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.border,
                label: 'PKR ${_pkr(_dailyCap)}',
                onChanged: (v) => setState(() => _dailyCap = v),
              ),
              const Align(
                alignment: Alignment.center,
                child: Text('Drag to set your daily approval limit',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildConfigCard(
            title: 'Travel Limit',
            icon: Icons.flight_takeoff_rounded,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Flights count here, not against your daily limit.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ),
              const SizedBox(height: 8),
              if (!_travelAvailable)
                const Text("Couldn't load your travel limit. Go back and open this screen again.",
                    style: TextStyle(color: AppColors.danger, fontSize: 12.5))
              else ...[
                Text(
                  'PKR ${_pkr(_travelCap)} per day',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: _travelCap.clamp(_travelMin, _travelMax).toDouble(),
                  min: _travelMin,
                  max: _travelMax,
                  divisions: 38,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  label: 'PKR ${_pkr(_travelCap)}',
                  onChanged: (v) => setState(() => _travelCap = v),
                ),
                const Align(
                  alignment: Alignment.center,
                  child: Text('Drag to set your daily travel limit',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          _buildConfigCard(
            title: 'Zero-Trust Rules',
            icon: Icons.rule_rounded,
            locked: _autoApproveLocked,
            lockedLabel: 'Pending supervisor sign-off \u2014 every order requires approval for now',
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Auto-approve micro-orders', style: TextStyle(color: Colors.white, fontSize: 14)),
                  Switch(
                    value: _autoApproveDraft,
                    activeColor: AppColors.primary,
                    inactiveTrackColor: AppColors.border,
                    onChanged: _autoApproveLocked ? null : (v) => setState(() => _autoApproveDraft = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _autoApproveDraft
                    ? 'Orders up to PKR ${_threshold.toStringAsFixed(0)} bypass manual approval.'
                    : 'Every single AI transaction requires your explicit authorization.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: _autoApproveDraft ? 1 : 0.3,
                child: IgnorePointer(
                  ignoring: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Approval Threshold', style: TextStyle(color: Colors.white, fontSize: 13.5)),
                          Text('PKR ${_threshold.toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                      Slider(
                        value: _threshold.clamp(50, 5000).toDouble(),
                        min: 50,
                        max: 5000,
                        divisions: 99,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.border,
                        label: 'PKR ${_threshold.toStringAsFixed(0)}',
                        onChanged: (v) {},
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveCap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(
                  height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text(
                'SAVE LIMITS',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    bool locked = false,
    String? lockedLabel,
  }) {
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
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              if (locked) ...[
                const Spacer(),
                const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 16),
              ],
            ],
          ),
          if (locked && lockedLabel != null) ...[
            const SizedBox(height: 6),
            Text(lockedLabel, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 16),
          Opacity(
            opacity: locked ? 0.5 : 1.0,
            child: IgnorePointer(ignoring: locked, child: Column(children: children)),
          ),
        ],
      ),
    );
  }
}