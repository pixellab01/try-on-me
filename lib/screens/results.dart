import 'package:flutter/material.dart';
import 'widgets.dart';
import 'camera_screen.dart';

class ResultsScreen extends StatelessWidget {
  final List<Map<String, String>> products;
  final bool offline;

  const ResultsScreen({super.key, required this.products, required this.offline});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${products.length} products mile'),
        actions: [Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Center(child: ModeChip(serverMode: !offline)),
        )],
      ),
      body: Column(
        children: [
          if (offline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              color: Colors.amber.shade100,
              child: Text(
                'DEMO results — server connect karne pe real visual search chalega (Settings me).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.68,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: products.length,
              itemBuilder: (_, i) => ProductCard(
                product: products[i],
                onTryOn: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CameraScreen(garment: products[i]),
                  ));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
