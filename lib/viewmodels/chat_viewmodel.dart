import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message_model.dart';
import '../services/database_service.dart';

class ChatState {
  final List<ChatMessageModel> messages;
  final bool isLoading;

  const ChatState({this.messages = const [], this.isLoading = false});

  ChatState copyWith({List<ChatMessageModel>? messages, bool? isLoading}) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ChatNotifier extends FamilyNotifier<ChatState, int> {
  @override
  ChatState build(int eventId) {
    Future.microtask(() => loadMessages(eventId));
    return const ChatState(isLoading: true);
  }

  Future<void> loadMessages(int eventId) async {
    state = state.copyWith(isLoading: true);
    final messages = await DatabaseService.getMessages(eventId);
    state = ChatState(messages: messages, isLoading: false);
  }

  Future<void> sendMessage({
    required int eventId,
    required int userId,
    required String userName,
    required String message,
  }) async {
    if (message.trim().isEmpty) return;
    await DatabaseService.insertMessage(ChatMessageModel(
      eventId: eventId,
      userId: userId,
      userName: userName,
      message: message.trim(),
      sentAt: DateTime.now(),
    ));
    await loadMessages(eventId);
  }

  Future<void> deleteMessage(int messageId, int eventId) async {
    await DatabaseService.deleteMessage(messageId);
    await loadMessages(eventId);
  }
}

final chatProvider =
    NotifierProviderFamily<ChatNotifier, ChatState, int>(ChatNotifier.new);
