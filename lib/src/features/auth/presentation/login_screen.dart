import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glam/src/app/theme/app_colors.dart';
import 'package:glam/src/app/theme/app_spacing.dart';
import 'package:glam/src/core/api/api_exception.dart';
import 'package:glam/src/features/auth/application/auth_providers.dart';

/// Sign-in with a GitLab instance URL and a personal access token.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _instanceController = TextEditingController(text: 'gitlab.com');
  final _tokenController = TextEditingController();
  final _tokenFocus = FocusNode();

  bool _obscure = true;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _instanceController.dispose();
    _tokenController.dispose();
    _tokenFocus.dispose();
    super.dispose();
  }

  Future<void> _pasteToken() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      _tokenController.text = text.trim();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .signIn(
            baseUrl: _instanceController.text,
            token: _tokenController.text.trim(),
          );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } on Object {
      setState(() => _error = 'Could not sign in. Check the instance URL.');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width > 560;

    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.all(Insets.xxl),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: Radii.borderLg,
          border: Border.all(color: colors.border),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Wordmark(),
              const SizedBox(height: Insets.xs),
              Text(
                'Sign in to your GitLab instance',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.inkMuted,
                ),
              ),
              const SizedBox(height: Insets.xl),
              TextFormField(
                controller: _instanceController,
                enabled: !_submitting,
                autocorrect: false,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'Instance URL',
                  hintText: 'gitlab.com or gitlab.example.com',
                  prefixIcon: Icon(Icons.dns_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter your GitLab instance';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _tokenFocus.requestFocus(),
              ),
              const SizedBox(height: Insets.md),
              TextFormField(
                controller: _tokenController,
                focusNode: _tokenFocus,
                enabled: !_submitting,
                obscureText: _obscure,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Personal access token',
                  hintText: 'glpat-…',
                  prefixIcon: const Icon(Icons.key_outlined),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Paste',
                        icon: const Icon(Icons.paste_outlined, size: 18),
                        onPressed: _pasteToken,
                      ),
                      IconButton(
                        tooltip: _obscure ? 'Show' : 'Hide',
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Paste a personal access token';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: Insets.md),
                Container(
                  padding: const EdgeInsets.all(Insets.md),
                  decoration: BoxDecoration(
                    color: colors.dangerSoft,
                    borderRadius: Radii.borderMd,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 18, color: colors.danger),
                      const SizedBox(width: Insets.sm),
                      Expanded(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: Insets.xl),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.colors.onAccent,
                        ),
                      )
                    : const Text('Sign in'),
              ),
              const SizedBox(height: Insets.md),
              Text(
                'Create a token under Preferences → Access Tokens with the '
                '`api` scope.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(wide ? Insets.xxl : Insets.lg),
            child: card,
          ),
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.accent, colors.brand],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: Radii.borderMd,
          ),
          child: const Center(
            child: Text(
              'G',
              style: TextStyle(
                fontFamily: 'Space Grotesk',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: Insets.sm + 2),
        Text('Glam', style: theme.textTheme.displaySmall),
      ],
    );
  }
}
