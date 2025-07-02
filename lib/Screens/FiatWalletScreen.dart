import 'package:carousel_slider/carousel_slider.dart';
import 'package:coincraze/CreateWallet.dart';
import 'package:coincraze/Models/Wallet.dart';
import 'package:coincraze/Screens/AddFundsScreen.dart';
import 'package:coincraze/Screens/BuyCryptoScreen.dart';
import 'package:coincraze/Screens/TransactionScreen.dart';
import 'package:coincraze/Services/api_service.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class FiatWalletScreen extends StatefulWidget {
  @override
  _FiatWalletScreenState createState() => _FiatWalletScreenState();
}

class _FiatWalletScreenState extends State<FiatWalletScreen> {
  final Map<String, String> _currencyToFlag = {
    'USD': 'assets/flags/USD.jpg',
    'INR': 'assets/flags/IndianCurrency.jpg',
    'EUR': 'assets/flags/Euro.jpg',
    'GBP': 'assets/flags/GBP.png',
    'JPY': 'assets/flags/Japan.png',
    'CAD': 'assets/flags/CAD.jpg',
    'AUD': 'assets/flags/australian-dollar.jpeg',
  };

  late Future<List<Wallet>> _walletsFuture;
  late Future<List<dynamic>> _newsFuture;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _walletsFuture = ApiService().getBalance();
    _newsFuture = _fetchNews();
  }

  Future<List<dynamic>> _fetchNews() async {
    try {
      final wallets = await _walletsFuture;
      final currencies = wallets.map((w) => w.currency.toUpperCase()).toList();
      return await ApiService().fetchCurrencyNews(currencies);
    } catch (e) {
      return [];
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _walletsFuture = ApiService().getBalance();
      _newsFuture = _fetchNews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Fiat Wallet',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 39, 39, 51),
              Color.fromARGB(255, 238, 238, 238),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: Color.fromARGB(255, 46, 46, 47),
            backgroundColor: Colors.white,
            child: FutureBuilder<List<Wallet>>(
              future: _walletsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildShimmerLoading();
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.redAccent,
                      ),
                    ),
                  );
                }
                final wallets = snapshot.data ?? [];
                final availableCurrencies = wallets.map((w) => w.currency.toUpperCase()).toList();
                if (wallets.isEmpty) {
                  return SizedBox.expand(
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 200,
                              height: 200,
                              child: Lottie.asset(
                                'assets/lottie/Empty.json',
                                fit: BoxFit.contain,
                                repeat: true,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No Wallets Available',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Start by creating a new wallet to manage your funds.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreateWalletScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 46, 46, 47),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 5,
                              ),
                              child: Text(
                                'Create Wallet',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 130),
                      CarouselSlider.builder(
                        itemCount: wallets.length,
                        itemBuilder: (context, index, realIndex) {
                          final wallet = wallets[index];
                          return _buildWalletCard(context, wallet);
                        },
                        options: CarouselOptions(
                          height: 200,
                          enlargeCenterPage: true,
                          autoPlay: wallets.length > 1,
                          autoPlayInterval: Duration(seconds: 5),
                          aspectRatio: 16 / 9,
                          enableInfiniteScroll: wallets.length > 1,
                          viewportFraction: 0.80,
                          onPageChanged: (index, reason) {},
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CreateWalletScreen(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color.fromARGB(255, 46, 46, 47),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                ),
                                child: Text(
                                  'Add New Wallet',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: () async {
                                  final prefs = await SharedPreferences.getInstance();
                                  final userId = prefs.getString('userId') ?? '';
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BuyCryptoScreen(
                                  
                                        availableCurrencies: availableCurrencies,
                                      ),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color.fromARGB(255, 46, 46, 47),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                ),
                                child: Text(
                                  'Buy Crypto',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 40), // Reduced from 50 to minimize spacing
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Text(
                          'Trending Currency News',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      FutureBuilder<List<dynamic>>(
                        future: _newsFuture,
                        builder: (context, newsSnapshot) {
                          if (newsSnapshot.connectionState == ConnectionState.waiting) {
                            return _buildNewsShimmer();
                          }
                          if (newsSnapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading news: ${newsSnapshot.error}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.redAccent,
                                ),
                              ),
                            );
                          }
                          final newsArticles = newsSnapshot.data ?? [];
                          if (newsArticles.isEmpty) {
                            return Center(
                              child: Text(
                                'No news available',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            );
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero, // Ensure no default padding
                            itemCount: newsArticles.length,
                            itemBuilder: (context, index) {
                              final article = newsArticles[index];
                              return _buildNewsCard(context, article, index);
                            },
                          );
                        },
                      ),
                      // Removed SizedBox(height: 20) to avoid extra spacing
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 130),
          CarouselSlider.builder(
            itemCount: 3,
            itemBuilder: (context, index, realIndex) {
              return Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.grey[400],
                            ),
                            SizedBox(width: 10),
                            Container(
                              width: 100,
                              height: 20,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Container(
                          width: 150,
                          height: 18,
                          color: Colors.grey[400],
                        ),
                        Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              color: Colors.grey[400],
                            ),
                            SizedBox(width: 10),
                            Container(
                              width: 30,
                              height: 30,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: 200,
              enlargeCenterPage: true,
              autoPlay: false,
              aspectRatio: 16 / 9,
              enableInfiniteScroll: false,
              viewportFraction: 0.80,
            ),
          ),
          SizedBox(height: 20),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 150,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      width: 150,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20), // Reduced from 50
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                width: 200,
                height: 20,
                color: Colors.white,
              ),
            ),
          ),
          _buildNewsShimmer(),
        ],
      ),
    );
  }

  Widget _buildNewsShimmer() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: EdgeInsets.only(
              left: 15,
              right: 15,
              top: index == 0 ? 8 : 8, // Match _buildNewsCard margin
              bottom: 8,
            ),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[400],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 6),
                      Container(
                        width: 100,
                        height: 12,
                        color: Colors.grey[400],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWalletCard(BuildContext context, Wallet wallet) {
    final flagImage = _currencyToFlag[wallet.currency.toUpperCase()];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 21, 21, 23),
            blurRadius: 2,
            offset: Offset(5, 0),
          ),
        ],
        image: flagImage != null
            ? DecorationImage(
                image: AssetImage(flagImage),
                fit: BoxFit.cover,
                opacity: 0.4,
              )
            : null,
        gradient: flagImage == null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 60, 60, 70),
                  Color.fromARGB(255, 100, 100, 120),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
                ],
              ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: wallet.currency.toUpperCase() == 'EUR'
                      ? ClipOval(
                          child: Image.asset(
                            'assets/flags/EuroFlag.png',
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover,
                          ),
                        )
                      : CountryFlag.fromCountryCode(
                          _getCountryCode(wallet.currency.toUpperCase()),
                          height: 24,
                          width: 24,
                        ),
                ),
                SizedBox(width: 10),
                Text(
                  '${wallet.currency.toUpperCase()} Wallet',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white70,
                  size: 30,
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Balance: ${wallet.balance.toStringAsFixed(2)} ${wallet.currency.toUpperCase()}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.white, size: 30),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getString('userId') ?? '';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFundsScreen(
                          userId: userId,
                          currency: wallet.currency,
                        ),
                      ),
                    );
                  },
                  tooltip: 'Add Funds',
                ),
                IconButton(
                  icon: Icon(Icons.history, color: Colors.white, size: 30),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final userId = prefs.getString('userId') ?? '';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransactionHistoryScreen(userId: userId),
                      ),
                    );
                  },
                  tooltip: 'Transaction History',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, dynamic article, int index) {
    return GestureDetector(
      onTap: () async {
        final url = article['url']?.toString();
        if (url != null && url.isNotEmpty) {
          try {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cannot launch URL: $url')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error launching URL: $e')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invalid URL')),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.only(
          left: 15,
          right: 15,
          top: index == 0 ? 4 : 8, // Reduced top margin for first item
          bottom: 8,
        ),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            article['urlToImage'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      article['urlToImage'],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: 100,
                    height: 100,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[600],
                    ),
                  ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article['title'] ?? 'No title',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    article['source']['name'] ?? 'Unknown source',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCountryCode(String currency) {
    final Map<String, String> currencyToCountry = {
      'USD': 'US',
      'INR': 'IN',
      'EUR': 'EU',
      'GBP': 'GB',
      'JPY': 'JP',
      'CAD': 'CA',
      'AUD': 'AU',
    };
    return currencyToCountry[currency] ?? 'UN';
  }
}
