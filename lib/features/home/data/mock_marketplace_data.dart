class MarketplaceCategory {
  const MarketplaceCategory({required this.label, required this.iconName});

  final String label;
  final String iconName;
}

class MarketplaceStore {
  const MarketplaceStore({
    required this.id,
    required this.name,
    required this.rating,
    required this.eta,
    required this.district,
    required this.address,
    required this.phone,
  });

  final String id;
  final String name;
  final String rating;
  final String eta;
  final String district;
  final String address;
  final String phone;
}

class MarketplaceProduct {
  const MarketplaceProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.brand,
    required this.category,
    required this.supplierId,
    required this.storeName,
    this.availableStock = 24,
    this.volumeMl,
    this.warehouseNames = const <String>['Almacen Central'],
  });

  final String id;
  final String name;
  final double price;
  final String brand;
  final String category;
  final String supplierId;
  final String storeName;
  final int availableStock;
  final int? volumeMl;
  final List<String> warehouseNames;
}

class MarketplacePromo {
  const MarketplacePromo({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

const marketplaceCategories = <MarketplaceCategory>[
  MarketplaceCategory(label: 'Cerveza', iconName: 'sports_bar'),
  MarketplaceCategory(label: 'Pisco', iconName: 'local_bar'),
  MarketplaceCategory(label: 'Whisky', iconName: 'local_bar'),
  MarketplaceCategory(label: 'Vino', iconName: 'wine_bar'),
  MarketplaceCategory(label: 'Ron', iconName: 'local_bar'),
  MarketplaceCategory(label: 'Hielo', iconName: 'ac_unit'),
];

const marketplaceStores = <MarketplaceStore>[
  MarketplaceStore(
    id: 'mock-0',
    name: 'Licoreria Demo Wask',
    rating: '4.9',
    eta: '18-24 min',
    district: 'Miraflores',
    address: 'Av. Larco 123, Miraflores, Lima',
    phone: '+51 1 234 5678',
  ),
  MarketplaceStore(
    id: 'mock-1',
    name: 'Licoreria El Tambo Peruano',
    rating: '4.8',
    eta: '20-26 min',
    district: 'San Isidro',
    address: 'Av. Javier Prado Este 890, San Isidro',
    phone: '+51 1 442 8890',
  ),
];

const marketplacePromos = <MarketplacePromo>[
  MarketplacePromo(title: '2x1 en cervezas', subtitle: 'Solo hoy noche WASK'),
  MarketplacePromo(
      title: 'S/ 10 off con WASK10', subtitle: 'Aplica en tu checkout'),
  MarketplacePromo(title: 'Envio gratis', subtitle: 'Desde S/ 80 o 10 pedidos'),
];

const marketplaceProducts = <MarketplaceProduct>[
  MarketplaceProduct(
    id: 'pilsen_630',
    name: 'Cerveza Pilsen 630ml',
    price: 5.50,
    brand: 'Pilsen Callao',
    category: 'Cerveza',
    supplierId: 'mock-0',
    storeName: 'Licoreria Demo Wask',
    availableStock: 42,
    volumeMl: 630,
    warehouseNames: ['Almacen Central Demo', 'Sucursal Lince'],
  ),
  MarketplaceProduct(
    id: 'cristal_1l',
    name: 'Cerveza Cristal 1L',
    price: 8.50,
    brand: 'Cristal',
    category: 'Cerveza',
    supplierId: 'mock-0',
    storeName: 'Licoreria Demo Wask',
    availableStock: 30,
    volumeMl: 1000,
    warehouseNames: ['Almacen Central Demo'],
  ),
  MarketplaceProduct(
    id: 'cusquena_trigo',
    name: 'Cerveza Cusquena Trigo 620ml',
    price: 7.20,
    brand: 'Cusquena',
    category: 'Cerveza',
    supplierId: 'mock-0',
    storeName: 'Licoreria Demo Wask',
    availableStock: 26,
    volumeMl: 620,
    warehouseNames: ['Sucursal Lince'],
  ),
  MarketplaceProduct(
    id: 'pisco_quebranta',
    name: 'Pisco Quebranta 750ml',
    price: 45.00,
    brand: 'Tabernero',
    category: 'Pisco',
    supplierId: 'mock-0',
    storeName: 'Licoreria Demo Wask',
    availableStock: 18,
    volumeMl: 750,
    warehouseNames: ['Almacen Central Demo'],
  ),
  MarketplaceProduct(
    id: 'whisky_red',
    name: 'Whisky Johnnie Walker Red 750ml',
    price: 119.90,
    brand: 'Johnnie Walker',
    category: 'Whisky',
    supplierId: 'mock-1',
    storeName: 'Licoreria El Tambo Peruano',
    availableStock: 14,
    volumeMl: 750,
    warehouseNames: ['Almacen San Isidro'],
  ),
  MarketplaceProduct(
    id: 'vino_tinto',
    name: 'Vino Tinto Malbec 750ml',
    price: 38.00,
    brand: 'Santiago Queirolo',
    category: 'Vino',
    supplierId: 'mock-1',
    storeName: 'Licoreria El Tambo Peruano',
    availableStock: 22,
    volumeMl: 750,
    warehouseNames: ['Almacen San Isidro'],
  ),
  MarketplaceProduct(
    id: 'ron_cartavio',
    name: 'Ron Cartavio Black 750ml',
    price: 42.90,
    brand: 'Cartavio',
    category: 'Ron',
    supplierId: 'mock-1',
    storeName: 'Licoreria El Tambo Peruano',
    availableStock: 19,
    volumeMl: 750,
    warehouseNames: ['Almacen San Isidro'],
  ),
  MarketplaceProduct(
    id: 'hielo_3kg',
    name: 'Bolsa de Hielo Gourmet 3kg',
    price: 6.50,
    brand: 'WASK Ice',
    category: 'Hielo',
    supplierId: 'mock-0',
    storeName: 'Licoreria Demo Wask',
    availableStock: 60,
    volumeMl: 3000,
    warehouseNames: ['Almacen Central Demo', 'Sucursal Lince'],
  ),
];

const marketplaceBrands = <String>[
  'Pilsen',
  'Cristal',
  'Cusquena',
  'Pisco',
  'Whisky',
  'Hielo',
];
