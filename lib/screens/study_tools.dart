import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../backend.dart';

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
        const SizedBox(height:24),
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
        Text('ملاحظة: أدوات الذكاء الاصطناعي تحتاج اتصالاً بالإنترنت وإعداد مزوّد AI على الخادم. محلّل PDF يستقبل النص المستخرج من الملف حالياً؛ رفع الملفات واستخراج النص تلقائياً يحتاجان مرحلة ربط إضافية.',style:TextStyle(color:colors.onSurfaceVariant,fontSize:11,height:1.6)),
      ],
    );
  }
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
  String? answer;
  @override void dispose(){controller.dispose();super.dispose();}
  Future<void> generate()async{
    final value=controller.text.trim();
    if(value.isEmpty){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اكتب المحتوى أو التفاصيل أولاً')));return;}
    setState(()=>busy=true);
    try{
      final result=await supabase.functions.invoke('ai-chat',body:{
        'question':'${widget.tool.prompt}\n\nمدخلات الطالب:\n$value',
        'retrieve':false,
      });
      final data=Map<String,dynamic>.from(result.data as Map);
      final text=(data['answer']??data['error']??'لم يصل رد من المساعد.').toString();
      if(mounted)setState(()=>answer=text);
    }on FunctionException catch(e){
      if(mounted)setState(()=>answer='تعذر تشغيل الأداة: ${e.details??e.reasonPhrase??e.toString()}');
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
        Text(widget.tool.title=='PDF Analyzer'?'محتوى ملف PDF':'المحتوى أو التفاصيل',style:const TextStyle(fontWeight:FontWeight.w800,fontSize:14)),
        const SizedBox(height:8),
        TextField(controller:controller,minLines:7,maxLines:14,textDirection:TextDirection.rtl,decoration:InputDecoration(hintText:widget.tool.hint,alignLabelWithHint:true)),
        const SizedBox(height:12),
        SizedBox(height:50,child:FilledButton.icon(onPressed:busy?null:generate,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.auto_awesome_rounded),label:Text(busy?'جاري التحليل...':'ابدأ الآن'),style:FilledButton.styleFrom(shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))))),
        if(answer!=null)...[
          const SizedBox(height:22),
          Row(children:[const Expanded(child:Text('النتيجة',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18))),IconButton(onPressed:()=>setState(()=>answer=null),icon:const Icon(Icons.close_rounded))]),
          Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Theme.of(context).cardColor,borderRadius:BorderRadius.circular(20),border:Border.all(color:colors.outlineVariant.withValues(alpha:.6))),child:MarkdownBody(data:answer!,selectable:true,styleSheet:MarkdownStyleSheet.fromTheme(Theme.of(context)))),
        ],
      ]),
    );
  }
}
