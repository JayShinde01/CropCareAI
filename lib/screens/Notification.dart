import 'package:flutter/material.dart';

// Convert to StatefulWidget to manage the list state (dismissing/reading)
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  // Use a unique dark color palette for better contrast
  final Color darkBackground = const Color(0xFF121212);
  final Color cardBackground = const Color(0xFF1E1E1E);
  final Color primaryTextColor = Colors.white;
  final Color secondaryTextColor = Colors.grey.shade400;

  // The notifications list now includes an 'isRead' status for better interaction
  List<Map<String, dynamic>> notifications = [
    {"title": "Payment received successfully!", "type": "success", "time": "2 min ago", "isRead": false},
    {"title": "New system update available", "type": "update", "time": "10 min ago", "isRead": false},
    {"title": "Your order is being processed", "type": "order", "time": "20 min ago", "isRead": false},
    {"title": "🔥 50% off discount is live!", "type": "offer", "time": "1 hr ago", "isRead": true},
    {"title": "New message from support team", "type": "message", "time": "2 hrs ago", "isRead": false},
    {"title": "Field inspection report ready", "type": "report", "time": "1 day ago", "isRead": true},
    {"title": "Low stock warning: Fertilizer X", "type": "warning", "time": "2 days ago", "isRead": true},
  ];

  IconData getIcon(String type) {
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

  Color getColor(String type) {
    switch (type) {
      case "success":
        return Colors.green.shade500;
      case "update":
        return Colors.blue.shade500;
      case "order":
        return Colors.orange.shade500;
      case "offer":
        return Colors.purple.shade500;
      case "message":
        return Colors.teal.shade500;
      case "report":
        return Colors.yellow.shade700;
      case "warning":
        return Colors.red.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  /// Removes the notification at the given index from the list.
  void _removeNotification(int index) {
    setState(() {
      notifications.removeAt(index);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Notification dismissed."),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  /// Marks all unread notifications as read.
  void _markAllRead() {
    bool foundUnread = false;
    setState(() {
      for (var n in notifications) {
        if (n["isRead"] == false) {
          n["isRead"] = true;
          foundUnread = true;
        }
      }
    });

    if (foundUnread) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All notifications marked as read.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Count unread notifications for the header badge
    final unreadCount = notifications.where((n) => n["isRead"] == false).length;

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: darkBackground,
        title: Text(
          "Notifications (${unreadCount > 0 ? unreadCount : '0'})",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 24,
            color: primaryTextColor,
          ),
        ),
        centerTitle: false,
        actions: [
          if (unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.mark_email_read_rounded, color: Colors.blueAccent),
              tooltip: "Mark all as read",
              onPressed: _markAllRead,
            ),
          const SizedBox(width: 8),
        ],
      ),

      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_rounded, size: 60, color: secondaryTextColor),
                  const SizedBox(height: 16),
                  Text("You're all caught up!", style: TextStyle(color: secondaryTextColor, fontSize: 18)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final n = notifications[index];
                final typeColor = getColor(n["type"]);
                final isRead = n["isRead"];

                return Dismissible(
                  // Use the index as part of the key since we manage the list dynamically
                  key: ValueKey(n["title"] + index.toString()),
                  background: Container(
                    padding: const EdgeInsets.only(right: 20),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _removeNotification(index);
                  },
                  child: GestureDetector(
                    onTap: () {
                      // Mark as read when tapped
                      if (!isRead) {
                        setState(() {
                          n["isRead"] = true;
                        });
                      }
                      // Implement navigation/action based on notification type here
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isRead ? Colors.transparent : typeColor.withOpacity(0.5),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ICON / Category
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              getIcon(n["type"]),
                              color: typeColor,
                              size: 24,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // TEXT Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n["title"],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isRead ? FontWeight.w400 : FontWeight.w600,
                                    color: isRead ? secondaryTextColor : primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n["time"],
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // UNREAD BADGE / READ Indicator
                          if (!isRead)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: typeColor,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            Icon(Icons.done, size: 16, color: Colors.grey.shade700),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}