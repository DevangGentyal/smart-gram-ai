import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConversationSummary {
  ConversationSummary({
    required this.id,
    required this.titleEn,
    required this.titleMr,
    required this.lastInteraction,
  });

  final String id;
  final String titleEn;
  final String titleMr;
  final DateTime lastInteraction;
}

class HomeState {
  const HomeState({
    required this.userName,
    required this.recentConversations,
  });

  final String userName;
  final List<ConversationSummary> recentConversations;

  HomeState copyWith({
    String? userName,
    List<ConversationSummary>? recentConversations,
  }) {
    return HomeState(
      userName: userName ?? this.userName,
      recentConversations: recentConversations ?? this.recentConversations,
    );
  }
}

class HomeController extends StateNotifier<HomeState> {
  HomeController()
      : super(
          HomeState(
            userName: 'Devang',
            recentConversations: [
              ConversationSummary(
                id: '1',
                titleEn: 'Agriculture advice',
                titleMr: 'कृषी सल्ला',
                lastInteraction: DateTime.now().subtract(const Duration(hours: 1)),
              ),
              ConversationSummary(
                id: '2',
                titleEn: 'Government schemes',
                titleMr: 'सरकारी योजना माहिती',
                lastInteraction: DateTime.now().subtract(const Duration(hours: 4)),
              ),
              ConversationSummary(
                id: '3',
                titleEn: 'Weather update',
                titleMr: 'हवामान अपडेट',
                lastInteraction: DateTime.now().subtract(const Duration(days: 1)),
              ),
            ],
          ),
        );

  void addConversation(ConversationSummary summary) {
    final updated = [
      summary,
      ...state.recentConversations.where((c) => c.id != summary.id),
    ];
    state = state.copyWith(recentConversations: updated);
  }
}

final homeControllerProvider =
    StateNotifierProvider<HomeController, HomeState>((ref) {
  return HomeController();
});


