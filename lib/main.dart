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

  DateTime startTime = DateTime(2024, 9, 6, 10, 45); // 發車時間
  DateTime endTime = DateTime(2024, 9, 6, 12, 16);   // 抵達時間
  String notificationTitle = '114自強 臺中-中壢';

  @override
  void initState() {
    super.initState();
    requestNotificationPermission();

    // 初始化通知
    final initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
  }

  void requestNotificationPermission() async {
    var status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  // 修正計算發車時間剩餘
  String _getRemainingStartTime(DateTime startTime) {
    DateTime now = DateTime.now();
    Duration remainingDuration = startTime.difference(now);
    if (remainingDuration.isNegative) {
      return '已發車';
    } else {
      int hours = remainingDuration.inHours;
      int minutes = (remainingDuration.inMinutes % 60);
      return '${hours}時${minutes}分';
    }
  }

  double _calculateProgress(DateTime startTime, DateTime endTime) {
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

  String _getRemainingTime(DateTime endTime) {
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

  String _getEstimatedArrivalTime(DateTime endTime) {
    return DateFormat('HH:mm').format(endTime);
  }

  // 修改開始函式，接受發車時間、抵達時間及通知標題
  Future<void> startNotificationProgress(DateTime start, DateTime end, String title) async {
    setState(() {
      startTime = start;
      endTime = end;
      notificationTitle = title;
    });

    // 按下按鈕後立即顯示一次通知
    await _showNotificationWithProgress(startTime, endTime, notificationTitle);

    // 每分鐘更新進度
    _timer = Timer.periodic(Duration(minutes: 1), (Timer timer) {
      setState(() {
        _showNotificationWithProgress(startTime, endTime, notificationTitle);
      });
    });
  }

  Future<void> _showNotificationWithProgress(DateTime start, DateTime end, String title) async {
    DateTime now = DateTime.now();
    String notificationBody;
    int progress = 0;

    if (now.isBefore(start)) {
      notificationBody = '預計發車時間: ${DateFormat('HH:mm').format(start)} \n'
          '剩餘: ${_getRemainingStartTime(start)}';
    } else if (now.isAfter(end)) {
      notificationBody = '已抵達';
    } else {
      double progressValue = _calculateProgress(start, end);
      notificationBody = '預計抵達: ${_getEstimatedArrivalTime(end)} \n'
          '剩餘: ${_getRemainingTime(end)} \n';
      progress = (progressValue * 100).toInt();
    }

    final androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'progress_channel',
      'Progress Channel',
      channelDescription: 'This channel is used for progress notifications',
      importance: Importance.max,
      priority: Priority.high,
      showProgress: now.isAfter(start) && now.isBefore(end),
      maxProgress: 100,
      progress: progress,
      // 禁用音效和震動
      playSound: false,
      enableVibration: false,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'stop_action',
          '停止',
        ),
      ],
    );
    final platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      title, // 使用傳入的通知標題
      notificationBody,
      platformChannelSpecifics,
    );
  }

  Future<void> stopNotificationProgress() async {
    _timer?.cancel();
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  void _handleNotificationResponse(NotificationResponse response) {
    if (response.actionId == 'stop_action') {
      stopNotificationProgress();
    }
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
              onPressed: () {
                DateTime newStart = DateTime(2024, 9, 13, 14, 45); // 自訂發車時間
                DateTime newEnd = DateTime(2024, 9, 13, 16, 16);   // 自訂抵達時間
                startNotificationProgress(newStart, newEnd, '122自強 臺中-中壢');
              },
              child: Text('開始發車通知'),
            ),
            ElevatedButton(
              onPressed: stopNotificationProgress,
              child: Text('停止發車通知'),
            ),
          ],
        ),
      ),
    );
  }
}
