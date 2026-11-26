import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../backend.dart';
import '../services.dart';
import '../notification_service.dart';
import '../update_service.dart';
import 'owner_console.dart';
import '../app_preferences.dart';

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
 int tab=0; bool owner=false;
 @override void initState(){super.initState();_loadRole();WidgetsBinding.instance.addPostFrameCallback((_)=>UpdateService.check(context));}
 Future<void> _loadRole() async {try{final v=await AcadMindData.isOwner();if(mounted)setState(()=>owner=v);}catch(_) {}}
 Future<void> refresh() async {setState((){});_loadRole();}
 @override Widget build(BuildContext context){final pages=[DashboardPage(onNavigate:(v)=>setState(()=>tab=v)),const SubjectsPage(),const SchedulePage(),const AnnouncementsPage(),const AiPage(),const ProfilePage(),if(owner)const OwnerPage()];final destinations=<NavigationDestination>[const NavigationDestination(icon:Icon(Icons.home_outlined),selectedIcon:Icon(Icons.home),label:'الرئيسية'),const NavigationDestination(icon:Icon(Icons.menu_book_outlined),label:'المواد'),const NavigationDestination(icon:Icon(Icons.calendar_month_outlined),label:'الجدول'),const NavigationDestination(icon:Icon(Icons.campaign_outlined),label:'الإعلانات'),const NavigationDestination(icon:Icon(Icons.auto_awesome_outlined),label:'AcadMind AI'),const NavigationDestination(icon:Icon(Icons.person_outline),label:'حسابي'),if(owner)const NavigationDestination(icon:Icon(Icons.admin_panel_settings_outlined),label:'الإدارة')];return Scaffold(appBar:AppBar(title:const Text('AcadMind',style:TextStyle(fontWeight:FontWeight.w900)),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh)),IconButton(onPressed:()async{await supabase.auth.signOut();},icon:const Icon(Icons.logout))]),body:pages[tab],bottomNavigationBar:NavigationBar(selectedIndex:tab,destinations:destinations,onDestinationSelected:(v)=>setState(()=>tab=v),labelBehavior:NavigationDestinationLabelBehavior.onlyShowSelected));}
}

class DashboardPage extends StatelessWidget {
  final ValueChanged<int> onNavigate;
  const DashboardPage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      FutureBuilder<Map<String, dynamic>>(
        future: AcadMindData.profile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;
          final name = profile == null ? 'طالب' : (profile['full_name'] ?? 'طالب').toString();
          final academic = profile?['academic_years'];
          final year = academic is Map ? (academic['name_ar'] ?? '').toString() : '';
          return Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF263FAE), Color(0xFF5276F0)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('أهلاً بيك 👋', style: TextStyle(color: Colors.white70)),
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(year.isEmpty ? 'منظّمك الدراسي في مكان واحد' : year, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 22),
      const Text('الوصول السريع', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.55,
        children: [
          _QuickTile(icon: Icons.menu_book, title: 'المواد الدراسية', subtitle: 'محاضرات ومصادر', onTap: () => onNavigate(1)),
          _QuickTile(icon: Icons.calendar_month, title: 'جدول المحاضرات', subtitle: 'مواعيدك الأسبوعية', onTap: () => onNavigate(2)),
          _QuickTile(icon: Icons.campaign, title: 'الإعلانات', subtitle: 'آخر أخبار الكلية', onTap: () => onNavigate(3)),
          _QuickTile(icon: Icons.auto_awesome, title: 'المساعد الذكي', subtitle: 'اسأل وذاكر بذكاء', onTap: () => onNavigate(4)),
        ],
      ),
      const SizedBox(height: 22),
      const Text('آخر الإعلانات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      FutureBuilder<List<Map<String, dynamic>>>(
        future: AcadMindData.announcements(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return _ErrorBox(message: 'تعذر تحميل الإعلانات: ${snapshot.error}');
          final items = snapshot.data ?? [];
          if (items.isEmpty) return const _EmptyBox(text: 'لا توجد إعلانات حالياً');
          return Column(children: items.take(3).map((item) => _AnnouncementCard(item: item)).toList());
        },
      ),
    ],
  );
}

class _QuickTile extends StatelessWidget {final IconData icon;final String title,subtitle;final VoidCallback onTap;const _QuickTile({required this.icon,required this.title,required this.subtitle,required this.onTap});@override Widget build(BuildContext c)=>Card(child:InkWell(borderRadius:BorderRadius.circular(20),onTap:onTap,child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,color:Theme.of(c).colorScheme.primary,size:27),const SizedBox(height:9),Text(title,style:const TextStyle(fontWeight:FontWeight.bold)),Text(subtitle,style:const TextStyle(fontSize:12,color:Colors.black54))]))));}
class SubjectsPage extends StatelessWidget {const SubjectsPage({super.key});@override Widget build(BuildContext c)=>_AsyncList<Map<String,dynamic>>(future:AcadMindData.subjects(),empty:'لا توجد مواد مضافة لحسابك بعد',builder:(item)=>ListTile(leading:const CircleAvatar(child:Icon(Icons.menu_book)),title:Text((item['name_ar']??item['name_en']??'مادة') as String),subtitle:Text((item['description']??item['code']??'') as String),trailing:const Icon(Icons.chevron_left),onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>SubjectDetailPage(subject:item)))));}
class SubjectDetailPage extends StatelessWidget {
  final Map<String, dynamic> subject;
  const SubjectDetailPage({super.key, required this.subject});

  Future<Map<String, List<Map<String, dynamic>>>> loadContent() async {
    final id = subject['id'];
    final lectures = await supabase.from('lectures').select('id,title,topic,description,notes,lecture_number').eq('subject_id', id).eq('is_active', true).order('display_order');
    final videos = await supabase.from('youtube_resources').select('id,title,youtube_url,description,channel').eq('subject_id', id).eq('is_active', true).order('display_order');
    final folders = await supabase.from('drive_folders').select('id,folder_name,folder_url,description').eq('subject_id', id).eq('is_active', true).order('display_order');
    return {'lectures': List<Map<String, dynamic>>.from(lectures), 'videos': List<Map<String, dynamic>>.from(videos), 'folders': List<Map<String, dynamic>>.from(folders)};
  }

  Future<void> openLink(String value) async {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.scheme == 'https') await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(title: Text((subject['name_ar'] ?? 'المادة') as String)),
    body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
      future: loadContent(),
      builder: (c, s) {
        if (s.hasError) return _ErrorBox(message: 'تعذر تحميل محتوى المادة: ${s.error}');
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        final data = s.data!;
        return ListView(padding: const EdgeInsets.all(12), children: [
          const Text('المحاضرات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          if (data['lectures']!.isEmpty) const _EmptyBox(text: 'لا توجد محاضرات مضافة بعد'),
          ...data['lectures']!.map((e) => Card(child: ListTile(leading: const Icon(Icons.play_lesson_outlined), title: Text(e['title'] as String), subtitle: Text((e['topic'] ?? e['description'] ?? '') as String)))),
          const Divider(height: 32),
          const Text('فيديوهات الشرح', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          if (data['videos']!.isEmpty) const _EmptyBox(text: 'لا توجد فيديوهات مضافة بعد'),
          ...data['videos']!.map((e) => Card(child: ListTile(leading: const Icon(Icons.play_circle_outline), title: Text(e['title'] as String), subtitle: Text((e['channel'] ?? e['description'] ?? '') as String), trailing: const Icon(Icons.open_in_new), onTap: () => openLink(e['youtube_url'] as String)))),
          const Divider(height: 32),
          const Text('ملفات ومجلدات المادة', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          if (data['folders']!.isEmpty) const _EmptyBox(text: 'لا توجد روابط ملفات مضافة بعد'),
          ...data['folders']!.map((e) => Card(child: ListTile(leading: const Icon(Icons.folder_open), title: Text(e['folder_name'] as String), subtitle: Text((e['description'] ?? '') as String), trailing: const Icon(Icons.open_in_new), onTap: () => openLink(e['folder_url'] as String)))),
        ]);
      },
    ),
  );
}

class SchedulePage extends StatefulWidget {const SchedulePage({super.key});@override State<SchedulePage> createState()=>_SchedulePageState();}
class _SchedulePageState extends State<SchedulePage> {static const days=['الأحد','الإثنين','الثلاثاء','الأربعاء','الخميس','الجمعة','السبت'];late Future<List<Map<String,dynamic>>> future;@override void initState(){super.initState();future=_load();}Future<List<Map<String,dynamic>>> _load()async{final rows=await AcadMindData.schedule();await NotificationService.instance.syncSchedule(rows);return rows;}@override Widget build(BuildContext c)=>_AsyncList<Map<String,dynamic>>(future:future,empty:'الجدول غير متاح بعد. تأكد أن الإدارة عيّنت السنة والمجموعة والشعبة لحسابك.',builder:(e)=>ListTile(leading:CircleAvatar(child:Text('${(e['day_of_week'] as int)+1}')),title:Text(((e['subjects'] is Map)?(e['subjects']['name_ar']??e['subjects']['name_en']):null)??'محاضرة'),subtitle:Text('${days[e['day_of_week'] as int]} • ${e['starts_at']} - ${e['ends_at']}\n${e['location']??''}'),isThreeLine:true,trailing:Text((e['class_type']??'') as String)));}
class AnnouncementsPage extends StatelessWidget {const AnnouncementsPage({super.key});@override Widget build(BuildContext c)=>_AsyncList<Map<String,dynamic>>(future:AcadMindData.announcements(),empty:'لا توجد إعلانات حالياً',builder:(e)=>_AnnouncementCard(item:e));}
class _AnnouncementCard extends StatelessWidget {final Map<String,dynamic> item;const _AnnouncementCard({required this.item});@override Widget build(BuildContext c)=>Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[const Icon(Icons.campaign,color:Color(0xFF3157D5)),const SizedBox(width:8),Expanded(child:Text((item['title']??'إعلان') as String,style:const TextStyle(fontWeight:FontWeight.bold,fontSize:16))),Text('${item['priority']??0}/5',style:const TextStyle(fontSize:11,color:Colors.black45))]),const SizedBox(height:8),Text((item['content']??'') as String),const SizedBox(height:5),Text((item['published_at']??'') as String,style:const TextStyle(fontSize:11,color:Colors.black45))])));}
class AiPage extends StatefulWidget { const AiPage({super.key}); @override State<AiPage> createState()=>_AiPageState(); }
class _AiPageState extends State<AiPage> {
  final input=TextEditingController();
  final messages=<Map<String,dynamic>>[];
  bool busy=false;
  String? subjectId;
  late Future<List<Map<String,dynamic>>> subjectFuture;
  @override void initState(){super.initState();subjectFuture=supabase.from('subjects').select('id,name_ar').eq('is_active',true).isFilter('deleted_at',null).order('name_ar').then((v)=>List<Map<String,dynamic>>.from(v));}
  @override void dispose(){input.dispose();super.dispose();}
  Future<void> send() async {
    final q=input.text.trim(); if(q.isEmpty||busy)return;
    setState((){messages.add({'role':'user','content':q});busy=true;}); input.clear();
    try {
      final response=await supabase.functions.invoke('ai-chat',body:{'question':q,'subjectId':subjectId,'retrieve':true});
      final data=response.data as Map<String,dynamic>;
      final answer=(data['answer']??data['message']??data['error']??'لم يصل رد من المساعد.').toString();
      final sources=List<Map<String,dynamic>>.from((data['sources'] as List? ?? const []).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)));
      if(mounted)setState(()=>messages.add({'role':'assistant','content':answer,'sources':sources}));
    } on FunctionException catch(e) { if(mounted)setState(()=>messages.add({'role':'assistant','content':'تعذر تشغيل المساعد: ${e.details??e.reasonPhrase??e.toString()}','sources':[]})); }
    catch(e) { if(mounted)setState(()=>messages.add({'role':'assistant','content':'حدث خطأ أثناء الاتصال بالمساعد: $e','sources':[]})); }
    finally {if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext c)=>Column(children:[
    Padding(padding:const EdgeInsets.fromLTRB(12,10,12,4),child:FutureBuilder<List<Map<String,dynamic>>>(future:subjectFuture,builder:(c,s){final items=s.data??[];return DropdownButtonFormField<String>(value:subjectId,decoration:const InputDecoration(labelText:'المادة المستخدمة كمصدر للإجابة',prefixIcon:Icon(Icons.menu_book)),items:[const DropdownMenuItem<String>(value:null,child:Text('سؤال عام بدون تحديد مادة')),...items.map((e)=>DropdownMenuItem<String>(value:'${e['id']}',child:Text('${e['name_ar']}')))],onChanged:(v)=>setState(()=>subjectId=v));})),
    Expanded(child:messages.isEmpty?const Center(child:Padding(padding:EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.auto_awesome,size:48,color:Color(0xFF3157D5)),SizedBox(height:14),Text('اسأل AcadMind AI',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),Text('اختر المادة للحصول على إجابة مدعومة بملفات المحاضرات التي رفعتها الإدارة.',textAlign:TextAlign.center)]))):ListView(padding:const EdgeInsets.all(12),children:messages.map((m)=>Align(alignment:m['role']=='user'?Alignment.centerRight:Alignment.centerLeft,child:Container(margin:const EdgeInsets.symmetric(vertical:6),padding:const EdgeInsets.all(14),constraints:const BoxConstraints(maxWidth:600),decoration:BoxDecoration(color:m['role']=='user'?const Color(0xFFE4EAFE):Colors.white,borderRadius:BorderRadius.circular(16)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[m['role']=='assistant'?MarkdownBody(data:m['content'] as String):Text(m['content'] as String),if((m['sources'] as List? ?? const []).isNotEmpty)...[const Divider(),const Text('المراجع المستخدمة',style:TextStyle(fontWeight:FontWeight.bold)),...(m['sources'] as List).map((src)=>Text('• ${src['documentName']??'ملف المادة'}${src['page']==null?'':' — صفحة ${src['page']}'}',style:const TextStyle(fontSize:12)))]])))).toList())),
    if(busy)const LinearProgressIndicator(),
    SafeArea(child:Padding(padding:const EdgeInsets.all(10),child:Row(children:[Expanded(child:TextField(controller:input,minLines:1,maxLines:4,decoration:const InputDecoration(hintText:'اكتب سؤالك هنا...'))),const SizedBox(width:8),IconButton.filled(onPressed:busy?null:send,icon:const Icon(Icons.send))])))
  ]);
}

class ProfilePage extends StatefulWidget { const ProfilePage({super.key}); @override State<ProfilePage> createState()=>_ProfilePageState(); }
class _ProfilePageState extends State<ProfilePage> {
  late Future<Map<String,dynamic>> future;
  @override void initState(){super.initState();future=AcadMindData.profile();}
  Future<void> reload()async{setState(()=>future=AcadMindData.profile());}
  Future<void> edit(Map<String,dynamic> p)async{
    final name=TextEditingController(text:'${p['full_name']??''}'),phone=TextEditingController(text:'${p['phone']??''}');
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('تعديل الملف الشخصي'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:name,decoration:const InputDecoration(labelText:'الاسم')),TextField(controller:phone,decoration:const InputDecoration(labelText:'رقم الهاتف'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),FilledButton(onPressed:()async{try{await supabase.from('profiles').update({'full_name':name.text.trim(),'phone':phone.text.trim()}).eq('id',supabase.auth.currentUser!.id);if(ctx.mounted)Navigator.pop(ctx);reload();}catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('فشل الحفظ: $e')));}},child:const Text('حفظ'))]));name.dispose();phone.dispose();
  }
  Future<void> changePassword()async{final password=TextEditingController(),confirm=TextEditingController();await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('تغيير كلمة المرور'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:password,obscureText:true,decoration:const InputDecoration(labelText:'كلمة المرور الجديدة')),TextField(controller:confirm,obscureText:true,decoration:const InputDecoration(labelText:'تأكيد كلمة المرور'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('إلغاء')),FilledButton(onPressed:()async{if(password.text.length<8||password.text!=confirm.text){ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content:Text('تأكد من تطابق كلمتي المرور وأن تكون 8 أحرف على الأقل')));return;}try{await supabase.auth.updateUser(UserAttributes(password:password.text));if(ctx.mounted)Navigator.pop(ctx);if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم تغيير كلمة المرور')));}catch(e){if(ctx.mounted)ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content:Text('$e')));}},child:const Text('تحديث'))]));password.dispose();confirm.dispose();}
  @override Widget build(BuildContext c)=>FutureBuilder<Map<String,dynamic>>(future:future,builder:(c,s){if(!s.hasData)return s.hasError?Center(child:Text('تعذر تحميل الحساب: ${s.error}')):const Center(child:CircularProgressIndicator());final p=s.data!;String related(String key)=>p[key] is Map?'${p[key]['name_ar']??p[key]['name']??''}':'';return ListView(padding:const EdgeInsets.all(16),children:[const CircleAvatar(radius:38,child:Icon(Icons.person,size:42)),const SizedBox(height:12),Center(child:Text('${p['full_name']??'طالب AcadMind'}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold))),Center(child:Text('${p['email']??''}',style:const TextStyle(color:Colors.black54))),const SizedBox(height:18),Card(child:Column(children:[ListTile(leading:const Icon(Icons.phone),title:const Text('رقم الهاتف'),subtitle:Text('${p['phone']??'غير مضاف'}')),ListTile(leading:const Icon(Icons.school),title:const Text('السنة الدراسية'),subtitle:Text(related('academic_years').isEmpty?'لم يتم التعيين':related('academic_years'))),ListTile(leading:const Icon(Icons.groups),title:const Text('المجموعة والشعبة'),subtitle:Text('${related('groups')} ${related('sections')}')),ListTile(leading:const Icon(Icons.verified_user),title:const Text('نوع الحساب وحالته'),subtitle:Text('${p['role']} • ${p['status']}'))])),const SizedBox(height:10),FilledButton.icon(onPressed:()=>edit(p),icon:const Icon(Icons.edit),label:const Text('تعديل بياناتي')),Card(child:Column(children:[ListTile(title:const Text('المظهر'),leading:const Icon(Icons.dark_mode_outlined),trailing:DropdownButton<ThemeMode>(value:appThemeMode.value,items:const [DropdownMenuItem(value:ThemeMode.system,child:Text('حسب الجهاز')),DropdownMenuItem(value:ThemeMode.light,child:Text('فاتح')),DropdownMenuItem(value:ThemeMode.dark,child:Text('داكن'))],onChanged:(v){if(v!=null)saveThemeMode(v);})),const ListTile(title:Text('اللغة'),leading:Icon(Icons.language),subtitle:Text('الواجهة العربية متاحة حالياً'))])),OutlinedButton.icon(onPressed:changePassword,icon:const Icon(Icons.lock_reset),label:const Text('تغيير كلمة المرور')),OutlinedButton.icon(onPressed:()async{await supabase.auth.signOut();},icon:const Icon(Icons.logout),label:const Text('تسجيل الخروج'))]);});
}

class OwnerPage extends StatelessWidget { const OwnerPage({super.key}); @override Widget build(BuildContext context) => const OwnerConsole(); }

class _AsyncList<T> extends StatelessWidget {final Future<List<T>> future;final String empty;final Widget Function(T) builder;const _AsyncList({required this.future,required this.empty,required this.builder});@override Widget build(BuildContext c)=>FutureBuilder<List<T>>(future:future,builder:(c,s){if(s.connectionState==ConnectionState.waiting)return const Center(child:CircularProgressIndicator());if(s.hasError)return _ErrorBox(message:'تعذر تحميل البيانات: ${s.error}');final list=s.data??[];if(list.isEmpty)return _EmptyBox(text:empty);return ListView.separated(padding:const EdgeInsets.all(12),itemCount:list.length,separatorBuilder:(_,__)=>const SizedBox(height:8),itemBuilder:(c,i)=>Card(child:builder(list[i])));});}
class _EmptyBox extends StatelessWidget {final String text;const _EmptyBox({required this.text});@override Widget build(BuildContext c)=>Center(child:Padding(padding:const EdgeInsets.all(30),child:Text(text,textAlign:TextAlign.center,style:const TextStyle(color:Colors.black54))));}
class _ErrorBox extends StatelessWidget {final String message;const _ErrorBox({required this.message});@override Widget build(BuildContext c)=>Center(child:Padding(padding:const EdgeInsets.all(20),child:Text(message,textAlign:TextAlign.center,style:TextStyle(color:Theme.of(c).colorScheme.error))));}
