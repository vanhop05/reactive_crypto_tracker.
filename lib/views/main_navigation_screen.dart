import 'package:flutter/material.dart';
import 'crypto_market_screen.dart';
import 'event_loop_lab_screen.dart';

/// Màn hình điều hướng chính với 2 phân hệ cốt lõi:
/// 1. Thị Trường (Crypto Market: luồng Stream thời gian thực, Binance WebSocket, Debounce, Throttle)
/// 2. Event Loop (Phòng thí nghiệm mô phỏng cơ chế ưu tiên hàng đợi của Dart)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    CryptoMarketScreen(),
    EventLoopLabScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 768;

    if (isWideScreen) {
      // Bố cục màn hình rộng cho Desktop / Tablet / Web với NavigationRail gọn gàng
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              backgroundColor: Theme.of(context).cardTheme.color,
              selectedIconTheme: const IconThemeData(color: Color(0xFF10B981)),
              selectedLabelTextStyle: const TextStyle(
                color: Color(0xFF10B981),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.show_chart),
                  selectedIcon: Icon(Icons.show_chart, color: Color(0xFF10B981)),
                  label: Text('Thị Trường'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.sync),
                  selectedIcon: Icon(Icons.sync, color: Color(0xFF10B981)),
                  label: Text('Event Loop'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      );
    }

    // Bố cục điện thoại di động (BottomNavigationBar)
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            activeIcon: Icon(Icons.show_chart, color: Color(0xFF10B981)),
            label: 'Thị Trường',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sync),
            activeIcon: Icon(Icons.sync, color: Color(0xFF10B981)),
            label: 'Event Loop',
          ),
        ],
      ),
    );
  }
}
