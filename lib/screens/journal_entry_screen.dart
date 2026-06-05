import 'package:flutter/material.dart';
import '../utils/size_config.dart';

class JournalEntryScreen extends StatefulWidget {
  final String category;
  final IconData icon;
  final Color color;

  const JournalEntryScreen({
    super.key,
    required this.category,
    required this.icon,
    required this.color,
  });

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isEditing = true;  // Start in editing mode
  int? _selectedEntryIndex;
  bool _isSidebarVisible = false;  // Start with sidebar hidden

  // Sample previous entries - in a real app, these would come from a database
  final List<Map<String, String>> _entries = [
    {
      'date': 'January 28, 2026',
      'time': '10:30 AM',
      'preview': 'Feeling great today! Had a wonderful morning...',
      'content':
          'Feeling great today! Had a wonderful morning walk and noticed I have more energy than usual. The weather was perfect and I took some time to meditate.',
    },
    {
      'date': 'January 27, 2026',
      'time': '8:15 PM',
      'preview': 'Tried a new yoga routine this evening...',
      'content':
          'Tried a new yoga routine this evening. It was challenging but felt really good afterward. Need to remember to do more stretching.',
    },
    {
      'date': 'January 26, 2026',
      'time': '2:45 PM',
      'preview': 'Made some healthy meal prep for the week...',
      'content':
          'Made some healthy meal prep for the week. Lots of vegetables and lean proteins. Feeling motivated to stick with my health goals.',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startNewEntry() {
    setState(() {
      _isEditing = true;
      _selectedEntryIndex = null;
      _controller.clear();
      _isSidebarVisible = false;  // Hide sidebar when creating new entry
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarVisible = !_isSidebarVisible;
    });
  }

  void _selectEntry(int index) {
    setState(() {
      _selectedEntryIndex = index;
      _controller.text = _entries[index]['content']!;
      _isEditing = false;
      _isSidebarVisible = true;  // Show sidebar when selecting entry
    });
  }

  void _saveEntry() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        final now = DateTime.now();
        final newEntry = {
          'date': '${_getMonthName(now.month)} ${now.day}, ${now.year}',
          'time': _formatTime(now),
          'preview': _controller.text.length > 50
              ? '${_controller.text.substring(0, 50)}...'
              : _controller.text,
          'content': _controller.text,
        };
        _entries.insert(0, newEntry);
        _selectedEntryIndex = 0;
        _isEditing = false;
        _isSidebarVisible = true;  // Show sidebar after saving
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.category} entry saved!'),
          backgroundColor: widget.color,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;
    // 40% of screen width on small screens, 35% clamped on larger screens
    final sidebarWidth = SizeConfig.screenWidth < 600
        ? 40.0 * vw
        : (35.0 * vw).clamp(250.0, 400.0);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Row(
        children: [
          // Left sidebar - List of entries
          if (_isSidebarVisible)
            Container(
              width: sidebarWidth,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              border: Border(
                right: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
              padding: EdgeInsets.only(
                    top: 7.1 * vh,
                    left: 4.0 * vw,
                    right: 4.0 * vw,
                    bottom: 2.0 * vh,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: EdgeInsets.all(1.0 * vw),
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: widget.color,
                            size: 5.0 * vw,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.0 * vw),
                      Icon(widget.icon, color: widget.color, size: 5.0 * vw),
                      SizedBox(width: 2.0 * vw),
                      Expanded(
                        child: Text(
                          widget.category,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: widget.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 1.0 * vw),
                      GestureDetector(
                        onTap: _startNewEntry,
                        child: Padding(
                          padding: EdgeInsets.all(1.0 * vw),
                          child: Icon(
                            Icons.add,
                            color: widget.color,
                            size: 5.5 * vw,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Entries list
                Expanded(
                  child: _entries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.icon,
                                size: 12.0 * vw,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 2.0 * vh),
                              Text(
                                'No entries yet',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            final isSelected = _selectedEntryIndex == index;
                            return InkWell(
                              onTap: () => _selectEntry(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? widget.color.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            entry['date']!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? widget.color
                                                  : const Color(0xFFE8DCC8),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          entry['time']!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      entry['preview']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          // Right side - Entry content/editor
          Expanded(
            child: _selectedEntryIndex == null && !_isEditing
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_add_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select an entry or create a new one',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Toolbar
                      if (_isEditing)
                        Container(
                      padding: EdgeInsets.only(
                            top: 7.1 * vh,
                            left: 4.0 * vw,
                            right: 4.0 * vw,
                            bottom: 1.5 * vh,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (!_isSidebarVisible)
                                GestureDetector(
                                  onTap: _toggleSidebar,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 4.0 * vw),
                                    child: Icon(
                                      Icons.menu,
                                      color: widget.color,
                                      size: 6.0 * vw,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'New Entry',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: widget.color,
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: _saveEntry,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: widget.color,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(2.0 * vw),
                                        ),
                                      ),
                                      child: const Text('Done'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                        padding: EdgeInsets.only(
                            top: 7.1 * vh,
                            left: 4.0 * vw,
                            right: 4.0 * vw,
                            bottom: 1.5 * vh,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              if (!_isSidebarVisible)
                                GestureDetector(
                                  onTap: _toggleSidebar,
                                  child: Padding(
                                    padding: EdgeInsets.only(right: 4.0 * vw),
                                    child: Icon(
                                      Icons.menu,
                                      color: widget.color,
                                      size: 6.0 * vw,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _entries[_selectedEntryIndex!]['date']!,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: widget.color,
                                          ),
                                        ),
                                        Text(
                                          _entries[_selectedEntryIndex!]['time']!,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () {
                                        setState(() {
                                          _isEditing = true;
                                        });
                                      },
                                      color: widget.color,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Content
                      Expanded(
                        child: Container(
                          color: const Color(0xFF1A1A1A),
                        padding: EdgeInsets.all(6.0 * vw),
                          child: _isEditing
                              ? TextField(
                                  controller: _controller,
                                  maxLines: null,
                                  expands: true,
                                  autofocus: true,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.5,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Start writing your ${widget.category} entry...',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                    ),
                                    border: InputBorder.none,
                                  ),
                                )
                              : SingleChildScrollView(
                                  child: Text(
                                    _controller.text,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
