import 'package:flutter/material.dart';
import 'platform_data.dart';

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel(this.label, {super.key});
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF9E9BB5),
          letterSpacing: 1.2,
        ),
      );
}

// ─── Small icon button (used in All Apps cards) ───────────────────────────────
class SmallIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const SmallIconBtn(this.icon, this.tooltip, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: Colors.grey.shade500),
          ),
        ),
      );
}

// ─── Platform dropdown ────────────────────────────────────────────────────────
class AppDropdown extends StatelessWidget {
  final List<SocialPlatform> platforms;
  final SocialPlatform selected;
  final ValueChanged<SocialPlatform?> onChanged;

  const AppDropdown({
    super.key,
    required this.platforms,
    required this.selected,
    required this.onChanged,
  });

  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<SocialPlatform>(
            value: selected,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: Theme.of(context).colorScheme.primary),
            items: platforms.map((p) {
              return DropdownMenuItem(
                value: p,
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: p.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(p.icon, color: p.color, size: 17),
                  ),
                  const SizedBox(width: 12),
                  Text(p.name,
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

// ─── Input card ───────────────────────────────────────────────────────────────
class InputCard extends StatelessWidget {
  final SocialPlatform platform;
  final TextEditingController textCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController urlCtrl;
  final TextEditingController titleCtrl;
  final TextEditingController hashtagsCtrl;
  final TextEditingController usernameCtrl;

  const InputCard({
    super.key,
    required this.platform,
    required this.textCtrl,
    required this.phoneCtrl,
    required this.urlCtrl,
    required this.titleCtrl,
    required this.hashtagsCtrl,
    required this.usernameCtrl,
  });

  Widget _field(
    BuildContext context,
    TextEditingController ctrl,
    String label, {
    IconData? prefix,
    int maxLines = 1,
    TextInputType? kbd,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? const Color(0xFF2C3E50) : Colors.white;
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide:
          BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: const BorderSide(color: Colors.red),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide:
          BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
    );

    final textStyle = TextStyle(color: isDark ? Colors.white : Colors.black87);
    final labelStyle =
        TextStyle(color: isDark ? Colors.white70 : Colors.black54);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: kbd,
        style: textStyle,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: labelStyle,
          filled: true,
          fillColor: fill,
          border: border,
          enabledBorder: border,
          focusedBorder: focusBorder,
          errorBorder: errorBorder,
          prefixIcon: prefix != null
              ? Icon(prefix,
                  size: 20, color: isDark ? Colors.white54 : Colors.black54)
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final f = platform.fields;
    return Container(
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (f.showUsername)
          _field(context, usernameCtrl, f.usernameLabel,
              prefix: Icons.person_outline),
        if (f.showText) _field(context, textCtrl, f.textLabel, maxLines: 3),
        if (f.showPhone)
          _field(context, phoneCtrl, f.phoneLabel,
              prefix: Icons.phone_outlined, kbd: TextInputType.phone),
        if (f.showUrl)
          _field(context, urlCtrl, f.urlLabel,
              prefix: Icons.link_outlined, kbd: TextInputType.url),
        if (f.showTitle)
          _field(context, titleCtrl, 'Article Title', prefix: Icons.title),
        if (f.showHashtags)
          _field(context, hashtagsCtrl, 'Hashtags (comma-separated, no #)',
              prefix: Icons.tag),
      ]),
    );
  }
}

// ─── Action row (4 colored buttons) ──────────────────────────────────────────
class ActionRow extends StatelessWidget {
  final VoidCallback onLaunch;
  final VoidCallback onShare;
  final VoidCallback onCopy;
  final VoidCallback onQR;

  const ActionRow({
    super.key,
    required this.onLaunch,
    required this.onShare,
    required this.onCopy,
    required this.onQR,
  });

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
                    letterSpacing: 0.3,
                  )),
            ]),
          ),
        ),
      );
}

// ─── Link preview card ────────────────────────────────────────────────────────
class LinkPreviewCard extends StatelessWidget {
  final String link;
  final VoidCallback onLaunch;
  final VoidCallback onCopy;

  const LinkPreviewCard({
    super.key,
    required this.link,
    required this.onLaunch,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.link, size: 15, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text('Generated Link',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                  letterSpacing: 0.5)),
          const Spacer(),
          _chip('Open', Icons.open_in_new, theme.colorScheme.primary,
              const Color(0x1A6C63FF), onLaunch),
          const SizedBox(width: 8),
          _chip('Copy', Icons.copy, const Color(0xFFFF6B6B),
              const Color(0x1AFF6B6B), onCopy),
        ]),
        TextField(
          controller: TextEditingController(text: link),
          readOnly: true,
          maxLines: null,
          decoration: InputDecoration(
            filled: true,
            fillColor:
                isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF6F5FF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 13,
          ),
        ),
      ]),
    );
  }

  Widget _chip(String label, IconData icon, Color fg, Color bg,
          VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
