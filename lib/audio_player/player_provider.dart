import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'player_notifier.dart';
import 'edit_player_state.dart';

final playerProvider = StateNotifierProvider<PlayerNotifier, EditPlayerState>((ref) {
  return PlayerNotifier();
});