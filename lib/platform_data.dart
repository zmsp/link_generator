import 'package:flutter/material.dart';
import 'custom_icons.dart';

// ─── Field configuration ──────────────────────────────────────────────────────
//
// Describes which input fields a platform uses and what to label them.
//
class FieldConfig {
  final bool showText;
  final bool showPhone;
  final bool showUrl;
  final bool showTitle;
  final bool showHashtags;
  final bool showUsername;
  final String textLabel;
  final String phoneLabel;
  final String urlLabel;
  final String usernameLabel;

  const FieldConfig({
    this.showText = false,
    this.showPhone = false,
    this.showUrl = false,
    this.showTitle = false,
    this.showHashtags = false,
    this.showUsername = false,
    this.textLabel = 'Message / Caption (WhatsApp, FB, X, etc.)',
    this.phoneLabel = 'Phone Number (WhatsApp, Telegram)',
    this.urlLabel = 'URL / Link (FB, LinkedIn, Reddit, etc.)',
    this.usernameLabel = 'Username / Handle (Insta, TikTok, CashApp, etc.)',
  });
}

// ─── Platform model ───────────────────────────────────────────────────────────
class SocialPlatform {
  final String name;
  final IconData icon;
  final Color color;
  final FieldConfig fields;

  const SocialPlatform({
    required this.name,
    required this.icon,
    required this.color,
    required this.fields,
  });
}

// ─── Platform list ────────────────────────────────────────────────────────────
//
// To add a new platform: add an entry here, then add cases to
// UrlGenerator.webUrl() and UrlGenerator.deepLink() below.
//
final kPlatforms = <SocialPlatform>[
  SocialPlatform(
    name: 'WhatsApp',
    icon: Custom.whatsapp,
    color: const Color(0xFF25D366),
    fields: const FieldConfig(
      showText: true,
      textLabel: 'Message',
      showPhone: true,
      phoneLabel: 'Phone Number (with country code)',
    ),
  ),
  SocialPlatform(
    name: 'Facebook',
    icon: Custom.facebook,
    color: const Color(0xFF1877F2),
    fields: const FieldConfig(
      showText: true,
      textLabel: 'Caption / Quote',
      showUrl: true,
      urlLabel: 'URL to Share',
    ),
  ),
  SocialPlatform(
    name: 'Instagram',
    icon: Icons.camera_alt,
    color: const Color(0xFFE1306C),
    fields: const FieldConfig(
      showUsername: true,
      usernameLabel: 'Instagram Handle',
    ),
  ),
  SocialPlatform(
    name: 'LinkedIn',
    icon: Custom.linkedin_squared,
    color: const Color(0xFF0A66C2),
    fields: const FieldConfig(
      showUrl: true,
      urlLabel: 'URL to Share',
      showTitle: true,
      showText: true,
      textLabel: 'Summary',
    ),
  ),
  SocialPlatform(
    name: 'X/Twitter',
    icon: Custom.twitter,
    color: const Color(0xFF1DA1F2),
    fields: const FieldConfig(
      showText: true,
      textLabel: 'Tweet Text',
      showUrl: true,
      urlLabel: 'URL to Attach',
      showHashtags: true,
    ),
  ),
  SocialPlatform(
    name: 'TikTok',
    icon: Icons.music_note,
    color: const Color(0xFF010101),
    fields: const FieldConfig(
      showUsername: true,
      usernameLabel: 'TikTok Username',
    ),
  ),
  SocialPlatform(
    name: 'Telegram',
    icon: Icons.send,
    color: const Color(0xFF2AABEE),
    fields: const FieldConfig(
      showPhone: true,
      phoneLabel: 'Phone Number',
      showUsername: true,
      usernameLabel: 'Telegram Username',
      showText: true,
      textLabel: 'Message',
      showUrl: true,
      urlLabel: 'URL to Share',
    ),
  ),
  SocialPlatform(
    name: 'Snapchat',
    icon: Icons.chat_bubble_outline,
    color: const Color(0xFFFFB800),
    fields: const FieldConfig(
      showUsername: true,
      usernameLabel: 'Snapchat Username',
    ),
  ),
  SocialPlatform(
    name: 'Pinterest',
    icon: Custom.pinterest,
    color: const Color(0xFFE60023),
    fields: const FieldConfig(
      showUrl: true,
      urlLabel: 'URL to Pin',
      showText: true,
      textLabel: 'Description',
    ),
  ),
  SocialPlatform(
    name: 'YouTube',
    icon: Icons.play_circle_fill,
    color: const Color(0xFFFF0000),
    fields: const FieldConfig(
      showUsername: true,
      usernameLabel: 'Channel Handle (e.g. @user)',
    ),
  ),
  SocialPlatform(
    name: 'Twitch',
    icon: Icons.live_tv,
    color: const Color(0xFF9146FF),
    fields: const FieldConfig(
      showUsername: true,
      usernameLabel: 'Twitch Username',
    ),
  ),
  SocialPlatform(
    name: 'Discord',
    icon: Icons.forum, // Material doesn't have a native Discord icon yet
    color: const Color(0xFF5865F2),
    fields: const FieldConfig(
      showUrl: true,
      urlLabel: 'Invite Link or Code',
      showUsername: true,
      usernameLabel: 'User ID (e.g. 12345678)',
    ),
  ),
  SocialPlatform(
    name: 'GitHub',
    icon: Icons.code,
    color: const Color(0xFF181717),
    fields: const FieldConfig(
      showUsername: true,
      usernameLabel: 'GitHub Username',
    ),
  ),
  SocialPlatform(
    name: 'Reddit',
    icon: Icons.reddit,
    color: const Color(0xFFFF4500),
    fields: const FieldConfig(
      showUrl: true,
      urlLabel: 'URL to Submit',
      showText: true,
      textLabel: 'Post Title',
    ),
  ),
  SocialPlatform(
    name: 'Venmo',
    icon: Icons.payment,
    color: const Color(0xFF008CFF),
    fields: const FieldConfig(
      showUsername: true,
      usernameLabel: 'Venmo Username',
    ),
  ),
  SocialPlatform(
    name: 'Cash App',
    icon: Icons.attach_money,
    color: const Color(0xFF00D632),
    fields: const FieldConfig(
      showUsername: true,
      usernameLabel: '\$Cashtag',
    ),
  ),
  SocialPlatform(
    name: 'PayPal',
    icon: Icons.account_balance_wallet,
    color: const Color(0xFF003087),
    fields: const FieldConfig(
      showUsername: true,
      usernameLabel: 'PayPal Username',
    ),
  ),
  SocialPlatform(
    name: 'Spotify',
    icon: Icons.library_music,
    color: const Color(0xFF1DB954),
    fields: const FieldConfig(
      showUrl: true,
      urlLabel: 'Spotify Link (Profile/Playlist)',
    ),
  ),
  SocialPlatform(
    name: 'Steam',
    icon: Icons.videogame_asset,
    color: const Color(0xFF171A21),
    fields: const FieldConfig(
      showUsername: true,
      usernameLabel: 'Steam Friend Code / ID',
    ),
  ),
];

// Sentinel used for "All Apps" dropdown entry
final kAllAppsPlatform = SocialPlatform(
  name: 'All Apps',
  icon: Icons.apps,
  color: Colors.green,
  fields: const FieldConfig(
    showText: true,
    showPhone: true,
    showUrl: true,
    showTitle: true,
    showHashtags: true,
    showUsername: true,
  ),
);

// Full list including "All Apps" for use in the dropdown
List<SocialPlatform> get kAllPlatforms => [kAllAppsPlatform, ...kPlatforms];

// ─── URL generator ────────────────────────────────────────────────────────────
//
// All URL strings are built with Uri.encodeComponent() which encodes spaces
// as %20 and all special characters — correct for web sharing APIs (RFC 3986).
//
class UrlGenerator {
  final String text;
  final String phone;
  final String url;
  final String title;
  final String hashtags;
  final String username;

  const UrlGenerator({
    required this.text,
    required this.phone,
    required this.url,
    required this.title,
    required this.hashtags,
    required this.username,
  });

  String _e(String s) => Uri.encodeComponent(s);
  String _user(String s) => s.replaceAll('@', '');

  /// Primary HTTPS sharing URL – displayed in the UI and copied to clipboard.
  String webUrl(String name) {
    switch (name) {
      // https://wa.me/{phone}?text={message}
      case 'WhatsApp':
        final p = phone.replaceAll(RegExp(r'[^0-9+]'), '');
        return 'https://wa.me/$p?text=${_e(text)}';

      // https://www.facebook.com/sharer/sharer.php?u={url}&quote={text}
      case 'Facebook':
        final q = text.isNotEmpty ? '&quote=${_e(text)}' : '';
        return 'https://www.facebook.com/sharer/sharer.php?u=${_e(url)}$q';

      // Profile link only (no official share API)
      case 'Instagram':
        final u = _user(username);
        return u.isNotEmpty
            ? 'https://www.instagram.com/$u'
            : 'https://www.instagram.com';

      // https://www.linkedin.com/sharing/share-offsite/?url={url}
      case 'LinkedIn':
        final t = title.isNotEmpty ? '&title=${_e(title)}' : '';
        final s = text.isNotEmpty ? '&summary=${_e(text)}' : '';
        return 'https://www.linkedin.com/sharing/share-offsite/?url=${_e(url)}$t$s';

      // https://twitter.com/intent/tweet?url={url}&text={text}&hashtags={tags}
      case 'X/Twitter':
        final u = url.isNotEmpty ? '&url=${_e(url)}' : '';
        final h = hashtags.isNotEmpty
            ? '&hashtags=${_e(hashtags.replaceAll(RegExp(r'[# ]'), ''))}'
            : '';
        return 'https://twitter.com/intent/tweet?text=${_e(text)}$u$h';

      // Profile link only
      case 'TikTok':
        final u = _user(username);
        return u.isNotEmpty
            ? 'https://www.tiktok.com/@$u'
            : 'https://www.tiktok.com';

      // https://t.me/share/url?url={url}&text={text}  OR  https://t.me/{username}
      case 'Telegram':
        if (username.isNotEmpty && url.isEmpty) {
          final t = text.isNotEmpty ? '?text=${_e(text)}' : '';
          return 'https://t.me/$username$t';
        }
        return 'https://t.me/share/url?url=${_e(url)}&text=${_e(text)}';

      // Profile link only
      case 'Snapchat':
        final u = _user(username);
        return u.isNotEmpty
            ? 'https://www.snapchat.com/add/$u'
            : 'https://www.snapchat.com';

      case 'YouTube':
        final u = _user(username);
        if (u.isEmpty) return 'https://www.youtube.com';
        return 'https://www.youtube.com/@$u';

      case 'Twitch':
        final u = _user(username);
        if (u.isEmpty) return 'https://www.twitch.tv';
        return 'https://www.twitch.tv/$u';

      case 'Discord':
        if (url.isNotEmpty) return url;
        if (username.isNotEmpty) return 'https://discord.com/users/$username';
        return 'https://discord.com';

      case 'GitHub':
        final u = _user(username);
        if (u.isEmpty) return 'https://github.com';
        return 'https://github.com/$u';

      // https://pinterest.com/pin/create/button/?url={url}&description={text}
      case 'Pinterest':
        return 'https://pinterest.com/pin/create/button/?url=${_e(url)}&description=${_e(text)}';

      // https://reddit.com/submit?url={url}&title={text}
      case 'Reddit':
        return 'https://reddit.com/submit?url=${_e(url)}&title=${_e(text)}';

      case 'Venmo':
        final u = _user(username);
        return u.isNotEmpty ? 'https://venmo.com/u/$u' : 'https://venmo.com';

      case 'Cash App':
        final u = _user(username);
        return u.isNotEmpty ? 'https://cash.app/\$$u' : 'https://cash.app';

      case 'PayPal':
        final u = _user(username);
        return u.isNotEmpty ? 'https://paypal.me/$u' : 'https://paypal.com';

      case 'Spotify':
        return url.isNotEmpty ? url : 'https://open.spotify.com';

      case 'Steam':
        final u = _user(username);
        // Steam has multiple formats, commonly /id/custom or /profiles/number.
        // We will default to /id/ for handles, but typically people use Friend Codes now.
        // It's just a best-effort simple link.
        return u.isNotEmpty
            ? 'https://steamcommunity.com/id/$u'
            : 'https://steamcommunity.com';

      default:
        return '';
    }
  }

  /// Native deep-link scheme – tried first on mobile to open the installed app.
  String deepLink(String name) => switch (name) {
        'WhatsApp' => 'whatsapp://send?phone=$phone&text=${_e(text)}',
        'Facebook' => 'fb://facewebmodal/f?href=${_e(url)}',
        'Instagram' => 'instagram://user?username=${_user(username)}',
        'LinkedIn' => 'linkedin://shareArticle?mini=true&url=${_e(url)}',
        'X/Twitter' => 'twitter://post?message=${_e(text)}',
        'TikTok' => 'tiktok://user?user_id=${_user(username)}',
        'Telegram' => 'tg://resolve?domain=$username&text=${_e(text)}',
        'Snapchat' => 'snapchat://add/${_user(username)}',
        'YouTube' => 'vnd.youtube://www.youtube.com/@${_user(username)}',
        'Twitch' => 'twitch://stream/${_user(username)}',
        'Discord' => url.isNotEmpty ? url : '',
        'GitHub' => '',
        'Pinterest' =>
          'pinterest://pin/create/button/?url=${_e(url)}&description=${_e(text)}',
        'Reddit' => 'reddit://submit?url=${_e(url)}&title=${_e(text)}',
        'Venmo' => 'venmo://users/${_user(username)}',
        'Cash App' => 'cashme://\$${_user(username)}',
        'PayPal' => 'paypal://paypal.me/${_user(username)}',
        'Spotify' => url.isNotEmpty ? url : '',
        'Steam' => 'steam://url/SteamIDPage/${_user(username)}',
        _ => '',
      };
}
