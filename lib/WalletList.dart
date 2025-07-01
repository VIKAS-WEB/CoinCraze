import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/Constants/API.dart';
import 'package:coincraze/Models/CryptoWallet.dart';
import 'package:coincraze/Services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
    _fetchWallets();
  }

  Future<void> _fetchWallets() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final fetchedWallets = await apiService.getCryptoWalletAddress();
      print('Fetched Wallets: $fetchedWallets'); // Debug print
      setState(() {
        wallets = fetchedWallets;
        isLoading = false;
      });
    } catch (e) {
      print('Fetch Wallets Error: $e'); // Debug print
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
      print('New Wallet: $newWallet'); // Debug print
      setState(() {
        wallets.add(newWallet);
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wallet address created successfully")),
      );
      await _fetchWallets(); // Refresh to sync with database
    } catch (e) {
      print('Create Wallet Error: $e'); // Debug print
      // Try casting if it's a http.Response
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
          SnackBar(content: Text('Error: $error\nAddress: $walletAddress')),
        );
      } else {
        // Fallback if not http.Response
        setState(() {
          isLoading = false;
          errorMessage = e.toString().contains('401')
              ? 'Authentication failed. Please log in again.'
              : 'Failed to create wallet address: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create wallet address: $e')),
        );
      }
    }
  }

  void _showCreateWalletDialog() {
    String? selectedCoin; // Moved outside builder
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          print('Building dialog'); // Debug print
          return AlertDialog(
            title: const Text("Create New Crypto Wallet Address"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    hintText: "Select Coin",
                    border: OutlineInputBorder(),
                  ),
                  items: ["Bitcoin", "Ethereum", "Tether", "Solana", "Dogecoin"]
                      .map(
                        (coin) =>
                            DropdownMenuItem(value: coin, child: Text(coin)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCoin = value;
                      print('Selected Coin: $selectedCoin'); // Debug print
                    });
                  },
                  value: selectedCoin,
                  validator: (value) =>
                      value == null ? 'Please select a coin' : null,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: selectedCoin == null
                    ? null
                    : () async {
                        print(
                          'Create button pressed for coin: $selectedCoin',
                        ); // Debug print
                        Navigator.pop(context);
                        await _createWallet(selectedCoin!);
                      },
                child: const Text("Create"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _copyAddress(String? address) {
    if (address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No address available to copy")),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Address copied to clipboard")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crypto Wallet Addresses"),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    errorMessage!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _fetchWallets,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      "Retry",
                      style: TextStyle(fontSize: 16, color: Colors.black),
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
                  const Text(
                    "No Crypto Wallet Addresses",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Create a new crypto wallet address to get started!",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _showCreateWalletDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      "Create Address",
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchWallets,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: wallets.length,
                itemBuilder: (context, index) {
                  final wallet = wallets[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.black54,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        "${wallet.currency} Wallet Address",
                        style: const TextStyle(
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
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    wallet.address != null
                                        ? "${wallet.address!.substring(0, 6)}...${wallet.address!.substring(wallet.address!.length - 4)}"
                                        : "No address",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
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
                            "Balance: ${wallet.balance.toStringAsFixed(4)} ${wallet.currency}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white,
                      ),
                      onTap: () {
                        // Navigate to wallet details screen
                      },
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateWalletDialog,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      backgroundColor: Colors.black87,
    );
  }
}
