import 'package:flutter/material.dart';
import '../config.dart';
import 'home.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pc = PageController();
  int _i = 0;

  final _pages = const [
    ('📸', 'Screenshot se shuru karo',
        'Kisi bhi shopping app ka screenshot upload karo.\nHum 8–10 matching products dhoondh denge.'),
    ('🎥', 'Khud pe try karo',
        'Product chuno, 4-second ka video record karo.\nAI tumhare upar kapde pehna dega — video me!'),
    ('🛍️', 'Pasand aaye to kharido',
        'Result screen pe "View Product" dabao\naur seedha store pe jaake kharid lo.'),
  ];

  Future<void> _done() async {
    await AppConfig.setOnboarded();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: _done, child: const Text('Skip')),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pc,
                onPageChanged: (v) => setState(() => _i = v),
                itemCount: _pages.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_pages[i].$1, style: const TextStyle(fontSize: 96)),
                      const SizedBox(height: 28),
                      Text(_pages[i].$2,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      Text(_pages[i].$3,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600, height: 1.5)),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _i == i ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _i == i ? const Color(0xFF7C3AED) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (_i < _pages.length - 1) {
                      _pc.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                    } else {
                      _done();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(_i < _pages.length - 1 ? 'Aage' : 'Shuru karo',
                      style: const TextStyle(fontSize: 17)),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
