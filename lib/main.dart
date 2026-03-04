import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'custom_icons.dart';

// ─── Entry point ─────────────────────────────────────────────────────────────
void main() => runApp(const MyApp());

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF6C63FF);
const _kGradEnd = Color(0xFF4A00E0);
const _kBg = Color(0xFFF3F2FF);
const _kSurface = Colors.white;

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Social Link Generator',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: _kPrimary),
            useMaterial3: true),
        home: const LinkGenerator(),
      );
}

// ─── Main page ────────────────────────────────────────────────────────────────
class LinkGenerator extends StatefulWidget {
  const LinkGenerator({super.key});
  @override
  LinkGeneratorState createState() => LinkGeneratorState();
}

class LinkGeneratorState extends State<LinkGenerator> {
  String selectedApp = 'WhatsApp';

  final textController = TextEditingController();
  final phoneController = TextEditingController();
  final urlController = TextEditingController();
  final titleController = TextEditingController();
  final hashtagsController = TextEditingController();

  late SharedPreferences prefs;
  bool _isInit = false;

  List<TextEditingController> get _controllers => [
        textController,
        phoneController,
        urlController,
        titleController,
        hashtagsController
      ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    for (final c in _controllers) c.addListener(_savePrefs);
  }

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    super.dispose();
  }

  // ── Persistence ────────────────────────────────────────────────────────────
  Future<void> _loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      textController.text = prefs.getString('text') ?? '';
      phoneController.text = prefs.getString('phone') ?? '';
      urlController.text = prefs.getString('url') ?? '';
      titleController.text = prefs.getString('title') ?? '';
      hashtagsController.text = prefs.getString('hashtags') ?? '';
      selectedApp = prefs.getString('app') ?? 'WhatsApp';
      if (!_webGenerators.containsKey(selectedApp)) selectedApp = 'WhatsApp';
      _isInit = true;
    });
  }

  Future<void> _savePrefs() async {
    if (!_isInit) return;
    await prefs.setString('text', textController.text);
    await prefs.setString('phone', phoneController.text);
    await prefs.setString('url', urlController.text);
    await prefs.setString('title', titleController.text);
    await prefs.setString('hashtags', hashtagsController.text);
    await prefs.setString('app', selectedApp);
    setState(() {});
  }

  // ── Platform helpers ───────────────────────────────────────────────────────
  final apps = [
    'All Apps',
    'WhatsApp',
    'Facebook',
    'Instagram',
    'LinkedIn',
    'X/Twitter',
    'TikTok',
    'Telegram',
    'Snapchat',
  ];

  ({IconData iconData, Color iconColor}) _appIcon(String app) => switch (app) {
        'WhatsApp' => (
            iconData: Custom.whatsapp,
            iconColor: const Color(0xFF25D366)
          ),
        'Facebook' => (
            iconData: Custom.facebook,
            iconColor: const Color(0xFF1877F2)
          ),
        'Instagram' => (
            iconData: Icons.camera_alt,
            iconColor: const Color(0xFFE1306C)
          ),
        'LinkedIn' => (
            iconData: Custom.linkedin_squared,
            iconColor: const Color(0xFF0A66C2)
          ),
        'X/Twitter' => (
            iconData: Custom.twitter,
            iconColor: const Color(0xFF1DA1F2)
          ),
        'TikTok' => (
            iconData: Icons.music_note,
            iconColor: const Color(0xFF010101)
          ),
        'Telegram' => (
            iconData: Icons.send,
            iconColor: const Color(0xFF2AABEE)
          ),
        'Snapchat' => (
            iconData: Icons.chat_bubble_outline,
            iconColor: const Color(0xFFFFB800)
          ),
        _ => (iconData: Icons.apps, iconColor: _kPrimary),
      };

  // ── HTTPS web sharing URLs (primary displayed/copyable link) ───────────────
  late final _webGenerators = <String, String Function()>{
    'WhatsApp': () {
      final phone = phoneController.text.replaceAll(RegExp(r'[^0-9+]'), '');
      final text = Uri.encodeComponent(textController.text);
      return 'https://wa.me/$phone?text=$text';
    },
    'Facebook': () {
      final u = Uri.encodeComponent(urlController.text);
      final q = textController.text.isNotEmpty
          ? '&quote=${Uri.encodeComponent(textController.text)}'
          : '';
      return 'https://www.facebook.com/sharer/sharer.php?u=$u$q';
    },
    'Instagram': () {
      final user = urlController.text.replaceAll('@', '');
      return user.isNotEmpty
          ? 'https://www.instagram.com/$user'
          : 'https://www.instagram.com';
    },
    'LinkedIn': () {
      final u = Uri.encodeComponent(urlController.text);
      final t = titleController.text.isNotEmpty
          ? '&title=${Uri.encodeComponent(titleController.text)}'
          : '';
      final s = textController.text.isNotEmpty
          ? '&summary=${Uri.encodeComponent(textController.text)}'
          : '';
      return 'https://www.linkedin.com/sharing/share-offsite/?url=$u$t$s';
    },
    'X/Twitter': () {
      final text = Uri.encodeComponent(textController.text);
      final url = urlController.text.isNotEmpty
          ? '&url=${Uri.encodeComponent(urlController.text)}'
          : '';
      final tags = hashtagsController.text.isNotEmpty
          ? '&hashtags=${Uri.encodeComponent(hashtagsController.text.replaceAll('#', '').replaceAll(' ', ''))}'
          : '';
      return 'https://x.com/intent/post?text=$text$url$tags';
    },
    'TikTok': () {
      final user = urlController.text.replaceAll('@', '');
      return user.isNotEmpty
          ? 'https://www.tiktok.com/@$user'
          : 'https://www.tiktok.com';
    },
    'Telegram': () {
      if (phoneController.text.isNotEmpty && urlController.text.isEmpty) {
        final t = textController.text.isNotEmpty
            ? '?text=${Uri.encodeComponent(textController.text)}'
            : '';
        return 'https://t.me/${phoneController.text}$t';
      }
      final url = Uri.encodeComponent(urlController.text);
      final text = Uri.encodeComponent(textController.text);
      return 'https://t.me/share/url?url=$url&text=$text';
    },
    'Snapchat': () {
      final user = urlController.text.replaceAll('@', '');
      return user.isNotEmpty
          ? 'https://www.snapchat.com/add/$user'
          : 'https://www.snapchat.com';
    },
  };

  // ── Native deep-link schemes (tries to open installed app) ─────────────────
  String _deepLinkUrl(String app) => switch (app) {
        'WhatsApp' =>
          'whatsapp://send?phone=${phoneController.text}&text=${Uri.encodeComponent(textController.text)}',
        'Facebook' =>
          'fb://facewebmodal/f?href=${Uri.encodeComponent(urlController.text)}',
        'Instagram' =>
          'instagram://user?username=${urlController.text.replaceAll("@", "")}',
        'LinkedIn' =>
          'linkedin://shareArticle?mini=true&url=${Uri.encodeComponent(urlController.text)}',
        'X/Twitter' =>
          'twitter://post?message=${Uri.encodeComponent(textController.text)}',
        'TikTok' => 'tiktok://user?user_id=${urlController.text}',
        'Telegram' =>
          'tg://resolve?domain=${phoneController.text}&text=${Uri.encodeComponent(textController.text)}',
        'Snapchat' => 'snapchat://add/${urlController.text}',
        _ => '',
      };

  String _generatedLink(String app) => _webGenerators[app]!();

  // ── Actions ───────────────────────────────────────────────────────────────
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

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

  /// Tries native deep link first (on device), falls back to HTTPS URL.
  Future<void> _launchLink(String app) async {
    await _savePrefs();

    if (!kIsWeb) {
      final deep = _deepLinkUrl(app);
      if (deep.isNotEmpty) {
        try {
          final uri = Uri.parse(deep);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
            return;
          }
        } catch (_) {}
      }
    }

    // HTTPS fallback
    final webUrl = _generatedLink(app);
    try {
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    } catch (_) {
      _snack('Could not open link');
    }
  }

  // ── QR code ───────────────────────────────────────────────────────────────
  Future<File> _generateQRImageFile(String link) async {
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
                final file = await _generateQRImageFile(link);
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
                    final status = await Permission.storage.request();
                    if (!dlg.mounted) return;
                    if (status.isGranted) {
                      final file = await _generateQRImageFile(link);
                      final result =
                          await ImageGallerySaver.saveFile(file.path);
                      if (!dlg.mounted) return;
                      ScaffoldMessenger.of(dlg).showSnackBar(SnackBar(
                        content: Text(result['isSuccess'] == true
                            ? 'Saved!'
                            : 'Save failed'),
                      ));
                    } else {
                      ScaffoldMessenger.of(dlg).showSnackBar(
                          const SnackBar(content: Text('Permission required')));
                    }
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

  // ── Help sheet ────────────────────────────────────────────────────────────
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
            color: _kSurface,
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
                'Generate shareable web links for any social platform — perfect for emails, websites, QR codes, and marketing.',
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
                        'Pre-fills a message. Works with WhatsApp, Facebook (quote), X/Twitter, LinkedIn, Telegram.'),
                    _helpItem('URL / Link',
                        'The page to share. Used by Facebook, LinkedIn, X/Twitter, Telegram.'),
                    _helpItem('Phone Number',
                        'WhatsApp recipient phone (include country code, e.g. +1 234 567 8900).'),
                    _helpItem('Username / Domain',
                        'Telegram username or Instagram/TikTok/Snapchat handle (no @ needed).'),
                  ]),
                  _helpSection('📱 Platform Guide', [
                    _helpItem('WhatsApp 💬',
                        'Generates wa.me link — opens a chat to a number with a pre-filled message.'),
                    _helpItem('Facebook 👍',
                        'Uses Facebook Sharer — share any web URL with an optional caption/quote.'),
                    _helpItem('Instagram 📸',
                        'Links to an Instagram profile. Enter the username in the URL field.'),
                    _helpItem('LinkedIn 💼',
                        'Uses share-offsite API — share a URL with optional title and summary.'),
                    _helpItem('X / Twitter 🐦',
                        'Pre-fills a Tweet with message, link, and hashtags (comma-separated, no #).'),
                    _helpItem('TikTok 🎵',
                        'Links to a TikTok profile. Enter the username in the URL field.'),
                    _helpItem('Telegram ✈️',
                        'Enter a username to link to their profile, or a URL to share via the share bot.'),
                    _helpItem('Snapchat 👻',
                        'Links to a Snapchat profile. Enter the username in the URL field.'),
                  ]),
                  _helpSection('🛠 Actions', [
                    _helpItem('Launch',
                        'Opens the link. On mobile, tries the native app first — falls back to the browser.'),
                    _helpItem('Share',
                        'Opens your device share sheet to send the link to contacts or other apps.'),
                    _helpItem('Copy',
                        'Copies the HTTPS link to clipboard — paste it anywhere.'),
                    _helpItem('QR Code',
                        'Creates a scannable QR code you can share or save to your gallery.'),
                  ]),
                  _helpSection('💡 Tips', [
                    _helpItem('All Apps mode',
                        'Select "All Apps" to generate links for every platform at once.'),
                    _helpItem('Selectable links',
                        'Tap and hold the generated link text to select and copy any portion.'),
                    _helpItem('Auto-save',
                        'All fields save automatically — they\'ll still be there next time you open the app.'),
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
                    color: _kPrimary)),
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

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        toolbarHeight: 62,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [_kPrimary, _kGradEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
        ),
        title: const Row(mainAxisSize: MainAxisSize.min, children: [
          Text('🔗', style: TextStyle(fontSize: 22)),
          SizedBox(width: 8),
          Text('Social Link Generator',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.3)),
        ]),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionLabel('PLATFORM'),
            const SizedBox(height: 6),
            _AppDropdown(
              apps: apps,
              selectedApp: selectedApp,
              appIconFn: _appIcon,
              onChanged: (v) => setState(() {
                selectedApp = v!;
                _savePrefs();
              }),
            ),
            const SizedBox(height: 16),
            if (selectedApp != 'All Apps') ...[
              _SectionLabel('DETAILS'),
              const SizedBox(height: 6),
              _InputCard(
                selectedApp: selectedApp,
                textController: textController,
                phoneController: phoneController,
                urlController: urlController,
                titleController: titleController,
                hashtagsController: hashtagsController,
              ),
              const SizedBox(height: 16),
              _ActionRow(
                onLaunch: () => _launchLink(selectedApp),
                onShare: () => _shareLink(_generatedLink(selectedApp)),
                onCopy: () => _copyLink(_generatedLink(selectedApp)),
                onQR: () => _showQRCode(_generatedLink(selectedApp)),
              ),
              const SizedBox(height: 16),
              _SectionLabel('GENERATED LINK'),
              const SizedBox(height: 6),
              _LinkPreviewCard(
                link: _generatedLink(selectedApp),
                onLaunch: () => _launchLink(selectedApp),
                onCopy: () => _copyLink(_generatedLink(selectedApp)),
              ),
            ] else ...[
              _SectionLabel('ALL PLATFORMS'),
              const SizedBox(height: 6),
              ..._buildAllAppsCards(),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAllAppsCards() =>
      apps.where((a) => a != 'All Apps').map((app) {
        final link = _generatedLink(app);
        final ic = _appIcon(app);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Header row: icon + name + action buttons
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: ic.iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(ic.iconData, color: ic.iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(app,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const Spacer(),
                _SmallIconBtn(
                    Icons.open_in_new, 'Open', () => _launchLink(app)),
                _SmallIconBtn(Icons.share, 'Share', () => _shareLink(link)),
                _SmallIconBtn(Icons.copy, 'Copy', () => _copyLink(link)),
                _SmallIconBtn(Icons.qr_code, 'QR', () => _showQRCode(link)),
              ]),
              const SizedBox(height: 10),
              // Selectable link text
              SelectableText(
                link,
                style: TextStyle(
                  color: ic.iconColor,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: ic.iconColor,
                ),
                onTap: () => _launchLink(app),
              ),
            ]),
          ),
        );
      }).toList();
}

// ─── Reusable widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9E9BB5),
            letterSpacing: 1.2),
      );
}

class _SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _SmallIconBtn(this.icon, this.tooltip, this.onTap);
  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(icon, size: 18, color: Colors.grey.shade500)),
        ),
      );
}

class _AppDropdown extends StatelessWidget {
  final List<String> apps;
  final String selectedApp;
  final ({IconData iconData, Color iconColor}) Function(String) appIconFn;
  final ValueChanged<String?> onChanged;
  const _AppDropdown(
      {required this.apps,
      required this.selectedApp,
      required this.appIconFn,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: _kSurface, borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedApp,
            isExpanded: true,
            icon:
                const Icon(Icons.keyboard_arrow_down_rounded, color: _kPrimary),
            items: apps.map((app) {
              final ic = appIconFn(app);
              return DropdownMenuItem(
                value: app,
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: ic.iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10)),
                    child: Icon(ic.iconData, color: ic.iconColor, size: 17),
                  ),
                  const SizedBox(width: 12),
                  Text(app,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15)),
                ]),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      );
}

class _InputCard extends StatelessWidget {
  final String selectedApp;
  final TextEditingController textController,
      phoneController,
      urlController,
      titleController,
      hashtagsController;
  const _InputCard({
    required this.selectedApp,
    required this.textController,
    required this.phoneController,
    required this.urlController,
    required this.titleController,
    required this.hashtagsController,
  });

  @override
  Widget build(BuildContext context) {
    final showText = !['Snapchat', 'TikTok', 'Instagram'].contains(selectedApp);
    final showPhone = ['WhatsApp', 'Telegram'].contains(selectedApp);
    final showUrl = selectedApp != 'WhatsApp';
    final showTitle = selectedApp == 'LinkedIn';
    final showHashtags = selectedApp == 'X/Twitter';

    String urlLabel() => switch (selectedApp) {
          'Snapchat' => 'Snapchat Username',
          'TikTok' => 'TikTok Username',
          'Instagram' => 'Instagram Username',
          _ => 'URL / Link',
        };

    const fill = Color(0xFFF6F5FF);
    const border =
        OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)));
    const eBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: Color(0xFFE0DEFF)),
    );

    Widget field(TextEditingController ctrl, String label,
            {IconData? prefix, int maxLines = 1, TextInputType? kbd}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: kbd,
            decoration: InputDecoration(
              labelText: label,
              filled: true,
              fillColor: fill,
              border: border,
              enabledBorder: eBorder,
              prefixIcon: prefix != null ? Icon(prefix, size: 20) : null,
            ),
          ),
        );

    return Container(
      decoration: BoxDecoration(
          color: _kSurface, borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (showText)
          field(textController,
              selectedApp == 'Facebook' ? 'Caption / Quote' : 'Text / Message',
              maxLines: 3),
        if (showPhone)
          field(phoneController,
              selectedApp == 'Telegram' ? 'Username / Domain' : 'Phone Number',
              prefix: Icons.phone_outlined, kbd: TextInputType.phone),
        if (showUrl)
          field(urlController, urlLabel(),
              prefix: Icons.link_outlined, kbd: TextInputType.url),
        if (showTitle)
          field(titleController, 'Article Title', prefix: Icons.title),
        if (showHashtags)
          field(hashtagsController, 'Hashtags (comma-separated, no #)',
              prefix: Icons.tag),
      ]),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final VoidCallback onLaunch, onShare, onCopy, onQR;
  const _ActionRow(
      {required this.onLaunch,
      required this.onShare,
      required this.onCopy,
      required this.onQR});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
            child: _ActionBtn('Launch', Icons.open_in_new,
                const Color(0xFF6C63FF), onLaunch)),
        const SizedBox(width: 8),
        Expanded(
            child: _ActionBtn(
                'Share', Icons.share, const Color(0xFF11998E), onShare)),
        const SizedBox(width: 8),
        Expanded(
            child: _ActionBtn(
                'Copy', Icons.copy, const Color(0xFFFF6B6B), onCopy)),
        const SizedBox(width: 8),
        Expanded(
            child:
                _ActionBtn('QR', Icons.qr_code, const Color(0xFF4A90D9), onQR)),
      ]);
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.label, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Material(
        color: color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 5),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3)),
            ]),
          ),
        ),
      );
}

class _LinkPreviewCard extends StatelessWidget {
  final String link;
  final VoidCallback onLaunch;
  final VoidCallback onCopy;
  const _LinkPreviewCard(
      {required this.link, required this.onLaunch, required this.onCopy});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kPrimary.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(children: [
            const Icon(Icons.link, size: 15, color: _kPrimary),
            const SizedBox(width: 6),
            const Text('Generated Link',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary,
                    letterSpacing: 0.5)),
            const Spacer(),
            // Open button
            GestureDetector(
              onTap: onLaunch,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.open_in_new, size: 12, color: _kPrimary),
                  SizedBox(width: 4),
                  Text('Open',
                      style: TextStyle(
                          fontSize: 11,
                          color: _kPrimary,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
            // Copy button
            GestureDetector(
              onTap: onCopy,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.copy, size: 12, color: Color(0xFFFF6B6B)),
                  SizedBox(width: 4),
                  Text('Copy',
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF6B6B),
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          // Selectable HTTPS link
          SelectableText(
            link,
            style: const TextStyle(
              color: _kPrimary,
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: _kPrimary,
            ),
            onTap: onLaunch,
          ),
        ]),
      );
}
