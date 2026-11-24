import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _nameController = TextEditingController();
  bool _isSaving = false;
  bool _isSendingReset = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController.text = _user?.displayName ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveDisplayName() async {
    final user = _user;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await user.updateDisplayName(_nameController.text.trim());
      await user.reload();
      if (mounted) {
        setState(() {});
      }
      _showSnack('Display name updated.');
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Could not update display name.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _user?.email;
    if (email == null || email.isEmpty) return;

    setState(() => _isSendingReset = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showSnack('Password reset email sent to $email.');
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? 'Failed to send reset email.');
    } finally {
      if (mounted) {
        setState(() => _isSendingReset = false);
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (user?.displayName?.isNotEmpty ?? false)
                                    ? user!.displayName!
                                    : 'Account User',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                user?.email ?? 'No email',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display Name',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveDisplayName,
                        icon: const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save Name'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.key),
                    title: const Text('User ID'),
                    subtitle: Text(user?.uid ?? '-'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_reset),
                    title: const Text('Reset Password'),
                    subtitle: const Text('Send a reset link to your email'),
                    trailing: _isSendingReset
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _isSendingReset ? null : _sendPasswordReset,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.amberAccent),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.amberAccent),
                    ),
                    onTap: _signOut,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}