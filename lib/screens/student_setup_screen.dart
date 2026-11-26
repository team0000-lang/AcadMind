
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../backend.dart';
import '../services.dart';

class StudentSetupScreen extends StatefulWidget {
  final bool forceEdit;
  final VoidCallback? onFinished;
  const StudentSetupScreen({super.key, this.forceEdit = false, this.onFinished});

  @override
  State<StudentSetupScreen> createState() => _StudentSetupScreenState();
}

class _StudentSetupScreenState extends State<StudentSetupScreen> {
  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> sections = [];
  Map<String, dynamic> profile = {};
  String? yearId, yearName, groupId, sectionId, error;
  bool loading = true, loadingSections = false, saving = false;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final p = await AcadMindData.profile();
      final years = List<Map<String, dynamic>>.from(await supabase
          .from('academic_years').select('id,name_ar,name_en')
          .eq('status', 'active').isFilter('deleted_at', null)
          .order('display_order').limit(1));
      if (years.isEmpty) throw Exception('لا توجد سنة دراسية نشطة حالياً.');
      final y = years.first;
      final yid = y['id'].toString();
      final list = List<Map<String, dynamic>>.from(await supabase
          .from('groups').select('id,name,code')
          .eq('academic_year_id', yid).eq('is_active', true)
          .isFilter('deleted_at', null).order('display_order'));
      final savedGroup = p['academic_year_id']?.toString() == yid
          ? p['group_id']?.toString() : null;
      final selected = list.any((g) => g['id'].toString() == savedGroup)
          ? savedGroup : null;
      if (!mounted) return;
      setState(() {
        profile = p;
        yearId = yid;
        yearName = (y['name_ar'] ?? y['name_en'] ?? '').toString();
        groups = list;
        groupId = selected;
        sectionId = null;
        loading = false;
      });
      if (selected != null) await loadSections(selected, preserve: true);
    } catch (e) {
      if (mounted) setState(() { error = e.toString().replaceFirst('Exception: ', ''); loading = false; });
    }
  }

  int sectionNumber(Map<String, dynamic> row) {
    final raw = (row['code'] ?? row['name'] ?? '').toString();
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  Future<void> loadSections(String id, {bool preserve = false}) async {
    setState(() {
      loadingSections = true;
      sections = [];
      if (!preserve) sectionId = null;
    });
    try {
      final group = groups.firstWhere((g) => g['id'].toString() == id);
      final allowed = group['code'] == 'G1' ? {1, 3, 5} : {2, 4, 6};
      final rows = List<Map<String, dynamic>>.from(await supabase
          .from('sections').select('id,name,code')
          .eq('academic_year_id', yearId!).eq('group_id', id)
          .eq('is_active', true).isFilter('deleted_at', null)
          .order('display_order'));
      final filtered = rows.where((s) => allowed.contains(sectionNumber(s))).toList();
      final oldSection = preserve && profile['group_id']?.toString() == id
          ? profile['section_id']?.toString() : null;
      final selected = filtered.any((s) => s['id'].toString() == oldSection)
          ? oldSection : null;
      if (!mounted) return;
      setState(() {
        sections = filtered;
        sectionId = selected;
        loadingSections = false;
      });
    } catch (e) {
      if (mounted) setState(() { error = 'تعذر تحميل السكاشن: $e'; loadingSections = false; });
    }
  }

  Future<void> save() async {
    if (yearId == null || groupId == null || sectionId == null || saving) return;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) { message('انتهت جلسة الدخول. سجّل الدخول مرة أخرى.'); return; }
    setState(() => saving = true);
    try {
      final row = await supabase.from('profiles').update({
        'academic_year_id': yearId,
        'group_id': groupId,
        'section_id': sectionId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId).select('id').maybeSingle();
      if (row == null) throw Exception('لم يتم العثور على ملف الطالب. تواصل مع الإدارة.');
      profileScopeRevision.value++;
      if (!mounted) return;
      if (widget.forceEdit) {
        Navigator.pop(context, true);
      } else {
        widget.onFinished?.call();
      }
    } on PostgrestException catch (e) {
      message('تعذر حفظ الاختيار: ' + e.message);
    } catch (e) {
      message('تعذر حفظ الاختيار: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void message(String value) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final selectedGroupRows = groups.where((g) => g['id'].toString() == groupId).toList();
    final selectedSectionRows = sections.where((s) => s['id'].toString() == sectionId).toList();
    final selectedGroup = selectedGroupRows.isEmpty ? null : selectedGroupRows.first;
    final selectedSection = selectedSectionRows.isEmpty ? null : selectedSectionRows.first;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FC),
        body: SafeArea(
          child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cloud_off_rounded, size: 42, color: Color(0xFF7A7E96)),
                    const SizedBox(height: 14),
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(onPressed: load, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة المحاولة')),
                  ]),
                ))
              : Column(children: [
                  Expanded(child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: [
                      Row(children: [
                        Container(width: 43, height: 43,
                          decoration: BoxDecoration(color: const Color(0xFF28235E), borderRadius: BorderRadius.circular(14)),
                          alignment: Alignment.center,
                          child: const Text('AM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
                        const SizedBox(width: 11),
                        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('AcadMind', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF222342))),
                          SizedBox(height: 2),
                          Text('إعداد حسابك الدراسي', style: TextStyle(fontSize: 11, color: Color(0xFF85899F))),
                        ]),
                        const Spacer(),
                        if (widget.forceEdit) IconButton(
                          onPressed: () => Navigator.pop(context, false),
                          icon: const Icon(Icons.close_rounded)),
                      ]),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
                            colors: [Color(0xFF171A3D), Color(0xFF39328F), Color(0xFF6255E8)]),
                          borderRadius: BorderRadius.circular(26)),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .13), borderRadius: BorderRadius.circular(30)),
                            child: Text(yearName ?? 'السنة الدراسية الحالية',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
                          const SizedBox(height: 17),
                          const Text('خلّينا نجهّز جدولك',
                            style: TextStyle(color: Colors.white, fontSize: 25, height: 1.3, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text('اختار المجموعة والسكشن بتوعك علشان نظهر لك المحاضرات والمواعيد الصحيحة.',
                            style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 13, height: 1.7)),
                          const SizedBox(height: 19),
                          Row(children: [
                            _StepPill(number: '01', label: 'المجموعة', active: groupId == null),
                            const SizedBox(width: 9),
                            Icon(Icons.arrow_back_rounded, color: Colors.white.withValues(alpha: .65), size: 17),
                            const SizedBox(width: 9),
                            _StepPill(number: '02', label: 'السكشن', active: groupId != null),
                          ]),
                        ]),
                      ),
                      const SizedBox(height: 27),
                      const _SectionTitle(number: '01', title: 'اختار مجموعتك', subtitle: 'حدد المجموعة المسجل فيها'),
                      const SizedBox(height: 13),
                      Row(children: groups.map((g) {
                        final id = g['id'].toString();
                        final code = g['code'].toString();
                        final selected = id == groupId;
                        return Expanded(child: Padding(
                          padding: EdgeInsetsDirectional.only(end: code == 'G1' ? 7 : 0, start: code == 'G2' ? 7 : 0),
                          child: _GroupCard(
                            selected: selected,
                            onTap: saving ? null : () async {
                              if (groupId == id) return;
                              setState(() { groupId = id; sectionId = null; error = null; });
                              await loadSections(id);
                            },
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Expanded(child: Text(code, style: TextStyle(
                                  color: selected ? Colors.white : const Color(0xFF29264F),
                                  fontSize: 27, fontWeight: FontWeight.w900))),
                                Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                                  size: 21, color: selected ? Colors.white : const Color(0xFFA8ABC0)),
                              ]),
                              const SizedBox(height: 7),
                              Text(g['name'].toString(), style: TextStyle(
                                color: selected ? Colors.white70 : const Color(0xFF777C96),
                                fontSize: 12, fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ));
                      }).toList()),
                      const SizedBox(height: 27),
                      const _SectionTitle(number: '02', title: 'اختار السكشن', subtitle: 'السكاشن المتاحة للمجموعة المختارة'),
                      const SizedBox(height: 13),
                      if (groupId == null)
                        const _Hint(text: 'اختار G1 أو G2 الأول علشان تظهر السكاشن المتاحة.', icon: Icons.touch_app_rounded)
                      else if (loadingSections)
                        const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
                      else if (sections.isEmpty)
                        const _Hint(text: 'مفيش سكاشن متاحة للمجموعة دي حالياً. راجع الإدارة.', icon: Icons.info_outline_rounded)
                      else
                        Wrap(spacing: 10, runSpacing: 10, children: sections.map((s) {
                          final id = s['id'].toString();
                          final selected = sectionId == id;
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: saving ? null : () => setState(() => sectionId = id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 94, height: 88,
                              decoration: BoxDecoration(
                                color: selected ? const Color(0xFF5145D6) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: selected ? const Color(0xFF5145D6) : const Color(0xFFE4E6F0)),
                                boxShadow: selected ? [BoxShadow(color: const Color(0xFF5145D6).withValues(alpha: .17), blurRadius: 15, offset: const Offset(0, 6))] : []),
                              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Text(sectionNumber(s).toString(), style: TextStyle(
                                  color: selected ? Colors.white : const Color(0xFF26254A),
                                  fontSize: 25, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 3),
                                Text('Section', style: TextStyle(
                                  color: selected ? Colors.white70 : const Color(0xFF888DA3),
                                  fontSize: 10, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                          );
                        }).toList()),
                      if (selectedGroup != null && selectedSection != null) ...[
                        const SizedBox(height: 19),
                        Container(padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: const Color(0xFFEBF8F4), borderRadius: BorderRadius.circular(16)),
                          child: Row(children: [
                            const Icon(Icons.verified_rounded, color: Color(0xFF22876A)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(
                              selectedGroup['code'].toString() + ' • ' + selectedSection['name'].toString(),
                              style: const TextStyle(color: Color(0xFF216B58), fontWeight: FontWeight.w800, fontSize: 13))),
                          ])),
                      ],
                    ],
                  )),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                    decoration: const BoxDecoration(color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE9EAF2)))),
                    child: SafeArea(top: false, child: SizedBox(width: double.infinity, height: 54,
                      child: FilledButton(
                        onPressed: saving || groupId == null || sectionId == null ? null : save,
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF5145D6), foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFE2E3EC),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
                        child: saving
                          ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Text('حفظ ومتابعة', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                              SizedBox(width: 9), Icon(Icons.arrow_back_rounded, size: 19),
                            ]),
                      ),
                    )),
                  ),
                ]),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String number, title, subtitle;
  const _SectionTitle({required this.number, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 35, height: 35, alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFFECEBFF), borderRadius: BorderRadius.circular(12)),
      child: Text(number, style: const TextStyle(color: Color(0xFF5145D6), fontWeight: FontWeight.w900, fontSize: 11))),
    const SizedBox(width: 11),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Color(0xFF252744), fontWeight: FontWeight.w900, fontSize: 16)),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: Color(0xFF858AA0), fontSize: 11)),
    ])),
  ]);
}

class _GroupCard extends StatelessWidget {
  final bool selected;
  final VoidCallback? onTap;
  final Widget child;
  const _GroupCard({required this.selected, required this.onTap, required this.child});
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFF5145D6) : Colors.white,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(19),
      child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(19),
          border: Border.all(color: selected ? const Color(0xFF5145D6) : const Color(0xFFE4E6F0)),
          boxShadow: selected ? [BoxShadow(color: const Color(0xFF5145D6).withValues(alpha: .16), blurRadius: 17, offset: const Offset(0, 7))] : []),
        child: child),
    ),
  );
}

class _StepPill extends StatelessWidget {
  final String number, label;
  final bool active;
  const _StepPill({required this.number, required this.label, required this.active});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: active ? Colors.white : Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(30)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(number, style: TextStyle(color: active ? const Color(0xFF40379E) : Colors.white70, fontSize: 10, fontWeight: FontWeight.w900)),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(color: active ? const Color(0xFF40379E) : Colors.white70, fontSize: 10, fontWeight: FontWeight.w800)),
    ]),
  );
}

class _Hint extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Hint({required this.text, required this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE5E7F0))),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF7771C9)), const SizedBox(width: 12),
      Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF71768D), fontSize: 12, height: 1.5))),
    ]),
  );
}
