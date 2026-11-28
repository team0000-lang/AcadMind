import 'package:flutter/material.dart';

import 'notification_center.dart';
import 'study_library.dart';
import 'study_tools.dart';

class _AiToolItem {
  final String title;
  final String subtitle;
  final String category;
  final IconData icon;
  final Color color;

  const _AiToolItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.color,
  });
}

const List<_AiToolItem> _aiTools = [
  _AiToolItem(
    title: 'AI Study Assistant',
    subtitle: 'Ask questions and get help from your course materials.',
    category: 'Assistant',
    icon: Icons.forum_rounded,
    color: Color(0xFF7868F6),
  ),
  _AiToolItem(
    title: 'PDF Analyzer',
    subtitle: 'Understand lecture files and extract key information.',
    category: 'Documents',
    icon: Icons.picture_as_pdf_rounded,
    color: Color(0xFFE36B78),
  ),
  _AiToolItem(
    title: 'Smart Summarizer',
    subtitle: 'Turn long lessons into clear, structured notes.',
    category: 'Documents',
    icon: Icons.summarize_rounded,
    color: Color(0xFF299D91),
  ),
  _AiToolItem(
    title: 'Quiz Generator',
    subtitle: 'Create practice questions and check your understanding.',
    category: 'Practice',
    icon: Icons.quiz_rounded,
    color: Color(0xFFE39A45),
  ),
  _AiToolItem(
    title: 'Flashcards',
    subtitle: 'Build quick revision cards from important concepts.',
    category: 'Practice',
    icon: Icons.style_rounded,
    color: Color(0xFF4C8BD8),
  ),
  _AiToolItem(
    title: 'AI Explainer',
    subtitle: 'Break down difficult topics into simple steps.',
    category: 'Assistant',
    icon: Icons.lightbulb_rounded,
    color: Color(0xFFB68A35),
  ),
  _AiToolItem(
    title: 'Study Planner',
    subtitle: 'Organize your study time into realistic sessions.',
    category: 'Planning',
    icon: Icons.calendar_month_rounded,
    color: Color(0xFFB16BD4),
  ),
  _AiToolItem(
    title: 'Progress Analytics',
    subtitle: 'Review your progress and find what to improve next.',
    category: 'Planning',
    icon: Icons.insights_rounded,
    color: Color(0xFF339C9A),
  ),
];

class AcadMindAiPage extends StatefulWidget {
  const AcadMindAiPage({super.key});

  @override
  State<AcadMindAiPage> createState() => _AcadMindAiPageState();
}

class _AcadMindAiPageState extends State<AcadMindAiPage> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  static const List<String> _categories = [
    'All',
    'Assistant',
    'Documents',
    'Practice',
    'Planning',
  ];

  @override
  void dispose() {
    _questionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _openAssistant() {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;
    openStudyTool(
      context,
      'AI Study Assistant',
      initialPrompt: question,
    );
  }

  void _openTool(_AiToolItem tool) {
    openStudyTool(context, tool.title);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final columns = width >= 720 ? 3 : 2;
    final query = _searchController.text.trim().toLowerCase();
    final visibleTools = _aiTools.where((tool) {
      final categoryMatches =
          _selectedCategory == 'All' || tool.category == _selectedCategory;
      final queryMatches = query.isEmpty ||
          tool.title.toLowerCase().contains(query) ||
          tool.subtitle.toLowerCase().contains(query);
      return categoryMatches && queryMatches;
    }).toList();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.primary, colors.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AcadMind AI',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Your personal study workspace',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Notifications',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationCenterPage(),
                      ),
                    ),
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primary.withValues(alpha: 0.96),
                      colors.tertiary.withValues(alpha: 0.88),
                      colors.primary.withValues(alpha: 0.78),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'YOUR AI STUDY PARTNER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 17),
                    const Text(
                      'Study smarter.\nUnderstand more.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ask, explore, practice and organize your learning in one place.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: TextField(
                        controller: _questionController,
                        minLines: 1,
                        maxLines: 3,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _openAssistant(),
                        decoration: InputDecoration(
                          hintText: 'Ask anything about your studies...',
                          hintStyle: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: colors.primary,
                          ),
                          suffixIcon: IconButton(
                            tooltip: 'Ask AcadMind',
                            onPressed: _openAssistant,
                            icon: Icon(
                              Icons.arrow_upward_rounded,
                              color: colors.primary,
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroTag(
                          icon: Icons.menu_book_rounded,
                          label: 'Course-aware',
                        ),
                        _HeroTag(
                          icon: Icons.bolt_rounded,
                          label: 'Study tools',
                        ),
                        _HeroTag(
                          icon: Icons.picture_as_pdf_rounded,
                          label: 'PDF support',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 10),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Study tools',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Choose the right tool for your next task',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '08 TOOLS',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            sliver: SliverToBoxAdapter(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search study tools',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest.withValues(
                    alpha: 0.45,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 42,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = category),
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: selected ? colors.onPrimary : colors.onSurface,
                    ),
                    selectedColor: colors.primary,
                    backgroundColor: colors.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    side: BorderSide(
                      color: selected
                          ? colors.primary
                          : colors.outlineVariant.withValues(alpha: 0.55),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  );
                },
              ),
            ),
          ),
          if (visibleTools.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: Text(
                    'No tools match your search.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _AiToolCard(
                    tool: visibleTools[index],
                    onTap: () => _openTool(visibleTools[index]),
                  ),
                  childCount: visibleTools.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 11,
                  mainAxisSpacing: 11,
                  childAspectRatio: width >= 720 ? 1.22 : 1.05,
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
            sliver: SliverToBoxAdapter(
              child: Material(
                color: colors.primaryContainer.withValues(alpha: 0.38),
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudyLibraryPage(),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(17),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.library_books_rounded,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your AI Library',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Find saved summaries, quizzes and study notes.',
                                style: TextStyle(fontSize: 10.5, height: 1.4),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 15,
                          color: colors.primary,
                        ),
                      ],
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

class _HeroTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiToolCard extends StatelessWidget {
  final _AiToolItem tool;
  final VoidCallback onTap;

  const _AiToolCard({required this.tool, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(21),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tool.color.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(tool.icon, color: tool.color, size: 21),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.north_east_rounded,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                    size: 17,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                tool.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                tool.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 9.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
