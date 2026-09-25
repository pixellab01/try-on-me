import 'package:flutter/material.dart';

/// Product card — search results + home dono me reuse.
class ProductCard extends StatelessWidget {
  final Map<String, String> product;
  final VoidCallback onTryOn;

  const ProductCard({super.key, required this.product, required this.onTryOn});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                gradient: LinearGradient(
                  colors: [const Color(0xFF7C3AED).withValues(alpha: 0.25), const Color(0xFFEC4899).withValues(alpha: 0.25)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(product['emoji'] ?? '👕',
                    style: const TextStyle(fontSize: 52)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
            child: Text(
              product['title'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Text(product['price'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(product['store'] ?? '',
                      overflow: TextOverflow.ellipsis,
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            child: SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: onTryOn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('✨ Try On', style: TextStyle(fontSize: 13)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chhota demo/server mode chip
class ModeChip extends StatelessWidget {
  final bool serverMode;
  const ModeChip({super.key, required this.serverMode});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: serverMode ? Colors.green.shade100 : Colors.amber.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        serverMode ? 'SERVER' : 'DEMO',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: serverMode ? Colors.green.shade800 : Colors.amber.shade900,
        ),
      ),
    );
  }
}
