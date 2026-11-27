import 'dart:async';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../backend.dart';
import '../services.dart';
import 'study_library.dart';

class _StudyTool {
  final String title, subtitle, prompt, hint;
  final IconData icon;
  final Color color;
  const _StudyTool(this.title, this.subtitle, this.prompt, this.hint, this.icon, this.color);
}

const _studyTools = <_StudyTool>[
  _StudyTool('AI Study Assistant','مساعدك لتنظيم المذاكرة والإجابة عن أسئلتك','أنت مساعد مذاكرة أكاديمي. ساعد الطالب في السؤال التالي بإجابة واضحة وخطوات عملية:','اكتب سؤالك أو هدفك الدراسي...',Icons.auto_awesome_rounded,Color(0xFF7768F8)),
  _StudyTool('PDF Analyzer','حلّل محتوى ملفات المحاضرات','حلّل النص الأكاديمي التالي كما لو كان مستخرجاً من ملف PDF. استخرج الفكرة العامة، أهم المفاهيم، التعريفات، النقاط التي تحتاج تركيزاً، وأسئلة للمراجعة. لا تخترع معلومات غير موجودة في النص:','الصق النص المستخرج من ملف PDF هنا...',Icons.picture_as_pdf_rounded,Color(0xFFE36B78)),
  _StudyTool('Smart Summarizer','ملخص منظم بدل صفحات طويلة','لخّص المحتوى التالي باللغة العربية في عناوين ونقاط واضحة، مع الحفاظ على المصطلحات المهمة والأمثلة والتفاصيل التي قد تأتي في الامتحان:','الصق المحاضرة أو النص هنا...',Icons.summarize_rounded,Color(0xFF399A91)),
  _StudyTool('Quiz Generator','اختبر فهمك بأسئلة متنوعة','أنشئ اختباراً تعليمياً من المحتوى التالي: 10 أسئلة متنوعة (اختيار من متعدد وصح وخطأ وأسئلة قصيرة)، ثم ضع نموذج الإجابة في نهاية منفصلة. لا تضف معلومات خارج المحتوى:','الصق محتوى الدرس وحدد مستوى الصعوبة...',Icons.quiz_rounded,Color(0xFFE39A45)),
  _StudyTool('Flashcards','حوّل المفاهيم إلى كروت مراجعة','حوّل المحتوى التالي إلى 12 بطاقة مراجعة. اكتب في كل بطاقة سؤالاً قصيراً ثم الإجابة، واجعل الإجابات دقيقة وسهلة الحفظ:','الصق التعريفات أو محتوى الدرس...',Icons.style_rounded,Color(0xFF4C8BD8)),
  _StudyTool('Study Planner','خطة مذاكرة تناسب وقتك','أنشئ خطة مذاكرة واقعية قابلة للتنفيذ بناءً على المعلومات التالية. قسّم المهام إلى جلسات، أضف فترات راحة، وحدد الأولويات والمراجعة:','اكتب المواد والمواعيد والوقت المتاح يومياً...',Icons.event_note_rounded,Color(0xFFB16BD4)),
  _StudyTool('AI Explainer','شرح مبسط خطوة بخطوة','اشرح الموضوع التالي كمدرس خصوصي. ابدأ من الأساسيات، استخدم مثالاً بسيطاً، ثم مثالاً تطبيقياً، وبعدها اختبر فهمي بسؤالين. وضّح أي افتراضات ولا تتجاوز ما تعرفه:','ما الموضوع الذي تريد فهمه؟',Icons.lightbulb_rounded,Color(0xFFDBA94D)),
  _StudyTool('Progress Analytics','راجع تقدمك وحدد ما يحتاج تحسيناً','حلّل تقرير الطالب التالي عن مذاكرته ونتائجه. استخرج نقاط القوة والضعف والمواد ذات الأولوية، ثم اقترح خطة تحسين قابلة للقياس. اعتمد فقط على البيانات التي أدخلها الطالب ولا تدّعِ أنها بيانات مسجلة تلقائياً:','اكتب درجاتك، ساعات مذاكرتك، والموضوعات التي تتقنها أو تجد صعوبة فيها...',Icons.insights_rounded,Color(0xFF339C9A)),
];

class StudyToolsPage extends StatelessWidget {
  const StudyToolsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF171B49), Color(0xFF5549D8), Color(0xFF887BFF)]),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: const Color(0xFF6558F5).withValues(alpha: .20), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.auto_awesome_rounded,color:Colors.white,size:22),SizedBox(width:9),Text('ACADMIND TOOLKIT',style:TextStyle(color:Colors.white70,fontSize:10,fontWeight:FontWeight.w800,letterSpacing:1.5))]),
            SizedBox(height:17),
            Text('ذاكر بذكاء، مش بمجهود أكتر.',style:TextStyle(color:Colors.white,fontSize:23,fontWeight:FontWeight.w900)),
            SizedBox(height:7),
            Text('مجموعة أدوات ذكية تساعدك تفهم، تلخّص، تتدرّب وتنظّم وقتك.',style:TextStyle(color:Colors.white70,fontSize:12,height:1.6)),
          ]),
        ),
        const SizedBox(height:16),
        const StudySessionCard(),
        const SizedBox(height:12),
        OutlinedButton.icon(onPressed:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>const StudyLibraryPage())),icon:const Icon(Icons.bookmarks_rounded),label:const Text('افتح مكتبتي الدراسية'),style:OutlinedButton.styleFrom(minimumSize:const Size.fromHeight(48),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15)))),
        const SizedBox(height:22),
        Row(children:[const Expanded(child:Text('كل أدواتك في مكان واحد',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900))),Text('8 TOOLS',style:TextStyle(color:colors.onSurfaceVariant,fontSize:10,fontWeight:FontWeight.w800,letterSpacing:1))]),
        const SizedBox(height:13),
        GridView.builder(
          shrinkWrap:true,
          physics:const NeverScrollableScrollPhysics(),
          itemCount:_studyTools.length,
          gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,mainAxisSpacing:12,crossAxisSpacing:12,childAspectRatio:1.04),
          itemBuilder:(context,index){
            final tool=_studyTools[index];
            return _ToolCard(tool:tool,onTap:()=>Navigator.of(context).push(MaterialPageRoute(builder:(_)=>ToolWorkspacePage(tool:tool))));
          },
        ),
        const SizedBox(height:14),
        Text('يمكنك اختيار المادة لربط الأداة بمراجعها داخل مكتبة AI. يدعم PDF Analyzer رفع ملفات PDF حتى 15 MB، وتظهر مصادر المادة أسفل الإجابة عند استخدامها.',style:TextStyle(color:colors.onSurfaceVariant,fontSize:11,height:1.6)),
      ],
    );
  }
}

class StudySessionCard extends StatefulWidget {
  const StudySessionCard({super.key});
  @override State<StudySessionCard> createState()=>_StudySessionCardState();
}
class _StudySessionCardState extends State<StudySessionCard>{
  final Stopwatch watch=Stopwatch();
  final TextEditingController title=TextEditingController(text:'جلسة مذاكرة');
  Timer? ticker;
  String elapsed='00:00:00';
  bool saving=false;
  void tick(){final d=watch.elapsed;if(mounted)setState(()=>elapsed='${d.inHours.toString().padLeft(2,'0')}:${(d.inMinutes%60).toString().padLeft(2,'0')}:${(d.inSeconds%60).toString().padLeft(2,'0')}');}
  void start(){watch.start();ticker=Timer.periodic(const Duration(seconds:1),(_)=>tick());setState((){});}
  Future<void> stopAndSave() async {
    watch.stop();ticker?.cancel();final minutes=(watch.elapsed.inSeconds/60).ceil();
    if(minutes<1){watch.reset();tick();setState((){});return;}
    setState(()=>saving=true);
    try{await supabase.from('study_sessions').insert({'user_id':supabase.auth.currentUser!.id,'title':title.text.trim().isEmpty?'جلسة مذاكرة':title.text.trim(),'started_at':DateTime.now().subtract(watch.elapsed).toUtc().toIso8601String(),'duration_minutes':minutes});if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تم حفظ جلسة مذاكرة لمدة $minutes دقيقة')));watch.reset();tick();}
    catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر حفظ الجلسة: $e')));}
    finally{if(mounted)setState(()=>saving=false);}
  }
  @override void dispose(){ticker?.cancel();title.dispose();super.dispose();}
  @override Widget build(BuildContext context){final colors=Theme.of(context).colorScheme;final running=watch.isRunning;return Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:colors.primaryContainer.withValues(alpha:.42),borderRadius:BorderRadius.circular(22),border:Border.all(color:colors.primary.withValues(alpha:.12))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(Icons.timer_rounded,color:colors.primary),const SizedBox(width:8),const Expanded(child:Text('جلسة مذاكرة مركّزة',style:TextStyle(fontWeight:FontWeight.w900,fontSize:15))),Text(elapsed,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:18))]),const SizedBox(height:8),TextField(controller:title,enabled:!running&&!saving,decoration:const InputDecoration(isDense:true,labelText:'اسم الجلسة',prefixIcon:Icon(Icons.edit_note_rounded))),const SizedBox(height:12),Row(children:[Expanded(child:FilledButton.icon(onPressed:running||saving?null:start,icon:const Icon(Icons.play_arrow_rounded),label:const Text('ابدأ'))),const SizedBox(width:8),Expanded(child:OutlinedButton.icon(onPressed:running&&!saving?stopAndSave:null,icon:saving?const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.stop_rounded),label:const Text('إنهاء وحفظ')))])]));}
}

class _ToolCard extends StatelessWidget {
  final _StudyTool tool;
  final VoidCallback onTap;
  const _ToolCard({required this.tool,required this.onTap});
  @override
  Widget build(BuildContext context){
    final colors=Theme.of(context).colorScheme;
    return Material(
      color:Theme.of(context).cardColor,
      borderRadius:BorderRadius.circular(23),
      child: InkWell(
        onTap:onTap,
        borderRadius:BorderRadius.circular(23),
        child: Container(
          padding:const EdgeInsets.all(15),
          decoration:BoxDecoration(borderRadius:BorderRadius.circular(23),border:Border.all(color:colors.outlineVariant.withValues(alpha:.65))),
          child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
            Container(width:46,height:46,decoration:BoxDecoration(color:tool.color.withValues(alpha:.13),borderRadius:BorderRadius.circular(15)),child:Icon(tool.icon,color:tool.color,size:24)),
            const Spacer(),
            Text(tool.title,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:13)),
            const SizedBox(height:5),
            Text(tool.subtitle,maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:colors.onSurfaceVariant,fontSize:10,height:1.4)),
            const SizedBox(height:9),
            Row(children:[Text('افتح الأداة',style:TextStyle(color:colors.primary,fontSize:10,fontWeight:FontWeight.w800)),const Spacer(),Icon(Icons.arrow_forward_rounded,size:15,color:colors.primary)]),
          ]),
        ),
      ),
    );
  }
}

class ToolWorkspacePage extends StatefulWidget {
  final _StudyTool tool;
  const ToolWorkspacePage({super.key,required this.tool});
  @override State<ToolWorkspacePage> createState()=>_ToolWorkspacePageState();
}
class _ToolWorkspacePageState extends State<ToolWorkspacePage>{
  final controller=TextEditingController();
  bool busy=false;
  bool loadingSubjects=true;
  String? answer;
  String? subjectId;
  List<Map<String,dynamic>> subjects=[];
  List<Map<String,dynamic>> sources=[];
  Map<String,dynamic>? practiceData;
  int practiceIndex=0;
  String? selectedAnswer;
  bool revealPractice=false;
  int practiceScore=0;
  PlatformFile? pdfFile;
  @override void initState(){super.initState();loadSubjects();}
  Future<void> loadSubjects() async {
    try {
      final rows=await supabase.from('subjects').select('id,name_en').eq('is_active',true).isFilter('deleted_at',null).order('name_en');
      if(!mounted)return;
      setState(()=>subjects=List<Map<String,dynamic>>.from(rows));
    } catch (_) {
      if(mounted) setState(()=>subjects=[]);
    } finally { if(mounted)setState(()=>loadingSubjects=false); }
  }
  @override void dispose(){controller.dispose();super.dispose();}
  Future<String> _realContext(String task) async {
    final since=DateTime.now().subtract(const Duration(days:30)).toUtc().toIso8601String();
    if(task=='planner'){
      final results=await Future.wait([
        supabase.from('academic_events').select('title,event_type,starts_at,subjects(name_en)').eq('is_active',true).gte('starts_at',DateTime.now().toUtc().toIso8601String()).order('starts_at').limit(60),
        AcadMindData.schedule(),
      ]);
      final events=List<Map<String,dynamic>>.from(results[0]);
      final schedule=List<Map<String,dynamic>>.from(results[1]);
      return '\\n\\nالامتحانات والمهام والأحداث المسجلة القادمة (لا تخترع مواعيد):\\n${events.map((e)=>'${e['title']} | ${e['event_type']} | ${e['starts_at']} | ${e['subjects'] is Map ? e['subjects']['name_en'] : ''}').join('\\n')}\\n\\nجدول المحاضرات الأسبوعي المسجل: ${schedule.take(60).map((e)=>'${e['subjects'] is Map ? e['subjects']['name_en'] : 'محاضرة'} | اليوم ${e['day_of_week']} | ${e['starts_at']} - ${e['ends_at']} | ${e['location']??''}').join('\\n')}';
    }
    if(task=='analytics'){
      final results=await Future.wait([
        supabase.from('study_sessions').select('title,duration_minutes,started_at,subjects(name_en)').gte('started_at',since).order('started_at',ascending:false).limit(200),
        supabase.from('quiz_attempts').select('title,score,max_score,created_at,subjects(name_en)').gte('created_at',since).order('created_at',ascending:false).limit(100),
        supabase.from('assignment_progress').select('status,updated_at').limit(200),
      ]);
      final sessions=List<Map<String,dynamic>>.from(results[0]);final quizzes=List<Map<String,dynamic>>.from(results[1]);final assignments=List<Map<String,dynamic>>.from(results[2]);
      final minutes=sessions.fold<int>(0,(sum,x)=>sum+((x['duration_minutes'] as num?)?.toInt()??0));
      final completed=assignments.where((x)=>x['status']=='completed').length;
      final quizAvg=quizzes.isEmpty?null:quizzes.fold<double>(0,(sum,x)=>sum+(((x['score'] as num?)?.toDouble()??0)/((x['max_score'] as num?)?.toDouble()??1)*100))/quizzes.length;
      return '\\n\\nبيانات التقدم الحقيقية (آخر 30 يوماً):\\nجلسات المذاكرة: ${sessions.length}\\nإجمالي دقائق المذاكرة: $minutes\\nمحاولات الاختبارات: ${quizzes.length}\\nمتوسط الاختبارات: ${quizAvg?.toStringAsFixed(1)??'لا توجد بيانات'}%\\nالواجبات المكتملة: $completed من ${assignments.length}\\nالجلسات: ${sessions.take(30).map((x)=>'${x['title']} • ${x['duration_minutes']} دقيقة').join(' | ')}\\nالاختبارات: ${quizzes.take(30).map((x)=>'${x['title']} • ${x['score']}/${x['max_score']}').join(' | ')}';
    }
    return '';
  }
  Future<void> saveToLibrary() async {
    if(answer==null||answer!.trim().isEmpty)return;setState(()=>busy=true);
    try{
      final type=switch(widget.tool.title){'PDF Analyzer'=>'analysis','Smart Summarizer'=>'summary','Quiz Generator'=>'quiz','Flashcards'=>'flashcards','AI Explainer'=>'explanation','Study Planner'=>'plan','AI Study Assistant'=>'chat',_=>'note'};
      await supabase.from('study_library_items').insert({'user_id':supabase.auth.currentUser!.id,'subject_id':subjectId,'item_type':type,'title':'${widget.tool.title} • ${DateTime.now().toLocal().toString().substring(0,16)}','content':answer,'metadata':{'sources':sources}});
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ النتيجة في مكتبتك الدراسية')));
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر حفظ النتيجة: $e')));}
    finally{if(mounted)setState(()=>busy=false);}
  }
  Future<void> pickPdf() async {
    final result=await FilePicker.platform.pickFiles(type:FileType.custom,allowedExtensions:['pdf'],withData:true);
    if(result==null)return;
    final file=result.files.single;
    if(file.size>15*1024*1024){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('الحد الأقصى لملف PDF هو 15 ميجابايت')));return;}
    if(file.bytes==null){if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر قراءة الملف، حاول مرة أخرى')));return;}
    setState(()=>pdfFile=file);
  }
  Future<void> generate()async{
    final value=controller.text.trim();
    if(value.isEmpty && !(widget.tool.title=='PDF Analyzer' && pdfFile!=null)){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اكتب المحتوى أو اختر ملف PDF أولاً')));return;}
    if(widget.tool.title=='AI Study Assistant' && subjectId==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اختر المادة أولاً حتى يستطيع المساعد الرجوع إلى ملفاتها ومصادرها.')));return;}
    final session = supabase.auth.currentSession;
    if(session == null){
      setState(()=>answer='جلسة الدخول غير موجودة. سجّل الدخول مرة أخرى لاستخدام أدوات الذكاء الاصطناعي.');
      return;
    }
    setState(() { busy = true; answer = null; sources = []; practiceData=null; practiceIndex=0; selectedAnswer=null; revealPractice=false; practiceScore=0; });
    try{
      final task = switch (widget.tool.title) {
        'AI Study Assistant' => 'chat',
        'PDF Analyzer' => 'pdf',
        'Smart Summarizer' => 'summarize',
        'Quiz Generator' => 'quiz',
        'Flashcards' => 'flashcards',
        'Study Planner' => 'planner',
        'AI Explainer' => 'explain',
        'Progress Analytics' => 'analytics',
        _ => 'chat',
      };
      final result=await supabase.functions.invoke('ai-chat',
        headers:{'Authorization':'Bearer ${session.accessToken}'},
        body:{
        'question':'${widget.tool.prompt}\n\nمدخلات الطالب:\n${value.isEmpty?'حلل الملف المرفق بالكامل واستخرج أهم النقاط والأسئلة.':value}${task=='quiz'?'\nأخرج JSON صالحاً فقط بلا Markdown وفق schema: {"title":"...","questions":[{"question":"...","options":["A","B","C","D"],"answer":"النص المطابق لأحد الخيارات","explanation":"..."}]} مع 8 أسئلة.':task=='flashcards'?'\nأخرج JSON صالحاً فقط بلا Markdown وفق schema: {"title":"...","cards":[{"front":"سؤال","back":"إجابة"}]} مع 12 بطاقة.':''}${await _realContext(task)}',
        'task':task,
        'subjectId':subjectId,
        'retrieve':subjectId!=null,
        if(widget.tool.title=='PDF Analyzer' && pdfFile!=null) 'fileBase64':base64Encode(pdfFile!.bytes!),
        if(widget.tool.title=='PDF Analyzer' && pdfFile!=null) 'fileMimeType':'application/pdf',
        if(widget.tool.title=='PDF Analyzer' && pdfFile!=null) 'fileName':pdfFile!.name,
      });
      final data=Map<String,dynamic>.from(result.data as Map);
      final text=(data['answer']??data['error']??'لم يصل رد من المساعد.').toString();
      final retrieved=data['sources'] is List ? List<Map<String,dynamic>>.from((data['sources'] as List).whereType<Map>().map((e)=>Map<String,dynamic>.from(e))) : <Map<String,dynamic>>[];
      Map<String,dynamic>? structured;
      if(task=='quiz'||task=='flashcards'){
        try{
          var raw=text.trim().replaceAll(RegExp(r'^\\s*```(?:json)?\\s*|\\s*```\\s*
    }on FunctionException catch(e){
      final detail=e.details is Map
          ? ((e.details as Map)['error']??(e.details as Map)['message']??'').toString()
          : (e.details?.toString()??'');
      final message=e.status==401
          ? 'جلسة الدخول انتهت أو غير موجودة. سجّل الدخول مرة أخرى.'
          : e.status==504
              ? 'Gemini اتأخر في الرد. جرّب محتوى أقصر أو أعد المحاولة.'
              : detail.isNotEmpty?detail:(e.reasonPhrase??'حاول مرة أخرى.');
      if(mounted)setState(()=>answer='تعذر تشغيل الأداة: $message');
    }catch(e){
      if(mounted)setState(()=>answer='حدث خطأ أثناء الاتصال بخدمة الذكاء الاصطناعي. تأكد من الاتصال وإعداد الخدمة ثم حاول مرة أخرى.');
    }finally{if(mounted)setState(()=>busy=false);}
  }
  Widget _buildInteractiveQuiz(ColorScheme colors) {
    final questions = List<Map<String,dynamic>>.from(
      (practiceData!['questions'] as List).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)));
    if (questions.isEmpty) return const Text('لم يتم إنشاء أسئلة قابلة للتشغيل.');
    if (practiceIndex >= questions.length) {
      return Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:colors.primaryContainer,borderRadius:BorderRadius.circular(18)),child:Column(children:[
        const Icon(Icons.emoji_events_rounded,size:42),const SizedBox(height:8),
        const Text('انتهى الاختبار',style:TextStyle(fontWeight:FontWeight.w900,fontSize:20)),
        Text('نتيجتك: $practiceScore / ${questions.length}',style:const TextStyle(fontWeight:FontWeight.w800)),
        FilledButton(onPressed:()=>setState((){practiceIndex=0;practiceScore=0;selectedAnswer=null;revealPractice=false;}),child:const Text('إعادة الاختبار')),
      ]));
    }
    final q=questions[practiceIndex];
    final options=List<String>.from(q['options'] is List?q['options']:const []);
    final correct=(q['answer']??'').toString();
    return Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Theme.of(context).cardColor,borderRadius:BorderRadius.circular(20),border:Border.all(color:colors.outlineVariant)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Text('سؤال ${practiceIndex+1} من ${questions.length}',style:TextStyle(color:colors.primary,fontWeight:FontWeight.w900)),const Spacer(),Text('النتيجة $practiceScore',style:const TextStyle(fontWeight:FontWeight.w800))]),
      const SizedBox(height:12),Text('${q['question']??''}',style:const TextStyle(fontSize:16,fontWeight:FontWeight.w800)),const SizedBox(height:12),
      ...options.map((option){
        final isCorrect=option.trim().toLowerCase()==correct.trim().toLowerCase();
        final isSelected=selectedAnswer==option;
        return Padding(padding:const EdgeInsets.only(bottom:8),child:OutlinedButton(
          onPressed:revealPractice?null:(){
            setState((){selectedAnswer=option;revealPractice=true;if(isCorrect)practiceScore++;});
          },
          style:OutlinedButton.styleFrom(minimumSize:const Size.fromHeight(46),alignment:Alignment.centerRight,side:BorderSide(color:revealPractice&&isCorrect?Colors.green:revealPractice&&isSelected?Colors.red:colors.outlineVariant)),
          child:Row(children:[Expanded(child:Text(option)),if(revealPractice&&isCorrect)const Icon(Icons.check_circle,color:Colors.green),if(revealPractice&&isSelected&&!isCorrect)const Icon(Icons.cancel,color:Colors.red)]),
        ));
      }),
      if(revealPractice)...[
        const SizedBox(height:8),Text('الإجابة الصحيحة: $correct',style:const TextStyle(color:Colors.green,fontWeight:FontWeight.w900)),
        if((q['explanation']??'').toString().isNotEmpty)Padding(padding:const EdgeInsets.only(top:6),child:Text('${q['explanation']}')),
        const SizedBox(height:12),
        FilledButton(onPressed:()=>setState((){practiceIndex++;selectedAnswer=null;revealPractice=false;}),child:Text(practiceIndex==questions.length-1?'عرض النتيجة':'السؤال التالي')),
      ],
    ]));
  }

  Widget _buildInteractiveFlashcards(ColorScheme colors) {
    final cards=List<Map<String,dynamic>>.from((practiceData!['cards'] as List).whereType<Map>().map((e)=>Map<String,dynamic>.from(e)));
    if(cards.isEmpty)return const Text('لم يتم إنشاء بطاقات قابلة للمراجعة.');
    if(practiceIndex>=cards.length)return Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:colors.primaryContainer,borderRadius:BorderRadius.circular(18)),child:Column(children:[
      const Icon(Icons.done_all_rounded,size:40),Text('راجعت ${cards.length} بطاقة',style:const TextStyle(fontWeight:FontWeight.w900)),
      FilledButton(onPressed:()=>setState((){practiceIndex=0;revealPractice=false;}),child:const Text('ابدأ من جديد')),
    ]));
    final card=cards[practiceIndex];
    return Column(children:[
      Text('بطاقة ${practiceIndex+1} من ${cards.length}',style:TextStyle(color:colors.primary,fontWeight:FontWeight.w800)),
      const SizedBox(height:10),
      InkWell(onTap:()=>setState(()=>revealPractice=!revealPractice),borderRadius:BorderRadius.circular(22),child:Container(width:double.infinity,constraints:const BoxConstraints(minHeight:190),padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:colors.primaryContainer,borderRadius:BorderRadius.circular(22)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        Icon(revealPractice?Icons.lightbulb_rounded:Icons.help_outline_rounded,size:32,color:colors.primary),const SizedBox(height:12),
        Text(revealPractice?'الإجابة':'اضغط لإظهار الإجابة',style:TextStyle(color:colors.primary,fontWeight:FontWeight.w900)),const SizedBox(height:10),
        Text('${revealPractice?card['back']:card['front']}',textAlign:TextAlign.center,style:const TextStyle(fontSize:17,fontWeight:FontWeight.w800)),
      ]))),
      if(revealPractice)Padding(padding:const EdgeInsets.only(top:14),child:FilledButton.icon(onPressed:()=>setState((){practiceIndex++;revealPractice=false;}),icon:const Icon(Icons.arrow_forward_rounded),label:const Text('البطاقة التالية'))),
    ]);
  }

  @override Widget build(BuildContext context){
    final colors=Theme.of(context).colorScheme;
    return Scaffold(
      appBar:AppBar(title:Text(widget.tool.title),actions:[IconButton(onPressed:()=>setState(()=>answer=null),tooltip:'مسح النتيجة',icon:const Icon(Icons.refresh_rounded))]),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:widget.tool.color.withValues(alpha:.10),borderRadius:BorderRadius.circular(22)),child:Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:widget.tool.color.withValues(alpha:.16),borderRadius:BorderRadius.circular(15)),child:Icon(widget.tool.icon,color:widget.tool.color,size:25)),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(widget.tool.title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(widget.tool.subtitle,style:TextStyle(color:colors.onSurfaceVariant,fontSize:11))]))])),
        const SizedBox(height:18),
        DropdownButtonFormField<String>(
          value: subjectId,
          isExpanded: true,
          decoration: const InputDecoration(labelText:'المادة الدراسية',prefixIcon:Icon(Icons.menu_book_rounded)),
          items: subjects.map((s)=>DropdownMenuItem<String>(value:'${s['id']}',child:Text('${s['name_en']}'))).toList(),
          onChanged: busy ? null : (value)=>setState(()=>subjectId=value),
        ),
        if(loadingSubjects) const Padding(padding:EdgeInsets.only(top:8),child:LinearProgressIndicator()),
        if(!loadingSubjects && subjects.isEmpty) const Padding(padding:EdgeInsets.only(top:8),child:Text('لا توجد مواد متاحة أو تعذر تحميلها. يمكنك المحاولة لاحقاً.',style:TextStyle(fontSize:11))),
        const SizedBox(height:14),
        Text(widget.tool.title=='PDF Analyzer'?'محتوى ملف PDF':'المحتوى أو التفاصيل',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:14)),
        const SizedBox(height:8),
        TextField(controller:controller,minLines:7,maxLines:14,textDirection:TextDirection.rtl,decoration:InputDecoration(hintText:widget.tool.hint,alignLabelWithHint:true)),
        if(widget.tool.title=='PDF Analyzer')...[
          const SizedBox(height:10),
          OutlinedButton.icon(onPressed:busy?null:pickPdf,icon:const Icon(Icons.upload_file_rounded),label:Text(pdfFile==null?'اختيار ملف PDF':'تغيير الملف: ${pdfFile!.name}')),
          if(pdfFile!=null) Text('تم اختيار ${pdfFile!.name} • ${(pdfFile!.size/1024/1024).toStringAsFixed(1)} MB',style:TextStyle(color:colors.onSurfaceVariant,fontSize:11)),
        ],
        const SizedBox(height:12),
        SizedBox(height:50,child:FilledButton.icon(onPressed:busy?null:generate,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.auto_awesome_rounded),label:Text(busy?'جاري التحليل...':'ابدأ الآن'),style:FilledButton.styleFrom(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))))),
        if(answer!=null)...[
          const SizedBox(height:22),
          Row(children:[const Expanded(child:Text('النتيجة',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18))),IconButton(tooltip:'حفظ في مكتبتي',onPressed:busy?null:saveToLibrary,icon:const Icon(Icons.bookmark_add_rounded)),IconButton(onPressed:()=>setState(()=>answer=null),icon:const Icon(Icons.close_rounded))]),
          if(widget.tool.title=='Quiz Generator' && practiceData?['questions'] is List) _buildInteractiveQuiz(colors),
          if(widget.tool.title=='Flashcards' && practiceData?['cards'] is List) _buildInteractiveFlashcards(colors),
          if(practiceData==null) Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Theme.of(context).cardColor,borderRadius:BorderRadius.circular(20),border:Border.all(color:colors.outlineVariant.withValues(alpha:.6))),child:MarkdownBody(data:answer!,selectable:true,styleSheet:MarkdownStyleSheet.fromTheme(Theme.of(context)))),
          if(sources.isNotEmpty)...[
            const SizedBox(height:12),
            const Text('المصادر المستخدمة',style:TextStyle(fontWeight:FontWeight.w900,fontSize:13)),
            const SizedBox(height:6),
            ...sources.map((source)=>ListTile(
              dense:true,
              contentPadding:const EdgeInsets.symmetric(horizontal:10),
              leading:const Icon(Icons.menu_book_rounded,size:18),
              title:Text('${source['documentName']??'Course document'}',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),
              subtitle:Text('صفحة ${source['page']??'غير محددة'}',style:TextStyle(fontSize:10,color:colors.onSurfaceVariant)),
            )),
          ],
        ],
      ]),
    );
  }
}
,multiLine:true),'');
          final start=raw.indexOf('{');final end=raw.lastIndexOf('}');
          if(start>=0&&end>start){final parsed=jsonDecode(raw.substring(start,end+1));if(parsed is Map)structured=Map<String,dynamic>.from(parsed);}
        }catch(_){structured=null;}
      }
      if(mounted)setState(() { answer = text; sources = retrieved; practiceData=structured; });
    }on FunctionException catch(e){
      final detail=e.details is Map
          ? ((e.details as Map)['error']??(e.details as Map)['message']??'').toString()
          : (e.details?.toString()??'');
      final message=e.status==401
          ? 'جلسة الدخول انتهت أو غير موجودة. سجّل الدخول مرة أخرى.'
          : e.status==504
              ? 'Gemini اتأخر في الرد. جرّب محتوى أقصر أو أعد المحاولة.'
              : detail.isNotEmpty?detail:(e.reasonPhrase??'حاول مرة أخرى.');
      if(mounted)setState(()=>answer='تعذر تشغيل الأداة: $message');
    }catch(e){
      if(mounted)setState(()=>answer='حدث خطأ أثناء الاتصال بخدمة الذكاء الاصطناعي. تأكد من الاتصال وإعداد الخدمة ثم حاول مرة أخرى.');
    }finally{if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context){
    final colors=Theme.of(context).colorScheme;
    return Scaffold(
      appBar:AppBar(title:Text(widget.tool.title),actions:[IconButton(onPressed:()=>setState(()=>answer=null),tooltip:'مسح النتيجة',icon:const Icon(Icons.refresh_rounded))]),
      body:ListView(padding:const EdgeInsets.all(16),children:[
        Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(color:widget.tool.color.withValues(alpha:.10),borderRadius:BorderRadius.circular(22)),child:Row(children:[Container(width:48,height:48,decoration:BoxDecoration(color:widget.tool.color.withValues(alpha:.16),borderRadius:BorderRadius.circular(15)),child:Icon(widget.tool.icon,color:widget.tool.color,size:25)),const SizedBox(width:13),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(widget.tool.title,style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:4),Text(widget.tool.subtitle,style:TextStyle(color:colors.onSurfaceVariant,fontSize:11))]))])),
        const SizedBox(height:18),
        DropdownButtonFormField<String>(
          value: subjectId,
          isExpanded: true,
          decoration: const InputDecoration(labelText:'المادة الدراسية',prefixIcon:Icon(Icons.menu_book_rounded)),
          items: subjects.map((s)=>DropdownMenuItem<String>(value:'${s['id']}',child:Text('${s['name_en']}'))).toList(),
          onChanged: busy ? null : (value)=>setState(()=>subjectId=value),
        ),
        if(loadingSubjects) const Padding(padding:EdgeInsets.only(top:8),child:LinearProgressIndicator()),
        if(!loadingSubjects && subjects.isEmpty) const Padding(padding:EdgeInsets.only(top:8),child:Text('لا توجد مواد متاحة أو تعذر تحميلها. يمكنك المحاولة لاحقاً.',style:TextStyle(fontSize:11))),
        const SizedBox(height:14),
        Text(widget.tool.title=='PDF Analyzer'?'محتوى ملف PDF':'المحتوى أو التفاصيل',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:14)),
        const SizedBox(height:8),
        TextField(controller:controller,minLines:7,maxLines:14,textDirection:TextDirection.rtl,decoration:InputDecoration(hintText:widget.tool.hint,alignLabelWithHint:true)),
        if(widget.tool.title=='PDF Analyzer')...[
          const SizedBox(height:10),
          OutlinedButton.icon(onPressed:busy?null:pickPdf,icon:const Icon(Icons.upload_file_rounded),label:Text(pdfFile==null?'اختيار ملف PDF':'تغيير الملف: ${pdfFile!.name}')),
          if(pdfFile!=null) Text('تم اختيار ${pdfFile!.name} • ${(pdfFile!.size/1024/1024).toStringAsFixed(1)} MB',style:TextStyle(color:colors.onSurfaceVariant,fontSize:11)),
        ],
        const SizedBox(height:12),
        SizedBox(height:50,child:FilledButton.icon(onPressed:busy?null:generate,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.auto_awesome_rounded),label:Text(busy?'جاري التحليل...':'ابدأ الآن'),style:FilledButton.styleFrom(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))))),
        if(answer!=null)...[
          const SizedBox(height:22),
          Row(children:[const Expanded(child:Text('النتيجة',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18))),IconButton(tooltip:'حفظ في مكتبتي',onPressed:busy?null:saveToLibrary,icon:const Icon(Icons.bookmark_add_rounded)),IconButton(onPressed:()=>setState(()=>answer=null),icon:const Icon(Icons.close_rounded))]),
          Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Theme.of(context).cardColor,borderRadius:BorderRadius.circular(20),border:Border.all(color:colors.outlineVariant.withValues(alpha:.6))),child:MarkdownBody(data:answer!,selectable:true,styleSheet:MarkdownStyleSheet.fromTheme(Theme.of(context)))),
          if(sources.isNotEmpty)...[
            const SizedBox(height:12),
            const Text('المصادر المستخدمة',style:TextStyle(fontWeight:FontWeight.w900,fontSize:13)),
            const SizedBox(height:6),
            ...sources.map((source)=>ListTile(
              dense:true,
              contentPadding:const EdgeInsets.symmetric(horizontal:10),
              leading:const Icon(Icons.menu_book_rounded,size:18),
              title:Text('${source['documentName']??'Course document'}',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700)),
              subtitle:Text('صفحة ${source['page']??'غير محددة'}',style:TextStyle(fontSize:10,color:colors.onSurfaceVariant)),
            )),
          ],
        ],
      ]),
    );
  }
}
