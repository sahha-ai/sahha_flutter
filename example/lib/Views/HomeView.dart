import 'package:flutter/material.dart';
import 'package:sahha_flutter/sahha_flutter.dart';

/// Dashboard for the test harness: an authentication status banner plus the
/// screens that exercise each area of the plugin API, grouped by concern.
class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => HomeState();
}

class HomeState extends State<HomeView> {
  /// Null while the first check is in flight, or after a failed check.
  bool? _isAuthenticated;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _refreshAuthStatus();
  }

  Future<void> _refreshAuthStatus() async {
    try {
      final value = await SahhaFlutter.isAuthenticated();
      debugPrint('isAuthenticated: $value');
      if (!mounted) return;
      setState(() {
        _isAuthenticated = value;
        _authError = null;
      });
    } catch (error) {
      debugPrint('isAuthenticated error: $error');
      if (!mounted) return;
      setState(() {
        _isAuthenticated = null;
        _authError = error.toString();
      });
    }
  }

  /// Pushes [route] and re-checks authentication when the screen comes back,
  /// so the banner reflects anything the pushed screen changed.
  Future<void> _open(String route) async {
    await Navigator.pushNamed(context, route);
    if (!mounted) return;
    await _refreshAuthStatus();
  }

  void _postSensorData() {
    debugPrint('Post Sensor Data requested');
    SahhaFlutter.postSensorData();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sensor data post requested')));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sahha Demo'),
        actions: [
          IconButton(
            tooltip: 'Refresh status',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAuthStatus,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _AuthBanner(
            isAuthenticated: _isAuthenticated,
            error: _authError,
            onTap: () => _open('/authentication'),
          ),
          _Section(
            title: 'Setup',
            tiles: [
              _NavTile(
                icon: Icons.lock_outline,
                iconColor: scheme.onPrimaryContainer,
                iconBackground: scheme.primaryContainer,
                title: 'Authentication',
                subtitle: 'Authenticate, deauthenticate, profile tokens',
                onTap: () => _open('/authentication'),
              ),
              _NavTile(
                icon: Icons.person_outline,
                iconColor: scheme.onPrimaryContainer,
                iconBackground: scheme.primaryContainer,
                title: 'Profile',
                subtitle: 'Post and fetch demographic details',
                onTap: () => _open('/profile'),
              ),
            ],
          ),
          _Section(
            title: 'Sensors',
            tiles: [
              _NavTile(
                icon: Icons.sensors,
                iconColor: scheme.onSecondaryContainer,
                iconBackground: scheme.secondaryContainer,
                title: 'Sensor Permissions',
                subtitle: 'Enable or check status for a chosen sensor set',
                onTap: () => _open('/permissions'),
              ),
              _NavTile(
                icon: Icons.fact_check_outlined,
                iconColor: scheme.onSecondaryContainer,
                iconBackground: scheme.secondaryContainer,
                title: 'Sensor Diagnostics',
                subtitle: 'Per-sensor status across the whole sensor list',
                onTap: () => _open('/diagnostics'),
              ),
              _NavTile(
                icon: Icons.cloud_upload_outlined,
                iconColor: scheme.onSecondaryContainer,
                iconBackground: scheme.secondaryContainer,
                title: 'Post Sensor Data',
                subtitle: 'Trigger an immediate upload of collected data',
                trailing: const Icon(Icons.upload_outlined),
                onTap: _postSensorData,
              ),
            ],
          ),
          _Section(
            title: 'Data',
            tiles: [
              _NavTile(
                icon: Icons.query_stats,
                iconColor: scheme.onTertiaryContainer,
                iconBackground: scheme.tertiaryContainer,
                title: 'Scores',
                subtitle: 'getScores over a score type and date range',
                onTap: () => _open('/scores'),
              ),
              _NavTile(
                icon: Icons.insert_chart_outlined,
                iconColor: scheme.onTertiaryContainer,
                iconBackground: scheme.tertiaryContainer,
                title: 'Biomarkers',
                subtitle: 'getBiomarkers by category, type and date range',
                onTap: () => _open('/biomarkers'),
              ),
              _NavTile(
                icon: Icons.pie_chart_outline,
                iconColor: scheme.onTertiaryContainer,
                iconBackground: scheme.tertiaryContainer,
                title: 'Stats',
                subtitle: 'getStats aggregates for a single sensor',
                isDeprecated: true,
                onTap: () => _open('/stats'),
              ),
              _NavTile(
                icon: Icons.timer_outlined,
                iconColor: scheme.onTertiaryContainer,
                iconBackground: scheme.tertiaryContainer,
                title: 'Samples',
                subtitle: 'getSamples raw readings for a single sensor',
                isDeprecated: true,
                onTap: () => _open('/samples'),
              ),
            ],
          ),
          _Section(
            title: 'Insights',
            tiles: [
              _NavTile(
                icon: Icons.psychology_outlined,
                iconColor: scheme.onPrimaryContainer,
                iconBackground: scheme.primaryContainer,
                title: 'Insights',
                subtitle: 'Sahha web view authorised with the profile token',
                onTap: () => _open('/web'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Authentication status card: green when authenticated, orange when not,
/// grey while unknown. Tapping it jumps to the authentication screen.
class _AuthBanner extends StatelessWidget {
  const _AuthBanner({
    required this.isAuthenticated,
    required this.error,
    required this.onTap,
  });

  final bool? isAuthenticated;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool authenticated = isAuthenticated ?? false;
    final bool unknown = isAuthenticated == null;

    final Color accent = unknown
        ? Colors.grey.shade600
        : authenticated
        ? Colors.green.shade600
        : Colors.orange.shade800;

    final String title = unknown
        ? (error == null ? 'Checking status…' : 'Status unavailable')
        : authenticated
        ? 'Authenticated'
        : 'Not authenticated';

    final String subtitle = unknown
        ? (error ?? 'Reading isAuthenticated from the SDK')
        : authenticated
        ? 'A profile is signed in on this device'
        : 'Tap to authenticate before fetching data';

    final IconData icon = unknown
        ? (error == null ? Icons.hourglass_empty : Icons.help_outline)
        : authenticated
        ? Icons.verified_user_outlined
        : Icons.gpp_maybe_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        color: accent.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: accent.withValues(alpha: 0.45)),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: accent, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled group of tiles rendered as one card.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.tiles});

  final String title;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 72),
                tiles[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Dashboard row: tinted icon, title, one-line description of what the
/// destination tests, and a trailing affordance.
class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
    this.isDeprecated = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isDeprecated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      shape: const RoundedRectangleBorder(),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isDeprecated) ...[
            const SizedBox(width: 8),
            const _DeprecatedBadge(),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing:
          trailing ??
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

/// Marks the screens backed by deprecated plugin APIs (getStats, getSamples).
class _DeprecatedBadge extends StatelessWidget {
  const _DeprecatedBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        'deprecated',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 10,
        ),
      ),
    );
  }
}
