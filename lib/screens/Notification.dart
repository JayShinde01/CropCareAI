// lib/screens/notification.dart
import 'package:demo/main.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Sample notifications (replace with real source if needed)
  List<Map<String, dynamic>> notifications = [
    {"id": "n1", "title": "payment_received_success", "type": "success", "time": "2 min ago", "isRead": false},
    {"id": "n2", "title": "new_system_update_available", "type": "update", "time": "10 min ago", "isRead": false},
    {"id": "n3", "title": "order_processed", "type": "order", "time": "20 min ago", "isRead": false},
    {"id": "n4", "title": "offer_50_off", "type": "offer", "time": "1 hr ago", "isRead": true},
    {"id": "n5", "title": "new_message_support", "type": "message", "time": "2 hrs ago", "isRead": false},
    {"id": "n6", "title": "field_inspection_ready", "type": "report", "time": "1 day ago", "isRead": true},
    {"id": "n7", "title": "low_stock_warning", "type": "warning", "time": "2 days ago", "isRead": true},
  ];

  // UI state
  bool showOnlyUnread = false;

  IconData _iconFor(String type) {
    switch (type) {
      case "success":
        return Icons.check_circle_rounded;
      case "update":
        return Icons.system_update_alt_rounded;
      case "order":
        return Icons.local_shipping_rounded;
      case "offer":
        return Icons.local_offer_rounded;
      case "message":
        return Icons.chat_bubble_rounded;
      case "report":
        return Icons.assignment_rounded;
      case "warning":
        return Icons.warning_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type, ThemeData theme) {
    switch (type) {
      case "success":
        return Colors.green.shade600;
      case "update":
        return Colors.blue.shade600;
      case "order":
        return Colors.orange.shade600;
      case "offer":
        return Colors.purple.shade600;
      case "message":
        return Colors.teal.shade600;
      case "report":
        return Colors.amber.shade700;
      case "warning":
        return Colors.red.shade600;
      default:
        return theme.iconTheme.color ?? Colors.grey.shade600;
    }
  }

  void _markAllRead() {
    final hasUnread = notifications.any((n) => n['isRead'] == false);
    if (!hasUnread) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('all_already_read'.tr())));
      return;
    }
    setState(() {
      for (var n in notifications) {
        n['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('all_marked_read'.tr())));
  }

  void _removeAtIndex(int index, Map<String, dynamic> removed) {
    setState(() {
      notifications.removeAt(index);
    });
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('notification_dismissed'.tr()),
        action: SnackBarAction(
          label: 'undo'.tr(),
          textColor: theme.colorScheme.primary,
          onPressed: () {
            setState(() {
              // simple: add back at top
              notifications.insert(0, removed);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scaffoldBg = theme.scaffoldBackgroundColor;
    final cardBg = theme.cardColor;
    final iconColor = theme.iconTheme.color ?? Colors.grey.shade700;
    final filtered = showOnlyUnread ? notifications.where((n) => n['isRead'] == false).toList() : notifications;
    final unreadCount = notifications.where((n) => n['isRead'] == false).length;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: AgrioDemoApp.primaryGreen,
        elevation: theme.appBarTheme.elevation ?? 2,
        title: Text('notifications_title'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            onPressed: _markAllRead,
            tooltip: 'mark_all_read'.tr(),
            icon: Icon(Icons.mark_email_read_rounded, color: iconColor),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'filter') setState(() => showOnlyUnread = !showOnlyUnread);
              if (v == 'clear') {
                setState(() => notifications.clear());
              }
            },
            icon: Icon(Icons.more_vert, color: iconColor),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'filter',
                child: Row(
                  children: [
                    Checkbox(value: showOnlyUnread, onChanged: (_) {}, activeColor: colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(child: Text('show_only_unread'.tr())),
                  ],
                ),
              ),
              PopupMenuItem(value: 'clear', child: Text('clear_all'.tr())),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              unreadCount > 0
                  ? tr('unread_count', namedArgs: {'count': unreadCount.toString()})
                  : 'all_caught_up'.tr(),
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onPrimary.withOpacity(0.9)),
            ),
          ),
        ),
      ),
      body: filtered.isEmpty
          ? _buildEmptyState(context, theme, colorScheme)
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final n = filtered[i];
                final titleKey = n['title'] as String;
                final time = n['time'] as String;
                final type = n['type'] as String;
                final isRead = n['isRead'] as bool;
                final color = _colorFor(type, theme);
                final icon = _iconFor(type);

                // Need original index in master list to remove correctly
                final originalIndex = notifications.indexWhere((el) => el['id'] == n['id']);

                return Dismissible(
                  key: ValueKey(n['id']),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeAtIndex(originalIndex, n),
                  child: Material(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        // mark read and optionally navigate
                        if (!isRead) {
                          setState(() {
                            n['isRead'] = true;
                          });
                        }
                        // TODO: navigate to relevant screen based on n['type']
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                              child: Icon(icon, color: color, size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    // Use tr for the title keys (titleKey may be plain text too)
                                    (titleKey.startsWith(RegExp(r'[a-z_]+$')))
                                        ? tr(titleKey)
                                        : titleKey,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 15,
                                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                      color: isRead ? theme.disabledColor : theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(time, style: theme.textTheme.bodySmall?.copyWith(color: theme.disabledColor)),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: isRead
                                  ? Icon(Icons.done, size: 18, color: theme.disabledColor)
                                  : Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: notifications.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _markAllRead,
              label: Text('mark_all_read'.tr(), style: const TextStyle(color: Colors.black)),
              icon: Icon(Icons.mark_email_read_rounded, color: colorScheme.onSecondary),
              backgroundColor: colorScheme.secondary,
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off, size: 68, color: theme.disabledColor),
            const SizedBox(height: 16),
            Text('no_notifications'.tr(), style: theme.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'notifications_empty_desc'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.disabledColor),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () {
                // placeholder: go to tutorials or help
                Navigator.pop(context);
              },
              icon: Icon(Icons.home_outlined, color: colorScheme.onPrimary),
              label: Text('go_home'.tr(), style: theme.textTheme.labelLarge?.copyWith(color: colorScheme.onPrimary)),
              style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
