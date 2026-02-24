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
  const MyApp({Key? key}) : super(key: key);
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
  const LinkGenerator({Key? key}) : super(key: key);
  @override
  _LinkGeneratorState createState() => _LinkGeneratorState();
}

class _LinkGeneratorState extends State<LinkGenerator> {
  String selectedApp = 'WhatsApp';
  final TextEditingController textController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController urlController = TextEditingController();

  late SharedPreferences prefs;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();

    textController.addListener(_savePrefs);
    phoneController.addListener(_savePrefs);
    urlController.addListener(_savePrefs);
  }

  @override
  void dispose() {
    textController.dispose();
    phoneController.dispose();
    urlController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      textController.text = prefs.getString('text') ?? '';
      phoneController.text = prefs.getString('phone') ?? '';
      urlController.text = prefs.getString('url') ?? '';
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
    await prefs.setString('app', selectedApp);
    setState(() {}); // Update the preview link
  }

  final List<String> apps = [
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
    'Facebook': () =>
        'fb://facewebmodal/f?href=${Uri.encodeComponent(urlController.text)}',
    'Instagram': () =>
        'instagram-stories://share?source_application=${Uri.encodeComponent(urlController.text)}',
    'LinkedIn': () =>
        'linkedin://shareArticle?mini=true&url=${Uri.encodeComponent(urlController.text)}&summary=${Uri.encodeComponent(textController.text)}',
    'X/Twitter': () =>
        'twitter://post?message=${Uri.encodeComponent(textController.text)}',
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
      builder: (context) => AlertDialog(
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
                ScaffoldMessenger.of(context).showSnackBar(
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
                  if (status.isGranted) {
                    final file = await _generateQRImageFile(link);
                    final result = await ImageGallerySaver.saveFile(file.path);
                    if (result['isSuccess'] == true) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('QR code saved to gallery!')),
                      );
                    } else {
                      throw Exception('Save failed');
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Storage permission required.')),
                    );
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to save QR code.')),
                );
              }
            },
            icon: const Icon(Icons.download),
            tooltip: 'Save',
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App not installed, use web fallback')),
      );
      // Fallback web logic
      String webUrl = '';
      if (selectedApp == 'WhatsApp')
        webUrl =
            'https://wa.me/${phoneController.text}?text=${Uri.encodeComponent(textController.text)}';
      else if (selectedApp == 'Facebook')
        webUrl =
            'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(urlController.text)}';
      else if (selectedApp == 'X/Twitter')
        webUrl =
            'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(textController.text)}';
      else if (selectedApp == 'LinkedIn')
        webUrl =
            'https://www.linkedin.com/shareArticle?mini=true&url=${Uri.encodeComponent(urlController.text)}&summary=${Uri.encodeComponent(textController.text)}';
      else if (selectedApp == 'Telegram')
        webUrl =
            'https://t.me/share/url?url=${Uri.encodeComponent(urlController.text)}&text=${Uri.encodeComponent(textController.text)}';

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
                    IconData iconData;
                    Color iconColor;
                    switch (app) {
                      case 'WhatsApp':
                        iconData = Custom.whatsapp;
                        iconColor = Colors.green;
                        break;
                      case 'Facebook':
                        iconData = Custom.facebook;
                        iconColor = Colors.blue;
                        break;
                      case 'Instagram':
                        iconData = Icons
                            .camera_alt; // Using internal flutter icon as custom font misses Instagram
                        iconColor = Colors.purple;
                        break;
                      case 'LinkedIn':
                        iconData = Custom.linkedin_squared;
                        iconColor = Colors.blueAccent;
                        break;
                      case 'X/Twitter':
                        iconData = Custom.twitter;
                        iconColor = Colors.lightBlueAccent;
                        break;
                      case 'TikTok':
                        iconData = Icons.music_note; // Missing TikTok from font
                        iconColor = Colors.black;
                        break;
                      case 'Telegram':
                        iconData = Icons.send; // Missing Telegram from font
                        iconColor = Colors.blue;
                        break;
                      case 'Snapchat':
                        iconData = Icons
                            .chat_bubble_outline; // Missing Snapchat from font
                        iconColor = Colors.yellow[700]!;
                        break;
                      default:
                        iconData = Icons.apps;
                        iconColor = Colors.grey;
                    }
                    return DropdownMenuItem(
                        value: app,
                        child: Row(
                          children: [
                            Icon(iconData, color: iconColor),
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 4.0),
                  child: TextFormField(
                    controller: textController,
                    decoration: const InputDecoration(
                        labelText: 'Text/Message',
                        border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                ),
                if (['WhatsApp', 'Telegram'].contains(selectedApp))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4.0),
                    child: TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                          labelText: 'Phone/Username',
                          border: OutlineInputBorder()),
                    ),
                  ),
                if (!['WhatsApp'].contains(selectedApp))
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 4.0),
                    child: TextFormField(
                      controller: urlController,
                      decoration: const InputDecoration(
                          labelText: 'URL/Post/User ID',
                          border: OutlineInputBorder()),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _generateAndLaunch,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Launch'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final link = generators[selectedApp]!();
                    _copyToClipboard(link);
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    final link = generators[selectedApp]!();
                    _showQRCode(link);
                  },
                  icon: const Icon(Icons.qr_code),
                  label: const Text('QR'),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('Generated Link Preview:',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(
              generators[selectedApp]!(),
              style: const TextStyle(
                  color: Colors.blue, decoration: TextDecoration.underline),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
