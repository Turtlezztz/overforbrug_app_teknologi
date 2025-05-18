import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import '../services/language_service.dart';
import '../models/purchase.dart';
import 'purchase_details_page.dart';
import '../services/settings_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _aiFeedback;
  String _animatedFeedback = '';
  bool _isLoading = false;
  bool _isDisposed = false;
  Timer? _typingTimer;
  int _typingIndex = 0;
  bool _showCursor = true;

  @override
  void dispose() {
    _isDisposed = true;
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startTypingAnimation(String text) {
    _typingTimer?.cancel();
    _typingIndex = 0;
    _animatedFeedback = '';
    _showCursor = true;
    
    _typingTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      
      if (_typingIndex < text.length) {
        setState(() {
          _animatedFeedback += text[_typingIndex];
          _typingIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          _showCursor = false;
        });
      }
    });
  }

  Future<void> _getAIFeedback() async {
    if (_isDisposed) return;
    
    setState(() {
      _isLoading = true;
      _animatedFeedback = '';
    });

    final purchases = getDummyPurchases();
    final currencyFormat = NumberFormat.currency(locale: 'da_DK', symbol: 'kr.');
    final languageService = context.read<LanguageService>();
    final settingsService = context.read<SettingsService>();
    final isEnglish = languageService.currentLanguage == 'English';
    
    // Format purchases for the prompt
    final purchasesText = purchases.map((p) => 
      '${p.store}: ${currencyFormat.format(p.amount)} (${DateFormat('dd/MM/yyyy').format(p.date)})'
    ).join('\n');

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer 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',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': isEnglish 
                ? 'You are a concise financial advisor analyzing spending patterns. Provide brief, actionable feedback in English. Focus on identifying potential overspending and suggesting specific improvements. Keep responses under 100 words.'
                : 'Du er en præcis økonomisk rådgiver, der analyserer forbrugsmønstre. Giv kortfattet, konkret feedback på dansk. Fokuser på at identificere potentielt overforbrug og foreslå specifikke forbedringer. Hold svar under 100 ord.'
            },
            {
              'role': 'user',
              'content': isEnglish
                ? 'Here are my recent purchases:\n$purchasesText\n\nPlease provide specific feedback on my spending patterns and suggest concrete improvements.'
                : 'Her er mine seneste køb:\n$purchasesText\n\nGiv venligst specifik feedback på mit forbrugsmønster og foreslå konkrete forbedringer.'
            }
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (_isDisposed) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!_isDisposed) {
          setState(() {
            _aiFeedback = data['choices'][0]['message']['content'];
            _isLoading = false;
          });
          _startTypingAnimation(_aiFeedback!);
        }
      } else {
        if (!_isDisposed) {
          final errorMessage = isEnglish
              ? 'Could not fetch feedback. Please try again later.'
              : 'Kunne ikke hente feedback. Prøv igen senere.';
          setState(() {
            _aiFeedback = errorMessage;
            _isLoading = false;
          });
          _startTypingAnimation(errorMessage);
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        final errorMessage = isEnglish
            ? 'An error occurred. Please try again later.'
            : 'Der opstod en fejl. Prøv igen senere.';
        setState(() {
          _aiFeedback = errorMessage;
          _isLoading = false;
        });
        _startTypingAnimation(errorMessage);
      }
    }
  }

  List<Purchase> getDummyPurchases() {
    return [
      Purchase(
        store: 'Amazon',
        amount: 299.99,
        date: DateTime.now().subtract(const Duration(days: 1)),
        productName: 'Wireless Headphones',
      ),
      Purchase(
        store: 'Netflix',
        amount: 89.00,
        date: DateTime.now().subtract(const Duration(days: 2)),
        productName: 'Premium Subscription',
      ),
      Purchase(
        store: 'Temu',
        amount: 59.00,
        date: DateTime.now().subtract(const Duration(days: 3)),
        productName: 'Phone Case Set',
      ),
      Purchase(
        store: 'Tiktok Shop',
        amount: 187.50,
        date: DateTime.now().subtract(const Duration(days: 4)),
        productName: 'Smart Watch',
      ),
      Purchase(
        store: 'H&M',
        amount: 245.00,
        date: DateTime.now().subtract(const Duration(days: 5)),
        productName: 'Summer Collection',
      ),
      Purchase(
        store: 'Zalando',
        amount: 399.99,
        date: DateTime.now().subtract(const Duration(days: 7)),
        productName: 'Running Shoes',
      ),
      Purchase(
        store: 'Spotify',
        amount: 59.00,
        date: DateTime.now().subtract(const Duration(days: 8)),
        productName: 'Family Plan',
      ),
      Purchase(
        store: 'Wolt',
        amount: 156.00,
        date: DateTime.now().subtract(const Duration(days: 10)),
        productName: 'Food Delivery',
      ),
      Purchase(
        store: 'Amazon',
        amount: 199.99,
        date: DateTime.now().subtract(const Duration(days: 12)),
        productName: 'Kindle E-reader',
      ),
      Purchase(
        store: 'Netflix',
        amount: 89.00,
        date: DateTime.now().subtract(const Duration(days: 15)),
        productName: 'Standard Plan',
      ),
    ];
  }

  Map<DateTime, double> getDailyTotals() {
    final purchases = getDummyPurchases();
    final Map<DateTime, double> dailyTotals = {};
    final settingsService = context.read<SettingsService>();
    
    // Initialize selected time period with 0
    for (int i = 0; i < settingsService.timeInterval; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      dailyTotals[DateTime(date.year, date.month, date.day)] = 0;
    }

    // Add purchase amounts to their respective days
    for (var purchase in purchases) {
      final date = DateTime(purchase.date.year, purchase.date.month, purchase.date.day);
      if (dailyTotals.containsKey(date)) {
        dailyTotals[date] = (dailyTotals[date] ?? 0) + purchase.amount;
      }
    }

    return dailyTotals;
  }

  @override
  void initState() {
    super.initState();
    _getAIFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();
    final settingsService = context.watch<SettingsService>();
    final purchases = getDummyPurchases();
    final currencyFormat = NumberFormat.currency(locale: 'da_DK', symbol: 'kr.');
    final dailyTotals = getDailyTotals();
    final sortedDates = dailyTotals.keys.toList()..sort();
    final maxAmount = dailyTotals.values.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageService.translate('home')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (settingsService.showAIFeedback)
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
              else if (_aiFeedback != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 32.0, 16.0, 16.0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          languageService.translate('ai_feedback'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(text: _animatedFeedback),
                              if (_showCursor)
                                TextSpan(
                                  text: '|',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            Container(
              height: 250,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    languageService.translate('spending_overview'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    languageService.translate('last_${settingsService.timeInterval}_days'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: maxAmount * 1.2,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: maxAmount / 4,
                          verticalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300],
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Colors.grey[300],
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()} kr.',
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: settingsService.timeInterval <= 7 ? 2 : 7,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= sortedDates.length) return const Text('');
                                final date = sortedDates[index];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('dd/MM').format(date),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(sortedDates.length, (index) {
                              return FlSpot(
                                index.toDouble(),
                                dailyTotals[sortedDates[index]]!,
                              );
                            }),
                            isCurved: true,
                            color: Theme.of(context).colorScheme.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                        ],
                        minX: 0,
                        maxX: (sortedDates.length - 1).toDouble(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                languageService.translate('recent_purchases'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: purchases.length,
              itemBuilder: (context, index) {
                final purchase = purchases[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Text(
                        purchase.store[0],
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      purchase.store,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(purchase.date),
                    ),
                    trailing: Text(
                      currencyFormat.format(purchase.amount),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      // Filter purchases for the selected store
                      final storePurchases = purchases.where((p) => p.store == purchase.store).toList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PurchaseDetailsPage(
                            store: purchase.store,
                            purchases: storePurchases,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
} 