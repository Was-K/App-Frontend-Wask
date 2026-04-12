class MarketplaceCategory {
  const MarketplaceCategory({required this.label, required this.iconName});

  final String label;
  final String iconName;
}

class MarketplaceStore {
  const MarketplaceStore({
    required this.name,
    required this.rating,
    required this.eta,
    required this.district,
  });

  final String name;
  final String rating;
  final String eta;
  final String district;
}

class MarketplaceProduct {
  const MarketplaceProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.brand,
    required this.category,
  });

  final String id;
  final String name;
  final double price;
  final String brand;
  final String category;
}

class MarketplacePromo {
  const MarketplacePromo({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

const marketplaceCategories = <MarketplaceCategory>[
  MarketplaceCategory(label: 'Cervezas', iconName: 'sports_bar'),
  MarketplaceCategory(label: 'Destilados', iconName: 'local_bar'),
  MarketplaceCategory(label: 'Vinos', iconName: 'wine_bar'),
  MarketplaceCategory(label: 'Snacks', iconName: 'fastfood'),
];

const marketplaceStores = <MarketplaceStore>[
  MarketplaceStore(
    name: 'Licoreria 24/7 Jesus Maria',
    rating: '4.9',
    eta: '18-24 min',
    district: 'Jesus Maria',
  ),
  MarketplaceStore(
    name: 'Bodega Premium Lince',
    rating: '4.8',
    eta: '20-26 min',
    district: 'Lince',
  ),
  MarketplaceStore(
    name: 'Cava Express Pueblo Libre',
    rating: '4.7',
    eta: '22-28 min',
    district: 'Pueblo Libre',
  ),
];

const marketplacePromos = <MarketplacePromo>[
  MarketplacePromo(title: '2x1 en cervezas', subtitle: 'Solo hoy 8:00 pm'),
  MarketplacePromo(
      title: 'S/20 off en whisky', subtitle: 'Compras desde S/120'),
  MarketplacePromo(title: 'Envio gratis', subtitle: 'Pedidos mayores a S/90'),
];

const marketplaceProducts = <MarketplaceProduct>[
  MarketplaceProduct(
    id: 'pisco_acholado',
    name: 'Pisco Acholado Reserva',
    price: 84.90,
    brand: 'Tabernero',
    category: 'Destilados',
  ),
  MarketplaceProduct(
    id: 'whisky_12',
    name: 'Whisky 12 anos',
    price: 149.90,
    brand: 'Johnnie Walker',
    category: 'Destilados',
  ),
  MarketplaceProduct(
    id: 'vino_malbec',
    name: 'Vino Malbec Edicion',
    price: 69.90,
    brand: 'Trapiche',
    category: 'Vinos',
  ),
  MarketplaceProduct(
    id: 'cusquena_dorada',
    name: 'Cusquena Dorada 6 pack',
    price: 32.90,
    brand: 'Cusquena',
    category: 'Cervezas',
  ),
  MarketplaceProduct(
    id: 'pilsen_12pack',
    name: 'Pilsen 12 pack',
    price: 58.50,
    brand: 'Pilsen',
    category: 'Cervezas',
  ),
  MarketplaceProduct(
    id: 'lays_classic',
    name: 'Lays Classic',
    price: 8.90,
    brand: 'Lays',
    category: 'Snacks',
  ),
];

const marketplaceBrands = <String>[
  'Cusquena',
  'Pilsen',
  'Heineken',
  'Johnnie Walker',
  'Tabernero',
  'Trapiche',
  'Lays',
];
