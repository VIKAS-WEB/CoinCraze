import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class ChartScreen extends StatefulWidget {
  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  List<CandleData> chartData = [];
  String currentPrice = "0.00";
  String changePercent = "0.00%";
  bool isLoading = true;
  Timer? _timer;
  String selectedCoin = 'bitcoin'; // Default coin
  // Popular coins list (tu isme aur add kar sakta hai)
  List<String> coinOptions = [
    'bitcoin',
    'ethereum',
    'ripple',
    'cardano',
    'solana',
    'polkadot',
    'dogecoin',
    'binancecoin',
    'chainlink',
    'avalanche-2'
  ];

  @override
  void initState() {
    super.initState();
    fetchData();
    _timer = Timer.periodic(Duration(minutes: 5), (timer) {
      fetchData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.coingecko.com/api/v3/coins/$selectedCoin/ohlc?vs_currency=usd&days=1'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final List<CandleData> newData = [];
        for (var item in data) {
          newData.add(CandleData(
            DateTime.fromMillisecondsSinceEpoch(item[0]),
            item[1].toDouble(), // Open
            item[2].toDouble(), // High
            item[3].toDouble(), // Low
            item[4].toDouble(), // Close
          ));
        }
        newData.sort((a, b) => a.time.compareTo(b.time));

        setState(() {
          chartData = newData.take(24).toList(); // Last 24 hours ka data
          currentPrice = chartData.last.close.toStringAsFixed(2);
          final latestChange = chartData.last.close - chartData.first.close;
          changePercent = '${(latestChange / chartData.first.close * 100).toStringAsFixed(2)}%';
          isLoading = false;
        });
      } else {
        throw Exception('Data nahi aaya');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crypto Chart - 1H'),
        actions: [
          IconButton(icon: Icon(Icons.settings), onPressed: () {}),
          IconButton(icon: Icon(Icons.camera_alt), onPressed: () {}),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<String>(
                        value: selectedCoin,
                        icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                        dropdownColor: const Color.fromARGB(255, 255, 255, 255),
                        style: TextStyle(color: Colors.black, fontSize: 16),
                        underline: Container(
                          height: 1,
                          color: Colors.black,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedCoin = newValue;
                              isLoading = true;
                              fetchData();
                            });
                          }
                        },
                        items: coinOptions.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value.toUpperCase()),
                          );
                        }).toList(),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: changePercent.contains('-') ? Colors.red[100] : Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              changePercent.contains('-') ? Icons.arrow_downward : Icons.arrow_upward,
                              size: 16,
                              color: changePercent.contains('-') ? Colors.red : Colors.green,
                            ),
                            SizedBox(width: 4),
                            Text(currentPrice, style: TextStyle(color: changePercent.contains('-') ? Colors.red : Colors.green, fontSize: 18)),
                            SizedBox(width: 4),
                            Text(changePercent, style: TextStyle(color: changePercent.contains('-') ? Colors.red : Colors.green)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SfCartesianChart(
                    primaryXAxis: DateTimeAxis(
                      intervalType: DateTimeIntervalType.hours,
                      dateFormat: DateFormat('HH'),
                      majorGridLines: MajorGridLines(width: 0.5, color: Colors.grey),
                      labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    primaryYAxis: NumericAxis(
                      majorGridLines: MajorGridLines(width: 0.5, color: Colors.grey),
                      labelFormat: '{value}',
                      minimum: chartData.isNotEmpty ? chartData.map((p) => p.low).reduce((a, b) => a < b ? a : b) * 0.99 : 0,
                      maximum: chartData.isNotEmpty ? chartData.map((p) => p.high).reduce((a, b) => a > b ? a : b) * 1.01 : 100000,
                      interval: (chartData.isNotEmpty ? (chartData.map((p) => p.high).reduce((a, b) => a > b ? a : b) - chartData.map((p) => p.low).reduce((a, b) => a < b ? a : b)) : 10000) / 5,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                    series: <CartesianSeries<CandleData, DateTime>>[
                      CandleSeries<CandleData, DateTime>(
                        dataSource: chartData,
                        xValueMapper: (CandleData data, _) => data.time,
                        lowValueMapper: (CandleData data, _) => data.low,
                        highValueMapper: (CandleData data, _) => data.high,
                        openValueMapper: (CandleData data, _) => data.open,
                        closeValueMapper: (CandleData data, _) => data.close,
                        bearColor: Colors.red,
                        bullColor: Colors.green,
                        showIndicationForSameValues: true,
                        animationDuration: 0,
                      ),
                    ],
                    plotAreaBackgroundColor: Colors.black,
                    backgroundColor: Colors.black,
                    plotAreaBorderWidth: 0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd MMM yyyy').format(DateTime.now()), style: TextStyle(fontSize: 12, color: Colors.white)),
                      Text(chartData.isNotEmpty ? chartData.first.close.toStringAsFixed(2) : '0.00', style: TextStyle(fontSize: 12, color: Colors.white)),
                    ],
                  ),
                ),
              ],
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