import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'stopwatch_screen.dart';

void main() {
  // Khởi chạy ứng dụng Flutter với widget gốc.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Cấu hình giao diện chung và đặt màn hình bấm giờ làm trang chính.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StreamBuilder Stopwatch',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.bgColor,
      ),
      home: const StopwatchScreen(),
    );
  }
}
