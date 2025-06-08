import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/client_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../services/whatsapp_service.dart';

class NotificationController extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  bool _isLoading = false;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications(String userId, {bool isAdmin = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (isAdmin) {
        _notifications = await DatabaseService.getAllNotifications();
      } else {
        _notifications = await DatabaseService.getNotificationsByUser(userId);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await DatabaseService.markNotificationAsRead(notificationId);
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationModel(
          id: _notifications[index].id,
          type: _notifications[index].type,
          title: _notifications[index].title,
          message: _notifications[index].message,
          targetUserId: _notifications[index].targetUserId,
          clientId: _notifications[index].clientId,
          isRead: true,
          priority: _notifications[index].priority,
          createdAt: _notifications[index].createdAt,
          scheduledFor: _notifications[index].scheduledFor,
        );
        notifyListeners();
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> sendWhatsAppToClient(ClientModel client, String message) async {
    try {
      await WhatsAppService.sendClientMessage(
        phoneNumber: client.clientPhone,
        country: client.phoneCountry,
        message: message,
        clientName: client.clientName,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> callClient(ClientModel client) async {
    try {
      await WhatsAppService.callClient(
        phoneNumber: client.clientPhone,
        country: client.phoneCountry,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> sendWhatsAppToUser(UserModel user, String message) async {
    try {
      await WhatsAppService.sendUserMessage(
        phoneNumber: user.phone,
        message: message,
        userName: user.name,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> scheduleClientNotifications() async {
    try {
      final clients = await DatabaseService.getAllClients();
      final settings = await DatabaseService.getAdminSettings();
      
      for (final client in clients) {
        if (!client.hasExited) {
          await _scheduleNotificationsForClient(client, settings);
        }
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> _scheduleNotificationsForClient(ClientModel client, Map<String, dynamic> settings) async {
    final clientSettings = settings['clientNotificationSettings'];
    final tiers = [
      clientSettings['firstTier'],
      clientSettings['secondTier'],
      clientSettings['thirdTier'],
    ];

    for (final tier in tiers) {
      final days = tier['days'] as int;
      final frequency = tier['frequency'] as int;
      final message = tier['message'] as String;

      if (client.daysRemaining <= days && client.daysRemaining > 0) {
        for (int i = 0; i < frequency; i++) {
          final scheduledTime = DateTime.now().add(Duration(hours: i * (24 ~/ frequency)));
          await NotificationService.scheduleClientNotification(
            clientId: client.id,
            clientName: client.clientName,
            message: message,
            scheduledTime: scheduledTime,
          );
        }
      }
    }
  }
}
