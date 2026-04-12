import 'package:flutter/material.dart';

import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../home/data/mock_marketplace_data.dart';
import '../../shared/widgets/wask_bottom_nav.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _suggestions(String query) {
    if (query.trim().isEmpty) {
      return <String>[];
    }

    final term = query.toLowerCase();
    final options = <String>{
      ...marketplaceProducts.map((product) => product.name),
      ...marketplaceBrands,
      ...marketplaceStores.map((store) => store.name),
      ...marketplaceCategories.map((category) => category.label),
    };

    return options
        .where((option) => option.toLowerCase().contains(term))
        .take(12)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _suggestions(_controller.text);

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      bottomNavigationBar: const WaskBottomNav(currentRoute: WaskRoutes.search),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Que deseas pedir hoy?',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 16),
            if (_controller.text.trim().isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Escribe para encontrar productos, marcas y licorerias.',
                    style: TextStyle(color: WaskColors.secondaryText),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (results.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('No encontramos resultados para tu busqueda.'),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final value = results[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: WaskColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.search_rounded),
                        title: Text(value),
                        trailing:
                            const Icon(Icons.north_west_rounded, size: 18),
                        onTap: () {
                          _controller.text = value;
                          setState(() {});
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
