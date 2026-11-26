import 'package:flutter/material.dart';
import '../backend.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});
  @override State<FeedbackScreen> createState()=>_FeedbackScreenState();
}
class _FeedbackScreenState extends State<FeedbackScreen> {
  final subject=TextEditingController();
  final message=TextEditingController();
  String category='suggestion';
  bool busy=false;
  @override void dispose(){subject.dispose();message.dispose();super.dispose();}
  Future<void> submit() async {
    if(subject.text.trim().length<3 || message.text.trim().length<10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('اكتب عنواناً من 3 أحرف على الأقل ورسالة من 10 أحرف على الأقل.')));
      return;
    }
    setState(()=>busy=true);
    try {
      await supabase.from('feedback').insert({
        'user_id':supabase.auth.currentUser!.id,
        'category':category,
        'subject':subject.text.trim(),
        'message':message.text.trim(),
      });
      if(!mounted)return;
      subject.clear(); message.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('وصلتنا رسالتك! شكرًا لمساعدتنا في تطوير AcadMind.')));
      Navigator.pop(context);
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('تعذر إرسال الرسالة: $e')));
    } finally { if(mounted)setState(()=>busy=false); }
  }
  @override Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(title:const Text('اقتراح أو مشكلة')),
      body:ListView(padding:const EdgeInsets.all(18),children:[
        Container(padding:const EdgeInsets.all(17),decoration:BoxDecoration(color:Theme.of(context).colorScheme.primaryContainer.withValues(alpha:.55),borderRadius:BorderRadius.circular(20)),child:const Row(children:[Icon(Icons.forum_outlined,size:28),SizedBox(width:12),Expanded(child:Text('رأيك بيساعدنا نخلي AcadMind أفضل. ابعت اقتراحك أو وضّح المشكلة بالتفصيل.',style:TextStyle(height:1.6,fontWeight:FontWeight.w600)))])),
        const SizedBox(height:20),
        DropdownButtonFormField<String>(value:category,decoration:const InputDecoration(labelText:'نوع الرسالة'),items:const [
          DropdownMenuItem(value:'suggestion',child:Text('اقتراح جديد')),
          DropdownMenuItem(value:'bug',child:Text('الإبلاغ عن مشكلة تقنية')),
          DropdownMenuItem(value:'content',child:Text('محتوى دراسي')),
          DropdownMenuItem(value:'other',child:Text('أخرى')),
        ],onChanged:(v)=>setState(()=>category=v??category)),
        const SizedBox(height:12),
        TextField(controller:subject,maxLength:120,decoration:const InputDecoration(labelText:'عنوان الرسالة')),
        const SizedBox(height:12),
        TextField(controller:message,minLines:6,maxLines:12,maxLength:5000,textDirection:TextDirection.rtl,decoration:const InputDecoration(labelText:'اكتب التفاصيل',alignLabelWithHint:true)),
        const SizedBox(height:16),
        SizedBox(height:50,child:FilledButton.icon(onPressed:busy?null:submit,icon:busy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.send_rounded),label:Text(busy?'جاري الإرسال...':'إرسال الرسالة'))),
      ]),
    );
  }
}
