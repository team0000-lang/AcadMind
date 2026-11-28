import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PdfTranslatorPage extends StatefulWidget {
  const PdfTranslatorPage({super.key});

  @override
  State<PdfTranslatorPage> createState() => _PdfTranslatorPageState();
}

class _PdfTranslatorPageState extends State<PdfTranslatorPage> {
  PlatformFile? _file;
  PdfDocument? _document;
  Uint8List? _pageBytes;
  List<Map<String, dynamic>> _translations = [];
  int _page = 1;
  int _pageCount = 0;
  bool _loading = false;
  bool _translating = false;
  bool _showTranslation = true;
  String _level = 'Simple';
  String? _error;

  @override
  void dispose() {
    _document?.close();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );
      if (result == null) return;
      final selected = result.files.single;
      if (selected.size > 15 * 1024 * 1024) {
        _message('الحد الأقصى لحجم الملف 15 MB');
        return;
      }
      if (selected.bytes == null) {
        _message('تعذرت قراءة الملف. حاول اختيار الملف مرة أخرى.');
        return;
      }
      setState(() {
        _loading = true;
        _error = null;
        _translations = [];
        _pageBytes = null;
      });
      final opened = await PdfDocument.openData(selected.bytes!);
      if (opened.pagesCount > 80) {
        await opened.close();
        if (mounted) setState(() => _loading = false);
        _message('الحد الأقصى المدعوم في الجلسة الواحدة هو 80 صفحة. اختر نسخة أصغر من الملف.');
        return;
      }
      await _document?.close();
      _document = opened;
      _file = selected;
      _pageCount = opened.pagesCount;
      _page = 1;
      await _renderPage();
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _error = 'تعذر فتح ملف PDF. قد يكون محمياً بكلمة مرور أو تالفاً.';
      });
    }
  }

  Future<void> _renderPage() async {
    final document = _document;
    if (document == null) return;
    setState(() {
      _loading = true;
      _translations = [];
      _error = null;
    });
    PdfPage? page;
    try {
      page = await document.getPage(_page);
      final scale = math.min(1600 / page.width, 1600 / page.height);
      final rendered = await page.render(
        width: math.max(1, (page.width * scale).round()).toDouble(),
        height: math.max(1, (page.height * scale).round()).toDouble(),
        format: PdfPageImageFormat.png,
      );
      if (rendered == null) throw Exception('Page rendering failed');
      if (mounted) setState(() => _pageBytes = rendered.bytes);
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذر تجهيز الصفحة للعرض.');
    } finally {
      await page?.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _translatePage() async {
    final bytes = _pageBytes;
    final session = Supabase.instance.client.auth.currentSession;
    if (bytes == null || session == null) {
      _message('سجّل الدخول وافتح ملف PDF أولاً.');
      return;
    }
    if (bytes.length > 6 * 1024 * 1024) {
      _message('حجم صورة الصفحة كبير. جرّب تصغير الصفحة أو استخدام ملف أخف.');
      return;
    }
    setState(() {
      _translating = true;
      _error = null;
    });
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'ai-chat',
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
        body: {
          'task': 'translate_page',
          'question': 'Translate this PDF page into ${_level == 'Simple' ? 'very simple student-friendly Arabic' : _level == 'University' ? 'clear university-level Arabic' : 'precise Arabic while preserving academic terminology'}. Return only the requested JSON translations with normalized bounding boxes.',
          'retrieve': false,
          'imageMimeType': 'image/png',
          'imageBase64': base64Encode(bytes),
        },
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      if (data['error'] != null) throw Exception(data['error'].toString());
      final raw = (data['answer'] ?? '').toString().trim();
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start < 0 || end <= start) throw Exception('لم يرجع المترجم بيانات أماكن مفهومة.');
      final decoded = jsonDecode(raw.substring(start, end + 1));
      final rows = decoded is Map && decoded['translations'] is List
          ? (decoded['translations'] as List)
          : const [];
      final parsed = rows.whereType<Map>().map((item) {
        final x = (item['x'] as num?)?.toDouble() ?? 0;
        final y = (item['y'] as num?)?.toDouble() ?? 0;
        final w = (item['w'] as num?)?.toDouble() ?? 0;
        final h = (item['h'] as num?)?.toDouble() ?? 0;
        final text = (item['text'] ?? '').toString().trim();
        if (text.isEmpty || w <= 0 || h <= 0) return null;
        return <String, dynamic>{
          'x': x.clamp(0, 1000),
          'y': y.clamp(0, 1000),
          'w': w.clamp(1, 1000),
          'h': h.clamp(1, 1000),
          'text': text,
        };
      }).whereType<Map<String, dynamic>>().toList();
      if (parsed.isEmpty) throw Exception('لم يتم العثور على نص واضح قابل للترجمة في هذه الصفحة.');
      if (mounted) setState(() {
        _translations = parsed;
        _showTranslation = true;
      });
    } on FunctionException catch (e) {
      final details = e.details is Map ? (e.details as Map)['error']?.toString() : null;
      if (mounted) setState(() => _error = details ?? 'تعذر الاتصال بخدمة الترجمة. حاول مرة أخرى.');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _translating = false);
    }
  }

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Widget _pagePreview() {
    final bytes = _pageBytes;
    if (bytes == null) return const SizedBox.shrink();
    return LayoutBuilder(builder: (context, constraints) {
      final image = Image.memory(bytes, fit: BoxFit.contain);
      return Center(
        child: AspectRatio(
          aspectRatio: _imageAspectRatio(bytes),
          child: Stack(
            fit: StackFit.expand,
            children: [
              image,
              if (_showTranslation)
                ..._translations.map((item) {
                  final left = (item['x'] as num).toDouble() / 1000;
                  final top = (item['y'] as num).toDouble() / 1000;
                  final width = (item['w'] as num).toDouble() / 1000;
                  final height = (item['h'] as num).toDouble() / 1000;
                  return Positioned(
                    left: constraints.maxWidth * left,
                    top: constraints.maxHeight * top,
                    width: math.max(18, constraints.maxWidth * width),
                    height: math.max(13, constraints.maxHeight * height),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .97),
                        border: Border.all(color: const Color(0x33265A53), width: .5),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(
                            item['text'].toString(),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            style: const TextStyle(
                              color: Color(0xFF172B28),
                              fontSize: 13,
                              height: 1.05,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      );
    });
  }

  double _imageAspectRatio(Uint8List bytes) {
    // The rendered PDF page uses its own dimensions; keep a portrait-safe fallback.
    return _pageBytes == null ? 0.707 : (_documentPageRatio ?? 0.707);
  }

  double? _documentPageRatio;

  Future<void> _loadRatio() async {
    final doc = _document;
    if (doc == null) return;
    final page = await doc.getPage(_page);
    _documentPageRatio = page.width / page.height;
    await page.close();
  }

  Future<void> _changePage(int next) async {
    if (_document == null || next < 1 || next > _pageCount || _loading || _translating) return;
    setState(() {
      _page = next;
      _pageBytes = null;
      _translations = [];
      _documentPageRatio = null;
    });
    await _loadRatio();
    await _renderPage();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Translator'),
        actions: [
          if (_translations.isNotEmpty)
            IconButton(
              tooltip: _showTranslation ? 'إظهار الأصل' : 'إظهار الترجمة',
              onPressed: () => setState(() => _showTranslation = !_showTranslation),
              icon: Icon(_showTranslation ? Icons.visibility_off_rounded : Icons.visibility_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF123C3A), Color(0xFF21877A)],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.translate_rounded, color: Colors.white, size: 28),
                SizedBox(height: 10),
                Text('افهم الصفحة من غير ما تفقد ترتيبها', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                SizedBox(height: 5),
                Text('ترجمة مبسطة تظهر فوق مواضع النص الأصلي داخل الصفحة.', style: TextStyle(color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: _loading || _translating ? null : _pickPdf,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(_file == null ? 'اختيار ملف PDF' : 'تغيير الملف • ${_file!.name}'),
          ),
          if (_file != null) ...[
            const SizedBox(height: 8),
            Text('${_file!.name}  •  $_pageCount صفحة', style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12)),
            DropdownButtonFormField<String>(
              value: _level,
              decoration: const InputDecoration(labelText: 'مستوى الترجمة', prefixIcon: Icon(Icons.tune_rounded)),
              items: const [
                DropdownMenuItem(value: 'Simple', child: Text('مبسطة جداً • للمذاكرة السريعة')),
                DropdownMenuItem(value: 'University', child: Text('جامعية واضحة')),
                DropdownMenuItem(value: 'Precise', child: Text('دقيقة مع الحفاظ على المصطلحات')),
              ],
              onChanged: _translating ? null : (value) => setState(() => _level = value ?? _level),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: _page > 1 && !_loading && !_translating ? () => _changePage(_page - 1) : null,
                  icon: const Icon(Icons.chevron_left_rounded), label: const Text('السابقة'),
                )),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('$_page / $_pageCount', style: const TextStyle(fontWeight: FontWeight.w800))),
                Expanded(child: OutlinedButton.icon(
                  onPressed: _page < _pageCount && !_loading && !_translating ? () => _changePage(_page + 1) : null,
                  icon: const Icon(Icons.chevron_right_rounded), label: const Text('التالية'),
                )),
              ],
            ),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _pageBytes == null || _loading || _translating ? null : _translatePage,
                icon: _translating ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded),
                label: Text(_translating ? 'جاري ترجمة الصفحة...' : _translations.isEmpty ? 'ترجم الصفحة الحالية' : 'إعادة ترجمة الصفحة'),
              ),
            ),
            if (_translations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('${_translations.length} موضع ترجمة • اضغط أيقونة العين لإظهار الأصل أو الترجمة', style: TextStyle(color: colors.primary, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
          ],
          if (_loading) const Padding(padding: EdgeInsets.all(22), child: Center(child: CircularProgressIndicator())),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(_error!, style: TextStyle(color: colors.error))),
          if (_pageBytes != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.outlineVariant)),
              child: _pagePreview(),
            ),
          ],
          if (_file == null) const Padding(
            padding: EdgeInsets.only(top: 30),
            child: Center(child: Text('اختر ملف PDF للبدء. يمكنك ترجمة كل صفحة بشكل منفصل للحفاظ على الدقة والتحكم في استهلاك الذكاء الاصطناعي.', textAlign: TextAlign.center)),
          ),
        ],
      ),
    );
  }
}
