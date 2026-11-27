import 'package:flutter/material.dart';
import '../backend.dart';

class StudyPracticePage extends StatefulWidget {
  final bool showAppBar;
  const StudyPracticePage({super.key, this.showAppBar = true});
  @override
  State<StudyPracticePage> createState() => _StudyPracticePageState();
}

class _StudyPracticePageState extends State<StudyPracticePage> {
  bool _owner = false;
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() async {
    final id = supabase.auth.currentUser?.id;
    if (id == null) {
      _owner = false;
      return [<Map<String, dynamic>>[], <Map<String, dynamic>>[]];
    }
    final profile =
        await supabase.from('profiles').select('role').eq('id', id).single();
    _owner = profile['role'] == 'owner';
    return Future.wait([
      supabase
          .from('study_quizzes')
          .select(
              'id,title,description,subject_id,academic_year_id,is_published,subjects(name_en)')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(100),
      supabase
          .from('flashcard_decks')
          .select(
              'id,title,description,subject_id,academic_year_id,is_published,subjects(name_en)')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(100),
    ]);
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _create(String kind) async {
    final years = List<Map<String, dynamic>>.from(await supabase
        .from('academic_years')
        .select('id,name_en,name_ar')
        .order('name_en'));
    if (!mounted) return;
    if (years.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('أضف سنة دراسية أولاً')));
      return;
    }
    final title = TextEditingController();
    final description = TextEditingController();
    var yearId = years.first['id'].toString();
    var done = false;
    await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
                  title: Text(
                      kind == 'quiz' ? 'إنشاء اختبار' : 'إنشاء مجموعة بطاقات'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: title,
                        decoration:
                            const InputDecoration(labelText: 'العنوان')),
                    TextField(
                        controller: description,
                        decoration: const InputDecoration(labelText: 'الوصف')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                        initialValue: yearId,
                        decoration:
                            const InputDecoration(labelText: 'السنة الدراسية'),
                        items: [
                          for (final y in years)
                            DropdownMenuItem(
                                value: y['id'].toString(),
                                child: Text((y['name_en'] ?? y['name_ar'] ?? '')
                                    .toString()))
                        ],
                        onChanged: (v) =>
                            setDialogState(() => yearId = v ?? yearId)),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('إلغاء')),
                    FilledButton(
                        onPressed: () async {
                          if (title.text.trim().length < 2) return;
                          try {
                            await supabase
                                .from(kind == 'quiz'
                                    ? 'study_quizzes'
                                    : 'flashcard_decks')
                                .insert({
                              'title': title.text.trim(),
                              'description': description.text.trim(),
                              'academic_year_id': yearId,
                              'created_by': supabase.auth.currentUser!.id,
                              'is_published': false,
                            });
                            done = true;
                            if (context.mounted) Navigator.pop(dialogContext);
                          } catch (_) {
                            if (context.mounted)
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'تعذر إنشاء المحتوى. راجع صلاحيات المالك.')));
                          }
                        },
                        child: const Text('إنشاء')),
                  ],
                )));
    title.dispose();
    description.dispose();
    if (done) await _refresh();
  }

  Future<void> _togglePublish(String table, Map<String, dynamic> row) async {
    try {
      await supabase.from(table).update(
          {'is_published': row['is_published'] != true}).eq('id', row['id']);
      await _refresh();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر تغيير حالة النشر')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: widget.showAppBar
            ? AppBar(title: const Text('الاختبارات والبطاقات'), actions: [
                IconButton(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'تحديث'),
                if (_owner)
                  PopupMenuButton<String>(
                      onSelected: _create,
                      itemBuilder: (_) => const [
                            PopupMenuItem(
                                value: 'quiz', child: Text('إنشاء اختبار')),
                            PopupMenuItem(
                                value: 'deck',
                                child: Text('إنشاء مجموعة بطاقات')),
                          ]),
              ])
            : null,
        body: FutureBuilder<List<dynamic>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return const _PracticeEmpty('تعذر تحميل الاختبارات والبطاقات.');
              final quizzes =
                  List<Map<String, dynamic>>.from(snapshot.data![0]);
              final decks = List<Map<String, dynamic>>.from(snapshot.data![1]);
              return DefaultTabController(
                  length: 2,
                  child: Column(children: [
                    const TabBar(tabs: [
                      Tab(text: 'الاختبارات', icon: Icon(Icons.quiz_outlined)),
                      Tab(
                          text: 'بطاقات المراجعة',
                          icon: Icon(Icons.style_outlined))
                    ]),
                    Expanded(
                        child: TabBarView(children: [
                      _contentList(quizzes, isQuiz: true),
                      _contentList(decks, isQuiz: false),
                    ])),
                  ]));
            }),
      );

  Widget _contentList(List<Map<String, dynamic>> records,
      {required bool isQuiz}) {
    if (records.isEmpty)
      return _PracticeEmpty(_owner
          ? 'لا يوجد محتوى بعد. أنشئ اختباراً أو مجموعة بطاقات من زر الإضافة.'
          : 'لا توجد اختبارات أو بطاقات منشورة لك حالياً.');
    return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final row = records[index];
          final subject = row['subjects'] is Map
              ? (row['subjects']['name_en'] ?? '').toString()
              : '';
          final published = row['is_published'] == true;
          return Card(
              child: ListTile(
            leading: CircleAvatar(
                child: Icon(isQuiz ? Icons.quiz_rounded : Icons.style_rounded)),
            title: Text('${row['title']}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text([subject, published ? 'منشور' : 'مسودة']
                .where((v) => v.isNotEmpty)
                .join(' • ')),
            trailing: _owner
                ? PopupMenuButton<String>(
                    onSelected: (action) async {
                      if (action == 'publish')
                        await _togglePublish(
                            isQuiz ? 'study_quizzes' : 'flashcard_decks', row);
                      if (action == 'edit')
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => isQuiz
                                    ? QuizEditorPage(quiz: row)
                                    : FlashcardEditorPage(deck: row)));
                      await _refresh();
                    },
                    itemBuilder: (_) => [
                          PopupMenuItem(
                              value: 'edit',
                              child: Text(
                                  isQuiz ? 'إدارة الأسئلة' : 'إدارة البطاقات')),
                          PopupMenuItem(
                              value: 'publish',
                              child: Text(
                                  published ? 'إلغاء النشر' : 'نشر للطلاب')),
                        ])
                : const Icon(Icons.chevron_right_rounded),
            onTap: _owner
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => isQuiz
                            ? QuizRunnerPage(quiz: row)
                            : FlashcardReviewPage(deck: row))),
          ));
        });
  }
}

class QuizRunnerPage extends StatefulWidget {
  final Map<String, dynamic> quiz;
  const QuizRunnerPage({super.key, required this.quiz});
  @override
  State<QuizRunnerPage> createState() => _QuizRunnerPageState();
}

class _QuizRunnerPageState extends State<QuizRunnerPage> {
  late Future<List<Map<String, dynamic>>> _future;
  final Map<String, String> _answers = {};
  int _index = 0;
  bool _submitting = false;
  Map<String, dynamic>? _result;
  final _shortAnswer = TextEditingController();
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _shortAnswer.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final rows = await supabase.rpc('get_practice_quiz_questions',
        params: {'p_quiz_id': widget.quiz['id']});
    return List<Map<String, dynamic>>.from(rows);
  }

  void _storeAnswer(String questionId, String answer) =>
      _answers[questionId] = answer;
  Future<void> _submit(List<Map<String, dynamic>> questions) async {
    setState(() => _submitting = true);
    try {
      final response = await supabase.rpc('submit_practice_quiz', params: {
        'p_quiz_id': widget.quiz['id'],
        'p_answers': [
          for (final e in _answers.entries)
            {'questionId': e.key, 'answer': e.value}
        ],
      });
      if (mounted)
        setState(() => _result = Map<String, dynamic>.from(response));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تعذر تسليم الاختبار. حاول مرة أخرى.')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('${widget.quiz['title']}')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError || snapshot.data!.isEmpty)
              return const _PracticeEmpty(
                  'لا توجد أسئلة متاحة في هذا الاختبار.');
            final questions = snapshot.data!;
            if (_result != null)
              return _QuizResult(
                  result: _result!,
                  questions: questions,
                  onRestart: () => setState(() {
                        _result = null;
                        _answers.clear();
                        _index = 0;
                      }));
            final q = questions[_index];
            final id = q['id'].toString();
            final choices = (q['options'] as List? ?? const [])
                .map((v) => v.toString())
                .toList();
            return ListView(padding: const EdgeInsets.all(18), children: [
              LinearProgressIndicator(
                  value: (_index + 1) / questions.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8)),
              const SizedBox(height: 14),
              Text('السؤال ${_index + 1} من ${questions.length}',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Text('${q['question']}',
                          style: const TextStyle(
                              fontSize: 19, fontWeight: FontWeight.w800)))),
              const SizedBox(height: 12),
              if (q['question_type'] == 'short_answer')
                TextField(
                    controller: _shortAnswer..text = _answers[id] ?? '',
                    onChanged: (v) => _storeAnswer(id, v),
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'إجابتك'))
              else
                for (final option
                    in (q['question_type'] == 'true_false' && choices.isEmpty
                        ? const ['صح', 'خطأ']
                        : choices))
                  RadioListTile<String>(
                      value: option,
                      groupValue: _answers[id],
                      title: Text(option),
                      onChanged: (v) {
                        if (v != null) setState(() => _storeAnswer(id, v));
                      }),
              const SizedBox(height: 18),
              Row(children: [
                if (_index > 0)
                  OutlinedButton(
                      onPressed: () => setState(() => _index--),
                      child: const Text('السابق')),
                const Spacer(),
                if (_index < questions.length - 1)
                  FilledButton(
                      onPressed: () => setState(() => _index++),
                      child: const Text('التالي'))
                else
                  FilledButton(
                      onPressed: _submitting ? null : () => _submit(questions),
                      child: Text(
                          _submitting ? 'جارٍ التصحيح...' : 'تسليم الاختبار'))
              ]),
            ]);
          }));
}

class _QuizResult extends StatelessWidget {
  final Map<String, dynamic> result;
  final List<Map<String, dynamic>> questions;
  final VoidCallback onRestart;
  const _QuizResult(
      {required this.result, required this.questions, required this.onRestart});
  @override
  Widget build(BuildContext context) {
    final score = (result['score'] as num?)?.toDouble() ?? 0;
    final max = (result['maxScore'] as num?)?.toDouble() ?? 0;
    final results =
        List<Map<String, dynamic>>.from(result['results'] as List? ?? const []);
    return ListView(padding: const EdgeInsets.all(18), children: [
      _PracticeMetric(
          title: 'نتيجتك',
          value: max == 0
              ? '—'
              : '${score.toStringAsFixed(1)} / ${max.toStringAsFixed(1)}  (${(score / max * 100).toStringAsFixed(0)}%)'),
      const SizedBox(height: 12),
      for (var i = 0; i < results.length && i < questions.length; i++)
        Card(
            child: ListTile(
                leading: Icon(
                    results[i]['correct'] == true
                        ? Icons.check_circle
                        : Icons.cancel,
                    color: results[i]['correct'] == true
                        ? Colors.green
                        : Colors.red),
                title: Text('${questions[i]['question']}'),
                subtitle: Text(
                    'الإجابة الصحيحة: ${results[i]['correctAnswer']}${(results[i]['explanation'] ?? '').toString().isEmpty ? '' : '\n${results[i]['explanation']}'}'))),
      FilledButton(onPressed: onRestart, child: const Text('محاولة جديدة')),
    ]);
  }
}

class QuizEditorPage extends StatefulWidget {
  final Map<String, dynamic> quiz;
  const QuizEditorPage({super.key, required this.quiz});
  @override
  State<QuizEditorPage> createState() => _QuizEditorPageState();
}

class _QuizEditorPageState extends State<QuizEditorPage> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async =>
      List<Map<String, dynamic>>.from(await supabase
          .from('quiz_questions')
          .select('id,question,question_type,points,display_order')
          .eq('quiz_id', widget.quiz['id'])
          .order('display_order'));
  Future<void> _addQuestion() async {
    final question = TextEditingController();
    final answer = TextEditingController();
    final explanation = TextEditingController();
    final optionsText = TextEditingController(
      text: 'الخيار الأول\nالخيار الثاني\nالخيار الثالث\nالخيار الرابع',
    );
    var type = 'multiple_choice';
    var saved = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('إضافة سؤال'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: question,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'السؤال')),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(
                      value: 'multiple_choice', child: Text('اختيار من متعدد')),
                  DropdownMenuItem(
                      value: 'true_false', child: Text('صح أو خطأ')),
                  DropdownMenuItem(
                      value: 'short_answer', child: Text('إجابة قصيرة')),
                ],
                onChanged: (value) =>
                    setDialogState(() => type = value ?? type),
              ),
              if (type == 'multiple_choice')
                TextField(
                  controller: optionsText,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                      labelText: 'الخيارات — خيار في كل سطر'),
                ),
              TextField(
                  controller: answer,
                  decoration:
                      const InputDecoration(labelText: 'الإجابة الصحيحة')),
              TextField(
                  controller: explanation,
                  decoration: const InputDecoration(labelText: 'شرح الإجابة')),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                if (question.text.trim().length < 2 ||
                    answer.text.trim().isEmpty) return;
                final options = type == 'multiple_choice'
                    ? optionsText.text
                        .split('\n')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList()
                    : type == 'true_false'
                        ? ['صح', 'خطأ']
                        : <String>[];
                if (type == 'multiple_choice' &&
                    (!options.contains(answer.text.trim()) ||
                        options.length < 2)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                        content:
                            Text('الإجابة الصحيحة يجب أن تطابق أحد الخيارات')),
                  );
                  return;
                }
                try {
                  final existing = await supabase
                      .from('quiz_questions')
                      .select('id')
                      .eq('quiz_id', widget.quiz['id']);
                  await supabase.from('quiz_questions').insert({
                    'quiz_id': widget.quiz['id'],
                    'question': question.text.trim(),
                    'question_type': type,
                    'options': options,
                    'correct_answer': answer.text.trim(),
                    'explanation': explanation.text.trim(),
                    'display_order': existing.length,
                  });
                  saved = true;
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (_) {
                  if (dialogContext.mounted)
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('تعذر حفظ السؤال')),
                    );
                }
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
    question.dispose();
    answer.dispose();
    explanation.dispose();
    optionsText.dispose();
    if (saved && mounted) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('أسئلة: ${widget.quiz['title']}'), actions: [
        IconButton(onPressed: _addQuestion, icon: const Icon(Icons.add))
      ]),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return const _PracticeEmpty('تعذر تحميل الأسئلة');
            final rows = snapshot.data ?? [];
            if (rows.isEmpty)
              return const _PracticeEmpty(
                  'أضف أسئلة للاختبار ثم انشره للطلاب.');
            return ListView(children: [
              for (final row in rows)
                ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: Text('${row['question']}'),
                    subtitle:
                        Text('${row['question_type']} • ${row['points']} نقاط'))
            ]);
          }));
}

class FlashcardEditorPage extends StatefulWidget {
  final Map<String, dynamic> deck;
  const FlashcardEditorPage({super.key, required this.deck});
  @override
  State<FlashcardEditorPage> createState() => _FlashcardEditorPageState();
}

class _FlashcardEditorPageState extends State<FlashcardEditorPage> {
  late Future<List<Map<String, dynamic>>> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async =>
      List<Map<String, dynamic>>.from(await supabase
          .from('flashcards')
          .select('id,question,difficulty,display_order')
          .eq('deck_id', widget.deck['id'])
          .order('display_order'));
  Future<void> _addCard() async {
    final front = TextEditingController();
    final back = TextEditingController();
    var saved = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('إضافة بطاقة'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: front,
              decoration:
                  const InputDecoration(labelText: 'السؤال / الوجه الأمامي')),
          TextField(
              controller: back,
              minLines: 2,
              maxLines: 4,
              decoration:
                  const InputDecoration(labelText: 'الإجابة / الوجه الخلفي')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              if (front.text.trim().isEmpty || back.text.trim().isEmpty) return;
              try {
                final existing = await supabase
                    .from('flashcards')
                    .select('id')
                    .eq('deck_id', widget.deck['id']);
                await supabase.from('flashcards').insert({
                  'deck_id': widget.deck['id'],
                  'question': front.text.trim(),
                  'answer': back.text.trim(),
                  'display_order': existing.length,
                });
                saved = true;
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (_) {
                if (dialogContext.mounted)
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('تعذر حفظ البطاقة')),
                  );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    front.dispose();
    back.dispose();
    if (saved && mounted) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text('بطاقات: ${widget.deck['title']}'), actions: [
        IconButton(onPressed: _addCard, icon: const Icon(Icons.add))
      ]),
      body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.hasError)
              return const _PracticeEmpty('تعذر تحميل البطاقات');
            final rows = snapshot.data ?? [];
            if (rows.isEmpty)
              return const _PracticeEmpty(
                  'أضف بطاقات ثم انشر المجموعة للطلاب.');
            return ListView(children: [
              for (final row in rows)
                ListTile(
                    leading: const Icon(Icons.style_outlined),
                    title: Text('${row['question']}'),
                    subtitle: Text('${row['difficulty']}'))
            ]);
          }));
}

class FlashcardReviewPage extends StatefulWidget {
  final Map<String, dynamic> deck;
  const FlashcardReviewPage({super.key, required this.deck});
  @override
  State<FlashcardReviewPage> createState() => _FlashcardReviewPageState();
}

class _FlashcardReviewPageState extends State<FlashcardReviewPage> {
  late Future<List<Map<String, dynamic>>> _future;
  int _index = 0;
  bool _showAnswer = false;
  int _known = 0;
  int _difficult = 0;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async =>
      List<Map<String, dynamic>>.from(await supabase
          .from('flashcards')
          .select('id,question,answer,difficulty')
          .eq('deck_id', widget.deck['id'])
          .order('display_order'));
  Future<void> _mark(Map<String, dynamic> card, String difficulty) async {
    try {
      await supabase.from('flashcard_reviews').upsert({
        'user_id': supabase.auth.currentUser!.id,
        'card_key': card['id'].toString(),
        'difficulty': difficulty,
        'reviewed_at': DateTime.now().toUtc().toIso8601String()
      }, onConflict: 'user_id,card_key');
      if (difficulty == 'known') _known++;
      if (difficulty == 'difficult') _difficult++;
      final rows = await _future;
      if (_index < rows.length - 1)
        setState(() {
          _index++;
          _showAnswer = false;
        });
      else if (mounted) setState(() {});
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر حفظ تقدم المراجعة')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${widget.deck['title']}')),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final cards = snapshot.data ?? const <Map<String, dynamic>>[];
            if (snapshot.hasError || cards.isEmpty) {
              return const _PracticeEmpty('لا توجد بطاقات في هذه المجموعة.');
            }
            final card = cards[_index.clamp(0, cards.length - 1)];
            return ListView(padding: const EdgeInsets.all(20), children: [
              LinearProgressIndicator(
                  value: (_index + 1) / cards.length,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8)),
              const SizedBox(height: 12),
              Text(
                  'بطاقة ${_index + 1} من ${cards.length} • أتقنت $_known • تحتاج مراجعة $_difficult',
                  textAlign: TextAlign.center),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => setState(() => _showAnswer = !_showAnswer),
                child: Card(
                    child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 230),
                  child: Center(
                      child: Padding(
                    padding: const EdgeInsets.all(25),
                    child: Text(
                        _showAnswer
                            ? '${card['answer']}'
                            : '${card['question']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 21, fontWeight: FontWeight.w800)),
                  )),
                )),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => setState(() => _showAnswer = !_showAnswer),
                icon: const Icon(Icons.flip_rounded),
                label: Text(_showAnswer ? 'عرض السؤال' : 'إظهار الإجابة'),
              ),
              if (_showAnswer)
                Row(children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => _mark(card, 'difficult'),
                          child: const Text('صعبة'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: FilledButton(
                          onPressed: () => _mark(card, 'known'),
                          child: const Text('أعرفها'))),
                ]),
              Row(children: [
                TextButton(
                    onPressed: _index > 0
                        ? () => setState(() {
                              _index--;
                              _showAnswer = false;
                            })
                        : null,
                    child: const Text('السابق')),
                const Spacer(),
                TextButton(
                    onPressed: _index < cards.length - 1
                        ? () => setState(() {
                              _index++;
                              _showAnswer = false;
                            })
                        : null,
                    child: const Text('التالي')),
              ]),
            ]);
          },
        ),
      );
}

class _PracticeMetric extends StatelessWidget {
  final String title, value;
  const _PracticeMetric({required this.title, required this.value});
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(value,
                style:
                    const TextStyle(fontSize: 25, fontWeight: FontWeight.w900))
          ])));
}

class _PracticeEmpty extends StatelessWidget {
  final String text;
  const _PracticeEmpty(this.text);
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.auto_stories_outlined,
                size: 42, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center)
          ])));
}
