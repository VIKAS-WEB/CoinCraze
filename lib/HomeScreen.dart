import 'package:cached_network_image/cached_network_image.dart';
import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/Constants/API.dart';
import 'package:coincraze/LoginScreen.dart';
import 'package:coincraze/ProfilePage.dart';
import 'package:coincraze/Screens/FiatWalletScreen.dart';
import 'package:coincraze/Screens/Transactions.dart';
import 'package:coincraze/WalletList.dart';
import 'package:coincraze/chartScreen.dart';
import 'package:coincraze/deposit.dart';
import 'package:coincraze/newKyc.dart';
import 'package:coincraze/walletScreen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

// Placeholder for LoginScreen (replace with your actual login screen import)
// import 'package:coincraze/login_screen.dart';

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  _HomescreenState createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  String? email;
  double walletBalance = 110.56;
  List transactions = [
    {
      'type': 'Received',
      'amount': 107.87,
      'currency': 'ETH',
      'date': '2025-06-16',
      'usd': '2,201.37',
    },
    {
      'type': 'Sent',
      'amount': 1000.00,
      'currency': 'USDT',
      'date': '2025-06-15',
      'usd': '1,000.00',
    },
  ];

  // Key to control the drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Crypto data
  List<Map<String, dynamic>> cryptoData = [];
  bool isLoading = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchCryptoData();
    _checkHiveData();
    _checkKycStatus(); // Check KYC status on init
  }

  // Check KYC status and show dialog if incomplete
  void _checkKycStatus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isKycCompleted = AuthManager().kycCompleted ?? false;
      if (!isKycCompleted) {
        _showKycDialog();
      }
    });
  }

  // Show bottom dialog for incomplete KYC
  void _showKycDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Complete Your KYC',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Please complete your KYC to use all functionalities of the app.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => NewKYC()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: Text(
                  'Go to KYC',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _checkHiveData() async {
    if (!Hive.isBoxOpen('userBox')) {
      await Hive.openBox('userBox');
    }
    final userBox = Hive.box('userBox');
    final allKeys = userBox.keys;
    for (var key in allKeys) {
      final value = userBox.get(key);
      print('Key: $key, Value: $value');
    }
  }

  Future<void> _loadUserData() async {
    if (!Hive.isBoxOpen('userBox')) {
      await Hive.openBox('userBox');
    }
    final userBox = Hive.box('userBox');
    final storedEmail = userBox.get('email');
    setState(() {
      email = storedEmail ?? 'User';
    });
    await AuthManager().loadSavedDetails(); // Load AuthManager data
  }

  Future<void> _fetchCryptoData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&order=market_cap_desc&per_page=10&page=1',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          cryptoData = List<Map<String, dynamic>>.from(
            data.map((item) {
              final sparkline =
                  item['sparkline_in_7d'] as Map<String, dynamic>? ?? {};
              final prices =
                  sparkline['price'] as List<dynamic>? ?? List.filled(20, 0.0);
              final normalizedPrices = _generateZigzagPrices(
                prices,
                item['price_change_percentage_24h'] ?? 0.0,
              );
              final imageUrl = item['image'] as String? ?? '';
              print('Debug - Coin: ${item['name']}, Image URL: $imageUrl');
              return {
                'name': item['name'] ?? 'Unknown',
                'symbol': (item['symbol'] as String? ?? 'UNK').toUpperCase(),
                'price': item['current_price'] ?? 0.0,
                'change_24h': item['price_change_percentage_24h'] ?? 0.0,
                'prices': normalizedPrices,
                'image': imageUrl.isNotEmpty
                    ? imageUrl
                    : 'https://via.placeholder.com/20',
              };
            }),
          );
          isLoading = false;
        });
      } else {
        throw Exception('Data Not Available, status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching data: $e');
    }
  }

  List<double> _generateZigzagPrices(List<dynamic> prices, double change) {
    List<double> zigzagPrices = [];
    if (prices.isEmpty) {
      return List.filled(20, 0.0);
    }

    for (int i = 0; i < prices.length; i++) {
      double baseValue = prices[i] is num ? prices[i].toDouble() : 0.0;
      if (i % 2 == 0) {
        zigzagPrices.add(baseValue + (change > 0 ? 0.1 : -0.1));
      } else {
        zigzagPrices.add(baseValue - (change > 0 ? 0.1 : -0.1));
      }
    }
    return zigzagPrices;
  }

  Future<void> _refreshData() async {
    await _fetchCryptoData();
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        return;
      }

      final userId = AuthManager().userId;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID not found. Please log in again.'),
          ),
        );
        return;
      }

      final profilePicturePath = await AuthManager().uploadProfilePicture(
        userId,
        image.path,
      );
      if (profilePicturePath != null) {
        setState(() {
          // Trigger UI update to display new image
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture uploaded successfully'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload profile picture')),
        );
      }
    } catch (e) {
      print('Error picking/uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading profile picture: $e')),
      );
    }
  }

  void _showKycStatus() {
    final isKycCompleted = AuthManager().kycCompleted ?? false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isKycCompleted ? 'Your KYC Is Completed' : 'Please Complete Your KYC',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: isKycCompleted ? Colors.green : Colors.red,
      ),
    );
  }

  // Logout functionality
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black.withOpacity(0.9),
          title: Text(
            'Logout',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout? This will clear all saved data.',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await AuthManager().clearUserData(); // Clear all data
                  if (!Hive.isBoxOpen('userBox')) {
                    await Hive.openBox('userBox');
                  }
                  final userBox = Hive.box('userBox');
                  await userBox.clear(); // Clear userBox explicitly
                  Navigator.pop(context); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    CupertinoPageRoute(
                      builder: (context) =>
                          const LoginScreen(), // Replace with your login screen
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Successfully logged out',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
                }
              },
              child: Text(
                'Logout',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirstName = AuthManager().firstName ?? 'User';
    final email = AuthManager().email ?? 'email';
    final greeting = getGreeting();
    final profilePicture = AuthManager().profilePicture;
    final isKycCompleted = AuthManager().kycCompleted ?? false;

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: Container(
          color: Colors.black.withOpacity(0.9),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 180,
                child: DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color.fromARGB(255, 65, 65, 68),
                        const Color.fromARGB(255, 48, 39, 53),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    image: DecorationImage(
                      image: AssetImage('assets/images/bg.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.1),
                        BlendMode.dstATop,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => ProfileScreen(),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 25,
                              backgroundImage: profilePicture != null
                                  ? CachedNetworkImageProvider(
                                      '$ProductionBaseUrl/$profilePicture',
                                    )
                                  : const AssetImage(
                                          'assets/images/ProfileImage.jpg',
                                        )
                                        as ImageProvider,
                            ),
                          ),
                          const SizedBox(width: 20.0),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Hey, $FirstName!',
                                style: GoogleFonts.poppins(
                                  fontSize: 20.0,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(
                                    255,
                                    234,
                                    232,
                                    232,
                                  ),
                                ),
                              ),
                              Text(
                                email,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.0,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.white),
                title: Text(
                  'Home',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                ),
                title: Text(
                  'Wallet',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (context) => WalletScreen()),
                  );
                  // Add navigation to wallet page
                },
              ),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.white),
                title: Text(
                  'Transaction History',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Add navigation to transaction history page
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.white),
                title: Text(
                  'Settings',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  // Add navigation to settings page
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: Text(
                  'Logout',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: _handleLogout, // Trigger logout
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
              maxHeight: double.infinity,
            ),
            child: IntrinsicHeight(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 2, 5, 97),
                      Color.fromARGB(255, 249, 247, 251),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  image: DecorationImage(
                    image: AssetImage('assets/images/bg.jpg'),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.1),
                      BlendMode.dstATop,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 0.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Align(
                          alignment: Alignment.center,
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _scaffoldKey.currentState?.openDrawer();
                                },
                                child: const Icon(
                                  Icons.menu,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  if (isKycCompleted) {
                                    _showKycStatus();
                                  } else {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) => const NewKYC(),
                                      ),
                                    );
                                  }
                                },
                                child: Icon(
                                  size: 25,
                                  isKycCompleted
                                      ? Icons.verified_user
                                      : Icons.error_outline,
                                  color: isKycCompleted
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                              const SizedBox(width: 20),
                              const Icon(
                                size: 25,
                                Icons.notifications,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 20),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => ProfileScreen(),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundImage: profilePicture != null
                                      ? CachedNetworkImageProvider(
                                          '$ProductionBaseUrl/$profilePicture',
                                        )
                                      : const AssetImage(
                                              'assets/images/ProfileImage.jpg',
                                            )
                                            as ImageProvider,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Wallet Balance with Greeting
                        const Padding(
                          padding: EdgeInsets.only(right: 100.0),
                          child: Divider(
                            thickness: 1,
                            color: Color.fromARGB(255, 121, 119, 119),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting, $FirstName!',
                              style: GoogleFonts.poppins(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 234, 232, 232),
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(right: 100.0),
                          child: Divider(
                            thickness: 1,
                            color: Color.fromARGB(255, 121, 119, 119),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Value',
                              style: GoogleFonts.poppins(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: const Color.fromARGB(255, 169, 166, 166),
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Text(
                              '\$$walletBalance',
                              style: GoogleFonts.poppins(
                                fontSize: 36.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              margin: const EdgeInsets.only(right: 150),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(
                                  255,
                                  255,
                                  255,
                                  251,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.2),
                                    blurRadius: 0.0,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'envi2ze0...@Ton.network',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(
                                        const ClipboardData(
                                          text: 'envi2ze0...@Ton.network',
                                        ),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Address copied to clipboard',
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Icon(
                                      Icons.content_copy,
                                      size: 16.0,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Deposit and Withdraw Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      CupertinoPageRoute(
                                        builder: (context) =>
                                            FiatWalletScreen(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    side: const BorderSide(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(15),
                                  ),
                                  child: const Icon(
                                    Icons.currency_rupee_sharp,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'FIAT WALLET',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) =>
                                              CryptoWalletScreen(),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      side: const BorderSide(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(15),
                                    ),
                                    child: const Icon(
                                      Icons.currency_bitcoin_rounded,
                                      color: Colors.white,
                                      size: 25,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Crypto Wallet',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    side: const BorderSide(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(15),
                                  ),
                                  child: const Icon(
                                    Icons.scanner_rounded,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Scan',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    side: const BorderSide(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                    shape: const CircleBorder(),
                                    padding: const EdgeInsets.all(15),
                                  ),
                                  child: const Icon(
                                    Icons.cast_connected_sharp,
                                    color: Colors.white,
                                    size: 25,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Connect',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Live Crypto Prices Horizontal List
                        isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : SizedBox(
                                height: 110,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: cryptoData.length,
                                  itemBuilder: (context, index) {
                                    final crypto = cryptoData[index];
                                    final change = crypto['change_24h'] ?? 0.0;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        right: 10.0,
                                      ),
                                      child: Container(
                                        width: 230,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          8.0,
                                                        ),
                                                    child: Image.network(
                                                      crypto['image']
                                                              as String? ??
                                                          'https://via.placeholder.com/20',
                                                      width: 45,
                                                      height: 45,
                                                      loadingBuilder:
                                                          (
                                                            context,
                                                            child,
                                                            loadingProgress,
                                                          ) {
                                                            if (loadingProgress ==
                                                                null) {
                                                              return child;
                                                            }
                                                            return CircularProgressIndicator(
                                                              value:
                                                                  loadingProgress
                                                                          .expectedTotalBytes !=
                                                                      null
                                                                  ? loadingProgress
                                                                            .cumulativeBytesLoaded /
                                                                        loadingProgress
                                                                            .expectedTotalBytes!
                                                                  : null,
                                                            );
                                                          },
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            print(
                                                              'Image load error for ${crypto['name']}: $error',
                                                            );
                                                            return Image.asset(
                                                              'assets/images/default_coin.png',
                                                              width: 20,
                                                              height: 20,
                                                            );
                                                          },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Text(
                                                    crypto['name'] as String? ??
                                                        'Unknown',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '\$${crypto['price'].toStringAsFixed(2)}',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%',
                                                    style: GoogleFonts.poppins(
                                                      color: change >= 0
                                                          ? Colors.green
                                                          : Colors.red,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Icon(
                                                    change >= 0
                                                        ? Icons.arrow_upward
                                                        : Icons.arrow_downward,
                                                    color: change >= 0
                                                        ? Colors.green
                                                        : Colors.red,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                        const SizedBox(height: 20),
                        // Portfolio Section
                        TransactionsScreen(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CandleData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  CandleData(this.time, this.open, this.high, this.low, this.close);
}

// Placeholder LoginScreen (replace with your actual login screen)
