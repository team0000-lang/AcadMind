import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../backend.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final email = TextEditingController();
  final password = TextEditingController();
  final fullName = TextEditingController();
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
  bool register = false, busy = false, obscure = true;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    fullName.dispose();
    _intro.dispose();
    super.dispose();
  }

  void msg(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value), behavior: SnackBarBehavior.floating));
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 6) {
      msg('اكتب البريد الإلكتروني وكلمة مرور من 6 أحرف على الأقل');
      return;
    }
    if (register && fullName.text.trim().isEmpty) {
      msg('اكتب اسمك الأول');
      return;
    }
    setState(() => busy = true);
    try {
      if (register) {
        await supabase.auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'full_name': fullName.text.trim()},
        );
        msg('تم إنشاء الحساب. لو تأكيد البريد مفعّل، افتح رسالة التحقق ثم سجّل الدخول.');
      } else {
        await supabase.auth.signInWithPassword(email: email.text.trim(), password: password.text);
      }
    } on AuthException catch (e) {
      msg(e.message);
    } catch (e) {
      msg('تعذر الاتصال. تأكد من الإنترنت وحاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> continueAsGuest() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await supabase.auth.signInAnonymously();
    } on AuthException catch (e) {
      final detail = e.message.toLowerCase();
      if (detail.contains('anonymous') || detail.contains('disabled') || detail.contains('not enabled')) {
        msg('الدخول كضيف محتاج تفعيل Anonymous Sign-ins من إعدادات Supabase أولاً.');
      } else {
        msg(e.message);
      }
    } catch (_) {
      msg('تعذر الدخول كضيف. تأكد من اتصال الإنترنت وحاول مرة أخرى.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetPassword() async {
    if (email.text.trim().isEmpty) {
      msg('اكتب بريدك الإلكتروني أولاً');
      return;
    }
    try {
      await supabase.auth.resetPasswordForEmail(email.text.trim());
      msg('لو البريد مسجل، هتوصلك رسالة استعادة كلمة المرور.');
    } on AuthException catch (e) {
      msg(e.message);
    } catch (_) {
      msg('تعذر إرسال رسالة الاستعادة. حاول مرة أخرى.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: -110, right: -85, child: _AuthGlow(color: colors.primary.withValues(alpha: .10), size: 280)),
          Positioned(bottom: -120, left: -100, child: _AuthGlow(color: colors.secondary.withValues(alpha: .09), size: 300)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 30),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, .07), end: Offset.zero).animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 82,
                              height: 82,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF8175FF), Color(0xFF4B43D0)]),
                                borderRadius: BorderRadius.circular(27),
                                boxShadow: [BoxShadow(color: colors.primary.withValues(alpha: .25), blurRadius: 24, offset: const Offset(0, 10))],
                              ),
                              alignment: Alignment.center,
                              child: const Text('AM', style: TextStyle(color: Colors.white, fontSize: 29, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 19),
                          const Text('AcadMind', textAlign: TextAlign.center, style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900, letterSpacing: -.5)),
                          const SizedBox(height: 7),
                          Text('مساعدك الذكي في رحلتك الجامعية', textAlign: TextAlign.center, style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14)),
                          const SizedBox(height: 30),
                          Container(
                            padding: const EdgeInsets.all(21),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(27),
                              border: Border.all(color: colors.outlineVariant.withValues(alpha: .55)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .035), blurRadius: 28, offset: const Offset(0, 10))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: Text(register ? 'أنشئ حسابك وابدأ' : 'أهلاً بعودتك 👋', key: ValueKey(register), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                                ),
                                const SizedBox(height: 5),
                                Text(register ? 'احفظ بياناتك وتابع رحلتك الدراسية.' : 'سجّل دخولك أو جرّب التطبيق كضيف.', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13)),
                                if (register) ...[
                                  const SizedBox(height: 18),
                                  TextField(controller: fullName, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'الاسم بالكامل', prefixIcon: Icon(Icons.person_outline_rounded))),
                                ],
                                const SizedBox(height: 15),
                                TextField(controller: email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.alternate_email_rounded))),
                                const SizedBox(height: 13),
                                TextField(
                                  controller: password,
                                  obscureText: obscure,
                                  onSubmitted: (_) => submit(),
                                  decoration: InputDecoration(
                                    labelText: 'كلمة المرور',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                                    suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)),
                                  ),
                                ),
                                const SizedBox(height: 19),
                                SizedBox(
                                  height: 53,
                                  child: FilledButton(
                                    onPressed: busy ? null : submit,
                                    style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                    child: busy ? const SizedBox(width: 21, height: 21, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(register ? 'إنشاء الحساب' : 'تسجيل الدخول', style: const TextStyle(fontWeight: FontWeight.w700)),
                                  ),
                                ),
                                if (!register) ...[
                                  Align(alignment: Alignment.center, child: TextButton(onPressed: busy ? null : resetPassword, child: const Text('نسيت كلمة المرور؟'))),
                                  const SizedBox(height: 2),
                                  Row(children: [Expanded(child: Divider(color: colors.outlineVariant)), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('أو', style: TextStyle(color: colors.onSurfaceVariant))), Expanded(child: Divider(color: colors.outlineVariant))]),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 51,
                                    child: OutlinedButton.icon(
                                      onPressed: busy ? null : continueAsGuest,
                                      icon: const Icon(Icons.person_outline_rounded),
                                      label: const Text('المتابعة كضيف'),
                                      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: busy ? null : () => setState(() => register = !register),
                                  child: Text(register ? 'لديك حساب بالفعل؟ تسجيل الدخول' : 'ليس لديك حساب؟ إنشاء حساب'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 17),
                          Text('بياناتك الأكاديمية محمية، وصلاحيات الإدارة لا يمنحها إلا مالك النظام.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _AuthGlow({required this.color, required this.size});
  @override
  Widget build(BuildContext context) => Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
}
