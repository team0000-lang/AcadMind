import 'package:flutter/material.dart';
import '../backend.dart';

class AcademicYearsAdmin extends StatefulWidget {
  final VoidCallback onChanged;
  const AcademicYearsAdmin({super.key, required this.onChanged});
  @override
  State<AcademicYearsAdmin> createState() => _AcademicYearsAdminState();
}

class _AcademicYearsAdminState extends State<AcademicYearsAdmin> {
  late Future<Map<String, dynamic>> future;
  bool busy = false;
  @override
  void initState() { super.initState(); future = load(); }

  Future<Map<String, dynamic>> load() async {
    final result = await Future.wait<dynamic>([
      supabase.from('academic_years').select('id,name_ar,name_en,code,status,display_order').isFilter('deleted_at', null).order('display_order'),
      supabase.from('groups').select('id,name,code,academic_year_id,is_active').isFilter('deleted_at', null).order('display_order'),
      supabase.from('sections').select('id,name,code,group_id,academic_year_id,is_active').isFilter('deleted_at', null).order('display_order'),
      supabase.from('academic_year_interest').select('id,user_id,academic_year_id,created_at').order('created_at', ascending: false),
    ]);
    final interests = List<Map<String, dynamic>>.from(result[3] as List);
    final ids = interests.map((e) => e['user_id'].toString()).toSet().toList();
    final profiles = ids.isEmpty ? <Map<String, dynamic>>[] : List<Map<String, dynamic>>.from(
      await supabase.from('profiles').select('id,full_name,email').inFilter('id', ids).isFilter('deleted_at', null));
    return {
      'years': List<Map<String, dynamic>>.from(result[0] as List),
      'groups': List<Map<String, dynamic>>.from(result[1] as List),
      'sections': List<Map<String, dynamic>>.from(result[2] as List),
      'interests': interests,
      'profiles': {for (final p in profiles) p['id'].toString(): p},
    };
  }

  void reload() {
    if (!mounted) return;
    setState(() => future = load());
    widget.onChanged();
  }

  Future<void> updateRow(String table, String id, String field, dynamic value) async {
    try {
      setState(() => busy = true);
      await supabase.from(table).update({field: value, 'updated_at': DateTime.now().toUtc().toIso8601String()}).eq('id', id);
      reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تعذر الحفظ: ' + e.toString())));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasError) return Center(child: Text('تعذر تحميل إعدادات الفرق: ' + snapshot.error.toString()));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final data = snapshot.data!;
      final years = data['years'] as List<Map<String, dynamic>>;
      final groups = data['groups'] as List<Map<String, dynamic>>;
      final sections = data['sections'] as List<Map<String, dynamic>>;
      final interests = data['interests'] as List<Map<String, dynamic>>;
      final profiles = data['profiles'] as Map<String, dynamic>;
      return RefreshIndicator(
        onRefresh: () async { reload(); },
        child: ListView(padding: const EdgeInsets.all(13), children: [
          const Text('إدارة الفرق الدراسية', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 5),
          const Text('تحكم في إتاحة كل فرقة ومجموعة وسكشن، وشاهد الطلاب المهتمين بالفرق القادمة.',
            style: TextStyle(color: Color(0xFF858AA0), fontSize: 11, height: 1.5)),
          const SizedBox(height: 12),
          ...years.map((year) {
            final id = year['id'].toString();
            final yearGroups = groups.where((g) => g['academic_year_id'].toString() == id).toList();
            final waiters = interests.where((r) => r['academic_year_id'].toString() == id).toList();
            final status = year['status'].toString();
            return Card(
              margin: const EdgeInsets.only(bottom: 11),
              child: ExpansionTile(
                initiallyExpanded: status == 'active',
                leading: CircleAvatar(
                  backgroundColor: status == 'active' ? const Color(0xFFECEBFF) : const Color(0xFFF0F1F5),
                  child: Icon(status == 'active' ? Icons.school : Icons.lock_clock,
                    color: status == 'active' ? const Color(0xFF5145D6) : Colors.grey)),
                title: Text(year['name_en'].toString(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                subtitle: Text(year['code'].toString() + ' • ' + waiters.length.toString() + ' طلب اهتمام',
                  style: const TextStyle(fontSize: 10)),
                childrenPadding: const EdgeInsets.fromLTRB(13, 0, 13, 13),
                children: [
                  DropdownButtonFormField<String>(
                    value: status, decoration: const InputDecoration(labelText: 'حالة الفرقة'),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('متاحة الآن')),
                      DropdownMenuItem(value: 'coming_soon', child: Text('قريباً')),
                      DropdownMenuItem(value: 'disabled', child: Text('مغلقة')),
                    ],
                    onChanged: busy ? null : (v) { if (v != null && v != status) updateRow('academic_years', id, 'status', v); },
                  ),
                  const SizedBox(height: 12),
                  const Align(alignment: Alignment.centerRight, child: Text('المجموعات', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12))),
                  ...yearGroups.map((g) {
                    final groupSections = sections.where((s) => s['group_id'].toString() == g['id'].toString()).toList();
                    return Container(
                      margin: const EdgeInsets.only(top: 7),
                      decoration: BoxDecoration(color: const Color(0xFFF7F7FC), borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: const Color(0xFFE8E9F2))),
                      child: Column(children: [
                        SwitchListTile(
                          dense: true, value: g['is_active'] == true, onChanged: busy ? null : (v) => updateRow('groups', g['id'].toString(), 'is_active', v),
                          title: Text(g['code'].toString() + ' • ' + g['name'].toString(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                          subtitle: Text(groupSections.where((s) => s['is_active'] == true).length.toString() + ' سكاشن مفعلة', style: const TextStyle(fontSize: 10)),
                        ),
                        if (groupSections.isNotEmpty) Padding(
                          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                          child: Wrap(spacing: 7, runSpacing: 5, children: groupSections.map((s) {
                            final enabled = s['is_active'] == true;
                            return FilterChip(
                              selected: enabled, showCheckmark: enabled,
                              label: Text(s['name'].toString(), style: const TextStyle(fontSize: 10)),
                              onSelected: busy ? null : (v) => updateRow('sections', s['id'].toString(), 'is_active', v),
                              selectedColor: const Color(0xFFECEBFF), backgroundColor: Colors.white,
                            );
                          }).toList()),
                        ),
                      ]),
                    );
                  }),
                  if (yearGroups.isEmpty) const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text('لم تتم إضافة مجموعات لهذه الفرقة بعد.', style: TextStyle(fontSize: 11, color: Color(0xFF858AA0)))),
                  const Divider(height: 22),
                  Row(children: [
                    const Expanded(child: Text('قائمة المهتمين بالفرقة', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12))),
                    Text(waiters.length.toString() + ' طالب', style: const TextStyle(color: Color(0xFF5145D6), fontWeight: FontWeight.w900, fontSize: 11)),
                  ]),
                  if (waiters.isEmpty) const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Text('لا توجد طلبات اهتمام حتى الآن.', style: TextStyle(fontSize: 11, color: Color(0xFF858AA0))))
                  else ...waiters.map((item) {
                    final p = profiles[item['user_id'].toString()] as Map<String, dynamic>?;
                    final date = DateTime.tryParse(item['created_at'].toString())?.toLocal();
                    final dateText = date == null ? '' : date.day.toString() + '/' + date.month.toString() + '/' + date.year.toString();
                    return ListTile(
                      dense: true, contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(radius: 16, child: Icon(Icons.person_outline, size: 17)),
                      title: Text(p?['full_name']?.toString() ?? 'طالب AcadMind', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)),
                      subtitle: Text(p?['email']?.toString() ?? 'البريد غير متاح', style: const TextStyle(fontSize: 10)),
                      trailing: Text(dateText, style: const TextStyle(color: Color(0xFF9296A8), fontSize: 9)),
                    );
                  }),
                  if (waiters.isNotEmpty) const Text(
                    'هذه قائمة اهتمام داخل لوحة الإدارة. إرسال Push عند فتح الفرقة يحتاج إعداد خدمة إشعارات خارجية.',
                    style: TextStyle(color: Color(0xFF9296A8), fontSize: 9, height: 1.5)),
                ],
              ),
            );
          }),
        ]),
      );
    },
  );
}
