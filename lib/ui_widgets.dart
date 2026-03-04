import 'package:flutter/material.dart';
import 'app_constants.dart';
import 'platform_data.dart';

// ─── Section label ────────────────────────────────────────────────────────────
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

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: kSurface, borderRadius: BorderRadius.circular(18)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<SocialPlatform>(
            value: selected,
            isExpanded: true,
            icon:
                const Icon(Icons.keyboard_arrow_down_rounded, color: kPrimary),
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

  const InputCard({
    super.key,
    required this.platform,
    required this.textCtrl,
    required this.phoneCtrl,
    required this.urlCtrl,
    required this.titleCtrl,
    required this.hashtagsCtrl,
  });

  static const _fill = Color(0xFFF6F5FF);
  static const _border =
      OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)));
  static const _eBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
    borderSide: BorderSide(color: Color(0xFFE0DEFF)),
  );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    IconData? prefix,
    int maxLines = 1,
    TextInputType? kbd,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: kbd,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: _fill,
            border: _border,
            enabledBorder: _eBorder,
            prefixIcon: prefix != null ? Icon(prefix, size: 20) : null,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final f = platform.fields;
    return Container(
      decoration: BoxDecoration(
          color: kSurface, borderRadius: BorderRadius.circular(18)),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (f.showText) _field(textCtrl, f.textLabel, maxLines: 3),
        if (f.showPhone)
          _field(phoneCtrl, f.phoneLabel,
              prefix: Icons.phone_outlined, kbd: TextInputType.phone),
        if (f.showUrl)
          _field(urlCtrl, f.urlLabel,
              prefix: Icons.link_outlined, kbd: TextInputType.url),
        if (f.showTitle)
          _field(titleCtrl, 'Article Title', prefix: Icons.title),
        if (f.showHashtags)
          _field(hashtagsCtrl, 'Hashtags (comma-separated, no #)',
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
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.link, size: 15, color: kPrimary),
            const SizedBox(width: 6),
            const Text('Generated Link',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: kPrimary,
                    letterSpacing: 0.5)),
            const Spacer(),
            _chip('Open', Icons.open_in_new, kPrimary, const Color(0x1A6C63FF),
                onLaunch),
            const SizedBox(width: 8),
            _chip('Copy', Icons.copy, const Color(0xFFFF6B6B),
                const Color(0x1AFF6B6B), onCopy),
          ]),
          const SizedBox(height: 12),
          SelectableText(
            link,
            style: const TextStyle(
              color: kPrimary,
              fontSize: 13,
              decoration: TextDecoration.underline,
              decorationColor: kPrimary,
            ),
            onTap: onLaunch,
          ),
        ]),
      );

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
