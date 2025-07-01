import 'dart:convert';
import 'package:coincraze/Services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coincraze/Models/CryptoWallet.dart';

class BuyCryptoScreen extends StatefulWidget {
  final String userId;
  final List<String> availableCurrencies;

  BuyCryptoScreen({required this.userId, required this.availableCurrencies});

  @override
  _BuyCryptoScreenState createState() => _BuyCryptoScreenState();
}

class _BuyCryptoScreenState extends State<BuyCryptoScreen> {
  final _amountController = TextEditingController();
  String _selectedCrypto = 'BTC'; // Default to BTC
  String _selectedFiat = 'USD';   // Default to USD
  double _cryptoAmount = 0.0;
  double _exchangeRate = 0.0;
  double _fee = 0.0;
  bool _isLoading = false;

  final List<String> _cryptos = ['BTC', 'ETH', 'USDT'];

  // Mapping of ticker symbols to full cryptocurrency names
  final Map<String, String> _cryptoFullNames = {
    'BTC': 'Bitcoin',
    'ETH': 'Ethereum',
    'USDT': 'Tether',
  };

  @override
  void initState() {
    super.initState();
    _selectedFiat = widget.availableCurrencies.contains('USD') ? 'USD' : (widget.availableCurrencies.isNotEmpty ? widget.availableCurrencies[0] : 'USD');
    _fetchExchangeRate();
    _amountController.addListener(_calculateCryptoAmount);
  }

  Future<void> _fetchExchangeRate() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      setState(() {
        _exchangeRate = 0.0;
        _cryptoAmount = 0.0;
        _fee = 0.0;
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final cryptoFullName = _cryptoFullNames[_selectedCrypto] ?? _selectedCrypto;
      final rates = await ApiService().fetchCryptoExchangeRates(cryptoFullName, _selectedFiat, amount);
      print('API Response parsed: $rates'); // Debug parsed rates
      setState(() {
        _exchangeRate = rates[_selectedFiat.toLowerCase()] ?? 0.0;
        if (_exchangeRate <= 0) {
          throw Exception('Invalid exchange rate received');
        }
        _calculateCryptoAmount();
      });
    } catch (e) {
      print('Error fetching exchange rate: $e'); // Debug
      setState(() {
        _exchangeRate = 60000.0; // Mock fallback value for USD to BTC
        _calculateCryptoAmount();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching rate, using mock value: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateCryptoAmount() {
    final fiatAmount = double.tryParse(_amountController.text) ?? 0.0;
    setState(() {
      _fee = fiatAmount * 0.015; // 1.5% fee
      _cryptoAmount = _exchangeRate > 0 ? (fiatAmount - _fee) / _exchangeRate : 0.0;
    });
  }

  // Future<void> _confirmTransaction() async {
  //   final fiatAmount = double.tryParse(_amountController.text) ?? 0.0;
  //   if (fiatAmount <= 0) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Please enter a valid amount')),
  //     );
  //     return;
  //   }

  //   setState(() => _isLoading = true);
  //   try {
  //     // Mock transaction: Update crypto wallet
  //     final prefs = await SharedPreferences.getInstance();
  //     final cryptoWallets = prefs.getStringList('crypto_wallets') ?? [];
  //     List<CryptoWallet> wallets = cryptoWallets
  //         .map((json) => CryptoWallet.fromJson(Map<String, dynamic>.from(jsonDecode(json))))
  //         .toList();
  //     final existingWalletIndex = wallets.indexWhere((w) => w.currency == _selectedCrypto);
  //     if (existingWalletIndex != -1) {
  //       wallets[existingWalletIndex] = CryptoWallet(
  //         currency: _selectedCrypto,
  //         balance: wallets[existingWalletIndex].balance + _cryptoAmount,
  //       );
  //     } else {
  //       wallets.add(CryptoWallet(currency: _selectedCrypto, balance: _cryptoAmount));
  //     }
  //     await prefs.setStringList(
  //       'crypto_wallets',
  //       wallets.map((w) => jsonEncode(w.toJson())).toList(),
  //     );

  //     // Show transaction summary
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Text('Transaction Successful', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text('Fiat Amount: $_selectedFiat $fiatAmount', style: GoogleFonts.poppins()),
  //             Text('Crypto Received: ${_cryptoAmount.toStringAsFixed(8)} $_selectedCrypto', style: GoogleFonts.poppins()),
  //             Text('Fee: $_selectedFiat ${_fee.toStringAsFixed(2)}', style: GoogleFonts.poppins()),
  //             Text('Exchange Rate: 1 $_selectedCrypto = $_selectedFiat ${_exchangeRate.toStringAsFixed(2)}', style: GoogleFonts.poppins()),
  //             Text('Date: ${DateTime.now().toString()}', style: GoogleFonts.poppins()),
  //           ],
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: Text('OK', style: GoogleFonts.poppins(color: Color.fromARGB(255, 46, 46, 47))),
  //           ),
  //         ],
  //       ),
  //     );
  //   } catch (e) {
  //     print('Transaction error: $e'); // Debug
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Transaction failed: $e')),
  //     );
  //   } finally {
  //     setState(() => _isLoading = false);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: (){
            Navigator.pop(context);
          },
          child: Icon(Icons.arrow_back, color: Colors.white,)),
        title: Text('Buy Crypto', style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Color.fromARGB(255, 46, 46, 47),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Crypto', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            DropdownButton<String>(
              value: _selectedCrypto,
              isExpanded: true,
              items: _cryptos
                  .map((crypto) => DropdownMenuItem(value: crypto, child: Text(crypto, style: GoogleFonts.poppins())))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCrypto = value!;
                  _fetchExchangeRate();
                });
              },
            ),
            SizedBox(height: 16),
            Text('Select Fiat Currency', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            DropdownButton<String>(
              value: _selectedFiat,
              isExpanded: true,
              items: widget.availableCurrencies
                  .map((currency) => DropdownMenuItem(value: currency, child: Text(currency, style: GoogleFonts.poppins())))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedFiat = value!;
                  _fetchExchangeRate();
                });
              },
            ),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Fiat Amount ($_selectedFiat)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _fetchExchangeRate(), // Trigger API call on input change
            ),
            SizedBox(height: 16),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Exchange Rate: 1 $_selectedCrypto = $_selectedFiat ${_exchangeRate.toStringAsFixed(2)}',
                      style: GoogleFonts.poppins()),
                  Text('Fee (1.5%): $_selectedFiat ${_fee.toStringAsFixed(2)}', style: GoogleFonts.poppins()),
                  Text('You will receive: ${_cryptoAmount.toStringAsFixed(8)} $_selectedCrypto',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ],
              ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 46, 46, 47),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Confirm Transaction', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}