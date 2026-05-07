import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/app_card.dart';
import '../../services/mock_data.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../utils/responsive.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late List<MockNotificationItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(MockRepository.instance.notifications);
  }

  void _markRead(String id) {
    setState(() {
      _items = _items
          .map(
            (e) => e.id == id
                ? MockNotificationItem(id: e.id, title: e.title, message: e.message, at: e.at, read: true)
                : e,
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final pad = pagePadding(context);
    final maxW = contentMaxWidth(context);

    return Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('Notifications', style: AppTextStyles.headingLarge)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _items = _items
                                .map(
                                  (e) => MockNotificationItem(
                                    id: e.id,
                                    title: e.title,
                                    message: e.message,
                                    at: e.at,
                                    read: true,
                                  ),
                                )
                                .toList();
                          });
                        },
                        child: const Text('Mark all read'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Stay on top of requests and operational alerts.', style: AppTextStyles.body),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxW),
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final n = _items[i];
                    final ts = DateFormat('MMM d, h:mm a').format(n.at);
                    return AppCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () => _markRead(n.id),
                      border: n.read
                          ? null
                          : Border.all(color: AppColors.primary.withValues(alpha: 0.25), width: 1.2),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 6, right: 12),
                            decoration: BoxDecoration(
                              color: n.read ? AppColors.border : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(n.title, style: AppTextStyles.title)),
                                    Text(ts, style: AppTextStyles.caption),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(n.message, style: AppTextStyles.body),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
