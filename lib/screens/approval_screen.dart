import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

class ApprovalScreen extends StatefulWidget {
  // Was hardcoded 'aqil_01' inside the API calls below — that meant every
  // user on the app saw and could act on ONE test account's pending queue,
  // bypassing ownership verification entirely. Now required: the caller
  // (wherever this screen is pushed) must pass the real logged-in user's ID
  // (Firebase UID / AppState.instance.currentUserId — whatever your actual
  // session source is). This is a required param specifically so the app
  // won't compile until every call site supplies a real value.
  final String userId;

  const ApprovalScreen({super.key, required this.userId});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  List<dynamic> _pendingActions = [];
  bool _isLoading = true;
  String? _loadError;
  final Set<int> _submittingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchPendingActions();
  }

  Future<void> _fetchPendingActions() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8080/api/actions/pending/${widget.userId}'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          _pendingActions = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _loadError = 'Could not load pending actions.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Network error: cannot reach the server.';
      });
    }
  }

  // Was: fire-and-forget with print() on failure. A user tapping Approve/Deny
  // needs to know if that decision actually reached the backend — silent
  // failure here means the user believes an action was authorized or
  // blocked when the server never received it.
  Future<void> _submitDecision(int actionId, String decision) async {
    setState(() => _submittingIds.add(actionId));
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8080/api/actions/$actionId/decision'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": widget.userId, "decision": decision}),
      );
      if (!mounted) return;
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't send your decision. Try again."),
            backgroundColor: AppColors.danger,
          ),
        );
        setState(() => _submittingIds.remove(actionId));
        return;
      }
      await _fetchPendingActions();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error: your decision was not sent.'),
          backgroundColor: AppColors.danger,
        ),
      );
      setState(() => _submittingIds.remove(actionId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? _buildErrorState()
          : _pendingActions.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: _fetchPendingActions,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _pendingActions.length,
          itemBuilder: (context, index) {
            return _buildApprovalCard(_pendingActions[index]);
          },
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 40),
          const SizedBox(height: 12),
          Text(_loadError ?? 'Something went wrong.',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: _fetchPendingActions, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
            child: const Icon(Icons.task_alt_rounded, color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('Nothing waiting on you',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          const Text('No actions are pending approval.',
              style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(Map<String, dynamic> action) {
    Map<String, dynamic> payload = jsonDecode(action['payload']);
    final isSubmitting = _submittingIds.contains(action['id']);

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.security_rounded, color: AppColors.warning, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Source: ${action['toolName']}",
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Divider(height: 30, color: AppColors.border),

            ...payload.entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text("${e.key.toUpperCase()}: ${e.value}",
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            )),

            const SizedBox(height: 16),
            Text(
              "Deduction: PKR ${action['cost']}",
              style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSubmitting ? null : () => _submitDecision(action['id'], "REJECT"),
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                        foregroundColor: AppColors.danger),
                    child: const Text("Deny"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : () => _submitDecision(action['id'], "APPROVE"),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success, foregroundColor: Colors.white),
                    child: isSubmitting
                        ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Text("Approve"),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}