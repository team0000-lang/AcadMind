import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../backend.dart';

class OwnerConsole extends StatefulWidget {
  const OwnerConsole({super.key});
  @override State<OwnerConsole> createState() => _OwnerConsoleState();
}

class _OwnerConsoleState extends State<OwnerConsole> with SingleTickerProviderStateMixin {
  late final TabController tabs = TabController(length: 7, vsync: this);
  Future<void> refresh() async { if(mounted) setState(() {}); }
  @override void dispose(){tabs.dispose();super.dispose();}
  @override Widget build(BuildContext context) => Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(16,12,16,4),child:Row(children:[const Expanded(child:Text('مركز إدارة AcadMind',style:TextStyle(fontSize:22,fontWeight:FontWeight.w900))),IconButton(onPressed:refresh,icon:const Icon(Icons.refresh))])),
    TabBar(controller:tabs,isScrollable:true,tabs:const [Tab(icon:Icon(Icons.people_alt_outlined),text:'الطلاب'),Tab(icon:Icon(Icons.menu_book_outlined),text:'المواد'),Tab(icon:Icon(Icons.calendar_month_outlined),text:'الجدول'),Tab(icon:Icon(Icons.upload_file_outlined),text:'مكتبة AI'),Tab(icon:Icon(Icons.campaign_outlined),text:'الإعلانات'),Tab(icon:Icon(Icons.system_update_alt),text:'التحديثات'),Tab(icon:Icon(Icons.feedback_outlined),text:'الاقتراحات')]),
    Expanded(child:TabBarView(controller:tabs,children:[StudentsAdmin(onChanged:refresh),SubjectsAdmin(onChanged:refresh),SchedulesAdmin(onChanged:refresh),KnowledgeAdmin(onChanged:refresh),AnnouncementsAdmin(onChanged:refresh),ReleaseAdmin(onChanged:refresh),FeedbackAdmin(onChanged:refresh)])),
  ]);
}

class StudentsAdmin extends StatefulWidget { final VoidCallback onChanged; const StudentsAdmin({super.key,required this.onChanged}); @override State<StudentsAdmin> createState()=>_StudentsAdminState(); }
class _StudentsAdminState extends State<StudentsAdmin> {
  late Future<List<Map<String,dynamic>>> future;
  @override void initState(){super.initState();future=load();}
  Future<List<Map<String,dynamic>>> load()=>supabase.from('profiles').select('id,full_name,email,phone,role,status,academic_year_id,group_id,section_id,academic_years(name_ar),groups(name),sections(name)').isFilter('deleted_at',null).order('created_at',ascending:false).then((v)=>List<Map<String,dynamic>>.from(v));
  void reload(){setState(()=>future=load());widget.onChanged();}
  Future<void> edit(Map<String,dynamic> p) async {
    final name=TextEditingController(text:'${p['full_name']??''}'); final phone=TextEditingController(text:'${p['phone']??''}');
    final years=List<Map<String,dynamic>>.from(await supabase.from('academic_years').select('id,name_ar').order('display_order'));
    String? year=p['academic_year_id']?.toString(), group=p['group_id']?.toString(), section=p['section_id']?.toString(); String status='${p['status']??'active'}';
    List<Map<String,dynamic>> groups=[]; List<Map<String,dynamic>> sections=[];
    Future<void> loadSections() async { sections=group==null?[]:List<Map<String,dynamic>>.from(await supabase.from('sections').select('id,name').eq('group_id',group!).eq('is_active',true).order('display_order')); if(!sections.any((x)=>x['id']==section))section=null; }
    Future<void> loadGroups() async { groups=year==null?[]:List<Map<String,dynamic>>.from(await supabase.from('groups').select('id,name').eq('academic_year_id',year!).eq('is_active',true).order('display_order')); if(!groups.any((x)=>x['id']==group))group=null; await loadSections(); }
    await loadGroups();
    if(!mounted)return;
    await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:const Text('تعديل بيانات الطالب'),content:SizedBox(width:480,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'اسم الطالب')),TextField(controller:phone,decoration:const InputDecoration(labelText:'رقم الهاتف')),const SizedBox(height:10),DropdownButtonFormField<String>(value:year,decoration:const InputDecoration(labelText:'السنة الدراسية'),items:years.map((e)=>DropdownMenuItem(value:'${e['id']}',child:Text('${e['name_ar']}'))).toList(),onChanged:(v)async{setD(()=>year=v);group=null;section=null;await loadGroups();setD((){});}),DropdownButtonFormField<String>(value:group,decoration:const InputDecoration(labelText:'المجموعة'),items:groups.map((e)=>DropdownMenuItem(value:'${e['id']}',child:Text('${e['name']}'))).toList(),onChanged:(v)async{setD(()=>group=v);section=null;await loadSections();setD((){});}),DropdownButtonFormField<String>(value:section,decoration:const InputDecoration(labelText:'الشعبة'),items:sections.map((e)=>DropdownMenuItem(value:'${e['id']}',child:Text('${e['name']}'))).toList(),onChanged:(v)=>setD(()=>section=v)),DropdownButtonFormField<String>(value:status,decoration:const InputDecoration(labelText:'حالة الحساب'),items:const [DropdownMenuItem(value:'active',child:Text('نشط')),DropdownMenuItem(value:'pending',child:Text('معلق')),DropdownMenuItem(value:'suspended',child:Text('موقوف'))],onChanged:(v)=>setD(()=>status=v??status))]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),FilledButton(onPressed:()async{try{await supabase.from('profiles').update({'full_name':name.text.trim(),'phone':phone.text.trim(),'academic_year_id':year,'group_id':group,'section_id':section,'status':status}).eq('id',p['id']);if(ctx.mounted)Navigator.pop(ctx);reload();}catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('فشل الحفظ: $e')));}},child:const Text('حفظ'))]))); 
    name.dispose();phone.dispose();
  }
  @override Widget build(BuildContext context)=>FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(c,s){if(!s.hasData)return s.hasError?Center(child:Text('خطأ: ${s.error}')):const Center(child:CircularProgressIndicator());final list=s.data!;return RefreshIndicator(onRefresh:()async=>reload(),child:ListView(padding:const EdgeInsets.all(12),children:[Text('إجمالي الحسابات: ${list.length}',style:const TextStyle(fontWeight:FontWeight.bold)),const SizedBox(height:8),if(list.isEmpty)const Text('لا توجد حسابات مسجلة حتى الآن'),...list.map((p){final y=p['academic_years'] is Map?p['academic_years']['name_ar']:'لم يحدد السنة';return Card(child:ListTile(leading:CircleAvatar(child:Text((p['full_name']??'ط').toString().isEmpty?'ط':(p['full_name']??'ط').toString().substring(0,1))),title:Text('${p['full_name']??'بدون اسم'}'),subtitle:Text('${p['email']??''}\n$y • ${p['status']} • ${p['role']}'),isThreeLine:true,trailing:IconButton(icon:const Icon(Icons.edit_outlined),onPressed:()=>edit(p))));})]));});
}

class SubjectsAdmin extends StatefulWidget {final VoidCallback onChanged;const SubjectsAdmin({super.key,required this.onChanged});@override State<SubjectsAdmin> createState()=>_SubjectsAdminState();}
class _SubjectsAdminState extends State<SubjectsAdmin>{late Future<List<Map<String,dynamic>>> future;@override void initState(){super.initState();future=load();}Future<List<Map<String,dynamic>>> load()=>supabase.from('subjects').select('id,name_ar,name_en,code,description,is_active,academic_year_id,icon_path').isFilter('deleted_at',null).order('name_ar').then((v)=>List<Map<String,dynamic>>.from(v));void reload(){setState(()=>future=load());widget.onChanged();}
Future<void> addSubject()async{final ar=TextEditingController(),en=TextEditingController(),code=TextEditingController(),desc=TextEditingController();String icon='menu_book';final ys=List<Map<String,dynamic>>.from(await supabase.from('academic_years').select('id,name_ar').order('display_order'));String? year=ys.isEmpty?null:'${ys.first['id']}';if(!mounted)return;await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:const Text('إضافة مادة'),content:SizedBox(width:420,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:ar,decoration:const InputDecoration(labelText:'اسم المادة بالعربي')),TextField(controller:en,decoration:const InputDecoration(labelText:'اسم المادة بالإنجليزي')),TextField(controller:code,decoration:const InputDecoration(labelText:'كود المادة')),TextField(controller:desc,decoration:const InputDecoration(labelText:'وصف المادة')),DropdownButtonFormField<String>(value:icon,decoration:const InputDecoration(labelText:'أيقونة المادة'),items:const [DropdownMenuItem(value:'business',child:Text('إدارة أعمال')),DropdownMenuItem(value:'language',child:Text('لغة')),DropdownMenuItem(value:'computer',child:Text('حاسب')),DropdownMenuItem(value:'code',child:Text('برمجة')),DropdownMenuItem(value:'science',child:Text('علوم')),DropdownMenuItem(value:'calculate',child:Text('رياضيات')),DropdownMenuItem(value:'menu_book',child:Text('كتاب'))],onChanged:(v)=>setD(()=>icon=v??'menu_book')),DropdownButtonFormField<String>(value:year,decoration:const InputDecoration(labelText:'السنة الدراسية'),items:ys.map((e)=>DropdownMenuItem(value:'${e['id']}',child:Text('${e['name_ar']}'))).toList(),onChanged:(v)=>setD(()=>year=v))]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),FilledButton(onPressed:()async{if(ar.text.trim().isEmpty||year==null)return;try{await supabase.from('subjects').insert({'name_ar':ar.text.trim(),'name_en':en.text.trim(),'code':code.text.trim().isEmpty?null:code.text.trim(),'description':desc.text.trim(),'academic_year_id':year,'icon_path':icon,'is_active':true});if(ctx.mounted)Navigator.pop(ctx);reload();}catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('$e')));}},child:const Text('إضافة'))])));ar.dispose();en.dispose();code.dispose();desc.dispose();}
Future<void> subjectActions(Map<String,dynamic> s)async{await showModalBottomSheet(context:context,builder:(ctx)=>SafeArea(child:Wrap(children:[ListTile(leading:const Icon(Icons.add),title:const Text('إضافة محاضرة'),onTap:(){Navigator.pop(ctx);_addLecture(s);}),ListTile(leading:const Icon(Icons.video_library),title:const Text('إضافة فيديو يوتيوب'),onTap:(){Navigator.pop(ctx);_addYoutube(s);}),ListTile(leading:const Icon(Icons.folder),title:const Text('إضافة مجلد Google Drive'),onTap:(){Navigator.pop(ctx);_addDrive(s);}),ListTile(leading:const Icon(Icons.tune),title:const Text('إدارة محاضرات وموارد المادة'),onTap:(){Navigator.pop(ctx);manageContent(s);}),ListTile(leading:const Icon(Icons.visibility_off),title:const Text('إخفاء المادة'),onTap:()async{Navigator.pop(ctx);await supabase.from('subjects').update({'is_active':false}).eq('id',s['id']);reload();})])));}
Future<void> manageContent(Map<String,dynamic> subject)async{
  final id=subject['id'];
  final lectures=List<Map<String,dynamic>>.from(await supabase.from('lectures').select('id,title').eq('subject_id',id).eq('is_active',true).isFilter('deleted_at',null));
  final videos=List<Map<String,dynamic>>.from(await supabase.from('youtube_resources').select('id,title').eq('subject_id',id).eq('is_active',true).isFilter('deleted_at',null));
  final drives=List<Map<String,dynamic>>.from(await supabase.from('drive_folders').select('id,folder_name').eq('subject_id',id).eq('is_active',true).isFilter('deleted_at',null));
  if(!mounted)return;
  await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text('محتوى ${subject['name_ar']}'),content:SizedBox(width:460,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('المحاضرات',style:TextStyle(fontWeight:FontWeight.bold)),...lectures.map((x)=>ListTile(dense:true,title:Text('${x['title']}'),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{await supabase.from('lectures').update({'is_active':false}).eq('id',x['id']);if(ctx.mounted)Navigator.pop(ctx);manageContent(subject);}))),const Divider(),const Text('فيديوهات YouTube',style:TextStyle(fontWeight:FontWeight.bold)),...videos.map((x)=>ListTile(dense:true,title:Text('${x['title']}'),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{await supabase.from('youtube_resources').update({'is_active':false}).eq('id',x['id']);if(ctx.mounted)Navigator.pop(ctx);manageContent(subject);}))),const Divider(),const Text('مجلدات Google Drive',style:TextStyle(fontWeight:FontWeight.bold)),...drives.map((x)=>ListTile(dense:true,title:Text('${x['folder_name']}'),trailing:IconButton(icon:const Icon(Icons.delete_outline),onPressed:()async{await supabase.from('drive_folders').update({'is_active':false}).eq('id',x['id']);if(ctx.mounted)Navigator.pop(ctx);manageContent(subject);}))) ]))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إغلاق'))]));
}
Future<void> _simpleForm(String title,List<(String,String)> fields,Future<void> Function(List<String>) save)async{final cs=fields.map((e)=>TextEditingController()).toList();if(!mounted)return;await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text(title),content:SizedBox(width:420,child:Column(mainAxisSize:MainAxisSize.min,children:List.generate(fields.length,(i)=>Padding(padding:const EdgeInsets.only(bottom:8),child:TextField(controller:cs[i],decoration:InputDecoration(labelText:fields[i].$1),keyboardType:fields[i].$2=='url'?TextInputType.url:TextInputType.text))))),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),FilledButton(onPressed:()async{try{await save(cs.map((e)=>e.text.trim()).toList());if(ctx.mounted)Navigator.pop(ctx);reload();}catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('فشل: $e')));}},child:const Text('حفظ'))]));for(final x in cs){x.dispose();}}
Future<void> _addLecture(Map s)=>_simpleForm('إضافة محاضرة', [('عنوان المحاضرة','text'),('رقم المحاضرة','text'),('الموضوع','text'),('الوصف','text')],(v)async{await supabase.from('lectures').insert({'subject_id':s['id'],'title':v[0],'lecture_number':int.tryParse(v[1]),'topic':v[2],'description':v[3],'is_active':true});});
Future<void> _addYoutube(Map s)=>_simpleForm('إضافة فيديو', [('عنوان الفيديو','text'),('رابط YouTube (HTTPS)','url'),('القناة','text'),('الوصف','text')],(v)async{final u=Uri.tryParse(v[1]);if(v[0].isEmpty||u==null||u.scheme!='https'||!(u.host=='youtube.com'||u.host=='www.youtube.com'||u.host=='youtu.be'))throw Exception('أدخل رابط يوتيوب صحيح');await supabase.from('youtube_resources').insert({'subject_id':s['id'],'title':v[0],'youtube_url':v[1],'channel':v[2],'description':v[3],'is_active':true});});
Future<void> _addDrive(Map s)async{await _simpleForm('إضافة مجلد Drive', [('اسم المجلد','text'),('رابط Google Drive','url'),('الوصف','text')],(v)async{final u=Uri.tryParse(v[1]);if(u==null||u.scheme!='https'||u.host!='drive.google.com')throw Exception('الرابط يجب أن يكون Google Drive');await supabase.from('drive_folders').insert({'subject_id':s['id'],'academic_year_id':s['academic_year_id'],'folder_name':v[0],'folder_url':v[1],'description':v[2],'is_active':true});});}
@override Widget build(BuildContext c)=>FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(c,s){if(!s.hasData)return s.hasError?Center(child:Text('${s.error}')):const Center(child:CircularProgressIndicator());return RefreshIndicator(onRefresh:()async=>reload(),child:ListView(padding:const EdgeInsets.all(12),children:[FilledButton.icon(onPressed:addSubject,icon:const Icon(Icons.add),label:const Text('إضافة مادة جديدة')),...s.data!.map((x)=>Card(child:ListTile(leading:CircleAvatar(child:Icon(switch(x['icon_path']){'business'=>Icons.business_center,'language'=>Icons.translate,'computer'=>Icons.computer,'code'=>Icons.code,'science'=>Icons.science,'calculate'=>Icons.functions,_=>Icons.menu_book})),title:Text('${x['name_ar']}'),subtitle:Text('${x['code']??''} • ${x['is_active']?'مفعلة':'مخفية'}'),trailing:IconButton(icon:const Icon(Icons.more_vert),onPressed:()=>subjectActions(x)))))]));});}

class SchedulesAdmin extends StatefulWidget {
  final VoidCallback onChanged;
  const SchedulesAdmin({super.key,required this.onChanged});
  @override State<SchedulesAdmin> createState()=>_SchedulesAdminState();
}
class _SchedulesAdminState extends State<SchedulesAdmin> {
  late Future<List<Map<String,dynamic>>> future;
  @override void initState(){super.initState();future=load();}
  Future<List<Map<String,dynamic>>> load()=>supabase.from('schedules')
    .select('id,subject_id,day_of_week,starts_at,ends_at,class_type,location,instructor,is_active,academic_year_id,group_id,section_id,subjects(name_ar),groups(name),sections(name)')
    .isFilter('deleted_at',null).order('day_of_week').order('starts_at')
    .then((v)=>List<Map<String,dynamic>>.from(v));
  void reload(){if(mounted)setState(()=>future=load());widget.onChanged();}
  @override Widget build(BuildContext c)=>FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(c,s){
    if(!s.hasData)return s.hasError?Center(child:Text('تعذر تحميل الجدول: ${s.error}')):const Center(child:CircularProgressIndicator());
    final rows=s.data!;
    return ListView(padding:const EdgeInsets.all(12),children:[
      FilledButton.icon(onPressed:()=>_scheduleForm(context,reload),icon:const Icon(Icons.add),label:const Text('إضافة موعد للجدول')),
      const SizedBox(height:10),
      if(rows.isEmpty)const Text('لا توجد مواعيد مضافة.'),
      ...rows.map((x)=>Card(child:ListTile(
        leading:CircleAvatar(child:Text('${(x['day_of_week'] as int)+1}')),
        title:Text('${(x['subjects'] is Map)?x['subjects']['name_ar']:'موعد'}'),
        subtitle:Text('${_day(x['day_of_week'] as int)} • ${x['starts_at']} - ${x['ends_at']}\n${x['location']??'بدون قاعة'} • ${x['instructor']??'لم يحدد المحاضر'}\n${(x['groups'] is Map)?x['groups']['name']??'': 'عام'} ${(x['sections'] is Map)?x['sections']['name']??'':''}'),
        isThreeLine:true,
        trailing:PopupMenuButton<String>(onSelected:(v)async{
          if(v=='edit')await _scheduleForm(context,reload,row:x);
          if(v=='hide'){await supabase.from('schedules').update({'is_active':false}).eq('id',x['id']);reload();}
        },itemBuilder:(_)=>const [PopupMenuItem(value:'edit',child:Text('تعديل الموعد')),PopupMenuItem(value:'hide',child:Text('إخفاء الموعد'))]),
      ))),
    ]);
  });
}
String _day(int d)=>['الأحد','الإثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت'][d.clamp(0,6)];

Future<void> _scheduleForm(BuildContext context,VoidCallback done,{Map<String,dynamic>? row}) async {
  final years=List<Map<String,dynamic>>.from(await supabase.from('academic_years').select('id,name_ar').order('display_order'));
  final subjects=List<Map<String,dynamic>>.from(await supabase.from('subjects').select('id,name_ar,academic_year_id').eq('is_active',true).isFilter('deleted_at',null).order('name_ar'));
  if(years.isEmpty||!context.mounted)return;
  String year='${row?['academic_year_id']??years.first['id']}';
  String? subject=row?['subject_id']?.toString();
  if(subject==null && row?['subject_id']!=null) subject='${row!['subject_id']}';
  final subjectOptions=subjects.where((e)=>e['academic_year_id']==year).toList();
  subject??=subjectOptions.isEmpty?null:'${subjectOptions.first['id']}';
  var groups=List<Map<String,dynamic>>.from(await supabase.from('groups').select('id,name,academic_year_id').eq('academic_year_id',year).eq('is_active',true).order('display_order'));
  String? group=row?['group_id']?.toString();
  var sections=group==null? <Map<String,dynamic>>[] : List<Map<String,dynamic>>.from(await supabase.from('sections').select('id,name,group_id').eq('group_id',group).eq('is_active',true).order('display_order'));
  String? section=row?['section_id']?.toString();
  int day=(row?['day_of_week'] as int?)??0;
  String type='${row?['class_type']??'lecture'}';
  final start=TextEditingController(text:row?['starts_at']?.toString().substring(0,5)??'09:00');
  final end=TextEditingController(text:row?['ends_at']?.toString().substring(0,5)??'10:00');
  final place=TextEditingController(text:'${row?['location']??''}');
  final teacher=TextEditingController(text:'${row?['instructor']??''}');
  if(!context.mounted)return;
  await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
    title:Text(row==null?'إضافة موعد':'تعديل الموعد'),
    content:SizedBox(width:480,child:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
      DropdownButtonFormField<String>(value:year,decoration:const InputDecoration(labelText:'السنة الدراسية'),items:years.map((e)=>DropdownMenuItem(value:'${e['id']}',child:Text('${e['name_ar']}'))).toList(),onChanged:(v)async{if(v==null)return;final g=await supabase.from('groups').select('id,name,academic_year_id').eq('academic_year_id',v).eq('is_active',true).order('display_order');if(!ctx.mounted)return;setD((){year=v;groups=List<Map<String,dynamic>>.from(g);group=null;section=null;sections=[];final matching=subjects.where((e)=>e['academic_year_id']==v).toList();subject=matching.isEmpty?null:'${matching.first['id']}';});}),
      DropdownButtonFormField<String>(value:subject,decoration:const InputDecoration(labelText:'المادة'),items:subjects.where((e)=>e['academic_year_id']==year).map((e)=>DropdownMenuItem(value:'${e['id']}',child:Text('${e['name_ar']}'))).toList(),onChanged:(v)=>setD(()=>subject=v)),
      DropdownButtonFormField<int>(value:day,decoration:const InputDecoration(labelText:'اليوم'),items:List.generate(7,(i)=>DropdownMenuItem(value:i,child:Text(_day(i)))),onChanged:(v)=>setD(()=>day=v??0)),
      DropdownButtonFormField<String>(value:type,decoration:const InputDecoration(labelText:'نوع الحصة'),items:const [DropdownMenuItem(value:'lecture',child:Text('محاضرة')),DropdownMenuItem(value:'section',child:Text('سكشن')),DropdownMenuItem(value:'practical',child:Text('عملي')),DropdownMenuItem(value:'lab',child:Text('معمل'))],onChanged:(v)=>setD(()=>type=v??'lecture')),
      DropdownButtonFormField<String>(value:group,decoration:const InputDecoration(labelText:'المجموعة (اختياري)'),items:groups.map((e)=>DropdownMenuItem(value:'${e['id']}',child:Text('${e['name']}'))).toList(),onChanged:(v)async{final data=v==null?[]:await supabase.from('sections').select('id,name,group_id').eq('group_id',v).eq('is_active',true).order('display_order');if(!ctx.mounted)return;setD((){group=v;section=null;sections=List<Map<String,dynamic>>.from(data);});}),
      DropdownButtonFormField<String>(value:section,decoration:const InputDecoration(labelText:'السكشن (اختياري)'),items:sections.where((e)=>e['group_id']==group).map((e)=>DropdownMenuItem(value:'${e['id']}',child:Text('${e['name']}'))).toList(),onChanged:(v)=>setD(()=>section=v)),
      TextField(controller:teacher,decoration:const InputDecoration(labelText:'اسم المحاضر / المعيد')),
      TextField(controller:start,decoration:const InputDecoration(labelText:'وقت البداية HH:MM')),
      TextField(controller:end,decoration:const InputDecoration(labelText:'وقت النهاية HH:MM')),
      TextField(controller:place,decoration:const InputDecoration(labelText:'المكان / القاعة')),
    ]))),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),
      FilledButton(onPressed:()async{
        try{
          final time=RegExp(r'^([01]\\d|2[0-3]):[0-5]\\d$');
          if(subject==null)throw Exception('اختر المادة');
          if(!time.hasMatch(start.text.trim())||!time.hasMatch(end.text.trim()))throw Exception('اكتب الوقت بصيغة HH:MM صحيحة');final startParts=start.text.trim().split(':').map(int.parse).toList();final endParts=end.text.trim().split(':').map(int.parse).toList();final startMinutes=startParts[0]*60+startParts[1];final endMinutes=endParts[0]*60+endParts[1];if(endMinutes<=startMinutes)throw Exception('وقت النهاية لازم يكون بعد وقت البداية');
          final payload={'academic_year_id':year,'subject_id':subject,'day_of_week':day,'class_type':type,'starts_at':start.text.trim(),'ends_at':end.text.trim(),'location':place.text.trim(),'instructor':teacher.text.trim(),'group_id':group,'section_id':section,'is_active':true};
          if(row==null){await supabase.from('schedules').insert(payload);}else{await supabase.from('schedules').update(payload).eq('id',row['id']);}
          if(ctx.mounted)Navigator.pop(ctx);done();
        }catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('تعذر الحفظ: $e')));}
      },child:Text(row==null?'إضافة':'حفظ التعديلات')),
    ],
  )));
  start.dispose();end.dispose();place.dispose();teacher.dispose();
}

class KnowledgeAdmin extends StatefulWidget{final VoidCallback onChanged;const KnowledgeAdmin({super.key,required this.onChanged});@override State<KnowledgeAdmin> createState()=>_KnowledgeAdminState();}
class _KnowledgeAdminState extends State<KnowledgeAdmin>{late Future<List<Map<String,dynamic>>> future;bool busy=false;@override void initState(){super.initState();future=load();}Future<List<Map<String,dynamic>>> load()=>supabase.from('knowledge_documents').select('id,document_name,status,mime_type,created_at,subjects(name_ar)').isFilter('deleted_at',null).order('created_at',ascending:false).then((v)=>List<Map<String,dynamic>>.from(v));void reload(){setState(()=>future=load());widget.onChanged();}
Future<void> upload()async{final subs=List<Map<String,dynamic>>.from(await supabase.from('subjects').select('id,name_ar').eq('is_active',true).isFilter('deleted_at',null).order('name_ar'));if(subs.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أضف مادة أولاً')));return;}String subject='${subs.first['id']}';final result=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['pdf','txt','docx'],withData:true);if(result==null||result.files.single.bytes==null)return;final file=result.files.single;final ext=(file.extension??'').toLowerCase();if(file.size>20*1024*1024){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('الحد الأقصى للملف 20 ميجابايت')));return;}if(!mounted)return;await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(title:const Text('ربط الملف بمادة'),content:DropdownButtonFormField<String>(value:subject,items:subs.map((e)=>DropdownMenuItem(value:'${e['id']}',child:Text('${e['name_ar']}'))).toList(),onChanged:(v)=>setD(()=>subject=v??subject)),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),FilledButton(onPressed:busy?null:()async{Navigator.pop(ctx);await processUpload(file,subject,ext);},child:const Text('رفع ومعالجة'))])));}
Future<void> processUpload(PlatformFile file,String subject,String ext)async{setState(()=>busy=true);String? docId;try{final mime={'pdf':'application/pdf','txt':'text/plain','docx':'application/vnd.openxmlformats-officedocument.wordprocessingml.document'}[ext]!;final uid=supabase.auth.currentUser!.id;final safe=file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'),'_');final path='$subject/$uid/${DateTime.now().millisecondsSinceEpoch}_${safe}';await supabase.storage.from('course-documents').uploadBinary(path,file.bytes!,fileOptions:FileOptions(contentType:mime,upsert:false));final doc=await supabase.from('knowledge_documents').insert({'subject_id':subject,'document_name':file.name,'mime_type':mime,'storage_path':path,'status':'uploaded','uploaded_by':uid}).select('id').single();final newDocId='${doc['id']}';docId=newDocId;await supabase.functions.invoke('ingest-knowledge',body:{'documentId':newDocId});if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم رفع الملف وتجهيزه للمساعد الذكي')));reload();}catch(e){if(docId!=null){try{await supabase.from('knowledge_documents').update({'status':'failed'}).eq('id',docId);}catch(_){}}if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('فشل رفع/معالجة الملف: $e')));}finally{if(mounted)setState(()=>busy=false);}}
@override Widget build(BuildContext c)=>FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(c,s){if(!s.hasData)return s.hasError?Center(child:Text('${s.error}')):const Center(child:CircularProgressIndicator());return ListView(padding:const EdgeInsets.all(12),children:[const Text('ارفع PDF أو Word أو TXT ليستخدمه المساعد في الإجابة من مراجع المواد.'),const SizedBox(height:10),FilledButton.icon(onPressed:busy?null:upload,icon:const Icon(Icons.cloud_upload_outlined),label:const Text('رفع ملف جديد')),if(busy)const LinearProgressIndicator(),const SizedBox(height:14),...s.data!.map((x)=>Card(child:ListTile(leading:const Icon(Icons.description_outlined),title:Text('${x['document_name']}'),subtitle:Text('${(x['subjects'] is Map)?x['subjects']['name_ar']:''} • ${x['status']}'),trailing:IconButton(tooltip:'أرشفة الملف',icon:const Icon(Icons.archive_outlined),onPressed:()async{try{await supabase.from('knowledge_documents').update({'status':'archived'}).eq('id',x['id']);reload();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}}))))]);});}

class AnnouncementsAdmin extends StatefulWidget{final VoidCallback onChanged;const AnnouncementsAdmin({super.key,required this.onChanged});@override State<AnnouncementsAdmin> createState()=>_AnnouncementsAdminState();}
class _AnnouncementsAdminState extends State<AnnouncementsAdmin>{final title=TextEditingController(),content=TextEditingController();bool busy=false;late Future<List<Map<String,dynamic>>> future;@override void initState(){super.initState();future=load();}Future<List<Map<String,dynamic>>> load()=>supabase.from('announcements').select('id,title,content,is_active,published_at').isFilter('deleted_at',null).order('published_at',ascending:false).then((v)=>List<Map<String,dynamic>>.from(v));void reload(){setState(()=>future=load());widget.onChanged();}@override void dispose(){title.dispose();content.dispose();super.dispose();}Future<void> add()async{if(title.text.trim().isEmpty||content.text.trim().isEmpty)return;setState(()=>busy=true);try{await supabase.from('announcements').insert({'title':title.text.trim(),'content':content.text.trim(),'target':'everyone','priority':2,'is_active':true});title.clear();content.clear();reload();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم نشر الإعلان')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('$e')));}finally{if(mounted)setState(()=>busy=false);}}@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('إعلان عام لكل الطلاب',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),TextField(controller:title,decoration:const InputDecoration(labelText:'العنوان')),const SizedBox(height:8),TextField(controller:content,minLines:3,maxLines:6,decoration:const InputDecoration(labelText:'نص الإعلان')),const SizedBox(height:10),FilledButton(onPressed:busy?null:add,child:const Text('نشر الإعلان')),const Divider(height:30),const Text('الإعلانات المنشورة',style:TextStyle(fontWeight:FontWeight.bold)),FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(c,s){if(!s.hasData)return s.hasError?Text('${s.error}'):const Center(child:CircularProgressIndicator());return Column(children:s.data!.map((x)=>Card(child:ListTile(title:Text('${x['title']}'),subtitle:Text('${x['is_active']?'ظاهر للطلاب':'مخفي'} • ${x['published_at']??''}'),trailing:IconButton(icon:Icon(x['is_active']==true?Icons.visibility_off:Icons.visibility),onPressed:()async{await supabase.from('announcements').update({'is_active':!(x['is_active']==true)}).eq('id',x['id']);reload();})))) .toList());})]);}

class ReleaseAdmin extends StatefulWidget{final VoidCallback onChanged;const ReleaseAdmin({super.key,required this.onChanged});@override State<ReleaseAdmin> createState()=>_ReleaseAdminState();}
class _ReleaseAdminState extends State<ReleaseAdmin>{final version=TextEditingController(),buildNumber=TextEditingController(),url=TextEditingController(),notes=TextEditingController();bool force=false,busy=false;@override void dispose(){version.dispose();buildNumber.dispose();url.dispose();notes.dispose();super.dispose();}Future<void> publish()async{final n=int.tryParse(buildNumber.text.trim()),u=Uri.tryParse(url.text.trim());if(version.text.trim().isEmpty||n==null||u==null||u.scheme!='https'){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('أدخل إصداراً ورقم بناء ورابط HTTPS صحيحاً')));return;}setState(()=>busy=true);try{await supabase.from('app_versions').insert({'platform':'android','version_name':version.text.trim(),'build_number':n,'update_url':u.toString(),'release_notes':notes.text.trim(),'minimum_supported_version':version.text.trim(),'force_update':force,'optional_update':!force,'enabled':true,'released_at':DateTime.now().toUtc().toIso8601String()});await supabase.from('update_settings').upsert({'platform':'android','minimum_supported_version':version.text.trim(),'force_update':force,'update_url':u.toString(),'message':notes.text.trim(),'enabled':true},onConflict:'platform');version.clear();buildNumber.clear();url.clear();notes.clear();if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم نشر التحديث')));widget.onChanged();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('فشل نشر التحديث: $e')));}finally{if(mounted)setState(()=>busy=false);}}@override Widget build(BuildContext c)=>ListView(padding:const EdgeInsets.all(16),children:[const Text('نشر إصدار Android جديد',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),TextField(controller:version,decoration:const InputDecoration(labelText:'رقم الإصدار مثل 1.0.2')),TextField(controller:buildNumber,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'رقم البناء')),TextField(controller:url,keyboardType:TextInputType.url,decoration:const InputDecoration(labelText:'رابط APK (HTTPS)')),TextField(controller:notes,minLines:2,maxLines:4,decoration:const InputDecoration(labelText:'ملاحظات التحديث')),SwitchListTile(value:force,onChanged:(v)=>setState(()=>force=v),title:const Text('تحديث إجباري')),FilledButton(onPressed:busy?null:publish,child:const Text('نشر التحديث'))]);}

class FeedbackAdmin extends StatefulWidget {
  final VoidCallback onChanged;
  const FeedbackAdmin({super.key,required this.onChanged});
  @override State<FeedbackAdmin> createState()=>_FeedbackAdminState();
}
class _FeedbackAdminState extends State<FeedbackAdmin> {
  late Future<List<Map<String,dynamic>>> future;
  @override void initState(){super.initState();future=load();}
  Future<List<Map<String,dynamic>>> load()=>supabase.from('feedback').select('id,user_id,category,subject,message,status,admin_reply,created_at,profiles(full_name,email)').order('created_at',ascending:false).then((v)=>List<Map<String,dynamic>>.from(v));
  void reload(){setState(()=>future=load());widget.onChanged();}
  String category(String v)=>switch(v){'suggestion'=>'اقتراح','bug'=>'مشكلة تقنية','content'=>'محتوى دراسي',_=>'أخرى'};
  String status(String v)=>switch(v){'new'=>'جديدة','in_progress'=>'قيد المتابعة','resolved'=>'تم الحل',_=>'مغلقة'};
  Future<void> edit(Map<String,dynamic> item)async{
    String value='${item['status']}';
    final reply=TextEditingController(text:'${item['admin_reply']??''}');
    await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setD)=>AlertDialog(
      title:Text('${item['subject']}'),
      content:SizedBox(width:450,child:SingleChildScrollView(child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisSize:MainAxisSize.min,children:[
        Text('${item['message']}'),
        const SizedBox(height:12),
        DropdownButtonFormField<String>(value:value,decoration:const InputDecoration(labelText:'حالة الطلب'),items:const [DropdownMenuItem(value:'new',child:Text('جديدة')),DropdownMenuItem(value:'in_progress',child:Text('قيد المتابعة')),DropdownMenuItem(value:'resolved',child:Text('تم الحل')),DropdownMenuItem(value:'closed',child:Text('مغلقة'))],onChanged:(v)=>setD(()=>value=v??value)),
        const SizedBox(height:10),TextField(controller:reply,minLines:2,maxLines:5,decoration:const InputDecoration(labelText:'رد الإدارة (اختياري)')),
      ]))),
      actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),FilledButton(onPressed:()async{try{await supabase.from('feedback').update({'status':value,'admin_reply':reply.text.trim().isEmpty?null:reply.text.trim(),'updated_at':DateTime.now().toUtc().toIso8601String()}).eq('id',item['id']);if(ctx.mounted)Navigator.pop(ctx);reload();}catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('$e')));}},child:const Text('حفظ'))],
    )));
    reply.dispose();
  }
  @override Widget build(BuildContext c)=>FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(c,s){
    if(!s.hasData)return s.hasError?Center(child:Text('تعذر تحميل الرسائل: ${s.error}')):const Center(child:CircularProgressIndicator());
    final rows=s.data!;
    return RefreshIndicator(onRefresh:()async=>reload(),child:ListView(padding:const EdgeInsets.all(12),children:[
      Text('إجمالي الرسائل: ${rows.length}',style:const TextStyle(fontWeight:FontWeight.w800)),
      if(rows.isEmpty)const Padding(padding:EdgeInsets.all(25),child:Text('لا توجد اقتراحات أو بلاغات بعد.',textAlign:TextAlign.center)),
      ...rows.map((x)=>Card(child:ListTile(
        leading:const CircleAvatar(child:Icon(Icons.feedback_outlined)),
        title:Text('${x['subject']}'),
        subtitle:Text('${category('${x['category']}')} • ${status('${x['status']}')}\n${(x['profiles'] is Map)?x['profiles']['email']??'طالب':''}'),
        isThreeLine:true,
        trailing:IconButton(icon:const Icon(Icons.open_in_new),onPressed:()=>edit(x)),
      ))),
    ]));
  });
}

