
import 'package:flutter/material.dart';
import 'study_tools.dart';
import 'study_library.dart';
import 'notification_center.dart';

class AcadMindAiPage extends StatelessWidget {
  const AcadMindAiPage({super.key});
  @override
  Widget build(BuildContext context) {
    final cs=Theme.of(context).colorScheme;
    final tools=[
      ['AI Explainer','Understand difficult topics',Icons.lightbulb_rounded,Color(0xFFDBA94D)],
      ['PDF Analyzer','Turn lectures into insights',Icons.picture_as_pdf_rounded,Color(0xFFE36B78)],
      ['Smart Summarizer','Create focused study notes',Icons.summarize_rounded,Color(0xFF399A91)],
      ['Quiz Generator','Test your understanding',Icons.quiz_rounded,Color(0xFFE39A45)],
      ['Flashcards','Review faster',Icons.style_rounded,Color(0xFF4C8BD8)],
      ['Study Planner','Plan your study sessions',Icons.event_note_rounded,Color(0xFFB16BD4)],
    ];
    final query=TextEditingController();
    return Scaffold(
      body:CustomScrollView(physics:const BouncingScrollPhysics(),slivers:[
        SliverPadding(padding:const EdgeInsets.fromLTRB(16,18,16,8),sliver:SliverToBoxAdapter(child:Row(children:[
          Container(width:48,height:48,decoration:BoxDecoration(gradient:LinearGradient(colors:[cs.primary,cs.secondary]),borderRadius:BorderRadius.circular(16)),child:const Icon(Icons.auto_awesome_rounded,color:Colors.white)),
          const SizedBox(width:12),
          const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('AcadMind AI',style:TextStyle(fontSize:23,fontWeight:FontWeight.w900)),SizedBox(height:2),Text('Your intelligent study companion',style:TextStyle(fontSize:11))])),
          IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const NotificationCenterPage())),icon:const Icon(Icons.notifications_none_rounded)),
        ]))),
        SliverPadding(padding:const EdgeInsets.symmetric(horizontal:16),sliver:SliverToBoxAdapter(child:Container(padding:const EdgeInsets.all(18),decoration:BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[cs.primary.withValues(alpha:.14),cs.secondary.withValues(alpha:.08),cs.surface]),borderRadius:BorderRadius.circular(28),border:Border.all(color:cs.primary.withValues(alpha:.16))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[Icon(Icons.chat_bubble_outline_rounded,color:cs.primary),const SizedBox(width:8),const Text('Ask AcadMind',style:TextStyle(fontWeight:FontWeight.w900,fontSize:18))]),
          const SizedBox(height:5),Text('Ask questions, explain lessons, or study from your files.',style:TextStyle(color:cs.onSurfaceVariant,fontSize:11.5)),
          const SizedBox(height:14),
          TextField(controller:query,minLines:2,maxLines:4,textInputAction:TextInputAction.send,onSubmitted:(_){final q=query.text.trim();if(q.isNotEmpty)openStudyTool(context,'AI Study Assistant',initialPrompt:q);},decoration:InputDecoration(hintText:'What do you want to understand today?',filled:true,fillColor:cs.surface,prefixIcon:const Icon(Icons.edit_note_rounded),suffixIcon:IconButton(onPressed:(){final q=query.text.trim();if(q.isNotEmpty)openStudyTool(context,'AI Study Assistant',initialPrompt:q);},icon:Icon(Icons.arrow_upward_rounded,color:cs.primary)),border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none))),
          const SizedBox(height:10),Row(children:[_Chip(Icons.picture_as_pdf_rounded,'PDF ready'),const SizedBox(width:7),_Chip(Icons.bolt_rounded,'Fast tools'),const SizedBox(width:7),_Chip(Icons.auto_awesome_rounded,'AI powered')]),
        ])))),
        SliverPadding(padding:const EdgeInsets.fromLTRB(16,20,16,10),sliver:SliverToBoxAdapter(child:Row(children:[const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Study Tools',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)),SizedBox(height:3),Text('Everything you need to study smarter',style:TextStyle(fontSize:10.5))])),TextButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const StudyToolsPage())),child:const Text('View all'))]))),
        SliverPadding(padding:const EdgeInsets.symmetric(horizontal:16),sliver:SliverGrid(delegate:SliverChildBuilderDelegate((c,i){final t=tools[i];return InkWell(onTap:()=>openStudyTool(context,t[0] as String),borderRadius:BorderRadius.circular(22),child:Container(padding:const EdgeInsets.all(15),decoration:BoxDecoration(color:Theme.of(context).cardColor,borderRadius:BorderRadius.circular(22),border:Border.all(color:cs.outlineVariant.withValues(alpha:.55))),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Container(width:43,height:43,decoration:BoxDecoration(color:(t[3] as Color).withValues(alpha:.13),borderRadius:BorderRadius.circular(14)),child:Icon(t[2] as IconData,color:t[3] as Color,size:22)),const Spacer(),Text(t[0] as String,style:const TextStyle(fontWeight:FontWeight.w900,fontSize:13)),const SizedBox(height:4),Text(t[1] as String,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(color:cs.onSurfaceVariant,fontSize:9.5)),const SizedBox(height:7),Icon(Icons.arrow_forward_rounded,size:15,color:cs.primary)])));},childCount:tools.length),gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.12))),
        SliverPadding(padding:const EdgeInsets.fromLTRB(16,20,16,10),sliver:SliverToBoxAdapter(child:const Text('Quick Actions',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)))),
        SliverPadding(padding:const EdgeInsets.symmetric(horizontal:16),sliver:SliverToBoxAdapter(child:Row(children:[
          Expanded(child:_Action(Icons.picture_as_pdf_rounded,'Upload PDF',()=>openStudyTool(context,'PDF Analyzer'))),const SizedBox(width:9),
          Expanded(child:_Action(Icons.summarize_rounded,'Summarize',()=>openStudyTool(context,'Smart Summarizer'))),const SizedBox(width:9),
          Expanded(child:_Action(Icons.quiz_rounded,'Generate Quiz',()=>openStudyTool(context,'Quiz Generator'))),
        ]))),
        SliverPadding(padding:const EdgeInsets.fromLTRB(16,20,16,10),sliver:SliverToBoxAdapter(child:const Text('Your AI Library',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)))),
        SliverPadding(padding:const EdgeInsets.fromLTRB(16,0,16,36),sliver:SliverToBoxAdapter(child:InkWell(onTap:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const StudyLibraryPage())),borderRadius:BorderRadius.circular(22),child:Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(gradient:LinearGradient(colors:[cs.primary.withValues(alpha:.09),cs.secondary.withValues(alpha:.05)]),borderRadius:BorderRadius.circular(22),border:Border.all(color:cs.primary.withValues(alpha:.14))),child:Row(children:[Container(width:44,height:44,decoration:BoxDecoration(color:cs.primary.withValues(alpha:.12),borderRadius:BorderRadius.circular(14)),child:Icon(Icons.bookmarks_rounded,color:cs.primary)),const SizedBox(width:12),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Open AI Library',style:TextStyle(fontWeight:FontWeight.w900)),SizedBox(height:4),Text('Saved summaries, quizzes and study notes.',style:TextStyle(fontSize:10.5))])),Icon(Icons.arrow_forward_ios_rounded,size:15,color:cs.primary)]))))),
      ]),
    );
  }
}
class _Chip extends StatelessWidget{final IconData icon;final String label;const _Chip(this.icon,this.label);@override Widget build(BuildContext c){final cs=Theme.of(c).colorScheme;return Expanded(child:Container(padding:const EdgeInsets.symmetric(vertical:8),decoration:BoxDecoration(color:cs.surface.withValues(alpha:.8),borderRadius:BorderRadius.circular(12)),child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[Icon(icon,size:13,color:cs.primary),const SizedBox(width:4),Text(label,style:const TextStyle(fontSize:9,fontWeight:FontWeight.w700))])));}}
class _Action extends StatelessWidget{final IconData icon;final String label;final VoidCallback onTap;const _Action(this.icon,this.label,this.onTap);@override Widget build(BuildContext c)=>InkWell(onTap:onTap,borderRadius:BorderRadius.circular(16),child:Container(padding:const EdgeInsets.symmetric(vertical:13),decoration:BoxDecoration(color:Theme.of(c).cardColor,borderRadius:BorderRadius.circular(16),border:Border.all(color:Theme.of(c).colorScheme.outlineVariant.withValues(alpha:.5))),child:Column(children:[Icon(icon,size:21,color:Theme.of(c).colorScheme.primary),const SizedBox(height:6),Text(label,style:const TextStyle(fontSize:9.5,fontWeight:FontWeight.w800))])));}
