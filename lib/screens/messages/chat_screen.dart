import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/message_repository.dart';
import '../../repositories/firestore_message_repository.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageRepository _messageRepository = FirestoreMessageRepository();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  late final String _currentUserId;
  late final String _currentUserName;
  late final String _conversationId;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel!;
    _currentUserId = user.uid;
    _currentUserName = user.fullName;
    _conversationId =
        _messageRepository.conversationIdFor(_currentUserId, widget.otherUserId);

    // Marque comme lu dès l'ouverture. Échoue silencieusement si la
    // conversation n'existe pas encore (première fois) — pas grave,
    // rien à marquer comme lu dans ce cas.
    _messageRepository
        .markAsRead(conversationId: _conversationId, userId: _currentUserId)
        .catchError((_) {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _controller.clear();

    try {
      await _messageRepository.sendMessage(
        currentUserId: _currentUserId,
        currentUserName: _currentUserName,
        otherUserId: widget.otherUserId,
        otherUserName: widget.otherUserName,
        content: content,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors de l'envoi du message")),
        );
      }
    }

    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _confirmDeleteMessage(MessageModel msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce message ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _messageRepository.deleteMessage(
        conversationId: _conversationId,
        messageId: msg.id,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression.')),
        );
      }
    }
  }

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherUserName)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messageRepository.watchMessages(_conversationId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'Dis bonjour à ${widget.otherUserName} !',
                      style: const TextStyle(color: AppTheme.textLight),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController
                        .jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMine = msg.senderId == _currentUserId;

                    return Align(
                      alignment:
                          isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        // Supprimer un message ne se fait que par un
                        // long-press sur ses propres bulles — un tap
                        // simple reste neutre, comme WhatsApp.
                        onLongPress:
                            isMine ? () => _confirmDeleteMessage(msg) : null,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.72,
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: isMine
                                ? AppTheme.primaryGreen
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: Radius.circular(isMine ? 14 : 2),
                              bottomRight: Radius.circular(isMine ? 2 : 14),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                msg.content,
                                style: TextStyle(
                                  color:
                                      isMine ? Colors.white : AppTheme.textDark,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatTime(msg.createdAt),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMine
                                      ? Colors.white70
                                      : AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Message...',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: AppTheme.primaryGreen),
                    onPressed: _isSending ? null : _send,
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
