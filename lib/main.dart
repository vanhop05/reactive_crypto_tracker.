import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'views/main_navigation_screen.dart';

void main() {
  // Đảm bảo các kết nối của Flutter Engine được khởi tạo đầy đủ trước khi chạy app
  WidgetsFlutterBinding.ensureInitialized();

  // Cấu hình thanh trạng thái hệ thống theo phong cách giao diện tài chính tối
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF151B26),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Minh họa khởi tạo Microtask trong Event Loop khi ứng dụng vừa bật lên
  scheduleMicrotask(() {
    debugPrint('[EVENT_LOOP] Microtask được thực thi trong quá trình khởi động ứng dụng.');
  });

  runApp(const CryptoPulseApp());
}

/// Widget gốc (Root Widget) của toàn bộ ứng dụng CryptoPulse Reactive.
class CryptoPulseApp extends StatelessWidget {
  const CryptoPulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CryptoPulse Reactive',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Mặc định sử dụng giao diện tối hiện đại
      home: const MainNavigationScreen(),
    );
  }
}
