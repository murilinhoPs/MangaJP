import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../data/backup_shot.dart';
import '../domain/backup_labels.dart';
import 'backup_keys.dart';

/// Ajustes › Sobre / Fontes (NF8). No extra route.
class AboutSection extends StatefulWidget {
  const AboutSection({super.key});

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  var _didShot = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (kBackupShotAbout && !_didShot) {
      _didShot = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        Scrollable.ensureVisible(
          context,
          alignment: 0.1,
          duration: Duration.zero,
        );
      });
    }
    return Card(
      key: BackupKeys.aboutSection,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              BackupLabels.aboutSection,
              style: AppTypeScale.ui14.copyWith(
                color: tokens.text,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const _LicenseLine(
              key: BackupKeys.jmdictAttr,
              label: BackupLabels.jmdict,
              url: BackupLabels.jmdictUrl,
            ),
            const SizedBox(height: 8),
            const _LicenseLine(
              key: BackupKeys.kanjidicAttr,
              label: BackupLabels.kanjidic,
              url: BackupLabels.kanjidicUrl,
            ),
            const SizedBox(height: 8),
            const _LicenseLine(
              key: BackupKeys.yomitanAttr,
              label: BackupLabels.yomitan,
              url: BackupLabels.yomitanUrl,
            ),
          ],
        ),
      ),
    );
  }
}

class _LicenseLine extends StatelessWidget {
  const _LicenseLine({super.key, required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return InkWell(
      onTap: () async {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          label,
          style: AppTypeScale.ui13.copyWith(
            color: tokens.coralText,
            decoration: TextDecoration.underline,
            decorationColor: tokens.coralText,
          ),
        ),
      ),
    );
  }
}
