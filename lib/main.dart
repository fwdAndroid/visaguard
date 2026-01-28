import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:provider/provider.dart';
import 'package:visaguard/provider/language_provider.dart';
import 'package:visaguard/services/location_task_handle.dart';
import 'package:visaguard/splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // FlutterForegroundTask.init(
  //   androidNotificationOptions: AndroidNotificationOptions(
  //     channelId: 'location_channel',
  //     channelName: 'Location Tracking',
  //     channelDescription: 'Updates location every 10 minutes',
  //     channelImportance: NotificationChannelImportance.LOW,
  //     priority: NotificationPriority.LOW,
  //   ),
  //   foregroundTaskOptions: const ForegroundTaskOptions(
  //     interval: 600000, // 10 minutes
  //     autoRunOnBoot: true,
  //     allowWakeLock: true,
  //     allowWifiLock: true,
  //   ),
  // );
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'location_channel',
      channelName: 'Location Tracking',
      channelDescription: 'Updates location every 10 minutes',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
    ),
    foregroundTaskOptions: const ForegroundTaskOptions(
      interval: 600000, // 10 minutes
      autoRunOnBoot: true,
      allowWakeLock: true,
      allowWifiLock: true,
    ), iosNotificationOptions: IOSNotificationOptions(),
  );


  runApp(
    MultiProvider(
      providers: [
        //Language
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],

      child: const MyApp(),
    ),
  );
}
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: SplashScreen(),
    );
  }
}
