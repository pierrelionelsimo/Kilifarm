import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/conversation_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/message_repository.dart';
import '../../repositories/firestore_message_repository.dart';
import '../../widgets/initials_avatar.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "à l'instant";
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${diff.inDays} j';
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().userModel?.uid;
    final MessageRepository messageRepository = FirestoreMessageRepository();

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<ConversationModel>>(
        stream: messageRepository.watchConversations(currentUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data ?? [];

          if (conversations.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  "Aucune conversation pour l'instant.\n"
                  "Écris à quelqu'un depuis son profil pour commencer.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textLight),
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final otherName = conv.otherParticipantName(currentUserId);
              final unread = conv.isUnread(currentUserId);

              return ListTile(
                leading: InitialsAvatar(fullName: otherName, radius: 22),
                title: Text(
                  otherName,
                  style: TextStyle(
                    fontWeight: unread ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  conv.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: unread ? AppTheme.textDark : AppTheme.textLight,
                    fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (conv.lastMessageAt != null)
                      Text(
                        _timeAgo(conv.lastMessageAt!),
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.textLight),
                      ),
                    if (unread)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        otherUserId: conv.otherParticipantId(currentUserId),
                        otherUserName: otherName,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
