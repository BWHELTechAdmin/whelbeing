import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_conversation.dart';
import '../providers/ai_conversation_provider.dart';
import '../repositories/ai_conversation_repository.dart';
import '../services/ai_service.dart';
import '../utils/size_config.dart';

class AiChatScreen extends ConsumerStatefulWidget {
  final AiMode mode;

  /// When non-null, the screen resumes an existing persisted conversation.
  final AiConversation? existingConversation;

  const AiChatScreen({
    super.key,
    required this.mode,
    this.existingConversation,
  });

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  late final List<ChatMessage> _messages;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  /// Set once the first turn is persisted; null until then.
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    final greeting = ChatMessage(
      role: 'assistant',
      content: widget.mode.greeting,
    );
    if (widget.existingConversation != null) {
      _conversationId = widget.existingConversation!.id;
      _messages = [greeting, ...widget.existingConversation!.messages];
    } else {
      _messages = [greeting];
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userMessage = ChatMessage(role: 'user', content: text);
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      // Only send actual conversation turns (exclude the local greeting seed).
      final history = _messages.skip(1).toList();
      final reply = await AiService.sendMessage(
        mode: widget.mode,
        messages: history,
      );
      setState(() {
        _messages.add(ChatMessage(role: 'assistant', content: reply));
      });
      // Persist after every successful AI reply (fire-and-forget).
      _persistConversation();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          role: 'assistant',
          content:
              'Sorry, something went wrong. Please check your connection and try again.',
        ));
      });
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  /// Persists the current conversation to Supabase and updates the provider.
  /// Creates a new record on the first turn; updates on subsequent turns.
  /// Errors are swallowed so a DB failure never disrupts the chat.
  Future<void> _persistConversation() async {
    try {
      // Exclude the local greeting seed (index 0).
      final realMessages = _messages.skip(1).toList();
      AiConversation result;

      if (_conversationId == null) {
        final firstUserText = realMessages.first.content;
        final title = firstUserText.length > 60
            ? '${firstUserText.substring(0, 60)}\u2026'
            : firstUserText;
        result = await AiConversationRepository.create(
          mode: widget.mode.id,
          title: title,
          messages: realMessages,
        );
        _conversationId = result.id;
      } else {
        result = await AiConversationRepository.update(
          id: _conversationId!,
          messages: realMessages,
        );
      }

      if (!mounted) return;
      ref.read(aiConversationsProvider.notifier).upsertLocal(result);
    } catch (_) {
      // Persistence is best-effort; never crash the chat UI.
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Text(widget.mode.emoji, style: const TextStyle(fontSize: 20)),
            SizedBox(width: 2.0 * vw),
            Text(
              widget.mode.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE8DCC8),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFF2A2520)),
        ),
      ),
      body: Column(
        children: [
          // ── Message list ──
          Expanded(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: ListView.builder(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(
                  horizontal: 4.0 * vw,
                  vertical: 2.0 * vh,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _MessageBubble(
                    message: _messages[index],
                    mode: widget.mode,
                  );
                },
              ),
            ),
          ),

          // ── Typing indicator ──
          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(
                left: 4.0 * vw,
                bottom: 1.0 * vh,
              ),
              child: Row(
                children: [
                  _TypingDot(delay: 0),
                  SizedBox(width: 1.5 * vw),
                  _TypingDot(delay: 200),
                  SizedBox(width: 1.5 * vw),
                  _TypingDot(delay: 400),
                ],
              ),
            ),

          // ── Input bar ──
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0D0D0D),
              border: Border(
                top: BorderSide(color: Color(0xFF2A2520)),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              4.0 * vw,
              1.5 * vh,
              4.0 * vw,
              MediaQuery.of(context).viewInsets.bottom > 0
                  ? 1.5 * vh
                  : 3.0 * vh,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(maxHeight: 15.0 * vh),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(6.0 * vw),
                      border: Border.all(color: const Color(0xFF2A2520)),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFE8DCC8),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4.0 * vw,
                          vertical: 1.4 * vh,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 3.0 * vw),
                GestureDetector(
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    width: 11.0 * vw,
                    height: 11.0 * vw,
                    decoration: BoxDecoration(
                      color: _isLoading
                          ? const Color(0xFF3D2E14)
                          : const Color(0xFFC9A96E),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      color: _isLoading ? const Color(0xFF6B5220) : Colors.black,
                      size: 5.5 * vw,
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

// ─── Message bubble ───────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final AiMode mode;

  const _MessageBubble({required this.message, required this.mode});

  bool get isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    final vh = SizeConfig.vh;
    final vw = SizeConfig.vw;

    return Padding(
      padding: EdgeInsets.only(bottom: 1.5 * vh),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // AI avatar
            Container(
              width: 8.0 * vw,
              height: 8.0 * vw,
              decoration: const BoxDecoration(
                color: Color(0xFF2A2520),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  mode.emoji,
                  style: TextStyle(fontSize: 4.0 * vw),
                ),
              ),
            ),
            SizedBox(width: 2.0 * vw),
          ],
          // Bubble
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: 4.0 * vw,
                vertical: 1.3 * vh,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(0xFF2A1F0A)
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(5.0 * vw),
                  topRight: Radius.circular(5.0 * vw),
                  bottomLeft: Radius.circular(isUser ? 5.0 * vw : 1.0 * vw),
                  bottomRight: Radius.circular(isUser ? 1.0 * vw : 5.0 * vw),
                ),
                border: Border.all(
                  color: isUser
                      ? const Color(0xFF6B5220)
                      : const Color(0xFF2A2520),
                ),
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFE8DCC8),
                        height: 1.5,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[300],
                          height: 1.5,
                        ),
                        strong: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFC9A96E),
                          fontWeight: FontWeight.bold,
                        ),
                        em: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[300],
                          fontStyle: FontStyle.italic,
                        ),
                        code: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFE8DCC8),
                          backgroundColor: Color(0xFF2A2520),
                          fontFamily: 'monospace',
                        ),
                        codeblockDecoration: const BoxDecoration(
                          color: Color(0xFF2A2520),
                          borderRadius: BorderRadius.all(Radius.circular(6)),
                        ),
                        listBullet: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[300],
                        ),
                        h1: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFFE8DCC8),
                          fontWeight: FontWeight.bold,
                        ),
                        h2: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFFE8DCC8),
                          fontWeight: FontWeight.bold,
                        ),
                        h3: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFE8DCC8),
                          fontWeight: FontWeight.w600,
                        ),
                        blockquoteDecoration: const BoxDecoration(
                          color: Color(0xFF1A1A1A),
                          border: Border(
                            left: BorderSide(
                              color: Color(0xFFC9A96E),
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) SizedBox(width: 2.0 * vw),
        ],
      ),
    );
  }
}

// ─── Animated typing indicator dot ───────────────────────────────────────────

class _TypingDot extends StatefulWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFFC9A96E),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
