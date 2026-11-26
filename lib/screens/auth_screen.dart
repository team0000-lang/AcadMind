
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../backend.dart';
import 'post_login_gate.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final email = TextEditingController();
  final password = TextEditingController();
  final fullName = TextEditingController();
  late final AnimationController intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  bool register = false, busy = false, obscure = true;

  @override
  void dispose() { email.dispose(); password.dispose(); fullName.dispose(); intro.dispose(); super.dispose(); }

  void message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value), behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(14)));
  }

  void openApp() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const PostLoginGate()));
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      message('اكتب البريد الإلكتروني وكلمة مرور من 6 أحرف على الأقل'); return;
    }
    if (register && fullName.text.trim().isEmpty) { message('اكتب اسمك بالكامل'); return; }
    setState(() => busy = true);
    try {
      if (register) {
        final response = await supabase.auth.signUp(
          email: email.text.trim(), password: password.text,
          data: {'full_name': fullName.text.trim()},
        );
        if (response.session == null) { message('تم إنشاء الحساب. سجّل الدخول للمتابعة.'); return; }
      } else {
        final response = await supabase.auth.signInWithPassword(email: email.text.trim(), password: password.text);
        if (response.session == null) { message('لم تُنشأ جلسة. راجع بيانات الدخول وحاول مرة أخرى.'); return; }
      }
      openApp();
    } on AuthException catch (e) {
      final value = e.message.toLowerCase();
      if (value.contains('email not confirmed') || value.contains('email_not_confirmed')) {
        message('تعذر تسجيل الدخول. تأكد من البريد الإلكتروني وكلمة المرور.');
      } else if (value.contains('invalid login credentials')) {
        message('البريد الإلكتروني أو كلمة المرور غير صحيحة.');
      } else { message(e.message); }
    } catch (_) {
      message('تعذر الاتصال. تأكد من الإنترنت وحاول مرة أخرى.');
    } finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> continueAsGuest() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final response = await supabase.auth.signInAnonymously();
      if (response.session == null) { message('لم يتم إنشاء جلسة للضيف. راجع إعدادات الدخول كضيف.'); return; }
      openApp();
    } on AuthException catch (e) {
      final value = e.message.toLowerCase();
      if (value.contains('anonymous') || value.contains('disabled') || value.contains('not enabled')) {
        message('الدخول كضيف يحتاج تفعيل Anonymous Sign-ins من إعدادات Supabase.');
      } else { message(e.message); }
    } catch (_) { message('تعذر الدخول كضيف. تأكد من اتصال الإنترنت وحاول مرة أخرى.'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> resetPassword() async {
    if (email.text.trim().isEmpty) { message('اكتب بريدك الإلكتروني أولاً'); return; }
    try {
      await supabase.auth.resetPasswordForEmail(email.text.trim());
      message('لو البريد مسجل، هتوصلك رسالة استعادة كلمة المرور.');
    } on AuthException catch (e) { message(e.message); }
    catch (_) { message('تعذر إرسال رسالة الاستعادة. حاول مرة أخرى.'); }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: const Color(0xFFF6F7FC),
      body: Stack(children: [
        Positioned(top: -135, right: -115, child: _Glow(size: 300, color: const Color(0xFF7065ED).withValues(alpha: .12))),
        Positioned(bottom: -150, left: -115, child: _Glow(size: 320, color: const Color(0xFF1AB8D2).withValues(alpha: .08))),
        SafeArea(child: Center(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460),
            child: FadeTransition(opacity: CurvedAnimation(parent: intro, curve: Curves.easeOut),
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, .06), end: Offset.zero).animate(CurvedAnimation(parent: intro, curve: Curves.easeOutCubic)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Container(width: 54, height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFF6D62EA), Color(0xFF29245F)]),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: const Color(0xFF5145D6).withValues(alpha: .20), blurRadius: 18, offset: const Offset(0, 7))]),
                      alignment: Alignment.center,
                      child: const Text('AM', style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 1))),
                    const SizedBox(width: 13),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('AcadMind', style: TextStyle(color: Color(0xFF222342), fontSize: 23, fontWeight: FontWeight.w900, letterSpacing: -.4)),
                      SizedBox(height: 3),
                      Text('YOUR SMART ACADEMIC COMPANION', style: TextStyle(color: Color(0xFF868AA0), fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
                    ])),
                  ]),
                  const SizedBox(height: 35),
                  const Text('كل بداية ذكية، تبدأ من هنا.', style: TextStyle(color: Color(0xFF222342), fontSize: 27, height: 1.35, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Text('نظّم دراستك، تابع محاضراتك، واستعن بالذكاء الاصطناعي في رحلتك الجامعية.',
                    style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13, height: 1.8)),
                  const SizedBox(height: 25),
                  Container(padding: const EdgeInsets.all(21),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: const Color(0xFFE8E9F2)),
                      boxShadow: [BoxShadow(color: const Color(0xFF222342).withValues(alpha: .045), blurRadius: 30, offset: const Offset(0, 12))]),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: Text(
                        register ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                        key: ValueKey(register), style: const TextStyle(color: Color(0xFF252643), fontSize: 20, fontWeight: FontWeight.w900))),
                      const SizedBox(height: 6),
                      Text(register ? 'ابدأ رحلتك الدراسية مع AcadMind.' : 'أهلاً بعودتك. كمّل من حيث توقفت.',
                        style: const TextStyle(color: Color(0xFF85899E), fontSize: 12)),
                      if (register) ...[
                        const SizedBox(height: 19),
                        _AuthField(controller: fullName, label: 'الاسم بالكامل', icon: Icons.person_outline_rounded, textInputAction: TextInputAction.next),
                      ],
                      const SizedBox(height: 14),
                      _AuthField(controller: email, label: 'البريد الإلكتروني', icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress, textDirection: TextDirection.ltr, textAlign: TextAlign.left, textInputAction: TextInputAction.next),
                      const SizedBox(height: 13),
                      TextField(controller: password, obscureText: obscure, textDirection: TextDirection.ltr, textAlign: TextAlign.left,
                        textInputAction: TextInputAction.done, onSubmitted: (_) => submit(),
                        decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure),
                            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined)))),
                      const SizedBox(height: 19),
                      SizedBox(height: 54, child: FilledButton(
                        onPressed: busy ? null : submit,
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF5145D6), foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: busy
                          ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(register ? 'إنشاء الحساب' : 'دخول إلى حسابي', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)))),
                      if (!register) ...[
                        Align(alignment: Alignment.center, child: TextButton(onPressed: busy ? null : resetPassword, child: const Text('نسيت كلمة المرور؟'))),
                        Row(children: [
                          const Expanded(child: Divider(color: Color(0xFFE9EAF1))),
                          Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('أو', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 11))),
                          const Expanded(child: Divider(color: Color(0xFFE9EAF1))),
                        ]),
                        const SizedBox(height: 12),
                        SizedBox(height: 51, child: OutlinedButton(
                          onPressed: busy ? null : continueAsGuest,
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF5145D6),
                            side: const BorderSide(color: Color(0xFFDCDCF2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.person_outline_rounded, size: 19), SizedBox(width: 9),
                            Text('تجربة التطبيق كضيف', style: TextStyle(fontWeight: FontWeight.w700)),
                          ]))),
                      ],
                      const SizedBox(height: 12),
                      TextButton(onPressed: busy ? null : () => setState(() => register = !register),
                        child: Text(register ? 'لديك حساب بالفعل؟ سجّل الدخول' : 'مستخدم جديد؟ أنشئ حسابك',
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.shield_outlined, size: 14, color: Color(0xFF9A9EB0)),
                    SizedBox(width: 6),
                    Text('حسابك وبياناتك الأكاديمية في أمان', style: TextStyle(color: Color(0xFF9A9EB0), fontSize: 10)),
                  ]),
                ]),
              ),
            ),
          ),
        ))),
      ]),
    ));
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextDirection? textDirection;
  final TextAlign? textAlign;
  final TextInputAction? textInputAction;
  const _AuthField({required this.controller, required this.label, required this.icon,
    this.keyboardType, this.textDirection, this.textAlign, this.textInputAction});
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller, keyboardType: keyboardType, textDirection: textDirection,
    textAlign: textAlign ?? TextAlign.start, textInputAction: textInputAction,
    decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
  );
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;
  const _Glow({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}
