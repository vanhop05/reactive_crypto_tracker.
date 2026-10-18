import 'package:flutter/material.dart';
import 'crypto_market_screen.dart';
import 'event_loop_lab_screen.dart';
import 'stream_operators_lab_screen.dart';
import 'architecture_guide_screen.dart';

/// Màn hình điều hướng chính hỗ trợ giao diện đáp ứng đa nền tảng (Responsive Layout):
/// - BottomNavigationBar cho Di động (iOS & Android)
/// - NavigationRail cho Máy tính (Desktop / Tablet / Trình duyệt Web rộng)
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
    StreamOperatorsLabScreen(),
    ArchitectureGuideScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 768;

    if (isWideScreen) {
      // Bố cục màn hình rộng cho Desktop / Tablet / Web với NavigationRail cạnh trái
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
                NavigationRailDestination(
                  icon: Icon(Icons.filter_alt),
                  selectedIcon: Icon(Icons.filter_alt, color: Color(0xFF10B981)),
                  label: Text('Toán Tử'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.menu_book),
                  selectedIcon: Icon(Icons.menu_book, color: Color(0xFF10B981)),
                  label: Text('Kiến Trúc'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1, color: Colors.white10),
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      );
    }

    // Mobile Phone Layout (iOS & Android) with BottomNavigationBar
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
          BottomNavigationBarItem(
            icon: Icon(Icons.filter_alt),
            activeIcon: Icon(Icons.filter_alt, color: Color(0xFF10B981)),
            label: 'Toán Tử',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            activeIcon: Icon(Icons.menu_book, color: Color(0xFF10B981)),
            label: 'Kiến Trúc',
          ),
        ],
      ),
    );
  }
}
