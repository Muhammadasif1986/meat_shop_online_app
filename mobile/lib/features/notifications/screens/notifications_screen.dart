import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/response_utils.dart';
import '../../../core/constants/api_constants.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final _api = ApiClient();

  Future<List<dynamic>> _fetchNotifications() async {
    try {
      final response = await _api.get(ApiConstants.notifications);
      return extractList(response.data);
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchNotifications(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final notifications = snapshot.data!;
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 72, color: AppColors.lightGray),
                  const SizedBox(height: 16),
                  const Text('No notifications yet', style: TextStyle(color: AppColors.gray)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: notifications.length,
              itemBuilder: (_, i) {
                final n = notifications[i] as Map<String, dynamic>;
                final title = n['title'] as String? ?? '';
                final body = n['body'] as String? ?? '';
                final type = n['type'] as String? ?? '';
                final createdAt = n['created_at'] as String? ?? '';

                String dateStr = '';
                try { dateStr = DateFormat('dd MMM').format(DateTime.parse(createdAt)); } catch (_) {}

                IconData icon;
                Color color;
                switch (type) {
                  case 'order': icon = Icons.receipt; color = AppColors.primary; break;
                  case 'promotion': icon = Icons.percent; color = AppColors.warning; break;
                  case 'delivery': icon = Icons.delivery_dining; color = AppColors.success; break;
                  default: icon = Icons.notifications; color = AppColors.gray;
                }

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
                    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
                    trailing: Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
