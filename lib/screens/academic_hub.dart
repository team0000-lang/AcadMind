import 'package:flutter/material.dart';

import '../backend.dart';
import '../notification_service.dart';
import '../academic_metrics.dart';
import 'study_practice.dart';

class AcademicHubPage extends StatefulWidget {
  const AcademicHubPage({super.key});
  @override
  State<AcademicHubPage> createState() => _AcademicHubPageState();
}

class _AcademicHubPageState extends State<AcademicHubPage> {
  late Future<List<Map<String, dynamic>>> _eventsFuture;
  bool _owner = false;
  int _range = 0;
  bool _showInactive = false;
  final _ranges = const ['القادمة', 'هذا الأسبوع', 'هذا الشهر'];

  @override
  void initState() {
    super.initState();
    _eventsFuture = _loadEvents();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      final row = await supabase
          .from('profiles')
          .select('role')
          .eq('id', supabase.auth.currentUser!.id)
          .single();
      if (mounted) setState(() => _owner = row['role'] == 'owner');
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> _loadEvents() async {
    var query = supabase
        .from('academic_events')
        .select(
          'id,event_type,title,subject_id,starts_at,ends_at,description,location,external_url,reminder_minutes,academic_year_id,group_id,section_id,is_active,groups(name,code),sections(name),subjects(name_en)',
        )
        .eq('is_active', _owner && _showInactive ? false : true);
    final result = await query
        .gte(
          'starts_at',
          DateTime.now()
              .subtract(const Duration(days: 30))
              .toUtc()
              .toIso8601String(),
        )
        .order('starts_at')
        .limit(250);
    final events = List<Map<String, dynamic>>.from(result);
    try {
      await NotificationService.instance.syncAcademicEvents(events);
    } catch (_) {}
    return events;
  }

  Future<void> _refresh() async {
    setState(() => _eventsFuture = _loadEvents());
    try {
      await _eventsFuture;
    } catch (_) {}
  }

  DateTime _date(Map<String, dynamic> event) =>
      DateTime.tryParse('${event['starts_at']}')?.toLocal() ?? DateTime.now();

  bool _withinRange(DateTime date) {
    final now = DateTime.now();
    if (_range == 1) {
      final first = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      return !date.isBefore(first) &&
          date.isBefore(first.add(const Duration(days: 7)));
    }
    if (_range == 2) return date.year == now.year && date.month == now.month;
    return !date.isBefore(now);
  }

  List<Map<String, dynamic>> _filter(
    List<Map<String, dynamic>> all,
    String? type,
  ) =>
      all.where((event) {
        if (type != null && event['event_type'] != type) return false;
        return _withinRange(_date(event));
      }).toList();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('المركز الأكاديمي'),
        actions: [
          IconButton(
            onPressed: _refresh,
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (_owner)
            IconButton(
              onPressed: () => setState(() {
                _showInactive = !_showInactive;
                _eventsFuture = _loadEvents();
              }),
              tooltip: _showInactive ? 'عرض النشطة' : 'عرض المعطلة',
              icon: Icon(
                _showInactive
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
            ),
          if (_owner)
            IconButton(
              onPressed: _createEvent,
              tooltip: 'إضافة حدث',
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _ErrorState(onRetry: _refresh);
          final all = snapshot.data ?? const <Map<String, dynamic>>[];
          return DefaultTabController(
            length: 5,
            child: Column(
              children: [
                Material(
                  color: colors.surface,
                  child: const TabBar(
                    isScrollable: true,
                    tabs: [
                      Tab(
                        text: 'التقويم',
                        icon: Icon(Icons.calendar_month_rounded),
                      ),
                      Tab(
                        text: 'الامتحانات',
                        icon: Icon(Icons.assignment_late_outlined),
                      ),
                      Tab(text: 'الواجبات', icon: Icon(Icons.task_alt_rounded)),
                      Tab(text: 'تقدمي', icon: Icon(Icons.insights_rounded)),
                      Tab(text: 'تدريب', icon: Icon(Icons.quiz_outlined)),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _calendar(all),
                      _eventsList(
                        _filter(all, 'exam') + _filter(all, 'quiz'),
                        'لا توجد امتحانات قادمة',
                      ),
                      _AssignmentList(
                        events: _filter(all, 'assignment') +
                            _filter(all, 'deadline'),
                        refresh: _refresh,
                      ),
                      _ProgressView(events: all, onLogStudy: _logStudySession),
                      const StudyPracticePage(showAppBar: false),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _calendar(List<Map<String, dynamic>> all) {
    final events = all.where((e) => _withinRange(_date(e))).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
          child: SegmentedButton<int>(
            segments: [
              for (var i = 0; i < _ranges.length; i++)
                ButtonSegment(value: i, label: Text(_ranges[i])),
            ],
            selected: {_range},
            onSelectionChanged: (value) => setState(() => _range = value.first),
          ),
        ),
        Expanded(child: _eventsList(events, 'لا توجد أحداث في هذه الفترة')),
      ],
    );
  }

  Widget _eventsList(List<Map<String, dynamic>> events, String empty) {
    if (events.isEmpty)
      return _EmptyState(
        message: empty,
        action: _owner ? 'أضف حدثاً من زر +' : null,
      );
    events.sort((a, b) => _date(a).compareTo(_date(b)));
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _EventCard(
        event: events[index],
        owner: _owner,
        onToggle: _owner ? () => _toggleEvent(events[index]) : null,
        onEdit: _owner && events[index]['is_active'] == true
            ? () => _createEvent(existing: events[index])
            : null,
      ),
    );
  }

  Future<void> _toggleEvent(Map<String, dynamic> event) async {
    try {
      await supabase.from('academic_events').update(
          {'is_active': event['is_active'] != true}).eq('id', event['id']);
      await _refresh();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تعذر تحديث الحدث')));
    }
  }

  Future<void> _createEvent({Map<String, dynamic>? existing}) async {
    final years = List<Map<String, dynamic>>.from(
      await supabase
          .from('academic_years')
          .select('id,name_en,name_ar')
          .order('name_en'),
    );
    final subjects = List<Map<String, dynamic>>.from(
      await supabase
          .from('subjects')
          .select('id,name_en,academic_year_id,group_id,section_id')
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('name_en'),
    );
    final groups = List<Map<String, dynamic>>.from(
      await supabase
          .from('groups')
          .select('id,code,name,academic_year_id')
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('code'),
    );
    final sections = List<Map<String, dynamic>>.from(
      await supabase
          .from('sections')
          .select('id,name,group_id,academic_year_id')
          .eq('is_active', true)
          .isFilter('deleted_at', null)
          .order('name'),
    );
    if (!mounted) return;
    if (years.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أضف سنة دراسية وفعّل إعدادها أولاً')),
      );
      return;
    }
    final title = TextEditingController(
      text: (existing?['title'] ?? '').toString(),
    );
    final description = TextEditingController(
      text: (existing?['description'] ?? '').toString(),
    );
    final location = TextEditingController(
      text: (existing?['location'] ?? '').toString(),
    );
    var type = (existing?['event_type'] ?? 'exam').toString();
    var yearId =
        (existing?['academic_year_id'] ?? years.first['id']).toString();
    String? groupId = existing?['group_id']?.toString();
    String? sectionId = existing?['section_id']?.toString();
    String? subjectId = existing?['subject_id']?.toString();
    var start = DateTime.tryParse('${existing?['starts_at']}')?.toLocal() ??
        DateTime.now().add(const Duration(days: 1));
    if (existing == null)
      start = DateTime(start.year, start.month, start.day, 9);
    var end = DateTime.tryParse('${existing?['ends_at']}')?.toLocal() ??
        start.add(const Duration(hours: 2));
    var reminder = (existing?['reminder_minutes'] as num?)?.toInt() ?? 0;
    var saved = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'إضافة حدث أكاديمي' : 'تعديل الحدث'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'العنوان *'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(labelText: 'النوع'),
                    items: const [
                      DropdownMenuItem(value: 'exam', child: Text('امتحان')),
                      DropdownMenuItem(
                        value: 'quiz',
                        child: Text('اختبار قصير'),
                      ),
                      DropdownMenuItem(
                        value: 'assignment',
                        child: Text('واجب'),
                      ),
                      DropdownMenuItem(
                        value: 'deadline',
                        child: Text('موعد تسليم'),
                      ),
                      DropdownMenuItem(value: 'event', child: Text('فعالية')),
                      DropdownMenuItem(value: 'lecture', child: Text('محاضرة')),
                    ],
                    onChanged: (v) => setDialogState(() => type = v ?? 'exam'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: yearId,
                    decoration: const InputDecoration(
                      labelText: 'السنة الدراسية المستهدفة',
                    ),
                    items: [
                      for (final y in years)
                        DropdownMenuItem(
                          value: y['id'].toString(),
                          child: Text(
                            (y['name_en'] ?? y['name_ar'] ?? '').toString(),
                          ),
                        ),
                    ],
                    onChanged: (v) =>
                        setDialogState(() => yearId = v ?? yearId),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    value: groupId,
                    decoration: const InputDecoration(
                      labelText: 'المجموعة (اختياري — كل المجموعات)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('كل المجموعات'),
                      ),
                      for (final g in groups.where(
                        (g) => g['academic_year_id'].toString() == yearId,
                      ))
                        DropdownMenuItem<String?>(
                          value: g['id'].toString(),
                          child: Text('${g['code'] ?? g['name']}'),
                        ),
                    ],
                    onChanged: (v) => setDialogState(() {
                      groupId = v;
                      sectionId = null;
                    }),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    value: sectionId,
                    decoration: const InputDecoration(
                      labelText: 'الشعبة (اختياري — كل الشعب)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('كل الشعب'),
                      ),
                      for (final s in sections.where(
                        (s) =>
                            groupId != null &&
                            s['group_id'].toString() == groupId,
                      ))
                        DropdownMenuItem<String?>(
                          value: s['id'].toString(),
                          child: Text('${s['name']}'),
                        ),
                    ],
                    onChanged: groupId == null
                        ? null
                        : (v) => setDialogState(() => sectionId = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    value: subjectId,
                    decoration: const InputDecoration(
                      labelText: 'المادة (اختياري)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('بدون مادة'),
                      ),
                      for (final s in subjects.where(
                        (s) =>
                            (s['academic_year_id'] == null ||
                                s['academic_year_id'].toString() == yearId) &&
                            (s['group_id'] == null ||
                                s['group_id'].toString() == groupId) &&
                            (s['section_id'] == null ||
                                s['section_id'].toString() == sectionId),
                      ))
                        DropdownMenuItem<String?>(
                          value: s['id'].toString(),
                          child: Text('${s['name_en']}'),
                        ),
                    ],
                    onChanged: (v) => setDialogState(() => subjectId = v),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: Text('${_format(start)} — ${_clock(start)}'),
                    subtitle: const Text('تاريخ ووقت البداية'),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: start,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (date == null || !context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(start),
                      );
                      if (time != null)
                        setDialogState(
                          () => start = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available),
                    title: Text('${_format(end)} — ${_clock(end)}'),
                    subtitle: const Text('النهاية (اختيارية)'),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: end,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (date == null || !context.mounted) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(end),
                      );
                      if (time != null)
                        setDialogState(
                          () => end = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                    },
                  ),
                  TextField(
                    controller: location,
                    decoration: const InputDecoration(labelText: 'المكان'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: description,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'التفاصيل'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: reminder,
                    decoration: const InputDecoration(labelText: 'تذكير'),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('بدون تذكير')),
                      DropdownMenuItem(value: 10, child: Text('قبل 10 دقائق')),
                      DropdownMenuItem(value: 60, child: Text('قبل ساعة')),
                      DropdownMenuItem(value: 1440, child: Text('قبل يوم')),
                    ],
                    onChanged: (v) => setDialogState(() => reminder = v ?? 0),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'يظهر الحدث للطلاب النشطين المطابقين للسنة والمجموعة والشعبة المحددة.',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().length < 2 ||
                    end.isBefore(start) ||
                    end.isAtSameMomentAs(start)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'أدخل عنواناً صحيحاً وتأكد أن النهاية بعد البداية',
                      ),
                    ),
                  );
                  return;
                }
                try {
                  final values = {
                    'event_type': type,
                    'title': title.text.trim(),
                    'subject_id': subjectId,
                    'starts_at': start.toUtc().toIso8601String(),
                    'ends_at': end.toUtc().toIso8601String(),
                    'description': description.text.trim().isEmpty
                        ? null
                        : description.text.trim(),
                    'location': location.text.trim().isEmpty
                        ? null
                        : location.text.trim(),
                    'reminder_minutes': reminder,
                    'academic_year_id': yearId,
                    'group_id': groupId,
                    'section_id': sectionId,
                    'created_by': supabase.auth.currentUser?.id,
                  };
                  if (existing == null) {
                    await supabase.from('academic_events').insert(values);
                  } else {
                    values.remove('created_by');
                    await supabase
                        .from('academic_events')
                        .update(values)
                        .eq('id', existing['id']);
                  }
                  saved = true;
                  if (context.mounted) Navigator.pop(dialogContext);
                } catch (_) {
                  if (context.mounted)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'تعذر حفظ الحدث. تحقق من إعداد السنة الدراسية وصلاحيات المالك.',
                        ),
                      ),
                    );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    title.dispose();
    description.dispose();
    location.dispose();
    if (saved) await _refresh();
  }

  Future<void> _logStudySession() async {
    final title = TextEditingController();
    final minutes = TextEditingController(text: '30');
    var saved = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تسجيل جلسة مذاكرة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'ماذا ذاكرت؟'),
            ),
            TextField(
              controller: minutes,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المدة بالدقائق'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () async {
              final duration = int.tryParse(minutes.text) ?? 0;
              if (title.text.trim().length < 2 ||
                  duration < 1 ||
                  duration > 1440) return;
              try {
                await supabase.from('study_sessions').insert({
                  'user_id': supabase.auth.currentUser!.id,
                  'title': title.text.trim(),
                  'duration_minutes': duration,
                });
                saved = true;
                if (context.mounted) Navigator.pop(dialogContext);
              } catch (_) {
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تعذر تسجيل الجلسة')),
                  );
              }
            },
            child: const Text('تسجيل'),
          ),
        ],
      ),
    );
    title.dispose();
    minutes.dispose();
    if (saved && mounted) setState(() {});
  }

  String _format(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
  String _clock(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _EventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool owner;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  const _EventCard({
    required this.event,
    required this.owner,
    this.onToggle,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final date =
        DateTime.tryParse('${event['starts_at']}')?.toLocal() ?? DateTime.now();
    final end = DateTime.tryParse('${event['ends_at']}')?.toLocal();
    final subject = event['subjects'] is Map
        ? (event['subjects']['name_en'] ?? '').toString()
        : '';
    final active = event['is_active'] == true;
    final icon = switch (event['event_type']) {
      'exam' => Icons.assignment_late_rounded,
      'quiz' => Icons.quiz_rounded,
      'assignment' || 'deadline' => Icons.task_alt_rounded,
      'lecture' => Icons.menu_book_rounded,
      _ => Icons.event_rounded,
    };
    final color = switch (event['event_type']) {
      'exam' => Colors.deepOrange,
      'quiz' => Colors.purple,
      'assignment' || 'deadline' => Colors.teal,
      _ => Theme.of(context).colorScheme.primary,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (context) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Text(
                            '${event['title']}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (subject.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                subject,
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            '${date.toLocal()}${end == null ? '' : '\nحتى ${end.toLocal()}'}',
                          ),
                          if ((event['location'] ?? '').toString().isNotEmpty)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.place_outlined),
                              title: Text('${event['location']}'),
                            ),
                          if ((event['description'] ?? '')
                              .toString()
                              .isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text('${event['description']}'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${event['title']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    if (!active)
                      const Text(
                        'معطّل — غير ظاهر للطلاب',
                        style: TextStyle(color: Colors.orange, fontSize: 11),
                      ),
                    if (subject.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          subject,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      '${date.year}/${date.month}/${date.day} • ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    if (end != null)
                      Text(
                        'حتى ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    if ((event['location'] ?? '').toString().isNotEmpty)
                      Text(
                        'المكان: ${event['location']}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (owner && onEdit != null)
              IconButton(
                onPressed: onEdit,
                tooltip: 'تعديل',
                icon: const Icon(Icons.edit_outlined),
              ),
            if (owner && onToggle != null)
              IconButton(
                onPressed: onToggle,
                tooltip: active ? 'تعطيل' : 'تفعيل',
                icon: Icon(
                  active
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_rounded,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentList extends StatefulWidget {
  final List<Map<String, dynamic>> events;
  final Future<void> Function() refresh;
  const _AssignmentList({required this.events, required this.refresh});
  @override
  State<_AssignmentList> createState() => _AssignmentListState();
}

class _AssignmentListState extends State<_AssignmentList> {
  late Future<Map<String, String>> _statuses;
  @override
  void initState() {
    super.initState();
    _statuses = _load();
  }

  Future<Map<String, String>> _load() async {
    final rows = await supabase
        .from('assignment_progress')
        .select('event_id,status')
        .eq('user_id', supabase.auth.currentUser!.id);
    return {
      for (final row in rows)
        row['event_id'].toString(): row['status'].toString(),
    };
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await supabase.from('assignment_progress').upsert({
        'user_id': supabase.auth.currentUser!.id,
        'event_id': id,
        'status': status,
      }, onConflict: 'user_id,event_id');
      if (mounted) setState(() => _statuses = _load());
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر حفظ حالة الواجب')));
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, String>>(
        future: _statuses,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (widget.events.isEmpty) {
            return const _EmptyState(message: 'لا توجد واجبات قادمة');
          }
          final statuses = snapshot.data ?? const <String, String>{};
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final event in widget.events)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${event['title']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'الموعد: ${event['starts_at']}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        if ((event['description'] ?? '').toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('${event['description']}'),
                          ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value:
                              statuses[event['id'].toString()] ?? 'not_started',
                          decoration: const InputDecoration(
                            labelText: 'حالة الإنجاز',
                            isDense: true,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'not_started',
                              child: Text('لم يبدأ'),
                            ),
                            DropdownMenuItem(
                              value: 'in_progress',
                              child: Text('قيد التنفيذ'),
                            ),
                            DropdownMenuItem(
                              value: 'completed',
                              child: Text('مكتمل'),
                            ),
                          ],
                          onChanged: (value) => value == null
                              ? null
                              : _setStatus(event['id'].toString(), value),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      );
}

class _ProgressView extends StatefulWidget {
  final List<Map<String, dynamic>> events;
  final VoidCallback onLogStudy;
  const _ProgressView({required this.events, required this.onLogStudy});
  @override
  State<_ProgressView> createState() => _ProgressViewState();
}

class _ProgressViewState extends State<_ProgressView> {
  late Future<List<dynamic>> _data;
  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<List<dynamic>> _load() async {
    final userId = supabase.auth.currentUser!.id;
    return Future.wait([
      supabase
          .from('assignment_progress')
          .select('status,event_id')
          .eq('user_id', userId),
      supabase
          .from('study_sessions')
          .select('duration_minutes,subject_id,title,started_at')
          .eq('user_id', userId)
          .order('started_at', ascending: false)
          .limit(100),
      supabase
          .from('quiz_attempts')
          .select('score,max_score,title,created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(100),
    ]);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<dynamic>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return const _EmptyState(message: 'تعذر تحميل بيانات التقدم');
          final assignments =
              List<Map<String, dynamic>>.from(snapshot.data![0]);
          final sessions = List<Map<String, dynamic>>.from(snapshot.data![1]);
          final quizzes = List<Map<String, dynamic>>.from(snapshot.data![2]);
          final metrics = AcademicMetrics.fromRecords(
            assignments: assignments,
            studySessions: sessions,
            quizAttempts: quizzes,
          );
          final exams = widget.events
              .where(
                (e) =>
                    e['event_type'] == 'exam' &&
                    DateTime.tryParse('${e['starts_at']}')
                            ?.isAfter(DateTime.now()) ==
                        true,
              )
              .toList()
            ..sort(
              (a, b) => DateTime.parse('${a['starts_at']}')
                  .compareTo(DateTime.parse('${b['starts_at']}')),
            );
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'واجبات مكتملة',
                      value:
                          '${metrics.completedAssignments} / ${metrics.totalAssignments}',
                      icon: Icons.task_alt_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      label: 'ساعات مذاكرة',
                      value: metrics.studyHours.toStringAsFixed(1),
                      icon: Icons.timer_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MetricCard(
                label: 'أداء الاختبارات المسجلة',
                value: metrics.quizPercent == null
                    ? 'لا توجد نتائج بعد'
                    : '${metrics.quizPercent!.toStringAsFixed(0)}%',
                icon: Icons.quiz_outlined,
              ),
              const SizedBox(height: 12),
              if (metrics.assignmentPercent != null)
                LinearProgressIndicator(
                  value: metrics.assignmentPercent!,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(9),
                ),
              const SizedBox(height: 16),
              if (exams.isNotEmpty)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.hourglass_bottom_rounded),
                    title: Text('الامتحان القادم: ${exams.first['title']}'),
                    subtitle: Text(
                      '${DateTime.parse('${exams.first['starts_at']}').toLocal()}',
                    ),
                  ),
                ),
              FilledButton.icon(
                onPressed: () async {
                  widget.onLogStudy();
                  await Future<void>.delayed(const Duration(milliseconds: 300));
                  if (mounted) setState(() => _data = _load());
                },
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('تسجيل جلسة مذاكرة'),
              ),
              const SizedBox(height: 8),
              Text(
                'تعرض هذه المؤشرات السجلات الفعلية لحسابك فقط؛ لا توجد درجات أو ساعات تقديرية.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      );
}

class _MetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final String message;
  final String? action;
  const _EmptyState({required this.message, this.action});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_note_rounded,
                size: 42,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (action != null)
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(action!, textAlign: TextAlign.center),
                ),
            ],
          ),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 42),
            const SizedBox(height: 12),
            const Text('تعذر تحميل المركز الأكاديمي'),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
}
