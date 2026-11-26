import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'backend.dart';

class UpdateService {
  static Future<void> check(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final build = int.tryParse(info.buildNumber) ?? 1;
      final rows = await supabase.from('app_versions').select().eq('platform', 'android').eq('enabled', true).order('build_number', ascending: false).limit(1);
      if (rows.isEmpty || !context.mounted) return;
      final latest = Map<String, dynamic>.from(rows.first);
      final setting = await supabase.from('update_settings').select().eq('platform', 'android').maybeSingle();
      final config = setting == null ? <String,dynamic>{} : Map<String,dynamic>.from(setting);
      if (setting != null && config['enabled'] == false) return;
      final newBuild = (latest['build_number'] as num?)?.toInt() ?? 0;
      if (newBuild <= build) return;
      final url = (config['update_url'] ?? latest['update_url'] ?? '').toString();
      if (url.isEmpty) return;
      final forced = config['force_update'] == true || latest['force_update'] == true;
      final notes = (latest['release_notes'] ?? config['message'] ?? 'يتوفر إصدار جديد من AcadMind.') as String;
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: !forced,
        builder: (dialogContext) => PopScope(
          canPop: !forced,
          child: AlertDialog(
            title: Text(forced ? 'تحديث مطلوب' : 'تحديث جديد متاح'),
            content: Text(notes),
            actions: [
              if (!forced) TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('لاحقاً')),
              FilledButton(onPressed: () async { final uri = Uri.tryParse(url); if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication); }, child: const Text('تحديث الآن')),
            ],
          ),
        ),
      );
    } catch (_) {
      // Update checks are non-blocking; connectivity issues must not prevent sign-in.
    }
  }
}
