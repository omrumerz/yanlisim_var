import 'dart:html' as html;

class NotificationService {
  static void requestPermission() {
    html.Notification.requestPermission();
  }

  static void showNotification(String title, String body) {
    if (html.Notification.permission == 'granted') {
      html.Notification(title, body: body);
    }
  }
}