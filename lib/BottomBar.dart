import 'package:coincraze/CoinSwap.dart';
import 'package:coincraze/HomeScreen.dart';
import 'package:coincraze/chartScreen.dart';
import 'package:coincraze/deposit.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // Swap tab (index 2) default active

  // Pages ke liye list
  final List<Widget> _pages = [
    Homescreen(),
    ChartScreen(),
    CoinSwapScreen(),
    LiquidityPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Selected page show karo
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.swap_horiz),
                Positioned(
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            label: 'Swap',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows),
            label: 'Liquidity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: const Color.fromARGB(255, 167, 167, 167),
        onTap: _onItemTapped,
        backgroundColor: Color.fromARGB(255, 36, 38, 40), // Light blue background
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// Pages ke classes
class StakePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Stake Page', style: TextStyle(fontSize: 24)));
  }
}

class PortfolioPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Portfolio Page', style: TextStyle(fontSize: 24)));
  }
}

class SwapPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Swap Page', style: TextStyle(fontSize: 24)));
  }
}

class LiquidityPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Liquidity Page', style: TextStyle(fontSize: 24)));
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Settings Page', style: TextStyle(fontSize: 24)));
  }
}