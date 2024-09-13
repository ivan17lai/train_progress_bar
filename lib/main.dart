import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NotificationProgressDemo(),
    );
  }
}

class NotificationProgressDemo extends StatefulWidget {
  @override
  _NotificationProgressDemoState createState() => _NotificationProgressDemoState();
}

class _NotificationProgressDemoState extends State<NotificationProgressDemo> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  Timer? _timer;

  // 設定發車時間和抵達時間
  DateTime startTime = DateTime(2024, 9, 6, 10, 45); // 發車時間
  DateTime endTime = DateTime(2024, 9, 6, 12, 16); // 抵達時間

  @override
  void initState() {
    super.initState();
    // 請求通知權限
    requestNotificationPermission();

    // 初始化通知
    final initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    // 開始進度更新
    _startProgress();
  }

  void requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  // 計算進度百分比：根據當前時間、發車時間和抵達時間
  double _calculateProgress() {
    DateTime now = DateTime.now();
    if (now.isBefore(startTime)) {
      return 0.0;
    } else if (now.isAfter(endTime)) {
      return 1.0;
    } else {
      final totalDuration = endTime.difference(startTime).inMilliseconds;
      final elapsedDuration = now.difference(startTime).inMilliseconds;
      return elapsedDuration / totalDuration;
    }
  }

  // 計算剩餘時間
  String _getRemainingTime() {
    DateTime now = DateTime.now();
    Duration remainingDuration = endTime.difference(now);
    if (remainingDuration.isNegative) {
      return '已抵達';
    } else {
      int hours = remainingDuration.inHours;
      int minutes = (remainingDuration.inMinutes % 60);
      return '${hours}時${minutes}分';
    }
  }

  // 計算預計抵達時間
  String _getEstimatedArrivalTime() {
    return DateFormat('HH:mm').format(endTime);
  }

  void _startProgress() {
    _timer = Timer.periodic(Duration(minutes: 1), (Timer timer) {
      setState(() {
        _showNotificationWithProgress();
      });
    });
  }

  Future<void> _showNotificationWithProgress() async {
    DateTime now = DateTime.now();
    String notificationBody;
    int progress = 0;

    if (now.isBefore(startTime)) {
      notificationBody = '預計發車時間: ${DateFormat('HH:mm').format(startTime)} \n'
          '剩餘: ${_getRemainingTime()}';
    } else if (now.isAfter(endTime)) {
      notificationBody = '已抵達';
    } else {
      double progressValue = _calculateProgress();
      notificationBody = '預計抵達: ${_getEstimatedArrivalTime()} \n'
          '剩餘: ${_getRemainingTime()} \n';
      progress = (progressValue * 100).toInt();
    }

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'progress_channel',
      'Progress Channel',
      channelDescription: 'This channel is used for progress notifications',
      importance: Importance.max,
      priority: Priority.high,
      showProgress: now.isAfter(startTime) && now.isBefore(endTime),
      maxProgress: 100,
      progress: progress,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'stop_action',
          '停止',
        ),
      ],
    );
    final platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    // 顯示通知
    await flutterLocalNotificationsPlugin.show(
      0,
      '114自強 臺中-中壢',
      notificationBody,
      platformChannelSpecifics,
    );
  }

  // 處理通知按鈕點擊
  void _handleNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'stop_action') {
      _stopProgress();
    }
  }

  // 停止進度更新
  void _stopProgress() {
    _timer?.cancel();
    flutterLocalNotificationsPlugin.cancel(0); // 移除通知
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('進度條通知')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('發車時間: ${DateFormat('yyyy-MM-dd HH:mm').format(startTime)}'),
            Text('抵達時間: ${DateFormat('yyyy-MM-dd HH:mm').format(endTime)}'),
            ElevatedButton(
              onPressed: _showNotificationWithProgress,
              child: Text('顯示發車通知'),
            ),
          ],
        ),
      ),
    );
  }
}
