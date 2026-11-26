import 'package:supabase_flutter/supabase_flutter.dart';
import 'backend.dart';

class AcadMindData {
  static Future<Map<String, dynamic>> profile() async {
    final id = supabase.auth.currentUser!.id;
    return await supabase.from('profiles').select('*, academic_years(name_ar,name_en), groups(name), sections(name)').eq('id', id).single();
  }
  static Future<List<Map<String, dynamic>>> subjects() async => List<Map<String,dynamic>>.from(await supabase.from('subjects').select('id,name_ar,name_en,description,code,icon_path').eq('is_active', true).isFilter('deleted_at', null).order('display_order'));
  static Future<List<Map<String, dynamic>>> announcements() async => List<Map<String,dynamic>>.from(await supabase.from('announcements').select('id,title,content,priority,published_at').eq('is_active', true).isFilter('deleted_at', null).order('published_at', ascending: false).limit(30));
  static Future<List<Map<String, dynamic>>> schedule() async {
    final p = await profile();
    var q = supabase.from('schedules').select('id,class_type,day_of_week,starts_at,ends_at,location,description,subjects(name_ar,name_en)').eq('is_active', true).isFilter('deleted_at', null);
    if (p['academic_year_id'] != null) q = q.eq('academic_year_id', p['academic_year_id']);
    if (p['group_id'] != null) q = q.or('group_id.is.null,group_id.eq.${p['group_id']}');
    if (p['section_id'] != null) q = q.or('section_id.is.null,section_id.eq.${p['section_id']}');
    return List<Map<String,dynamic>>.from(await q.order('day_of_week').order('starts_at'));
  }
  static Future<bool> isOwner() async => (await profile())['role'] == 'owner';
}
