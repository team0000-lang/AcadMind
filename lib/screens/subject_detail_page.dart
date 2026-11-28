
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../backend.dart';

class SubjectDetailPage extends StatefulWidget {
  final Map<String,dynamic> subject;
  const SubjectDetailPage({super.key,required this.subject});
  @override State<SubjectDetailPage> createState()=>_SubjectDetailPageState();
}
class _SubjectDetailPageState extends State<SubjectDetailPage>{
  late Future<Map<String,List<Map<String,dynamic>>>> future;
  @override void initState(){super.initState();future=_load();}
  Future<Map<String,List<Map<String,dynamic>>>> _load() async{
    final id=widget.subject['id'];
    final lectures=List<Map<String,dynamic>>.from(await supabase.from('lectures').select('id,title,topic,description,notes,lecture_number').eq('subject_id',id).eq('is_active',true).isFilter('deleted_at',null).order('display_order'));
    final videos=List<Map<String,dynamic>>.from(await supabase.from('youtube_resources').select('id,title,youtube_url,lecture_id,description,channel').eq('subject_id',id).eq('is_active',true).isFilter('deleted_at',null).order('display_order'));
    final material=List<Map<String,dynamic>>.from(await supabase.from('drive_folders').select('id,folder_name,folder_url,description').eq('subject_id',id).eq('is_active',true).isFilter('deleted_at',null).order('display_order'));
    return {'lectures':lectures,'videos':videos,'material':material};
  }
  Future<void> _open(String url)async{final uri=Uri.tryParse(url);if(uri!=null&&await canLaunchUrl(uri))await launchUrl(uri,mode:LaunchMode.externalApplication);}
  @override Widget build(BuildContext context){
    final cs=Theme.of(context).colorScheme; final name=(widget.subject['name_en']??'Subject').toString();
    return Scaffold(appBar:AppBar(title:Text(name,style:const TextStyle(fontWeight:FontWeight.w900))),body:FutureBuilder<Map<String,List<Map<String,dynamic>>>>(future:future,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return Center(child:Text('Unable to load subject content',style:TextStyle(color:cs.onSurfaceVariant)));
      final data=s.data??{'lectures':<Map<String,dynamic>>[],'videos':<Map<String,dynamic>>[],'material':<Map<String,dynamic>>[]};
      final lectures=data['lectures']!;final videos=data['videos']!;final material=data['material']!;
      return ListView(padding:const EdgeInsets.fromLTRB(16,12,16,36),children:[
        Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:LinearGradient(colors:[cs.primary.withValues(alpha:.13),cs.secondary.withValues(alpha:.07)]),borderRadius:BorderRadius.circular(24),border:Border.all(color:cs.primary.withValues(alpha:.13))),child:Row(children:[
          Container(width:46,height:46,decoration:BoxDecoration(color:cs.primary.withValues(alpha:.13),borderRadius:BorderRadius.circular(15)),child:Icon(Icons.menu_book_rounded,color:cs.primary)),const SizedBox(width:12),
          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(name,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:3),Text(${lectures.length}+' lectures',style:TextStyle(color:cs.onSurfaceVariant,fontSize:10.5))]))
        ])),
        const SizedBox(height:14),
        Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:Theme.of(context).cardColor,borderRadius:BorderRadius.circular(20),border:Border.all(color:cs.outlineVariant.withValues(alpha:.55))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Icon(Icons.folder_open_rounded,color:cs.primary),const SizedBox(width:8),const Expanded(child:Text('Material',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)))]),
          const SizedBox(height:5),Text('Course material and Google Drive resources',style:TextStyle(fontSize:10.5,color:cs.onSurfaceVariant)),
          const SizedBox(height:10),
          if(material.isEmpty)Text('No material has been added yet.',style:TextStyle(fontSize:11,color:cs.onSurfaceVariant))
          else ...material.map((m)=>Padding(padding:const EdgeInsets.only(bottom:8),child:ListTile(contentPadding:EdgeInsets.zero,dense:true,leading:Container(width:38,height:38,decoration:BoxDecoration(color:cs.primary.withValues(alpha:.1),borderRadius:BorderRadius.circular(12)),child:Icon(Icons.drive_folder_upload_rounded,color:cs.primary,size:20)),title:Text(m['folder_name'].toString(),style:const TextStyle(fontWeight:FontWeight.w800,fontSize:12)),subtitle:Text((m['description']??'').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:9.5,color:cs.onSurfaceVariant)),trailing:FilledButton.tonalIcon(onPressed:()=>_open(m['folder_url'].toString()),icon:const Icon(Icons.open_in_new_rounded,size:15),label:const Text('Open')))))
        ])),
        const SizedBox(height:20),
        Row(children:[const Expanded(child:Text('Lectures',style:TextStyle(fontSize:18,fontWeight:FontWeight.w900))),Text(lectures.length.toString(),style:TextStyle(color:cs.onSurfaceVariant,fontSize:11,fontWeight:FontWeight.w800))]),
        const SizedBox(height:10),
        if(lectures.isEmpty)Container(padding:const EdgeInsets.all(22),decoration:BoxDecoration(color:Theme.of(context).cardColor,borderRadius:BorderRadius.circular(20)),child:const Center(child:Text('No lectures available yet.')))
        else ...lectures.asMap().entries.map((entry){final l=entry.value;final lectureVideos=videos.where((v)=>v['lecture_id']==l['id']).toList();return Padding(padding:const EdgeInsets.only(bottom:10),child:_LectureCard(lecture:l,index:entry.key+1,videos:lectureVideos,onOpen:_open));}),
      ]);
    }));
  }
}
class _LectureCard extends StatelessWidget{
  final Map<String,dynamic> lecture;final int index;final List<Map<String,dynamic>> videos;final Future<void> Function(String) onOpen;
  const _LectureCard({required this.lecture,required this.index,required this.videos,required this.onOpen});
  @override Widget build(BuildContext context){final cs=Theme.of(context).colorScheme;return Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Theme.of(context).cardColor,borderRadius:BorderRadius.circular(20),border:Border.all(color:cs.outlineVariant.withValues(alpha:.55))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:38,height:38,decoration:BoxDecoration(color:cs.primary.withValues(alpha:.1),borderRadius:BorderRadius.circular(12)),child:Center(child:Text(index.toString(),style:TextStyle(color:cs.primary,fontWeight:FontWeight.w900)))),const SizedBox(width:11),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(lecture['title'].toString(),style:const TextStyle(fontSize:14,fontWeight:FontWeight.w900)),if((lecture['topic']??'').toString().trim().isNotEmpty)Padding(padding:const EdgeInsets.only(top:3),child:Text(lecture['topic'].toString(),style:TextStyle(fontSize:10,color:cs.primary,fontWeight:FontWeight.w700)))]))]),
    if((lecture['description']??'').toString().trim().isNotEmpty)Padding(padding:const EdgeInsets.only(top:10),child:Text(lecture['description'].toString(),style:TextStyle(fontSize:11,color:cs.onSurfaceVariant,height:1.45))),
    const SizedBox(height:10),
    if(videos.isEmpty)Text('No explanation video yet.',style:TextStyle(fontSize:10,color:cs.onSurfaceVariant))
    else ...videos.map((v)=>Padding(padding:const EdgeInsets.only(top:7),child:InkWell(onTap:()=>onOpen(v['youtube_url'].toString()),borderRadius:BorderRadius.circular(14),child:Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:cs.primary.withValues(alpha:.06),borderRadius:BorderRadius.circular(14)),child:Row(children:[Icon(Icons.play_circle_fill_rounded,color:cs.primary,size:25),const SizedBox(width:9),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(v['title'].toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w800)),Text((v['description']??'YouTube explanation').toString(),maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:9,color:cs.onSurfaceVariant))])),Icon(Icons.open_in_new_rounded,size:15,color:cs.primary)])))))
  ]));}
}
