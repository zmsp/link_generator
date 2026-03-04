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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deep Link Generator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LinkGenerator(),
    );
  }
}

class LinkGenerator extends StatefulWidget {
  const LinkGenerator({super.key});
  @override
  LinkGeneratorState createState() => LinkGeneratorState();
}

class LinkGeneratorState extends State<LinkGenerator> {
  String selectedApp = 'WhatsApp';

  // Helper: returns icon + color for a given app name
  ({IconData iconData, Color iconColor}) _appIcon(String app) {
    switch (app) {
      case 'WhatsApp':
        return (iconData: Custom.whatsapp, iconColor: Colors.green);
      case 'Facebook':
        return (iconData: Custom.facebook, iconColor: Colors.blue);
      case 'Instagram':
        return (iconData: Icons.camera_alt, iconColor: Colors.purple);
      case 'LinkedIn':
        return (
          iconData: Custom.linkedin_squared,
          iconColor: Colors.blueAccent
        );
      case 'X/Twitter':
        return (iconData: Custom.twitter, iconColor: Colors.lightBlueAccent);
      case 'TikTok':
        return (iconData: Icons.music_note, iconColor: Colors.black);
      case 'Telegram':
        return (iconData: Icons.send, iconColor: Colors.blue);
      case 'Snapchat':
        return (
          iconData: Icons.chat_bubble_outline,
          iconColor: Colors.yellow.shade700
        );
      default:
        return (iconData: Icons.apps, iconColor: Colors.grey);
    }
  }

  List<Widget> _buildSingleAppView() {
    return [
      Text('Generated Link Preview:',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      SelectableText(
        generators[selectedApp]!(),
        style: const TextStyle(
            color: Colors.blue, decoration: TextDecoration.underline),
        textAlign: TextAlign.center,
      ),
    ];
  }

  List<Widget> _buildAllAppsView() {
    final appNames = apps.where((a) => a != 'All Apps').toList();
    return [
      Text('All Generated Links:',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      ...appNames.map((app) {
        final link = generators[app]!();
        final icon = _appIcon(app);
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: Icon(icon.iconData, color: icon.iconColor, size: 28),
            title:
                Text(app, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              link,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.blue, decoration: TextDecoration.underline),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.share, size: 20),
                  tooltip: 'Share',
                  onPressed: () => _shareLink(link),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  tooltip: 'Copy',
                  onPressed: () => _copyToClipboard(link),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code, size: 20),
                  tooltip: 'QR Code',
                  onPressed: () => _showQRCode(link),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }

  final TextEditingController textController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController urlController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController hashtagsController = TextEditingController();

  late SharedPreferences prefs;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();

    textController.addListener(_savePrefs);
    phoneController.addListener(_savePrefs);
    urlController.addListener(_savePrefs);
    titleController.addListener(_savePrefs);
    hashtagsController.addListener(_savePrefs);
  }

  @override
  void dispose() {
    textController.dispose();
    phoneController.dispose();
    urlController.dispose();
    titleController.dispose();
    hashtagsController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      textController.text = prefs.getString('text') ?? '';
      phoneController.text = prefs.getString('phone') ?? '';
      urlController.text = prefs.getString('url') ?? '';
      titleController.text = prefs.getString('title') ?? '';
      hashtagsController.text = prefs.getString('hashtags') ?? '';
      selectedApp = prefs.getString('app') ?? 'WhatsApp';
      if (!generators.containsKey(selectedApp)) selectedApp = 'WhatsApp';
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
    setState(() {}); // Update the preview link
  }

  final List<String> apps = [
    'All Apps',
    'WhatsApp',
    'Facebook',
    'Instagram',
    'LinkedIn',
    'X/Twitter',
    'TikTok',
    'Telegram',
    'Snapchat'
  ];

  late final Map<String, String Function()> generators = {
    'WhatsApp': () =>
        'whatsapp://send?text=${Uri.encodeComponent(textController.text)}${phoneController.text.isNotEmpty ? '&phone=${phoneController.text}' : ''}',
    'Facebook': () {
      final href = Uri.encodeComponent(urlController.text);
      final quote = textController.text.isNotEmpty
          ? '&quote=${Uri.encodeComponent(textController.text)}'
          : '';
      return 'fb://facewebmodal/f?href=$href$quote';
    },
    'Instagram': () =>
        'instagram-stories://share?source_application=${Uri.encodeComponent(urlController.text)}',
    'LinkedIn': () {
      final url = Uri.encodeComponent(urlController.text);
      final summary = Uri.encodeComponent(textController.text);
      final title = titleController.text.isNotEmpty
          ? '&title=${Uri.encodeComponent(titleController.text)}'
          : '';
      return 'linkedin://shareArticle?mini=true&url=$url&summary=$summary$title';
    },
    'X/Twitter': () {
      final msg = Uri.encodeComponent(textController.text);
      final url = urlController.text.isNotEmpty
          ? '&url=${Uri.encodeComponent(urlController.text)}'
          : '';
      final tags = hashtagsController.text.isNotEmpty
          ? '&hashtags=${Uri.encodeComponent(hashtagsController.text.replaceAll('#', ''))}'
          : '';
      return 'twitter://post?message=$msg$url$tags';
    },
    'TikTok': () =>
        'tiktok://user?user_id=${Uri.encodeComponent(urlController.text)}',
    'Telegram': () =>
        'tg://resolve?domain=${phoneController.text}&text=${Uri.encodeComponent(textController.text)}',
    'Snapchat': () =>
        'snapchat://add/${Uri.encodeComponent(urlController.text)}',
  };

  void _copyToClipboard(String link) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard')),
    );
  }

  Future<void> _shareLink(String link) async {
    try {
      await SharePlus.instance.share(ShareParams(text: link));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing not supported on this platform')),
      );
    }
  }

  Future<File> _generateQRImageFile(String link) async {
    final qrValidationResult = QrValidator.validate(
      data: link,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.L,
    );
    final qrCode = qrValidationResult.qrCode;
    final painter = QrPainter.withQr(
      qr: qrCode!,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF000000),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF000000),
      ),
      gapless: true,
    );

    final picData =
        await painter.toImageData(2048, format: ui.ImageByteFormat.png);
    final buffer = picData!.buffer;
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/qr_code.png').writeAsBytes(
        buffer.asUint8List(picData.offsetInBytes, picData.lengthInBytes));
    return file;
  }

  void _showQRCode(String link) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('QR Code'),
        content: SizedBox(
          width: 250,
          height: 250,
          child: QrImageView(
            data: link,
            version: QrVersions.auto,
            size: 250.0,
            backgroundColor: Colors.white,
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          IconButton(
            onPressed: () async {
              try {
                final file = await _generateQRImageFile(link);
                await SharePlus.instance.share(
                  ShareParams(
                    files: [XFile(file.path)],
                    text: 'Check out this deep link QR code!',
                  ),
                );
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Failed to share QR code.')),
                );
              }
            },
            icon: const Icon(Icons.share),
            tooltip: 'Share',
          ),
          IconButton(
            onPressed: () async {
              try {
                if (Platform.isAndroid || Platform.isIOS) {
                  var status = await Permission.storage.request();
                  if (!dialogContext.mounted) return;
                  if (status.isGranted) {
                    final file = await _generateQRImageFile(link);
                    final result = await ImageGallerySaver.saveFile(file.path);
                    if (!dialogContext.mounted) return;
                    if (result['isSuccess'] == true) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                            content: Text('QR code saved to gallery!')),
                      );
                    } else {
                      throw Exception('Save failed');
                    }
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                          content: Text('Storage permission required.')),
                    );
                  }
                }
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Failed to save QR code.')),
                );
              }
            },
            icon: const Icon(Icons.download),
            tooltip: 'Save',
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndLaunch() async {
    await _savePrefs();
    final link = generators[selectedApp]!();
    final uri = Uri.parse(link);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App not installed, use web fallback')),
      );
      // Fallback web logic
      String webUrl = '';
      if (selectedApp == 'WhatsApp') {
        webUrl =
            'https://wa.me/${phoneController.text}?text=${Uri.encodeComponent(textController.text)}';
      } else if (selectedApp == 'Facebook') {
        final quote = textController.text.isNotEmpty
            ? '&quote=${Uri.encodeComponent(textController.text)}'
            : '';
        webUrl =
            'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(urlController.text)}$quote';
      } else if (selectedApp == 'X/Twitter') {
        final url = urlController.text.isNotEmpty
            ? '&url=${Uri.encodeComponent(urlController.text)}'
            : '';
        final tags = hashtagsController.text.isNotEmpty
            ? '&hashtags=${Uri.encodeComponent(hashtagsController.text.replaceAll('#', ''))}'
            : '';
        webUrl =
            'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(textController.text)}$url$tags';
      } else if (selectedApp == 'LinkedIn') {
        final title = titleController.text.isNotEmpty
            ? '&title=${Uri.encodeComponent(titleController.text)}'
            : '';
        webUrl =
            'https://www.linkedin.com/shareArticle?mini=true&url=${Uri.encodeComponent(urlController.text)}&summary=${Uri.encodeComponent(textController.text)}$title';
      } else if (selectedApp == 'Telegram') {
        webUrl =
            'https://t.me/share/url?url=${Uri.encodeComponent(urlController.text)}&text=${Uri.encodeComponent(textController.text)}';
      }

      if (webUrl.isNotEmpty) {
        final webUri = Uri.parse(webUrl);
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Deep Link Generator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InputDecorator(
              decoration: const InputDecoration(
                  labelText: 'Select App', border: OutlineInputBorder()),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedApp,
                  isDense: true,
                  items: apps.map((app) {
                    final icon = _appIcon(app);
                    return DropdownMenuItem(
                        value: app,
                        child: Row(
                          children: [
                            Icon(icon.iconData, color: icon.iconColor),
                            const SizedBox(width: 10),
                            Text(app),
                          ],
                        ));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedApp = value!;
                      _savePrefs();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: const Text('Input Fields'),
              initiallyExpanded: true,
              children: [
                // Text/Message — hidden for Snapchat/TikTok/Instagram (unused)
                if (!['Snapchat', 'TikTok', 'Instagram', 'All Apps']
                    .contains(selectedApp))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4.0),
                    child: TextFormField(
                      controller: textController,
                      decoration: InputDecoration(
                          labelText: selectedApp == 'Facebook'
                              ? 'Caption / Quote'
                              : 'Text / Message',
                          border: const OutlineInputBorder()),
                      maxLines: 3,
                    ),
                  ),
                // Phone / Username — WhatsApp & Telegram only
                if (['WhatsApp', 'Telegram', 'All Apps'].contains(selectedApp))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4.0),
                    child: TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                          labelText: selectedApp == 'Telegram'
                              ? 'Username / Domain'
                              : 'Phone Number',
                          border: const OutlineInputBorder()),
                    ),
                  ),
                // URL field — all except WhatsApp
                if (!['WhatsApp'].contains(selectedApp))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4.0),
                    child: TextFormField(
                      controller: urlController,
                      keyboardType: TextInputType.url,
                      decoration: InputDecoration(
                          labelText: selectedApp == 'Snapchat'
                              ? 'Snapchat Username'
                              : selectedApp == 'TikTok'
                                  ? 'TikTok User ID'
                                  : selectedApp == 'Instagram'
                                      ? 'Source App URL'
                                      : 'URL / Link',
                          border: const OutlineInputBorder()),
                    ),
                  ),
                // Article Title — LinkedIn only
                if (['LinkedIn', 'All Apps'].contains(selectedApp))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4.0),
                    child: TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                          labelText: 'Article Title (LinkedIn)',
                          border: OutlineInputBorder()),
                    ),
                  ),
                // Hashtags — X/Twitter only
                if (['X/Twitter', 'All Apps'].contains(selectedApp))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4.0),
                    child: TextFormField(
                      controller: hashtagsController,
                      decoration: const InputDecoration(
                          labelText: 'Hashtags (X/Twitter, comma-separated)',
                          hintText: 'flutter, opensource',
                          border: OutlineInputBorder()),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            if (selectedApp != 'All Apps')
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _generateAndLaunch,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Launch'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _shareLink(generators[selectedApp]!()),
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _copyToClipboard(generators[selectedApp]!()),
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showQRCode(generators[selectedApp]!()),
                    icon: const Icon(Icons.qr_code),
                    label: const Text('QR'),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            if (selectedApp == 'All Apps')
              ..._buildAllAppsView()
            else
              ..._buildSingleAppView(),
          ],
        ),
      ),
    );
  }
}
