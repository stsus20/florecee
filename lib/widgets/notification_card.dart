import 'package:flutter/material.dart';

import '../services/app_store.dart';
import '../services/notification_service.dart';
import 'planta_card.dart';

class NotificationCard extends StatefulWidget {
  final AppStore store;
  const NotificationCard({super.key, required this.store});
  @override
  State<NotificationCard> createState() => _NotificationCardState();
}

class _NotificationCardState extends State<NotificationCard> {
  bool busy = false;
  Future<void> act(Future<void> Function() action, {String? success}) async {
    setState(() => busy = true);
    try {
      await action();
      await widget.store.reload();
      if (mounted && success != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo completar la prueba. ${widget.store.notifications.statusText}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.store.notifications;
    final enabled = service.access == NotificationAccess.enabled;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [salvia, Color(0xFFF3F0E2)]),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDDE4D5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                enabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_rounded,
                color: verde,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Un recordatorio para florecer',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(service.statusText),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (enabled)
                FilledButton.tonalIcon(
                  onPressed: busy
                      ? null
                      : () => act(
                          service.testNotification,
                          success: 'Prueba enviada al sistema. Revisa el panel de notificaciones.',
                        ),
                  icon: const Icon(Icons.send_outlined, size: 18),
                  label: const Text('Probar notificación'),
                )
              else
                FilledButton.tonalIcon(
                  onPressed: busy
                      ? null
                      : () => act(() async {
                          await service.request();
                        }),
                  icon: const Icon(Icons.notifications_outlined, size: 18),
                  label: const Text('Comprobar permiso'),
                ),
              TextButton(
                onPressed: busy ? null : () => act(service.openSettings),
                child: const Text('Ajustes'),
              ),
            ],
          ),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),
        ],
      ),
    );
  }
}
