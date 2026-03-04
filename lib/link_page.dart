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

import 'app_constants.dart';
import 'platform_data.dart';
import 'ui_widgets.dart';

// ─── Widget ───────────────────────────────────────────────────────────────────
class LinkGenerator extends StatefulWidget {
  const LinkGenerator({super.key});
  @override
  LinkGeneratorState createState() => LinkGeneratorState();
}

class LinkGeneratorState extends State<LinkGenerator> {
  // ── State ──────────────────────────────────────────────────────────────────
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  SocialPlatform _selected = kAllAppsPlatform; // default: All Apps
  bool _isInit = false;
  late SharedPreferences _prefs;

  final _textCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _hashtagsCtrl = TextEditingController();

  List<TextEditingController> get _ctrls =>
      [_textCtrl, _phoneCtrl, _urlCtrl, _titleCtrl, _hashtagsCtrl];

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
      _selected = kAllPlatforms.firstWhere(
        (p) => p.name == savedName,
        orElse: () => kAllAppsPlatform, // default all platforms
      );
      _isInit = true;
    });
    // Auto-open the customize drawer on first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openDrawer();
    });
  }

  Future<void> _savePrefs() async {
    if (!_isInit) return;
    await _prefs.setString('text', _textCtrl.text);
    await _prefs.setString('phone', _phoneCtrl.text);
    await _prefs.setString('url', _urlCtrl.text);
    await _prefs.setString('title', _titleCtrl.text);
    await _prefs.setString('hashtags', _hashtagsCtrl.text);
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

  void _openDrawer() => _scaffoldKey.currentState?.openEndDrawer();

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
        content: SizedBox(
          width: 240,
          height: 240,
          child: QrImageView(
              data: link,
              version: QrVersions.auto,
              size: 240,
              backgroundColor: Colors.white),
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
          decoration: const BoxDecoration(
            color: kSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Text('🔗', style: TextStyle(fontSize: 24)),
                SizedBox(width: 10),
                Expanded(
                    child: Text('How it works',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700))),
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
                  _helpSection('📋 Common Fields', [
                    _helpItem('Text / Message',
                        'Pre-fills a message. Works with WhatsApp, Facebook, X/Twitter, LinkedIn, Telegram.'),
                    _helpItem('URL / Link',
                        'The page to share. Used by Facebook, LinkedIn, X/Twitter, Telegram, Pinterest, Reddit.'),
                    _helpItem('Phone Number',
                        'WhatsApp recipient phone (include country code, e.g. +1 234 567 8900).'),
                    _helpItem('Username',
                        'Used by Instagram, TikTok, Snapchat, and Telegram for profile links.'),
                  ]),
                  _helpSection('📱 Platform Guide', [
                    _helpItem('WhatsApp 💬',
                        'wa.me link — opens a chat with a pre-filled message.'),
                    _helpItem('Facebook 👍',
                        'Sharer — shares a URL with optional caption.'),
                    _helpItem('Instagram 📸',
                        'Profile link via username (no web share API).'),
                    _helpItem('LinkedIn 💼',
                        'share-offsite — shares a URL with title and summary.'),
                    _helpItem('X / Twitter 🐦',
                        'intent/tweet — pre-fills message, URL, and hashtags.'),
                    _helpItem('TikTok 🎵',
                        'Profile link via username (no web share API).'),
                    _helpItem('Telegram ✈️',
                        'Username → profile link. URL → t.me/share/url.'),
                    _helpItem('Snapchat 👻',
                        'Profile link via username (no web share API).'),
                    _helpItem('Pinterest 📌',
                        'pin/create/button — pins a URL with a description.'),
                    _helpItem('Reddit 🤖',
                        'reddit.com/submit — submits a URL with a post title.'),
                  ]),
                  _helpSection('🛠 Actions', [
                    _helpItem('Launch',
                        'On mobile, tries native app first — falls back to browser.'),
                    _helpItem('Share',
                        'Opens device share sheet with the generated link.'),
                    _helpItem('Copy', 'Copies the HTTPS URL to clipboard.'),
                    _helpItem('QR',
                        'Shows a scannable QR code you can share or save.'),
                  ]),
                  _helpSection('💡 Tips', [
                    _helpItem('Customize drawer',
                        'Tap the ✦ button in the AppBar to open the input panel.'),
                    _helpItem('All Apps mode',
                        '"All Apps" generates links for every platform at once.'),
                    _helpItem('Selectable links',
                        'Tap & hold any link to select and copy a portion.'),
                    _helpItem('Auto-save',
                        'All inputs save automatically and restore on next launch.'),
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
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: kPrimary)),
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

  // ── Customize drawer (input panel) ─────────────────────────────────────────
  Widget _buildInputDrawer() {
    return Drawer(
      width: 340,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gradient header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary, kGradEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 52, 12, 20),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🎛️', style: TextStyle(fontSize: 28)),
                      SizedBox(height: 10),
                      Text('Customize',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700)),
                      Text('Fill in your details',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ]),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
          ),

          // Scrollable inputs
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionLabel('PLATFORM'),
                    const SizedBox(height: 6),
                    AppDropdown(
                      platforms: kAllPlatforms,
                      selected: _selected,
                      onChanged: (p) => setState(() {
                        _selected = p!;
                        _savePrefs();
                      }),
                    ),
                    const SizedBox(height: 16),
                    const SectionLabel('DETAILS'),
                    const SizedBox(height: 6),
                    // Show all fields when "All Apps" is selected so each platform
                    // can pick up what it needs. Individual platforms show their own fields.
                    InputCard(
                      platform: _selected.name == 'All Apps'
                          ? kAllAppsPlatform
                          : _selected,
                      textCtrl: _textCtrl,
                      phoneCtrl: _phoneCtrl,
                      urlCtrl: _urlCtrl,
                      titleCtrl: _titleCtrl,
                      hashtagsCtrl: _hashtagsCtrl,
                    ),
                  ]),
            ),
          ),

          // Apply / Done button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Done'),
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
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

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: kBg,
      endDrawer: _buildInputDrawer(),
      appBar: AppBar(
        toolbarHeight: 62,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimary, kGradEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Show selected platform name in subtitle when not All Apps
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
          // Customize button — opens input drawer
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            tooltip: 'Customize inputs',
            onPressed: _openDrawer,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'How to use',
            onPressed: _showHelp,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (isAllApps) ...[
            // ── All platforms view ─────────────────────────────────────────
            Row(children: [
              const SectionLabel('ALL PLATFORMS'),
              const Spacer(),
              GestureDetector(
                onTap: _openDrawer,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.tune_rounded, size: 13, color: kPrimary),
                    SizedBox(width: 4),
                    Text('Edit inputs',
                        style: TextStyle(
                            fontSize: 11,
                            color: kPrimary,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            ..._buildAllAppsCards(),
          ] else ...[
            // ── Single platform view ───────────────────────────────────────
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
          ],
        ]),
      ),
    );
  }

  List<Widget> _buildAllAppsCards() => kPlatforms.map((p) {
        final link = _webUrl(p.name);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
                color: kSurface, borderRadius: BorderRadius.circular(18)),
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
