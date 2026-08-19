import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sahha_flutter/sahha_flutter.dart';
import 'package:sahha_flutter_example/services/stress_lab.dart';
import 'package:sahha_flutter_example/widgets/response_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exercises the authentication surface of the plugin: `authenticate`,
/// `authenticateToken`, `deauthenticate`, `isAuthenticated` and
/// `getProfileToken`.
class AuthenticationView extends StatefulWidget {
  const AuthenticationView({super.key});

  @override
  State<AuthenticationView> createState() => AuthenticationState();
}

class AuthenticationState extends State<AuthenticationView> {
  final TextEditingController appIdController = TextEditingController();
  final TextEditingController appSecretController = TextEditingController();
  final TextEditingController externalIdController = TextEditingController();
  final TextEditingController profileTokenController = TextEditingController();
  final TextEditingController refreshTokenController = TextEditingController();

  String appId = '';
  String appSecret = '';
  String externalId = '';

  bool _obscureAppSecret = true;
  bool _isAuthenticating = false;
  bool _isDeauthenticating = false;
  bool _isTokenAuthenticating = false;

  bool _statusLoading = true;
  bool? _isAuthenticated;
  String? _profileToken;

  bool get _isBusy =>
      _isAuthenticating || _isDeauthenticating || _isTokenAuthenticating;

  @override
  void initState() {
    super.initState();

    getPrefs();
    refreshStatus();
  }

  @override
  void dispose() {
    appIdController.dispose();
    appSecretController.dispose();
    externalIdController.dispose();
    profileTokenController.dispose();
    refreshTokenController.dispose();
    super.dispose();
  }

  // The 'appId' / 'appSecret' / 'externalId' keys are intentionally not
  // namespaced so existing installs of the harness keep their credentials.
  Future<void> getPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    // Build-time credentials only seed empty fields, so anything typed in on
    // device still wins. They are passed with --dart-define and never stored
    // in the repo.
    var storedAppId = prefs.getString('appId') ?? '';
    var storedAppSecret = prefs.getString('appSecret') ?? '';
    var storedExternalId = prefs.getString('externalId') ?? '';
    if (storedAppId.isEmpty) storedAppId = SahhaBuildCredentials.appId;
    if (storedAppSecret.isEmpty) {
      storedAppSecret = SahhaBuildCredentials.appSecret;
    }
    if (storedExternalId.isEmpty) {
      storedExternalId = SahhaBuildCredentials.externalId;
    }

    if (!mounted) return;
    setState(() {
      appId = storedAppId;
      appIdController.text = appId;
      appSecret = storedAppSecret;
      appSecretController.text = appSecret;
      externalId = storedExternalId;
      externalIdController.text = externalId;
    });
  }

  Future<void> setPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appId', appId);
    await prefs.setString('appSecret', appSecret);
    await prefs.setString('externalId', externalId);
  }

  /// Re-reads `isAuthenticated` and `getProfileToken` for the status card.
  Future<void> refreshStatus() async {
    if (mounted) setState(() => _statusLoading = true);

    bool? authenticated;
    String? profileToken;

    try {
      authenticated = await SahhaFlutter.isAuthenticated();
      debugPrint('Is Authenticated Result: $authenticated');
    } catch (error) {
      debugPrint('Is Authenticated Error: $error');
    }

    try {
      profileToken = await SahhaFlutter.getProfileToken();
      debugPrint('Get Profile Token Result: $profileToken');
    } catch (error) {
      debugPrint('Get Profile Token Error: $error');
    }

    if (!mounted) return;
    setState(() {
      _isAuthenticated = authenticated;
      _profileToken = profileToken;
      _statusLoading = false;
    });
  }

  Future<void> onTapAuthenticate() async {
    if (appId.isEmpty) {
      return _showMissingInfo('You need to input an APP ID');
    }
    if (appSecret.isEmpty) {
      return _showMissingInfo('You need to input an APP SECRET');
    }
    if (externalId.isEmpty) {
      return _showMissingInfo('You need to input an EXTERNAL ID');
    }

    setState(() => _isAuthenticating = true);

    bool? success;
    Object? failure;
    try {
      success = await SahhaFlutter.authenticate(
        appId: appId,
        appSecret: appSecret,
        externalId: externalId,
      );
      debugPrint('Authenticate Result: $success');
      await setPrefs();
    } catch (error) {
      failure = error;
      debugPrint('Authenticate Error: $error');
    }

    if (!mounted) return;
    setState(() => _isAuthenticating = false);
    await refreshStatus();

    if (!mounted) return;
    await showResponseSheet(
      context,
      title: failure == null ? 'Authenticated' : 'Authentication failed',
      subtitle: 'SahhaFlutter.authenticate',
      body: (failure ?? success).toString(),
      isError: failure != null,
    );
  }

  Future<void> onTapAuthenticateToken() async {
    final profileToken = profileTokenController.text.trim();
    final refreshToken = refreshTokenController.text.trim();

    if (profileToken.isEmpty) {
      return _showMissingInfo('You need to input a PROFILE TOKEN');
    }
    if (refreshToken.isEmpty) {
      return _showMissingInfo('You need to input a REFRESH TOKEN');
    }

    setState(() => _isTokenAuthenticating = true);

    bool? success;
    Object? failure;
    try {
      success = await SahhaFlutter.authenticateToken(
        profileToken: profileToken,
        refreshToken: refreshToken,
      );
      debugPrint('Authenticate Token Result: $success');
    } catch (error) {
      failure = error;
      debugPrint('Authenticate Token Error: $error');
    }

    if (!mounted) return;
    setState(() => _isTokenAuthenticating = false);
    await refreshStatus();

    if (!mounted) return;
    await showResponseSheet(
      context,
      title: failure == null ? 'Authenticated' : 'Token authentication failed',
      subtitle: 'SahhaFlutter.authenticateToken',
      body: (failure ?? success).toString(),
      isError: failure != null,
    );
  }

  Future<void> onTapDeauthenticate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final scheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: const Text('Deauthenticate?'),
          content: const Text(
            'This signs the current profile out of the SDK on this device. '
            'The external ID will be cleared.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Deauthenticate'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeauthenticating = true);

    bool? success;
    Object? failure;
    try {
      success = await SahhaFlutter.deauthenticate();
      debugPrint('Deauthenticate Result: $success');
    } catch (error) {
      failure = error;
      debugPrint('Deauthenticate Error: $error');
    }

    if (!mounted) return;
    setState(() {
      _isDeauthenticating = false;
      if (failure == null) {
        externalId = '';
        externalIdController.text = '';
      }
    });
    if (failure == null) await setPrefs();
    await refreshStatus();

    if (!mounted) return;
    await showResponseSheet(
      context,
      title: failure == null ? 'Deauthenticated' : 'Deauthentication failed',
      subtitle: 'SahhaFlutter.deauthenticate',
      body: (failure ?? success).toString(),
      isError: failure != null,
    );
  }

  Future<void> _showMissingInfo(String message) {
    return showResponseSheet(
      context,
      title: 'Missing info',
      body: message,
      isError: true,
    );
  }

  void _copyProfileToken() {
    final token = _profileToken;
    if (token == null || token.isEmpty) return;
    Clipboard.setData(ClipboardData(text: token));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile token copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Authentication'),
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            icon: const Icon(Icons.refresh),
            onPressed: _statusLoading ? null : refreshStatus,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildStatusCard(theme),
          const _SectionLabel('App credentials'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: appIdController,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(labelText: 'APP ID'),
                    onChanged: (text) => setState(() => appId = text),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: appSecretController,
                    autocorrect: false,
                    enableSuggestions: false,
                    obscureText: _obscureAppSecret,
                    decoration: InputDecoration(
                      labelText: 'APP SECRET',
                      suffixIcon: IconButton(
                        tooltip: _obscureAppSecret
                            ? 'Show app secret'
                            : 'Hide app secret',
                        icon: Icon(
                          _obscureAppSecret
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscureAppSecret = !_obscureAppSecret,
                        ),
                      ),
                    ),
                    onChanged: (text) => setState(() => appSecret = text),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: externalIdController,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: const InputDecoration(labelText: 'EXTERNAL ID'),
                    onChanged: (text) => setState(() => externalId = text),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isBusy ? null : onTapAuthenticate,
            child: _busyLabel(
              context,
              busy: _isAuthenticating,
              label: 'AUTHENTICATE',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _isBusy ? null : onTapDeauthenticate,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
            child: _busyLabel(
              context,
              busy: _isDeauthenticating,
              label: 'DEAUTHENTICATE',
            ),
          ),
          const _SectionLabel('Advanced'),
          ExpansionTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: const Text('Authenticate with tokens'),
            subtitle: const Text('SahhaFlutter.authenticateToken'),
            // Children default to centre alignment, which would shrink the
            // fields and button to their intrinsic width.
            expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: profileTokenController,
                autocorrect: false,
                enableSuggestions: false,
                maxLines: 2,
                minLines: 1,
                decoration: const InputDecoration(labelText: 'PROFILE TOKEN'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refreshTokenController,
                autocorrect: false,
                enableSuggestions: false,
                maxLines: 2,
                minLines: 1,
                decoration: const InputDecoration(labelText: 'REFRESH TOKEN'),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _isBusy ? null : onTapAuthenticateToken,
                child: _busyLabel(
                  context,
                  busy: _isTokenAuthenticating,
                  label: 'AUTHENTICATE WITH TOKENS',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    final bool authenticated = _isAuthenticated ?? false;
    final bool unknown = _isAuthenticated == null;
    final Color accent = unknown
        ? Colors.grey.shade600
        : authenticated
        ? Colors.green.shade600
        : Colors.orange.shade800;
    final String label = unknown
        ? 'Unknown'
        : authenticated
        ? 'Authenticated'
        : 'Not authenticated';
    final String? token = _profileToken;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Status',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_statusLoading)
                  const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  _StatusChip(label: label, color: accent),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Profile token',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    token == null || token.isEmpty
                        ? 'None'
                        : _truncateToken(token),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: monoStyle(context, fontSize: 13),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy profile token',
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  onPressed: token == null || token.isEmpty
                      ? null
                      : _copyProfileToken,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _truncateToken(String token) {
    if (token.length <= 26) return token;
    return '${token.substring(0, 14)}…${token.substring(token.length - 8)}';
  }

  static Widget _busyLabel(
    BuildContext context, {
    required bool busy,
    required String label,
  }) {
    if (!busy) return Text(label);
    return SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
      child: Text(
        text,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}
