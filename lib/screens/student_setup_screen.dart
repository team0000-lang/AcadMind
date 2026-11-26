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
  static const brand = Color(0xFF5145D6);
  static const ink = Color(0xFF252744);
  List<Map<String, dynamic>> years = [], groups = [], sections = [], subjects = [];
  final Set<String> interestedYears = {};
  Map<String, dynamic> profile = {};
  String? yearId, groupId, sectionId, error;
  int step = 0;
  bool loading = true, loadingGroups = false, loadingSections = false, saving = false, interestBusy = false;

  Map<String, dynamic>? get selectedYear => years.cast<Map<String, dynamic>?>().firstWhere(
    (e) => e?['id'].toString() == yearId, orElse: () => null);
  Map<String, dynamic>? get selectedGroup => groups.cast<Map<String, dynamic>?>().firstWhere(
    (e) => e?['id'].toString() == groupId, orElse: () => null);
  Map<String, dynamic>? get selectedSection => sections.cast<Map<String, dynamic>?>().firstWhere(
    (e) => e?['id'].toString() == sectionId, orElse: () => null);

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      final result = await Future.wait<dynamic>([
        AcadMindData.profile(),
        supabase.from('academic_years').select('id,name_ar,name_en,code,status,display_order')
          .or('status.eq.active,status.eq.coming_soon').isFilter('deleted_at', null).order('display_order'),
        supabase.from('academic_year_interest').select('academic_year_id')
          .eq('user_id', supabase.auth.currentUser!.id),
      ]);
      final p = Map<String, dynamic>.from(result[0] as Map);
      final ys = List<Map<String, dynamic>>.from(result[1] as List);
      final interests = List<Map<String, dynamic>>.from(result[2] as List);
      final saved = p['academic_year_id']?.toString();
      final valid = ys.any((y) => y['id'].toString() == saved && y['status'] == 'active');
      if (!mounted) return;
      setState(() {
        profile = p;
        years = ys;
        interestedYears..clear()..addAll(interests.map((e) => e['academic_year_id'].toString()));
        yearId = valid ? saved : null;
        groupId = null; sectionId = null; groups = []; sections = []; subjects = [];
        step = 0; loading = false;
      });
      if (yearId != null) await loadYear(yearId!, preserve: true);
    } catch (e) {
      if (mounted) setState(() { error = e.toString(); loading = false; });
    }
  }

  Future<void> chooseYear(Map<String, dynamic> year) async {
    if (year['status'] != 'active' || loadingGroups || saving) return;
    setState(() {
      yearId = year['id'].toString();
      groupId = null; sectionId = null; groups = []; sections = []; subjects = [];
      error = null;
    });
    await loadYear(yearId!);
  }

  Future<void> loadYear(String id, {bool preserve = false}) async {
    setState(() { loadingGroups = true; error = null; });
    try {
      final result = await Future.wait<dynamic>([
        supabase.from('groups').select('id,name,code,is_active').eq('academic_year_id', id)
          .eq('is_active', true).isFilter('deleted_at', null).order('display_order'),
        supabase.from('subjects').select('id,name_en,code,icon_path').eq('academic_year_id', id)
          .eq('is_active', true).isFilter('deleted_at', null).order('display_order'),
      ]);
      final gs = List<Map<String, dynamic>>.from(result[0] as List);
      final ss = List<Map<String, dynamic>>.from(result[1] as List);
      final old = preserve && profile['academic_year_id']?.toString() == id
          ? profile['group_id']?.toString() : null;
      final selected = gs.any((g) => g['id'].toString() == old) ? old : null;
      if (!mounted) return;
      setState(() { groups = gs; subjects = ss; groupId = selected; loadingGroups = false; });
      if (selected != null) await loadSections(selected, preserve: true);
    } catch (e) {
      if (mounted) setState(() { error = 'تعذر تحميل بيانات الفرقة: ' + e.toString(); loadingGroups = false; });
    }
  }

  int sectionNumber(Map<String, dynamic> row) =>
      int.tryParse((row['code'] ?? row['name'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  Future<void> chooseGroup(String id) async {
    setState(() { groupId = id; sectionId = null; sections = []; });
    await loadSections(id);
  }

  Future<void> loadSections(String id, {bool preserve = false}) async {
    setState(() { loadingSections = true; if (!preserve) sectionId = null; });
    try {
      final group = groups.firstWhere((g) => g['id'].toString() == id);
      final allowed = group['code'] == 'G1' ? {1, 3, 5} : {2, 4, 6};
      final rows = List<Map<String, dynamic>>.from(await supabase.from('sections')
        .select('id,name,code,is_active').eq('academic_year_id', yearId!)
        .eq('group_id', id).eq('is_active', true).isFilter('deleted_at', null).order('display_order'));
      final filtered = rows.where((s) => allowed.contains(sectionNumber(s))).toList();
      final old = preserve && profile['group_id']?.toString() == id ? profile['section_id']?.toString() : null;
      final selected = filtered.any((s) => s['id'].toString() == old) ? old : null;
      if (!mounted) return;
      setState(() { sections = filtered; sectionId = selected; loadingSections = false; });
    } catch (e) {
      if (mounted) setState(() { error = 'تعذر تحميل السكاشن: ' + e.toString(); loadingSections = false; });
    }
  }

  Future<void> notifyMe(Map<String, dynamic> year) async {
    final id = year['id'].toString();
    if (interestBusy || interestedYears.contains(id)) return;
    setState(() => interestBusy = true);
    try {
      await supabase.from('academic_year_interest').insert({
        'user_id': supabase.auth.currentUser!.id, 'academic_year_id': id,
      });
      if (!mounted) return;
      setState(() => interestedYears.add(id));
      message('تم تسجيل اهتمامك، وسيظهر طلبك للإدارة.');
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        setState(() => interestedYears.add(id));
        message('أنت مسجل بالفعل ضمن المهتمين بهذه الفرقة.');
      } else {
        message('تعذر التسجيل: ' + e.message);
      }
    } catch (e) {
      message('تعذر التسجيل: ' + e.toString());
    } finally {
      if (mounted) setState(() => interestBusy = false);
    }
  }

  Future<void> save() async {
    if (yearId == null || groupId == null || sectionId == null || saving) return;
    final uid = supabase.auth.currentUser?.id;
    if (uid == null) { message('انتهت جلسة الدخول. سجّل الدخول مرة أخرى.'); return; }
    setState(() => saving = true);
    try {
      final row = await supabase.from('profiles').update({
        'academic_year_id': yearId, 'group_id': groupId, 'section_id': sectionId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', uid).select('id').maybeSingle();
      if (row == null) throw Exception('لم يتم العثور على ملف الطالب. تواصل مع الإدارة.');
      profileScopeRevision.value++;
      if (!mounted) return;
      if (widget.forceEdit) { Navigator.pop(context, true); } else { widget.onFinished?.call(); }
    } on PostgrestException catch (e) {
      message('تعذر حفظ الاختيار: ' + e.message);
    } catch (e) {
      message('تعذر حفظ الاختيار: ' + e.toString());
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
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (error != null) {
      return Scaffold(body: Center(child: Padding(
        padding: const EdgeInsets.all(26), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 42),
          const SizedBox(height: 12), const Text('تعذر تحميل بيانات الدراسة'),
          const SizedBox(height: 8), Text(error!, textAlign: TextAlign.center),
          const SizedBox(height: 14), FilledButton.icon(onPressed: load, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
        ]),
      )));
    }
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FC),
        body: SafeArea(child: Column(children: [
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 22), children: [
            Row(children: [
              Container(width: 44, height: 44, alignment: Alignment.center,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF322A91), Color(0xFF695CF4)]), borderRadius: BorderRadius.circular(15)),
                child: const Text('AM', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
              const SizedBox(width: 10),
              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AcadMind', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: ink)),
                Text('YOUR SMART ACADEMIC COMPANION', style: TextStyle(fontSize: 8, letterSpacing: 1, color: Color(0xFF858AA0))),
              ]),
              const Spacer(),
              if (widget.forceEdit) IconButton(onPressed: () => Navigator.pop(context, false), icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(21), decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
                colors: [Color(0xFF15183A), Color(0xFF37308E), Color(0xFF6355E9)]),
              borderRadius: BorderRadius.circular(25)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('PERSONALIZE YOUR LEARNING', style: TextStyle(color: Colors.white70, fontSize: 9, letterSpacing: 1.2, fontWeight: FontWeight.w800)),
                const SizedBox(height: 13),
                const Text('خلّينا نجهّز مساحتك الدراسية', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 7),
                Text('اختار فرقتك ومجموعتك والسكشن عشان يظهر لك جدولك وموادك الصحيحة.',
                  style: TextStyle(color: Colors.white.withValues(alpha: .78), fontSize: 12, height: 1.7)),
                if (selectedYear != null) ...[
                  const SizedBox(height: 12),
                  Text(selectedYear!['name_en'].toString(), textDirection: TextDirection.ltr,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ]),
            ),
            const SizedBox(height: 18),
            Row(children: List.generate(3, (i) => Expanded(child: Padding(
              padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 5),
              child: Column(children: [
                AnimatedContainer(duration: const Duration(milliseconds: 200), height: 5,
                  decoration: BoxDecoration(color: step >= i ? brand : const Color(0xFFE2E4EF), borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 6),
                Text(['الفرقة', 'المجموعة', 'السكشن'][i], style: TextStyle(
                  fontSize: 10, color: step == i ? brand : const Color(0xFF858AA0),
                  fontWeight: step == i ? FontWeight.w900 : FontWeight.w600)),
              ]),
            )))),
            const SizedBox(height: 23),
            AnimatedSwitcher(duration: const Duration(milliseconds: 240), child: step == 0 ? _yearStep() : step == 1 ? _groupStep() : _sectionStep()),
          ])),
          _footer(),
        ])),
      ),
    );
  }

  Widget _title(String number, String title, String subtitle) => Row(children: [
    Container(width: 36, height: 36, alignment: Alignment.center,
      decoration: BoxDecoration(color: const Color(0xFFECEBFF), borderRadius: BorderRadius.circular(12)),
      child: Text(number, style: const TextStyle(color: brand, fontWeight: FontWeight.w900, fontSize: 11))),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 16)),
      Text(subtitle, style: const TextStyle(color: Color(0xFF858AA0), fontSize: 10)),
    ])),
  ]);

  Widget _yearStep() => Column(key: const ValueKey('year'), crossAxisAlignment: CrossAxisAlignment.start, children: [
    _title('01', 'اختار الفرقة الدراسية', 'الفرقة الأولى متاحة، وباقي الفرق قيد التجهيز.'),
    const SizedBox(height: 14),
    ...years.map((y) {
      final active = y['status'] == 'active';
      final selected = y['id'].toString() == yearId;
      final waiting = interestedYears.contains(y['id'].toString());
      return Container(margin: const EdgeInsets.only(bottom: 9), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: selected ? const Color(0xFFF0EFFF) : Colors.white,
          borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? brand : const Color(0xFFE5E7F0))),
        child: Row(children: [
          CircleAvatar(backgroundColor: active ? const Color(0xFFECEBFF) : const Color(0xFFF0F1F5),
            child: Icon(active ? Icons.school_rounded : Icons.lock_clock_rounded, color: active ? brand : Colors.grey)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(y['name_en'].toString(), textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w900, color: ink, fontSize: 13)),
            Text(active ? 'المحتوى الدراسي متاح الآن' : 'سيتم إتاحة المحتوى لاحقاً',
              style: const TextStyle(color: Color(0xFF858AA0), fontSize: 10)),
          ])),
          if (active)
            selected ? const Icon(Icons.check_circle_rounded, color: brand, size: 24)
              : OutlinedButton(onPressed: loadingGroups ? null : () => chooseYear(y), child: const Text('اختيار'))
          else if (y['status'] == 'coming_soon')
            waiting ? const _Status(label: 'تم التسجيل', color: Color(0xFF22876A))
              : TextButton(onPressed: interestBusy ? null : () => notifyMe(y), child: const Text('نبّهني', style: TextStyle(color: brand)))
          else const _Status(label: 'مغلقة', color: Colors.grey),
        ]),
      );
    }),
    if (selectedYear != null) ...[
      const SizedBox(height: 14),
      Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5E7F0))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.menu_book_rounded, color: brand),
            const SizedBox(width: 8),
            const Expanded(child: Text('Available Subjects', style: TextStyle(fontWeight: FontWeight.w900, color: ink))),
            Text(subjects.length.toString(), style: const TextStyle(color: brand, fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 8),
          if (subjects.isEmpty) const Text('المواد ستظهر هنا عند إضافتها من الإدارة.',
            style: TextStyle(color: Color(0xFF858AA0), fontSize: 11)),
          ...subjects.map((s) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF269B8C), size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(s['name_en'].toString(), textDirection: TextDirection.ltr, textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ink))),
            Text(s['code']?.toString() ?? '', style: const TextStyle(fontSize: 9, color: Color(0xFF9296A8))),
          ]))),
        ]),
      ),
    ],
  ]);

  Widget _groupStep() => Column(key: const ValueKey('group'), crossAxisAlignment: CrossAxisAlignment.start, children: [
    _title('02', 'اختار مجموعتك', 'حدد المجموعة المسجل فيها بالكلية.'),
    const SizedBox(height: 15),
    if (loadingGroups) const Center(child: CircularProgressIndicator())
    else if (groups.isEmpty) const _Hint('لا توجد مجموعات مفتوحة لهذه الفرقة حالياً.', Icons.info_outline)
    else Row(children: groups.map((g) {
      final selected = g['id'].toString() == groupId;
      final code = g['code'].toString();
      return Expanded(child: Padding(padding: EdgeInsetsDirectional.only(end: code == 'G1' ? 6 : 0, start: code == 'G2' ? 6 : 0),
        child: _GroupCard(selected: selected, onTap: () => chooseGroup(g['id'].toString()), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(code, style: TextStyle(color: selected ? Colors.white : ink, fontSize: 27, fontWeight: FontWeight.w900))),
            Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? Colors.white : Colors.grey)]),
          const SizedBox(height: 7),
          Text(g['name'].toString(), style: TextStyle(color: selected ? Colors.white70 : Colors.grey, fontSize: 11)),
        ])),
      ));
    }).toList()),
  ]);

  Widget _sectionStep() => Column(key: const ValueKey('section'), crossAxisAlignment: CrossAxisAlignment.start, children: [
    _title('03', 'اختار السكشن', 'السكاشن المتاحة حسب المجموعة المختارة.'),
    const SizedBox(height: 15),
    if (selectedGroup != null) Padding(padding: const EdgeInsets.only(bottom: 13), child: Text(
      selectedGroup!['code'].toString() + ' • ' + sections.length.toString() + ' Sections',
      textDirection: TextDirection.ltr, style: const TextStyle(color: brand, fontWeight: FontWeight.w900, fontSize: 11))),
    if (loadingSections) const Center(child: CircularProgressIndicator())
    else if (sections.isEmpty) const _Hint('لا توجد سكاشن متاحة للمجموعة الحالية.', Icons.info_outline)
    else Wrap(spacing: 10, runSpacing: 10, children: sections.map((s) {
      final selected = s['id'].toString() == sectionId;
      return InkWell(onTap: () => setState(() => sectionId = s['id'].toString()), borderRadius: BorderRadius.circular(15),
        child: AnimatedContainer(duration: const Duration(milliseconds: 180), width: 100, height: 90,
          decoration: BoxDecoration(color: selected ? brand : Colors.white, borderRadius: BorderRadius.circular(15),
            border: Border.all(color: selected ? brand : const Color(0xFFE4E6F0))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(sectionNumber(s).toString(), style: TextStyle(color: selected ? Colors.white : ink, fontSize: 26, fontWeight: FontWeight.w900)),
            Text('Section', style: TextStyle(color: selected ? Colors.white70 : Colors.grey, fontSize: 10)),
          ]),
        ),
      );
    }).toList()),
    if (selectedSection != null) Container(margin: const EdgeInsets.only(top: 18), padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: const Color(0xFFEBF8F4), borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        const Icon(Icons.verified_rounded, color: Color(0xFF22876A)),
        const SizedBox(width: 9),
        Expanded(child: Text(selectedYear!['name_en'].toString() + ' • ' + selectedGroup!['code'].toString() + ' • ' + selectedSection!['name'].toString(),
          textDirection: TextDirection.ltr, textAlign: TextAlign.right,
          style: const TextStyle(color: Color(0xFF216B58), fontWeight: FontWeight.w800, fontSize: 11))),
      ])),
  ]);

  Widget _footer() => Container(padding: const EdgeInsets.fromLTRB(18, 11, 18, 15),
    decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE9EAF2)))),
    child: SafeArea(top: false, child: Row(children: [
      if (step > 0 || widget.forceEdit) ...[
        OutlinedButton(onPressed: saving ? null : () {
          if (step > 0) { setState(() => step--); }
          else if (widget.forceEdit) { Navigator.pop(context, false); }
        }, style: OutlinedButton.styleFrom(minimumSize: const Size(50, 52)), child: const Icon(Icons.arrow_forward)),
        const SizedBox(width: 8),
      ],
      Expanded(child: SizedBox(height: 52, child: FilledButton(
        onPressed: saving || (step == 0 && yearId == null) || (step == 1 && groupId == null) || (step == 2 && sectionId == null)
          ? null : step == 2 ? save : () => setState(() => step++),
        style: FilledButton.styleFrom(backgroundColor: brand, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : Text(step == 2 ? 'حفظ وإكمال' : 'متابعة', style: const TextStyle(fontWeight: FontWeight.w900)),
      ))),
    ])),
  );
}

class _GroupCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  const _GroupCard({required this.selected, required this.onTap, required this.child});
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFF5145D6) : Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(duration: const Duration(milliseconds: 180), padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? const Color(0xFF5145D6) : const Color(0xFFE4E6F0))),
        child: child)),
  );
}

class _Status extends StatelessWidget {
  final String label;
  final Color color;
  const _Status({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: .10), borderRadius: BorderRadius.circular(25)),
    child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
  );
}

class _Hint extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Hint(this.text, this.icon);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7F0))),
    child: Row(children: [Icon(icon, color: const Color(0xFF7771C9)), const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(color: Color(0xFF71768D), fontSize: 11)))]));
}
