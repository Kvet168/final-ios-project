import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_controller.dart';
import '../data/providers.dart';
import '../network/api_client.dart';
import 'widgets.dart';

/// Optimistic overrides so the heart responds instantly while the server round trip finishes.
final _wishOverride = StateProvider<Map<String, bool>>((ref) => const {});

/// Wishlist heart for destinations and stays. Signed-out taps route to sign-in and return here.
class SaveHeart extends ConsumerWidget {
  const SaveHeart({super.key, required this.kind, required this.id, this.size = 42});
  final String kind, id;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authProvider).signedIn;
    final wish = signedIn ? ref.watch(wishlistProvider).value : null;
    final server = (wish?['items'] as List?)?.any((i) => i['ref_id'] == id) ?? false;
    final saved = ref.watch(_wishOverride)[id] ?? server;
    return HeartButton(
      size: size,
      active: saved,
      onTap: () async {
        if (!signedIn) {
          context.push('/login?next=${Uri.encodeComponent(GoRouterState.of(context).uri.toString())}');
          return;
        }
        final api = ref.read(apiProvider);
        ref.read(_wishOverride.notifier).state = {...ref.read(_wishOverride), id: !saved};
        try {
          if (saved) {
            await api.delete('/wishlist/$kind/$id');
          } else {
            await api.putEmpty('/wishlist/$kind/$id');
          }
          ref.invalidate(wishlistProvider);
          await ref.read(wishlistProvider.future);
        } catch (e) {
          if (context.mounted) showError(context, e);
        } finally {
          final next = {...ref.read(_wishOverride)}..remove(id);
          ref.read(_wishOverride.notifier).state = next;
        }
      },
    );
  }
}
