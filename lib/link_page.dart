import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'platform_data.dart';
import 'ui_widgets.dart';

class LinkGenerator extends StatefulWidget {
  final VoidCallback onToggleTheme;
  const LinkGenerator({super.key, required this.onToggleTheme});
  @override
  LinkGeneratorState createState() => LinkGeneratorState();
}

enum PlatformFilter { all, messages, accounts }

class LinkGeneratorState extends State<LinkGenerator> {
  // ── State ──────────────────────────────────────────────────────────────────
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  SocialPlatform _selected = kAllAppsPlatform; // default: All Apps
  bool _isInit = false;
  int _tabIndex = 0;
  late SharedPreferences _prefs;

  final _textCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _hashtagsCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  List<TextEditingController> get _ctrls => [
        _textCtrl,
        _phoneCtrl,
        _urlCtrl,
        _titleCtrl,
        _hashtagsCtrl,
        _usernameCtrl
      ];

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadPrefs();
    for (final c in _ctrls) {
      c.addListener(_savePrefs);
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final savedName = _prefs.getString('app');
    setState(() {
      _textCtrl.text = _prefs.getString('text') ?? '';
      _phoneCtrl.text = _prefs.getString('phone') ?? '';
      _urlCtrl.text = _prefs.getString('url') ?? '';
      _titleCtrl.text = _prefs.getString('title') ?? '';
      _hashtagsCtrl.text = _prefs.getString('hashtags') ?? '';
      _usernameCtrl.text = _prefs.getString('username') ?? '';
      _selected = kAllPlatforms.firstWhere(
        (p) => p.name == savedName,
        orElse: () => kAllAppsPlatform, // default all platforms
      );
      _isInit = true;
    });
  }

  Future<void> _savePrefs() async {
    if (!_isInit) return;
    await _prefs.setString('text', _textCtrl.text);
    await _prefs.setString('phone', _phoneCtrl.text);
    await _prefs.setString('url', _urlCtrl.text);
    await _prefs.setString('title', _titleCtrl.text);
    await _prefs.setString('hashtags', _hashtagsCtrl.text);
    await _prefs.setString('username', _usernameCtrl.text);
    await _prefs.setString('app', _selected.name);
    setState(() {});
  }

  // ── URL helpers ────────────────────────────────────────────────────────────
  UrlGenerator get _gen => UrlGenerator(
        text: _textCtrl.text,
        phone: _phoneCtrl.text,
        url: _urlCtrl.text,
        title: _titleCtrl.text,
        hashtags: _hashtagsCtrl.text,
        username: _usernameCtrl.text,
      );

  String _webUrl(String platformName) => _gen.webUrl(platformName);

  // ── UI helpers ─────────────────────────────────────────────────────────────
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  void _copyLink(String link) {
    Clipboard.setData(ClipboardData(text: link));
    _snack('Link copied!');
  }

  Future<void> _shareLink(String link) async {
    try {
      await SharePlus.instance.share(ShareParams(text: link));
    } catch (_) {
      _snack('Sharing not supported on this platform');
    }
  }

  /// Tries native deep link on device; falls back to HTTPS web URL.
  ///
  /// On web: URL is computed before any async gaps so Chrome's popup
  /// blocker doesn't intercept the window.open() call.
  Future<void> _launchLink(String platformName) async {
    final link = _webUrl(platformName); // compute synchronously first

    if (kIsWeb) {
      // ignore: unawaited_futures
      _savePrefs(); // fire-and-forget — no async gap before launchUrl
      if (link.isNotEmpty) {
        try {
          await launchUrl(Uri.parse(link),
              mode: LaunchMode.externalApplication);
        } catch (_) {
          _snack('Could not open link');
        }
      }
      return;
    }

    await _savePrefs();

    // Native: try deep link (opens installed app) then HTTPS fallback
    final deep = _gen.deepLink(platformName);
    if (deep.isNotEmpty) {
      try {
        final uri = Uri.parse(deep);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return;
        }
      } catch (_) {}
    }

    if (link.isNotEmpty) {
      try {
        await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
      } catch (_) {
        _snack('Could not open link');
      }
    }
  }

  // ── QR code ────────────────────────────────────────────────────────────────
  Future<File> _generateQRFile(String link) async {
    final res = QrValidator.validate(
        data: link,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.L);
    final painter = QrPainter.withQr(
      qr: res.qrCode!,
      eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square, color: Color(0xFF000000)),
      dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square, color: Color(0xFF000000)),
      gapless: true,
    );
    final picData =
        await painter.toImageData(2048, format: ui.ImageByteFormat.png);
    final buffer = picData!.buffer;
    final dir = await getTemporaryDirectory();
    return File('${dir.path}/qr_code.png').writeAsBytes(
        buffer.asUint8List(picData.offsetInBytes, picData.lengthInBytes));
  }

  void _showQRCode(String link) {
    showDialog(
      context: context,
      builder: (dlg) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('QR Code', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
              height: 240,
              child: QrImageView(
                  data: link,
                  version: QrVersions.auto,
                  size: 240,
                  backgroundColor: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              '${_selected.name} @ ${_usernameCtrl.text.isNotEmpty ? _usernameCtrl.text : _phoneCtrl.text}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share QR',
            onPressed: () async {
              try {
                final file = await _generateQRFile(link);
                await SharePlus.instance.share(ShareParams(
                    files: [XFile(file.path)], text: 'Link QR code'));
              } catch (_) {
                if (!dlg.mounted) return;
                ScaffoldMessenger.of(dlg).showSnackBar(
                    const SnackBar(content: Text('Could not share')));
              }
            },
          ),
          if (!kIsWeb)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Save to Gallery',
              onPressed: () async {
                try {
                  if (Platform.isAndroid || Platform.isIOS) {
                    final file = await _generateQRFile(link);
                    await Gal.putImage(file.path);
                    if (!dlg.mounted) return;
                    ScaffoldMessenger.of(dlg)
                        .showSnackBar(const SnackBar(content: Text('Saved!')));
                  }
                } catch (_) {
                  if (!dlg.mounted) return;
                  ScaffoldMessenger.of(dlg).showSnackBar(
                      const SnackBar(content: Text('Failed to save')));
                }
              },
            ),
          TextButton(
              onPressed: () => Navigator.pop(dlg), child: const Text('Close')),
        ],
      ),
    );
  }

  // ── Help bottom sheet ──────────────────────────────────────────────────────
  void _showHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scroll) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                const Text('🔗', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                const Expanded(
                    child: Text('How it works',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700))),
                Switch(
                  value: Theme.of(context).brightness == Brightness.dark,
                  onChanged: (_) {
                    Navigator.pop(ctx);
                    widget.onToggleTheme();
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(
                'Generate shareable HTTPS links for any social platform — perfect for emails, websites, QR codes, and marketing.',
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF666688), height: 1.4),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
                child: ListView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                  _helpSection('📱 Quick Guide', [
                    _helpItem('1. Enter Details',
                        'Go to the Inputs tab. Type your link, message, or username. You only need to fill in what your chosen app requires.'),
                    _helpItem('2. Choose Platform',
                        'Pick an app from the Messages or Accounts tab.'),
                    _helpItem('3. Share It',
                        'Instantly test the link, copy it, share it, or create a QR code for someone to scan right away.'),
                  ]),
                  _helpSection('💡 Tips', [
                    _helpItem('All Apps Mode',
                        'Select "All Apps" to generate links for every platform at the same time.'),
                    _helpItem('Auto-save',
                        'Your inputs are saved automatically, so you won\'t lose your work when you close the app.'),
                  ]),
                ])),
          ]),
        ),
      ),
    );
  }

  Widget _helpSection(String title, List<Widget> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary)),
          ),
          ...items,
        ],
      );

  Widget _helpItem(String label, String desc) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text(desc,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF888888), height: 1.4)),
        ]),
      );

  // ── Pages ──────────────────────────────────────────────────────────────────
  Widget _buildInputsPage() {
    final isAllApps = _selected.name == 'All Apps';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('PLATFORM FORMAT'),
          const SizedBox(height: 6),
          AppDropdown(
            platforms: kAllPlatforms,
            selected: _selected,
            onChanged: (p) => setState(() {
              _selected = p!;
              _savePrefs();
            }),
          ),
          if (!isAllApps) ...[
            const SizedBox(height: 16),
            const SectionLabel('ACTIONS'),
            const SizedBox(height: 6),
            ActionRow(
              onLaunch: () => _launchLink(_selected.name),
              onShare: () => _shareLink(_webUrl(_selected.name)),
              onCopy: () => _copyLink(_webUrl(_selected.name)),
              onQR: () => _showQRCode(_webUrl(_selected.name)),
            ),
            const SizedBox(height: 16),
            const SectionLabel('GENERATED LINK'),
            const SizedBox(height: 6),
            LinkPreviewCard(
              link: _webUrl(_selected.name),
              onLaunch: () => _launchLink(_selected.name),
              onCopy: () => _copyLink(_webUrl(_selected.name)),
            ),
            const SizedBox(height: 24),
          ],
          const SectionLabel('DETAILS'),
          const SizedBox(height: 6),
          InputCard(
            platform: isAllApps ? kAllAppsPlatform : _selected,
            textCtrl: _textCtrl,
            phoneCtrl: _phoneCtrl,
            urlCtrl: _urlCtrl,
            titleCtrl: _titleCtrl,
            hashtagsCtrl: _hashtagsCtrl,
            usernameCtrl: _usernameCtrl,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('MESSAGING APPS'),
          const SizedBox(height: 8),
          ..._buildCardsList(PlatformFilter.messages),
        ],
      ),
    );
  }

  Widget _buildAccountsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionLabel('ACCOUNT PROFILES'),
          const SizedBox(height: 8),
          ..._buildCardsList(PlatformFilter.accounts),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAllApps = _selected.name == 'All Apps';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 62,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                isDark ? Colors.green.shade900 : Colors.green.shade500
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(mainAxisSize: MainAxisSize.min, children: [
              Text('🔗', style: TextStyle(fontSize: 18)),
              SizedBox(width: 6),
              Text('Social Link Generator',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      letterSpacing: -0.3)),
            ]),
            if (!isAllApps)
              Text('${_selected.name} mode',
                  style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
            tooltip: 'App Info & Theme',
            onPressed: _showHelp,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          _buildInputsPage(),
          _buildMessagesPage(),
          _buildAccountsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (idx) => setState(() => _tabIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note),
            label: 'Create',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_outlined),
            selectedIcon: Icon(Icons.chat),
            label: 'Chats',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profiles',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCardsList(PlatformFilter filter) {
    List<SocialPlatform> orderedPlatforms = [];
    final theme = Theme.of(context);

    if (filter == PlatformFilter.all) {
      orderedPlatforms = kPlatforms;
    } else if (filter == PlatformFilter.messages) {
      final msgsOrder = [
        'WhatsApp',
        'Facebook',
        'LinkedIn',
        'X/Twitter',
        'Telegram',
        'Pinterest',
        'Reddit'
      ];
      orderedPlatforms = msgsOrder
          .map((name) => kPlatforms.firstWhere((p) => p.name == name,
              orElse: () => kPlatforms.first))
          .where((p) => msgsOrder.contains(p.name))
          .toList();
    } else if (filter == PlatformFilter.accounts) {
      final accountsOrder = [
        'Instagram',
        'TikTok',
        'Snapchat',
        'YouTube',
        'Twitch',
        'Discord',
        'Steam',
        'Venmo',
        'Cash App',
        'PayPal',
        'Spotify',
        'GitHub'
      ];
      orderedPlatforms = accountsOrder
          .map((name) => kPlatforms.firstWhere((p) => p.name == name,
              orElse: () => kPlatforms.first))
          .where((p) => accountsOrder.contains(p.name))
          .toList();
    }

    return orderedPlatforms.map((p) {
      final link = _webUrl(p.name);
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: p.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(p.icon, color: p.color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(p.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const Spacer(),
              SmallIconBtn(
                  Icons.open_in_new, 'Open', () => _launchLink(p.name)),
              SmallIconBtn(Icons.share, 'Share', () => _shareLink(link)),
              SmallIconBtn(Icons.copy, 'Copy', () => _copyLink(link)),
              SmallIconBtn(Icons.qr_code, 'QR', () => _showQRCode(link)),
            ]),
            const SizedBox(height: 10),
            TextField(
              controller: TextEditingController(text: link),
              readOnly: true,
              maxLines: null,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF6F5FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: TextStyle(
                color: p.color,
                fontSize: 12,
              ),
            ),
          ]),
        ),
      );
    }).toList();
  }
}
