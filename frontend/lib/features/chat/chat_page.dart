import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/colors.dart';
import '../../core/localization/localized_text.dart';
import '../../core/typography.dart';
import 'chat_bubble_ai.dart';
import 'chat_bubble_user.dart';
import 'chat_controller.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  ProviderSubscription<ChatState>? _chatSubscription;

  @override
  void initState() {
    super.initState();
    _chatSubscription = ref.listenManual<ChatState>(
      chatControllerProvider,
      (previous, next) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      },
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent -
          300, // scroll to TOP of new bubble
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _chatSubscription?.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _messageController.text;
    _messageController.clear();
    await ref.read(chatControllerProvider.notifier).sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          localizedText(
            context,
            en: 'Conversation ${widget.conversationId}',
            mr: 'संभाषण ${widget.conversationId}',
          ),
        ),
        actions: const [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.surface,
            child: Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
          ),
          SizedBox(width: 20),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final message = chatState.messages[index];
                      return Padding(
                          key: ValueKey(message.id),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: message.isUser
                              ? UserChatBubble(text: message.text)
                              : AiChatBubble(
                                  text: message.text,
                                  isPlaying: message.isPlayingAudio,
                                  onPlayPause: () => ref
                                      .read(chatControllerProvider.notifier)
                                      .togglePlay(message.id),
                                ));
                    },
                  ),
                ),
                _InputBar(
                  controller: _messageController,
                  onSend: _handleSend,
                  isRecording: chatState.isRecording,
                  micLevel: chatState.micLevel, // NEW
                  onMicHoldStart: () => ref
                      .read(chatControllerProvider.notifier)
                      .startListening(),
                  onMicHoldEnd: () =>
                      ref.read(chatControllerProvider.notifier).stopListening(),
                  onMicCancelled: () => ref
                      .read(chatControllerProvider.notifier)
                      .cancelListening(),
                ),
              ],
            ),
            // Floating STOP AUDIO bar
            if (ref.watch(chatControllerProvider.notifier).isAnyAudioPlaying)
              Positioned(
                top: 12,
                left: 20,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    ref.read(chatControllerProvider.notifier).stopAllAudio();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                        )
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Stop Audio",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatefulWidget {
  final double micLevel;

  const _InputBar({
    required this.controller,
    required this.onSend,
    required this.isRecording,
    required this.micLevel, // NEW
    required this.onMicHoldStart,
    required this.onMicHoldEnd,
    required this.onMicCancelled,
  });

  final TextEditingController controller;
  final Future<void> Function() onSend;
  final bool isRecording;
  final VoidCallback onMicHoldStart;
  final Future<void> Function() onMicHoldEnd;
  final VoidCallback onMicCancelled;

  @override
  State<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends State<_InputBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: widget.controller,
        builder: (context, value, _) {
          final hasText = value.text.trim().isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.isRecording
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: widget.isRecording
                            ? Border.all(color: AppColors.primary)
                            : null,
                      ),
                      child: widget.isRecording
                          ? _RecordWaveform(level: widget.micLevel)
                          : TextField(
                              controller: widget.controller,
                              minLines: 1,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText: localizedText(
                                  context,
                                  en: 'Type a message…',
                                  mr: 'संदेश लिहा...',
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // SEND button or MIC
                  hasText
                      ? InkWell(
                          onTap: widget.onSend,
                          customBorder: const CircleBorder(),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            child: const Icon(Icons.near_me_rounded,
                                color: Colors.white),
                          ),
                        )
                      : GestureDetector(
                          onLongPressStart: (_) => widget.onMicHoldStart(),
                          onLongPressEnd: (_) => widget.onMicHoldEnd(),
                          onLongPressCancel: widget.onMicCancelled,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isRecording
                                  ? Colors.white
                                  : AppColors.primary,
                              border: Border.all(
                                color: widget.isRecording
                                    ? Colors.white
                                    : AppColors.primary,
                                width: 2,
                              ),
                              boxShadow: [
                                if (widget.isRecording)
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.25),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  )
                              ],
                            ),
                            child: Icon(
                              widget.isRecording
                                  ? Icons.graphic_eq
                                  : Icons.mic_none_rounded,
                              color: widget.isRecording
                                  ? AppColors.primary
                                  : Colors.white,
                            ),
                          ),
                        ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                localizedText(
                  context,
                  en: hasText ? 'Send message' : 'Hold mic to talk',
                  mr: hasText ? 'संदेश पाठवा' : 'बोलण्यासाठी धरून ठेवा',
                ),
                textAlign: TextAlign.right,
                style: AppTypography.textTheme.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecordWaveform extends StatelessWidget {
  final double level;
  const _RecordWaveform({required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(12, (i) {
          final height = 8 + (level * 24) * ((i % 4) + 1) / 4;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 4,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
