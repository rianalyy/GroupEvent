import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/chat_message_model.dart';
import '../../../viewmodels/chat_viewmodel.dart';

class ChatTab extends StatefulWidget {
  final ChatState chatState;
  final int eventId;
  final dynamic currentUser;
  final WidgetRef ref;
  const ChatTab({super.key, required this.chatState, required this.eventId, required this.currentUser, required this.ref});

  @override
  State<ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || widget.currentUser == null) return;
    _ctrl.clear();
    await widget.ref.read(chatProvider(widget.eventId).notifier).sendMessage(
      eventId: widget.eventId,
      userId: widget.currentUser.id!,
      userName: widget.currentUser.name,
      message: text,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chatState.messages.isNotEmpty) _scrollToBottom();

    return Column(children: [
      Expanded(
        child: widget.chatState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondaryLight))
            : widget.chatState.messages.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.white.withOpacity(0.15)),
                    const SizedBox(height: 12),
                    const Text('Démarrez la conversation !', style: TextStyle(color: Colors.white38, fontSize: 15)),
                    const SizedBox(height: 6),
                    const Text('Tous les participants peuvent voir et envoyer des messages.',
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 12)),
                  ]))
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    itemCount: widget.chatState.messages.length,
                    itemBuilder: (ctx, i) {
                      final msg = widget.chatState.messages[i];
                      final isMe = widget.currentUser != null && msg.userId == widget.currentUser!.id;
                      final showName = i == 0 || widget.chatState.messages[i - 1].userId != msg.userId;
                      return _ChatBubble(
                        msg: msg, isMe: isMe, showName: showName,
                        onLongPress: isMe ? () => widget.ref.read(chatProvider(widget.eventId).notifier)
                            .deleteMessage(msg.id!, widget.eventId) : null,
                      );
                    }),
      ),
      Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.2),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08)))),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
              maxLines: null, keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Message...', hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                filled: true, fillColor: Colors.white.withOpacity(0.08),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: AppColors.secondaryLight, width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(width: 44, height: 44,
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8)]),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
          ),
        ]),
      ),
    ]);
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessageModel msg;
  final bool isMe;
  final bool showName;
  final VoidCallback? onLongPress;
  const _ChatBubble({required this.msg, required this.isMe, required this.showName, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final time = '${msg.sentAt.hour.toString().padLeft(2, '0')}:${msg.sentAt.minute.toString().padLeft(2, '0')}';
    return Padding(
      padding: EdgeInsets.only(bottom: 4, left: isMe ? 50 : 0, right: isMe ? 0 : 50),
      child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        if (showName && !isMe)
          Padding(padding: const EdgeInsets.only(left: 12, bottom: 3),
              child: Text(msg.userName, style: const TextStyle(color: AppColors.secondaryLight, fontSize: 11, fontWeight: FontWeight.w600))),
        GestureDetector(
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isMe ? AppColors.primaryGradient : null,
              color: isMe ? null : Colors.white.withOpacity(0.09),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
              ),
            ),
            child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
              Text(msg.message, style: const TextStyle(color: AppColors.white, fontSize: 14, height: 1.4)),
              const SizedBox(height: 4),
              Text(time, style: TextStyle(color: isMe ? Colors.white60 : Colors.white38, fontSize: 10)),
            ]),
          ),
        ),
        const SizedBox(height: 2),
      ]),
    );
  }
}
