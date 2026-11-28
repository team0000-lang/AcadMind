import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../backend.dart';

class RedesignedSubjectDetailPage extends StatefulWidget {
  final Map<String, dynamic> subject;

  const RedesignedSubjectDetailPage({
    super.key,
    required this.subject,
  });

  @override
  State<RedesignedSubjectDetailPage> createState() =>
      _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<RedesignedSubjectDetailPage> {
  late Future<Map<String, List<Map<String, dynamic>>>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _load() async {
    final id = widget.subject['id'];
    final lectures = List<Map<String, dynamic>>.from(
      await supabase
          .from('lectures')
          .select('id,title,topic,description,notes,lecture_number')
          .eq('subject_id', id)
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('display_order'),
    );
    final videos = List<Map<String, dynamic>>.from(
      await supabase
          .from('youtube_resources')
          .select('id,title,youtube_url,lecture_id,description,channel')
          .eq('subject_id', id)
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('display_order'),
    );
    final materials = List<Map<String, dynamic>>.from(
      await supabase
          .from('drive_folders')
          .select('id,folder_name,folder_url,description')
          .eq('subject_id', id)
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('display_order'),
    );
    return {
      'lectures': lectures,
      'videos': videos,
      'materials': materials,
    };
  }

  Future<void> _open(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final name = (widget.subject['name_en'] ?? 'Subject').toString();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(
                icon: Icon(Icons.menu_book_rounded),
                text: 'Lectures',
              ),
              Tab(
                icon: Icon(Icons.play_circle_outline_rounded),
                text: 'Videos',
              ),
              Tab(
                icon: Icon(Icons.folder_open_rounded),
                text: 'Materials',
              ),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _SubjectMessage(
                icon: Icons.cloud_off_rounded,
                title: 'Unable to load subject content',
                subtitle: 'Check your connection and try again.',
                action: TextButton.icon(
                  onPressed: () => setState(() => future = _load()),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              );
            }

            final data = snapshot.data ??
                <String, List<Map<String, dynamic>>>{
                  'lectures': [],
                  'videos': [],
                  'materials': [],
                };
            final lectures = data['lectures'] ?? [];
            final videos = data['videos'] ?? [];
            final materials = data['materials'] ?? [];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primary.withValues(alpha: 0.14),
                          colors.tertiary.withValues(alpha: 0.07),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: 0.13),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.auto_stories_rounded,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Wrap(
                                spacing: 7,
                                runSpacing: 5,
                                children: [
                                  _CountTag(
                                    icon: Icons.menu_book_rounded,
                                    label: '${lectures.length} Lectures',
                                  ),
                                  _CountTag(
                                    icon: Icons.play_circle_rounded,
                                    label: '${videos.length} Videos',
                                  ),
                                  _CountTag(
                                    icon: Icons.folder_rounded,
                                    label: '${materials.length} Materials',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _LecturesTab(
                        lectures: lectures,
                      ),
                      _VideosTab(
                        videos: videos,
                        onOpen: _open,
                      ),
                      _MaterialsTab(
                        materials: materials,
                        onOpen: _open,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CountTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CountTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: colors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _LecturesTab extends StatelessWidget {
  final List<Map<String, dynamic>> lectures;

  const _LecturesTab({required this.lectures});

  @override
  Widget build(BuildContext context) {
    if (lectures.isEmpty) {
      return const _SubjectMessage(
        icon: Icons.menu_book_outlined,
        title: 'No lectures yet',
        subtitle: 'Your lectures will appear here when they are added.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      itemCount: lectures.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _LectureCard(
        lecture: lectures[index],
        index: index + 1,
      ),
    );
  }
}

class _LectureCard extends StatelessWidget {
  final Map<String, dynamic> lecture;
  final int index;

  const _LectureCard({required this.lecture, required this.index});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final description = (lecture['description'] ?? '').toString().trim();
    final topic = (lecture['topic'] ?? '').toString().trim();
    final notes = (lecture['notes'] ?? '').toString().trim();

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    index.toString(),
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (lecture['title'] ?? 'Lecture').toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (topic.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        topic,
                        style: TextStyle(
                          fontSize: 10,
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                height: 1.5,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                notes,
                style: const TextStyle(fontSize: 10.5, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VideosTab extends StatelessWidget {
  final List<Map<String, dynamic>> videos;
  final Future<void> Function(String) onOpen;

  const _VideosTab({required this.videos, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (videos.isEmpty) {
      return const _SubjectMessage(
        icon: Icons.ondemand_video_rounded,
        title: 'No videos yet',
        subtitle: 'Explanation videos will appear here when they are added.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      itemCount: videos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final video = videos[index];
        final description = (video['description'] ?? '').toString().trim();
        final channel = (video['channel'] ?? '').toString().trim();
        return Material(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => onOpen((video['youtube_url'] ?? '').toString()),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colors.errorContainer.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: colors.error,
                      size: 29,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (video['title'] ?? 'YouTube video').toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (channel.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            channel,
                            style: TextStyle(
                              fontSize: 9,
                              color: colors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.open_in_new_rounded,
                    size: 17,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MaterialsTab extends StatelessWidget {
  final List<Map<String, dynamic>> materials;
  final Future<void> Function(String) onOpen;

  const _MaterialsTab({required this.materials, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (materials.isEmpty) {
      return const _SubjectMessage(
        icon: Icons.folder_open_rounded,
        title: 'No materials yet',
        subtitle: 'Course files and Google Drive folders will appear here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      itemCount: materials.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final material = materials[index];
        final description = (material['description'] ?? '').toString().trim();
        return Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.drive_folder_upload_rounded,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (material['folder_name'] ?? 'Course material').toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                onPressed: () =>
                    onOpen((material['folder_url'] ?? '').toString()),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('Open'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SubjectMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const _SubjectMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: colors.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                color: colors.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 12),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
