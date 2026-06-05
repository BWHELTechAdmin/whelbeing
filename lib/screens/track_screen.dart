import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/health_record_model.dart';
import '../providers/health_record_provider.dart';
import '../repositories/profile_repository.dart';
import '../utils/size_config.dart';

class TrackScreen extends ConsumerStatefulWidget {
  const TrackScreen({super.key});

  @override
  ConsumerState<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends ConsumerState<TrackScreen> {
  int _visibleCount = 3;
  List<String> _focusAreas = [];
  bool _areasInitialized = false;

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    final recordsAsync = ref.watch(healthRecordsProvider);

    // Seed chips from DB once when data first arrives.
    ref.listen<AsyncValue<List<String>>>(healthAreasProvider, (_, next) {
      if (!_areasInitialized && next.valueOrNull != null) {
        _areasInitialized = true;
        setState(() => _focusAreas = List.of(next.value!));
      }
    });
    final areasAsync = ref.watch(healthAreasProvider);
    if (!_areasInitialized && areasAsync.valueOrNull != null) {
      _areasInitialized = true;
      _focusAreas = List.of(areasAsync.value!);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Record',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(4.0 * vw, 1.0 * vh, 4.0 * vw, 2.8 * vh),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFocusAreas(),
            SizedBox(height: 2.0 * vh),
            recordsAsync.when(
              loading: _buildLoadingRecord,
              error: (e, _) => _buildErrorRecord(),
              data: _buildHealthRecord,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFocusAreas() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'HEALTH FOCUS AREAS',
            subtitle: 'AI-personalized from your inputs and visits',
          ),
          SizedBox(height: 2.0 * SizeConfig.vh),
          Wrap(
            spacing: 2.0 * SizeConfig.vw,
            runSpacing: 1.0 * SizeConfig.vh,
            children: [
              ..._focusAreas.map((a) => _FocusChip(label: a)),
              _AddChip(onTap: _showAddAreaDialog),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddAreaDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Add Focus Area',
          style: TextStyle(color: Color(0xFFE8DCC8)),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Color(0xFFE8DCC8)),
          decoration: InputDecoration(
            hintText: 'e.g. Thyroid, Sleep, Hormones',
            hintStyle: TextStyle(color: Colors.grey[600]),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF2A2520)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFC9A96E)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF8B6548))),
          ),
          TextButton(
            onPressed: () {
            final text = controller.text.trim();
              if (text.isNotEmpty) {
                final truncated = text.length > 64 ? text.substring(0, 64) : text;
                setState(() => _focusAreas.add(truncated));
                // Fire-and-forget persist to DB
                ref
                    .read(profileRepositoryProvider)
                    .addHealthArea(truncated)
                    .ignore();
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Add',
                style: TextStyle(color: Color(0xFFC9A96E))),
          ),
        ],
      ),
    );
  }

  void _loadMore() {
    setState(() => _visibleCount += 5);
  }

  Widget _buildLoadingRecord() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'HEALTH RECORD',
            subtitle: 'Your visits, labs & AI-flagged follow-ups',
          ),
          const Divider(color: Color(0xFF2A2520), height: 24),
          Center(
            child: Padding(
              padding:
                  EdgeInsets.symmetric(vertical: 2.0 * SizeConfig.vh),
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFC9A96E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorRecord() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'HEALTH RECORD',
            subtitle: 'Your visits, labs & AI-flagged follow-ups',
          ),
          const Divider(color: Color(0xFF2A2520), height: 24),
          _LogButton(onTap: _showLogBottomSheet),
          const Divider(color: Color(0xFF2A2520), height: 24),
          Padding(
            padding:
                EdgeInsets.symmetric(vertical: 2.0 * SizeConfig.vh),
            child: Text(
              'Could not load records.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRecord(List<HealthRecordModel> records) {
    final count = _visibleCount.clamp(0, records.length);
    final hasMore = _visibleCount < records.length;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: 'HEALTH RECORD',
            subtitle: 'Your visits, labs & AI-flagged follow-ups',
          ),
          const Divider(color: Color(0xFF2A2520), height: 24),
          _LogButton(onTap: _showLogBottomSheet),
          if (records.isEmpty) ...[
            const Divider(color: Color(0xFF2A2520), height: 24),
            Padding(
              padding:
                  EdgeInsets.symmetric(vertical: 2.0 * SizeConfig.vh),
              child: Center(
                child: Text(
                  'No records yet. Log your first visit or lab.',
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ),
            ),
          ] else ...[
            const Divider(color: Color(0xFF2A2520), height: 24),
            ...List.generate(
              count,
              (i) => _TimelineEntry(
                record: records[i],
                isLast: i == count - 1 && !hasMore,
              ),
            ),
            if (hasMore) ...[
              const Divider(color: Color(0xFF2A2520), height: 1),
              _LoadMoreButton(onTap: _loadMore),
            ],
          ],
        ],
      ),
    );
  }

  void _showLogBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (ctx) => _LogEntrySheet(
        onSave: ({
          required HealthRecordType type,
          required DateTime recordDate,
          required String title,
          String? notes,
        }) {
          ref.read(healthRecordsProvider.notifier).addRecord(
                type: type,
                recordDate: recordDate,
                title: title,
                notes: notes,
              );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vw = SizeConfig.vw;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5.0 * vw),
      decoration: BoxDecoration(
        color: const Color(0xFF161410),
        borderRadius: BorderRadius.circular(4.0 * vw),
        border: Border.all(color: const Color(0xFF2A2520)),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFFC9A96E),
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
        ),
      ],
    );
  }
}

class _FocusChip extends StatelessWidget {
  final String label;
  const _FocusChip({required this.label});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    final display = label.length > 64 ? '${label.substring(0, 64)}…' : label;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.5 * vw, vertical: 0.8 * vh),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2520).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(5.0 * vw),
        border: Border.all(color: const Color(0xFF3D2E14)),
      ),
      child: Text(
        display,
        style: const TextStyle(fontSize: 13, color: Color(0xFFE8DCC8)),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.5 * vw, vertical: 0.8 * vh),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(5.0 * vw),
          border: Border.all(color: const Color(0xFF3D2E14)),
        ),
        child: const Text(
          '+ Add area',
          style: TextStyle(fontSize: 13, color: Color(0xFFC9A96E)),
        ),
      ),
    );
  }
}

class _TimelineEntry extends StatelessWidget {
  final HealthRecordModel record;
  final bool isLast;
  const _TimelineEntry({required this.record, required this.isLast});

  Color get _dotColor {
    if (record.isRecent) return const Color(0xFF5DB075);
    if (record.status == HealthRecordStatus.missingResult) {
      return const Color(0xFFC9A96E);
    }
    return const Color(0xFF4A4036);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 5.0 * vw,
            child: Column(
              children: [
                SizedBox(height: 0.35 * vh),
                Container(
                  width: 2.5 * vw,
                  height: 2.5 * vw,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 1,
                        color: const Color(0xFF2A2520),
                        margin: EdgeInsets.symmetric(vertical: 0.5 * vh),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 3.5 * vw),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0.5 * vh : 2.8 * vh),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.formattedDate,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8B6548),
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 0.6 * vh),
                  Text(
                    record.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE8DCC8),
                      height: 1.25,
                    ),
                  ),
                  SizedBox(height: 0.5 * vh),
                  Text(
                    record.notes ?? 'No additional notes.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      height: 1.4,
                    ),
                  ),
                  if (record.status != HealthRecordStatus.none) ...[
                    SizedBox(height: 1.2 * vh),
                    _StatusBadge(status: record.status),
                  ],
                  if (record.aiSuggestion != null) ...[
                    SizedBox(height: 1.2 * vh),
                    _AiSuggestion(text: record.aiSuggestion!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final HealthRecordStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    final isFlagged = status == HealthRecordStatus.flagged;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.0 * vw, vertical: 0.7 * vh),
      decoration: BoxDecoration(
        color:
            isFlagged ? const Color(0xFF3D2A10) : const Color(0xFF2A1E10),
        borderRadius: BorderRadius.circular(5.0 * vw),
        border: Border.all(
          color: isFlagged
              ? const Color(0xFFC9A96E).withValues(alpha: 0.4)
              : const Color(0xFF8B6548).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 3.5 * vw,
            color: isFlagged
                ? const Color(0xFFC9A96E)
                : const Color(0xFF8B6548),
          ),
          SizedBox(width: 1.5 * vw),
          Text(
            isFlagged
                ? 'Flagged — follow up needed'
                : 'Missing result — follow up',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isFlagged
                  ? const Color(0xFFC9A96E)
                  : const Color(0xFF8B6548),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiSuggestion extends StatelessWidget {
  final String text;
  const _AiSuggestion({required this.text});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vw = SizeConfig.vw;
    return Container(
      padding: EdgeInsets.all(3.5 * vw),
      decoration: BoxDecoration(
        color: const Color(0xFF1E160A),
        borderRadius: BorderRadius.circular(2.5 * vw),
        border: Border.all(
          color: const Color(0xFF3D2E14).withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✶',
            style: TextStyle(color: Color(0xFFC9A96E), fontSize: 12),
          ),
          SizedBox(width: 2.0 * vw),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(
                    text: 'AI SUGGESTION  ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC9A96E),
                      letterSpacing: 1.2,
                    ),
                  ),
                  TextSpan(
                    text: text,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[300],
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LogButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 0.8 * vh),
        child: const Center(
          child: Text(
            '+ LOG A VISIT OR LAB',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFC9A96E),
              letterSpacing: 1.8,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadMoreButton extends StatelessWidget {
  final VoidCallback onTap;
  const _LoadMoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(top: 1.7 * vh),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'LOAD MORE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8B6548),
                  letterSpacing: 1.8,
                ),
              ),
              SizedBox(width: 1.0 * vw),
              Icon(
                Icons.keyboard_arrow_down,
                color: const Color(0xFF8B6548),
                size: 4.0 * vw,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Log Entry Bottom Sheet
// ---------------------------------------------------------------------------

class _LogEntrySheet extends StatefulWidget {
  final void Function({
    required HealthRecordType type,
    required DateTime recordDate,
    required String title,
    String? notes,
  }) onSave;
  const _LogEntrySheet({required this.onSave});

  @override
  State<_LogEntrySheet> createState() => _LogEntrySheetState();
}

class _LogEntrySheetState extends State<_LogEntrySheet> {
  HealthRecordType _type = HealthRecordType.visit;
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get _formattedDate =>
      '${_months[_date.month - 1].toUpperCase()} ${_date.day}, ${_date.year}';

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(5.0 * vw, 2.4 * vh, 5.0 * vw, 2.4 * vh + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 9.0 * vw,
              height: 0.5 * vh,
              decoration: BoxDecoration(
                color: const Color(0xFF3A3028),
                borderRadius: BorderRadius.circular(0.5 * vw),
              ),
            ),
          ),
          SizedBox(height: 2.4 * vh),
          const Text(
            'LOG A NEW ENTRY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFC9A96E),
              letterSpacing: 2.0,
            ),
          ),
          SizedBox(height: 2.0 * vh),
          Row(
            children: [
              _TypeChip(
                label: 'Visit',
                icon: Icons.local_hospital_outlined,
                selected: _type == HealthRecordType.visit,
                onTap: () => setState(() => _type = HealthRecordType.visit),
              ),
              SizedBox(width: 2.0 * vw),
              _TypeChip(
                label: 'Lab',
                icon: Icons.biotech_outlined,
                selected: _type == HealthRecordType.lab,
                onTap: () => setState(() => _type = HealthRecordType.lab),
              ),
              SizedBox(width: 2.0 * vw),
              _TypeChip(
                label: 'Symptom Log',
                icon: Icons.edit_note,
                selected: _type == HealthRecordType.symptomLog,
                onTap: () =>
                    setState(() => _type = HealthRecordType.symptomLog),
              ),
            ],
          ),
          SizedBox(height: 2.0 * vh),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 3.5 * vw, vertical: 1.5 * vh),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1A14),
                borderRadius: BorderRadius.circular(2.5 * vw),
                border: Border.all(color: const Color(0xFF2A2520)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: const Color(0xFFC9A96E),
                    size: 4.0 * vw,
                  ),
                  SizedBox(width: 2.5 * vw),
                  Text(
                    _formattedDate,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFFE8DCC8)),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_drop_down,
                      color: Colors.grey[600], size: 5.0 * vw),
                ],
              ),
            ),
          ),
          SizedBox(height: 1.5 * vh),
          _Field(
            controller: _titleController,
            label: 'Title',
            hint: _type == HealthRecordType.lab
                ? 'e.g. CBC + Iron Panel'
                : _type == HealthRecordType.visit
                    ? 'e.g. OB-GYN Annual Visit'
                    : 'e.g. Fatigue & heavy cycles',
          ),
          SizedBox(height: 1.5 * vh),
          _Field(
            controller: _notesController,
            label: 'Notes',
            hint: _type == HealthRecordType.lab
                ? 'Enter result values, e.g. Ferritin: 8 ng/mL (low)'
                : 'Add notes, findings, or observations…',
            maxLines: 3,
          ),
          SizedBox(height: 2.4 * vh),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC9A96E),
                foregroundColor: const Color(0xFF0D0D0D),
                padding: EdgeInsets.symmetric(vertical: 1.7 * vh),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3.0 * vw),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Save Entry',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: const Color(0xFFC9A96E)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    final notes = _notesController.text.trim();
    widget.onSave(
      type: _type,
      recordDate: _date,
      title: title,
      notes: notes.isEmpty ? null : notes,
    );
    Navigator.of(context).pop();
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.0 * vw, vertical: 1.0 * vh),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFC9A96E).withValues(alpha: 0.15)
              : const Color(0xFF1E1A14),
          borderRadius: BorderRadius.circular(5.0 * vw),
          border: Border.all(
            color: selected
                ? const Color(0xFFC9A96E).withValues(alpha: 0.5)
                : const Color(0xFF2A2520),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 3.5 * vw,
              color: selected
                  ? const Color(0xFFC9A96E)
                  : Colors.grey[600],
            ),
            SizedBox(width: 1.5 * vw),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: selected
                    ? const Color(0xFFC9A96E)
                    : Colors.grey[600],
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String label;
  final int maxLines;
  const _Field({
    required this.controller,
    required this.hint,
    required this.label,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Color(0xFFE8DCC8)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(fontSize: 12, color: Colors.grey[600]),
        hintText: hint,
        hintStyle:
            TextStyle(fontSize: 13, color: Colors.grey[700]),
        filled: true,
        fillColor: const Color(0xFF1E1A14),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 3.5 * vw, vertical: 1.5 * vh),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2.5 * vw),
          borderSide: const BorderSide(color: Color(0xFF2A2520)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2.5 * vw),
          borderSide: const BorderSide(
              color: Color(0xFFC9A96E), width: 1.5),
        ),
      ),
    );
  }
}
