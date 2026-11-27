import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../backend.dart';

class StudyLibraryPage extends StatefulWidget {
  const StudyLibraryPage({super.key});
  @override State<StudyLibraryPage> createState() => _StudyLibraryPageState();
}

class _StudyLibraryPageState extends State<StudyLibraryPage> {
  late Future<List<Map<String,dynamic>>> future;
  final search = TextEditingController();
  String filter = 'all';
  static const filters = <String,String>{
    'all':'الكل','summary':'ملخصات','analysis':'تحليلات','quiz':'اختبارات',
    'flashcards':'بطاقات','explanation':'شروحات','plan':'خطط','chat':'محادثات','note':'ملاحظات',
  };
  @override void initState(){super.initState();future=load();}
  @override void dispose(){search.dispose();super.dispose();}
  Future<List<Map<String,dynamic>>> load() async {
    var q=supabase.from('study_library_items').select('id,title,item_type,content,created_at,metadata,subject_id,subjects(name_en)');
    if(filter!='all') q=q.eq('item_type',filter);
    final rows=await q.order('created_at',ascending:false).limit(150);
    return List<Map<String,dynamic>>.from(rows);
  }
  void refresh(){setState(()=>future=load());}
  Future<void> remove(Map<String,dynamic> item) async {
    try {
      await supabase.from('study_library_items').delete().eq('id',item['id']);
      refresh();
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حذف العنصر من مكتبتك')));
    } catch (_) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تعذر حذف العنصر')));
    }
  }
  void open(Map<String,dynamic> item) {
    showModalBottomSheet<void>(context:context,isScrollControlled:true,showDragHandle:true,
      builder:(ctx)=>SafeArea(child:Padding(
        padding:EdgeInsets.fromLTRB(18,8,18,MediaQuery.of(ctx).viewInsets.bottom+24),
        child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('${item['title']}',style:const TextStyle(fontSize:19,fontWeight:FontWeight.w900)),
          const SizedBox(height:8),
          Text('${filters[item['item_type']]??'محتوى محفوظ'} • ${item['subjects'] is Map ? (item['subjects']['name_en']??'') : ''}',style:TextStyle(color:Theme.of(ctx).colorScheme.onSurfaceVariant,fontSize:11)),
          const Divider(height:24),
          ConstrainedBox(constraints:BoxConstraints(maxHeight:MediaQuery.of(ctx).size.height*.62),child:SingleChildScrollView(child:MarkdownBody(data:'${item['content']}',selectable:true))),
        ]),
      )));
  }
  @override Widget build(BuildContext context){
    final colors=Theme.of(context).colorScheme;
    return Scaffold(
      appBar:AppBar(title:const Text('مكتبتي الدراسية'),actions:[IconButton(onPressed:refresh,icon:const Icon(Icons.refresh_rounded))]),
      body:Column(children:[
        Padding(padding:const EdgeInsets.fromLTRB(16,8,16,8),child:TextField(controller:search,onChanged:(_)=>setState((){}),decoration:InputDecoration(prefixIcon:const Icon(Icons.search_rounded),hintText:'ابحث في ملخصاتك وملاحظاتك...',suffixIcon:IconButton(onPressed:()=>setState(search.clear),icon:const Icon(Icons.close_rounded))))),
        SizedBox(height:44,child:ListView(scrollDirection:Axis.horizontal,padding:const EdgeInsets.symmetric(horizontal:12),children:filters.entries.map((e)=>Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:ChoiceChip(label:Text(e.value),selected:filter==e.key,onSelected:(_){setState((){filter=e.key;future=load();});}))).toList())),
        Expanded(child:FutureBuilder<List<Map<String,dynamic>>>(future:future,builder:(context,s){
          if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
          if(s.hasError)return Center(child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('تعذر تحميل مكتبتك'),TextButton(onPressed:refresh,child:const Text('إعادة المحاولة'))]));
          final needle=search.text.trim().toLowerCase();
          final rows=(s.data??[]).where((x)=>needle.isEmpty||'${x['title']} ${x['content']}'.toLowerCase().contains(needle)).toList();
          if(rows.isEmpty)return Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[Icon(Icons.auto_stories_outlined,size:48,color:colors.onSurfaceVariant),const SizedBox(height:12),const Text('مكتبتك لسه فاضية',style:TextStyle(fontWeight:FontWeight.w900,fontSize:17)),const SizedBox(height:6),Text('احفظ أول ملخص أو تحليل أو خطة مذاكرة من أدوات الدراسة الذكية.',textAlign:TextAlign.center,style:TextStyle(color:colors.onSurfaceVariant,fontSize:12))])));
          return ListView.separated(padding:const EdgeInsets.fromLTRB(14,12,14,28),itemCount:rows.length,separatorBuilder:(_,__)=>const SizedBox(height:9),itemBuilder:(context,i){
            final item=rows[i];final type=(item['item_type']??'note').toString();
            return Card(child:ListTile(onTap:()=>open(item),leading:CircleAvatar(backgroundColor:colors.primaryContainer,child:Icon(switch(type){'summary'=>Icons.summarize_rounded,'analysis'=>Icons.picture_as_pdf_rounded,'quiz'=>Icons.quiz_rounded,'flashcards'=>Icons.style_rounded,'explanation'=>Icons.lightbulb_rounded,'plan'=>Icons.event_note_rounded,'chat'=>Icons.chat_rounded,_=>Icons.notes_rounded},color:colors.primary)),title:Text('${item['title']}',maxLines:2,overflow:TextOverflow.ellipsis,style:const TextStyle(fontWeight:FontWeight.w800)),subtitle:Text('${filters[type]??'محتوى'} • ${item['subjects'] is Map ? (item['subjects']['name_en']??'بدون مادة') : 'بدون مادة'}',style:TextStyle(fontSize:11,color:colors.onSurfaceVariant)),trailing:PopupMenuButton<String>(onSelected:(v){if(v=='delete')remove(item);if(v=='open')open(item);},itemBuilder:(_)=>const [PopupMenuItem(value:'open',child:Text('فتح')),PopupMenuItem(value:'delete',child:Text('حذف'))])));
          });
        })),
      ]),
    );
  }
}
