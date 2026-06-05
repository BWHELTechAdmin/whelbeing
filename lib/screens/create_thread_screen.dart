import 'package:flutter/material.dart';
import '../models/thread.dart';
import '../utils/size_config.dart';

class CreateThreadScreen extends StatefulWidget {
  const CreateThreadScreen({super.key});

  @override
  State<CreateThreadScreen> createState() => _CreateThreadScreenState();
}

class _CreateThreadScreenState extends State<CreateThreadScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedGroup = 'General';

  final List<String> _groups = [
    'General',
    'New Mothers',
    'Mindful Living',
    'Fitness Together',
    'Nutrition',
    'Mental Health',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _titleController.text.trim().isNotEmpty &&
      _bodyController.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;

    final thread = CommunityThread(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: 'You',
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      group: _selectedGroup,
      createdAt: DateTime.now(),
    );

    Navigator.of(context).pop(thread);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'New Post',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 2.0 * vw),
            child: TextButton(
              onPressed: _canSubmit ? _submit : null,
              child: Text(
                'Post',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _canSubmit
                      ? const Color(0xFFE8DCC8)
                      : Colors.grey[400],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.0 * vw),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Group selector
            const Text(
              'Community',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 1.0 * vh),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.5 * vw),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3.0 * vw),
                border: Border.all(color: const Color(0xFF2A2520)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedGroup,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFFC9A96E),
                  ),
                  items: _groups
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              g,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFE8DCC8),
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedGroup = v);
                  },
                ),
              ),
            ),
            SizedBox(height: 2.4 * vh),
            // Title field
            const Text(
              'Title',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 1.0 * vh),
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'What would you like to discuss?',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3.0 * vw),
                  borderSide: const BorderSide(color: Color(0xFF2A2520)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3.0 * vw),
                  borderSide: const BorderSide(color: Color(0xFF2A2520)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3.0 * vw),
                  borderSide:
                      const BorderSide(color: Color(0xFFC9A96E), width: 1.5),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 3.5 * vw,
                  vertical: 1.5 * vh,
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            SizedBox(height: 2.4 * vh),
            // Body field
            const Text(
              'Body',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE8DCC8),
              ),
            ),
            SizedBox(height: 1.0 * vh),
            TextField(
              controller: _bodyController,
              onChanged: (_) => setState(() {}),
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Share your thoughts, questions, or experiences…',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3.0 * vw),
                  borderSide: const BorderSide(color: Color(0xFF2A2520)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3.0 * vw),
                  borderSide: const BorderSide(color: Color(0xFF2A2520)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3.0 * vw),
                  borderSide:
                      const BorderSide(color: Color(0xFFC9A96E), width: 1.5),
                ),
                contentPadding: EdgeInsets.all(3.5 * vw),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }
}
