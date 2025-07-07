import 'package:coincraze/utils/CoinImageProvider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/services.dart';
import 'package:coincraze/AuthManager.dart'; // Your AuthManager
import 'package:coincraze/BottomBar.dart'; // Your MainScreen
import 'package:coincraze/Constants/API.dart'; // Your API constants
import 'package:coincraze/Models/CryptoWallet.dart'; // Your CryptoWallet model
import 'package:coincraze/Services/api_service.dart'; // Your ApiService
import 'dart:convert';

class CryptoWalletScreen extends StatefulWidget {
  const CryptoWalletScreen({super.key});

  @override
  State<CryptoWalletScreen> createState() => _CryptoWalletScreenState();
}

class _CryptoWalletScreenState extends State<CryptoWalletScreen> {
  List<CryptoWallet> wallets = [];
  bool isLoading = true;
  String? errorMessage;
  final ApiService apiService = ApiService();

  // Map to store coin metadata (name -> image URL)
  Map<String, String> coinImages = {
    'Bitcoin': 'https://assets.coingecko.com/coins/images/1/large/bitcoin.png',
    'Ethereum':
        'https://assets.coingecko.com/coins/images/279/large/ethereum.png',
    'Tether': 'https://assets.coingecko.com/coins/images/325/large/Tether.png',
    'Solana': 'https://assets.coingecko.com/coins/images/4128/large/solana.png',
    'Dogecoin':
        'https://assets.coingecko.com/coins/images/5/large/dogecoin.png',
    'Litecoin':
        'image": "https://assets.coingecko.com/coins/images/2/large/litecoin.png?…',
  };

  // Map to handle testnet coins (maps API coinName to mainnet coin for display and image fetching)
  Map<String, String> coinNameToMainnet = {
    'ETC_TEST': 'Ethereum Classic',
    'LTC_TEST': 'Litecoin',
    'BTC_TEST': 'Bitcoin',
    'DOGE_TEST': 'Dogecoin',
    'EOS_TEST': 'EOS',
    'ADA_TEST': 'Cardano',
    'DASH_TEST': 'Dash',
    'CELESTIA_TEST': 'Celestia',
    'HBAR_TEST': 'Hedera Hashgraph',
    'TRX_TEST': 'TRON',
  };

  // Reverse map for creating wallets (mainnet name to testnet coinName)
  Map<String, String> mainnetToCoinName = {
    'Ethereum': 'ETC',
    'Litecoin': 'LTC_TEST',
    'Bitcoin': 'BTC_TEST',
    'Dogecoin': 'DOGE_TEST',
    'EOS': 'EOS_TEST',
    'Cardano': 'ADA_TEST',
    'Dash': 'DASH_TEST',
    'Celestia': 'CELESTIA_TEST',
    'Hedera Hashgraph': 'HBAR_TEST',
    'TRON': 'TRX_TEST',
  };

  List<Map<String, dynamic>> _filteredAssets = [];

  @override
  void initState() {
    super.initState();
    _fetchWallets();
    _fetchCoinMetadata();
    _prepareAndShowDialog();
  }

  Future<void> _prepareAndShowDialog() async {
    try {
      print('Fetching supported assets...');
      final assets = await apiService.getSupportedAssets(); // API call
      print('Total assets received: ${assets.length}');

      final filtered = assets
          .where((asset) => (asset['nativeAsset'] as String).endsWith('_TEST'))
          .take(20)
          .toList();

      print('Filtered assets: ${filtered.length}');
      setState(() {
        _filteredAssets = filtered;
      });

      _showCreateWalletDialog(); // 🟢 Now dialog will open after loading data
    } catch (e) {
      print('Error while loading assets: $e');
    }
  }

  // Fetch coin metadata from CoinGecko
  Future<void> _fetchCoinMetadata() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=bitcoin,ethereum,tether,solana,dogecoin',
        ),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          coinImages = {for (var coin in data) coin['name']: coin['image']};
        });
        print('Updated coinImages: $coinImages');
      } else {
        print('Failed to fetch coin metadata: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching coin metadata: $e');
    }
  }

  Future<void> _fetchWallets() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final fetchedWallets = await apiService
          .getCryptoWalletBalances(); // Updated to use getCryptoWalletBalances
      print(
        'Fetched Wallets with Balances: $fetchedWallets',
      ); // Updated debug message
      setState(() {
        wallets = fetchedWallets;
        isLoading = false;
      });
    } catch (e) {
      print('Fetch Wallets Error: $e');
      setState(() {
        isLoading = false;
        errorMessage = e.toString().contains('401')
            ? 'Authentication failed. Please log in again.'
            : 'Failed to load wallets: $e';
      });
    }
  }

  Future<void> _createWallet(String coinName) async {
    setState(() => isLoading = true);
    try {
      final newWallet = await apiService.createWalletAddress(coinName);
      print('New Wallet: $newWallet');
      setState(() {
        wallets.add(newWallet);
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Wallet address created successfully",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _fetchWallets();
    } catch (e) {
      print('Create Wallet Error: $e');
      if (e is http.Response) {
        print('Create Wallet Response: ${e.body}');
        final responseJson = jsonDecode(e.body);
        final error = responseJson['error'];
        final walletAddress = responseJson['walletAddress'];
        setState(() {
          isLoading = false;
          errorMessage = 'Failed: $error\nAddress: $walletAddress';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $error\nAddress: $walletAddress',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        setState(() {
          isLoading = false;
          errorMessage = e.toString().contains('401')
              ? 'Authentication failed. Please log in again.'
              : 'Failed to create wallet address: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to create wallet address: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateWalletDialog() {
    String? selectedCoin;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          print('Building dialog');
          return Dialog(
            backgroundColor: Colors.black.withOpacity(0.8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 30), // space for close icon

                      Text(
                        "Create New Crypto Wallet",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 20),

                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: Text(
                          'Select Coin',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        dropdownColor: Colors.black87,
                        items: coinNameToMainnet.entries
                            .map<DropdownMenuItem<String>>((entry) {
                              final nativeAsset = entry.key;
                              final mainnetName = entry.value;

                              return DropdownMenuItem<String>(
                                value: nativeAsset,
                                child: Row(
                                  children: [
                                    FutureBuilder<String>(
                                      future: CoinImageProvider.getImage(
                                        nativeAsset,
                                      ),
                                      builder: (context, snapshot) {
                                        final imageUrl =
                                            snapshot.data ??
                                            CoinImageProvider.fallbackImage;

                                        return ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: imageUrl,
                                            width: 24,
                                            height: 24,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) =>
                                                Shimmer.fromColors(
                                                  baseColor:
                                                      Colors.grey.shade800,
                                                  highlightColor:
                                                      Colors.grey.shade600,
                                                  child: Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration:
                                                        const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                ),
                                            errorWidget:
                                                (context, url, error) =>
                                                    const Icon(
                                                      Icons.currency_bitcoin,
                                                      color: Colors.white,
                                                      size: 24,
                                                    ),
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      mainnetName,
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCoin = value;
                            print('Selected Coin: $selectedCoin');
                          });
                        },
                        value: selectedCoin,
                        validator: (value) =>
                            value == null ? 'Please select a coin' : null,
                      ),

                      const SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: GoogleFonts.poppins(color: Colors.amber),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: selectedCoin == null
                                ? null
                                : () async {
                                    print(
                                      'Create button pressed for coin: $selectedCoin',
                                    );
                                    Navigator.pop(context);

                                    final apiCoinName = selectedCoin == 'ETC'
                                        ? 'ETC'
                                        : mainnetToCoinName[selectedCoin] ??
                                              selectedCoin!;
                                    await _createWallet(apiCoinName);
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            child: Text(
                              "Create",
                              style: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ❌ Close icon in the top-right corner
                Positioned(
                  right: 8,
                  top: 8,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _copyAddress(String? address) {
    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No address available to copy",
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Address copied to clipboard",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainScreen()),
            );
          },
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          "Crypto Wallets",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.black87, Colors.blueGrey.shade900],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isLoading
            ? Center(
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade800,
                  highlightColor: Colors.grey.shade600,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 200, height: 20, color: Colors.white),
                      const SizedBox(height: 20),
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : errorMessage != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      errorMessage!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.redAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _fetchWallets,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      child: Text(
                        "Retry",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : wallets.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "No Crypto Wallets",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Create a new wallet to get started!",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _showCreateWalletDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      child: Text(
                        "Create Wallet",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _fetchWallets,
                color: Colors.amber,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 140, 16, 16),
                  itemCount: wallets.length,
                  itemBuilder: (context, index) {
                    final wallet = wallets[index];
                    // Map testnet coin to mainnet coin for display and image fetching
                    final displayCoin =
                        coinNameToMainnet[wallet.currency] ?? wallet.currency;
                    final imageUrl =
                        coinImages[displayCoin] ??
                        'https://via.placeholder.com/40';
                    print(
                      'Wallet $index: coinName=${wallet.currency}, balance=${wallet.balance}',
                    ); // Updated to coinName
                    return AnimatedOpacity(
                      opacity: 1.0,
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 0,
                        color: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: FutureBuilder<String>(
                              future: CoinImageProvider.getImage(
                                wallet.currency,
                              ),
                              builder: (context, snapshot) {
                                final imageUrl =
                                    snapshot.data ??
                                    'https://via.placeholder.com/40?text=?'; // fallback image

                                return ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: imageUrl,
                                    width:
                                        MediaQuery.of(context).size.width * 0.1,
                                    height:
                                        MediaQuery.of(context).size.width * 0.1,
                                    placeholder: (context, url) =>
                                        Shimmer.fromColors(
                                          baseColor: Colors.grey.shade800,
                                          highlightColor: Colors.grey.shade600,
                                          child: Container(
                                            width:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.1,
                                            height:
                                                MediaQuery.of(
                                                  context,
                                                ).size.width *
                                                0.1,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    errorWidget: (context, url, error) =>
                                        Image.asset(
                                          'assets/images/default_coin.png',
                                          width:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.1,
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.width *
                                              0.1,
                                        ),
                                  ),
                                );
                              },
                            ),
                            title: Text(
                              displayCoin, // Display "Ethereum" instead of "ETH_TEST"
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _copyAddress(wallet.address),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          wallet.address != null
                                              ? "${wallet.address!.substring(0, 6)}...${wallet.address!.substring(wallet.address!.length - 4)}"
                                              : "No address",
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.grey.shade400,
                                          ),
                                        ),
                                        if (wallet.address != null) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.copy,
                                            size: 16,
                                            color: Colors.amber,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Balance: ${wallet.balance.toStringAsFixed(4)} ${displayCoin}",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.amber,
                                  ),
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.white70,
                            ),
                            onTap: () {
                              // Navigate to wallet details screen
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _prepareAndShowDialog,
        backgroundColor: Colors.amber,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
