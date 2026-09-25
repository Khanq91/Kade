import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/event_style.dart';
import '../../core/formats.dart';
import '../../core/strings.dart';
import '../../core/theme/kade_theme_extension.dart';
import '../../data/user_events_provider.dart';

/// Danh sách sự kiện cá nhân (`/events`, mở từ Cài đặt → "Sự kiện của tôi").
class UserEventsScreen extends ConsumerWidget {
  const UserEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(activeUserEventsProvider);
    final colors = Theme.of(context).extension<KadeColors>()!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: Strings.back,
          icon: const BackButtonIcon(),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/settings'),
        ),
        title: const Text(Strings.myEvents),
      ),
      body: events.isEmpty
          ? const Center(child: Text(Strings.noUserEvents))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                  itemCount: events.length,
                  itemBuilder: (context, i) {
                    final e = events[i];
                    return Card(
                      color: colors.sf,
                      elevation: 1,
                      shadowColor: colors.sh,
                      margin: const EdgeInsets.only(bottom: 7),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: UserEventTag(event: e),
                        title: Text(e.title),
                        subtitle: Text(formatUserEventWhen(e)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/events/${e.id}'),
                      ),
                    );
                  },
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: Strings.addEvent,
        onPressed: () => context.push('/events/new'),
        backgroundColor: colors.ac,
        foregroundColor: colors.on,
        elevation: 1,
        shape: const StadiumBorder(),
        icon: const Icon(Icons.add),
        label: const Text(Strings.addEvent),
      ),
    );
  }
}
