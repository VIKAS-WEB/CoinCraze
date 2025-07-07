import 'dart:convert';
import 'package:coincraze/AuthManager.dart';
import 'package:coincraze/Constants/API.dart';
import 'package:coincraze/Models/CryptoWallet.dart';
import 'package:coincraze/Models/Transactions.dart';
import 'package:coincraze/Models/Wallet.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Replace with your NewsAPI key (store securely in production)
  static const String _newsApiKey =
      '6c41a5cc7ebe4221a238471104f4a5b5'; // Get from newsapi.org
  static const String _baseUrl = 'https://newsapi.org/v2';
  final authToken = AuthManager().getAuthToken().toString();

  // New method for Tatum integration

  Future<CryptoWallet> createWalletAddress(String coinName) async {
    try {
      final authToken = await AuthManager().getAuthToken();
      print('Resolved Auth Token: $authToken'); // Debug print
      if (authToken == null) {
        throw Exception('No auth token found. Please log in.');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/wallet/createCryptoWallet'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'coinName': coinName}),
      );

      print('Create Wallet Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonResponse = jsonDecode(response.body);
          final data = jsonResponse['data'] ?? jsonResponse;
          return CryptoWallet.fromJson(data);
        } catch (e) {
          // Fallback if response is a string (wallet address)
          print('Parsing as string: ${response.body}');
          return CryptoWallet(
            userId: null,
            currency: coinName,
            address: response.body.trim(), // Clean up any whitespace
            balance: 0.0,
            mnemonic: null,
            vaultAccountId: null,
          );
        }
      } else {
        throw Exception('Failed to create wallet: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createWalletAddress: $e');
      throw Exception('Error creating wallet: $e');
    }
  }

  Future<Map<String, double>> fetchCryptoExchangeRates(
    String crypto,
    String fiat,
    double amount,
  ) async {
    final fromCurrency = fiat.toLowerCase(); // Use fiat as 'from' currency
    final toCurrency = crypto.toLowerCase(); // Use crypto as 'to' currency
    final url = Uri.parse(
      '$baseUrl/api/wallet/convert?from=$fromCurrency&to=$toCurrency&amount=$amount',
    );
    print('Fetching exchange rate from: $url'); // Debug full URL
    final response = await http.get(url);
    print(
      'API Response status: ${response.statusCode}, body: ${response.body}',
    ); // Debug response

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData.isEmpty || !jsonData.containsKey('rate')) {
        print(
          'Empty or invalid response for $fromCurrency to $toCurrency with amount $amount',
        );
        throw Exception('No exchange rate data available');
      }
      final rate = (jsonData['rate'] as num)
          .toDouble(); // Extract rate directly
      if (rate <= 0) {
        print('Invalid rate value: $rate for $fromCurrency to $toCurrency');
        throw Exception('Invalid exchange rate');
      }
      print(
        'Fetched rate: $rate for $fromCurrency to $toCurrency (1 $toCurrency = $rate $fromCurrency)',
      );
      return {fromCurrency: rate}; // Return as {fiat: rate} map
    } else {
      print(
        'API error, status: ${response.statusCode}, body: ${response.body}',
      );
      throw Exception(
        'Failed to fetch exchange rate, status: ${response.statusCode}',
      );
    }
  }

  Future<List<CryptoWallet>> getCryptoWalletBalances() async {
    try {
      final token = await AuthManager().getAuthToken();
      print('Auth Token: $token');
      final response = await http.get(
        Uri.parse('$baseUrl/api/wallet/fetchCryptoWalletBalances'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('API URL: $baseUrl/api/wallet/fetchCryptoWalletBalances');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        print('Parsed Data: $data');
        return data.map((json) => CryptoWallet.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
          'Failed to fetch crypto wallet balances: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching crypto wallet balances: $e');
      throw Exception('Error fetching crypto wallet balances: $e');
    }
  }

  Future<List<CryptoWallet>> getCryptoWalletAddress() async {
    try {
      final token = await AuthManager().getAuthToken();
      print(token);
      final response = await http.get(
        Uri.parse('$baseUrl/api/wallet/fetchCryptoWalletAddresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('API URL: $baseUrl/api/wallet/fetchCryptoWalletAddresses');
      print('Auth Token: $authToken');
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        print('Parsed Data: $data');
        return data.map((json) => CryptoWallet.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to fetch Wallet Address: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching wallets: $e');
      throw Exception('Error fetching crypto balances: $e');
    }
  }

  Future<List<Wallet>> getBalance() async {
    try {
      final token = await AuthManager().getAuthToken();
      final response = await http.get(
        Uri.parse('$baseUrl/api/wallet/balance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Balance Request URL: $baseUrl/api/wallet/balance');
      print(
        'Balance Request Headers: ${{'Content-Type': 'application/json', 'Authorization': 'Bearer $token'}}',
      );
      print('Balance Response Status: ${response.statusCode}');
      print('Balance Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Wallet.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to fetch balance: ${response.body}');
      }
    } catch (e) {
      print('Balance Error: $e');
      rethrow;
    }
  }

  Future<List<Transactions>> getTransactions() async {
    try {
      final token = await AuthManager().getAuthToken();
      print('Token: $token');
      final response = await http.get(
        Uri.parse('$baseUrl/api/wallet/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Transactions Request URL: $baseUrl/api/wallet/transactions');
      print('Transactions Response Status: ${response.statusCode}');
      print('Transactions Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Explicitly map to List<Transactions>
        return data
            .map((json) => Transactions.fromJson(json))
            .toList(growable: false);
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to fetch transactions: ${response.body}');
      }
    } catch (e) {
      print('Transactions Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiateStripePayment(
    String userId,
    double amount,
    String currency,
  ) async {
    try {
      final token = await AuthManager().getAuthToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/wallet/add-money/stripe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'amount': amount,
          'currency': currency,
        }),
      );

      print('Stripe Payment Response Status: ${response.statusCode}');
      print('Stripe Payment Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to initiate Stripe payment: ${response.body}');
      }
    } catch (e) {
      print('Stripe Payment Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiateRazorpayPayment(
    String userId,
    double amount,
    String currency,
  ) async {
    try {
      final token = await AuthManager().getAuthToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/wallet/add-money/razorpay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'amount': amount,
          'currency': currency,
        }),
      );

      print('Razorpay Payment Response Status: ${response.statusCode}');
      print('Razorpay Payment Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
          'Failed to initiate Razorpay payment: ${response.body}',
        );
      }
    } catch (e) {
      print('Razorpay Payment Error: $e');
      rethrow;
    }
  }

  Future<void> withdraw(String userId, double amount, String currency) async {
    try {
      final token = await AuthManager().getAuthToken();
      final response = await http.post(
        Uri.parse('$baseUrl/api/wallet/withdraw'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'amount': amount,
          'currency': currency,
        }),
      );

      print('Withdraw Response Status: ${response.statusCode}');
      print('Withdraw Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to initiate withdrawal: ${response.body}');
      }
    } catch (e) {
      print('Withdraw Error: $e');
      rethrow;
    }
  }

  Future<void> createWallet(String currency) async {
    try {
      final token = await AuthManager().getAuthToken();
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      final response = await http.post(
        Uri.parse('$baseUrl/api/wallet/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'userId': userId, 'currency': currency}),
      );

      print('Create Wallet Response Status: ${response.statusCode}');
      print('Create Wallet Response Body: ${response.body}');

      if (response.statusCode == 201) {
        return;
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to create wallet: ${response.body}');
      }
    } catch (e) {
      print('Create Wallet Error: $e');
      rethrow;
    }
  }

  // Fetch currency-related news
  Future<List<dynamic>> fetchCurrencyNews(List<String> currencies) async {
    try {
      final query = currencies.isNotEmpty
          ? currencies.map((c) => c.toLowerCase()).join(' OR ') + ' currency'
          : 'currency market';
      final url = Uri.parse(
        '$_baseUrl/everything?q=$query&apiKey=$_newsApiKey&language=en&sortBy=publishedAt&pageSize=10',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return jsonData['articles'] ?? [];
      } else {
        throw Exception('Failed to load news: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching news: $e');
    }
  }

  // New method to sell crypto and update fiat wallet
  Future<void> sellCryptoToFiat({
    required String cryptoCurrency,
    required String fiatCurrency,
    required double cryptoAmount,
    required double fiatAmount,
    required String cryptoWalletId,
    required String fiatWalletId,
  }) async {
    try {
      final token = await AuthManager().getAuthToken();
      print('Sell Crypto Token: $token');
      final response = await http.post(
        Uri.parse('$baseUrl/api/wallet/sellCrypto'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'cryptoWalletId': cryptoWalletId,
          'fiatWalletId': fiatWalletId,
          'cryptoAmount': cryptoAmount,
          'fiatAmount': fiatAmount,
          'cryptoCurrency': cryptoCurrency,
        }),
      );

      print('Sell Crypto Response Status: ${response.statusCode}');
      print('Sell Crypto Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to sell crypto: ${response.body}');
      }
    } catch (e) {
      print('Sell Crypto Error: $e');
      throw Exception('Error selling crypto: $e');
    }
  }

  Future<List<CryptoWallet>> getCompleteCryptoDetails() async {
    try {
      final token = await AuthManager().getAuthToken();
      final userId = await AuthManager().userId;

      if (userId == null) {
        throw Exception('User ID not found');
      }

      final url = Uri.parse(
        '$baseUrl/api/wallet/fetchCompleteCryptoDetails?userId=$userId',
      );

      print('🔐 Token: $token');
      print('🧑‍💻 User ID: $userId');
      print('🌐 Request URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📦 Status Code: ${response.statusCode}');
      print('📨 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> data = jsonResponse['data'];
        return data.map((json) => CryptoWallet.fromJson(json)).toList();
      } else {
        throw Exception(
          'Failed to fetch Wallet Address: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error fetching wallets: $e');
      throw Exception('Error fetching crypto balances: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSupportedAssets() async {
    final Token = await AuthManager().getAuthToken();
    final url = Uri.parse('$baseUrl/api/wallet/getSupportedAssets');
    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $Token'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List<dynamic> rawAssets =
          json['data']; // 👈 yahan 'data' se list nikaali
      return rawAssets
          .cast<
            Map<String, dynamic>
          >(); // 👈 convert to List<Map<String, dynamic>>
    } else {
      throw Exception('Failed to load supported assets');
    }
  }
}
