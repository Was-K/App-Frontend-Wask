import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/navigation/wask_routes.dart';
import '../../../core/services/geolocation_service.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/models/app_models.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shared/widgets/wask_osm_map.dart';
import '../../suppliers/data/suppliers_service.dart';

class _LimaStreetSuggestion {
  const _LimaStreetSuggestion({
    required this.street,
    required this.district,
    required this.latitude,
    required this.longitude,
  });

  final String street;
  final String district;
  final double latitude;
  final double longitude;
}

class AddressSelectionScreen extends StatefulWidget {
  const AddressSelectionScreen({
    super.key,
    this.geolocationService,
  });

  final GeolocationService? geolocationService;

  @override
  State<AddressSelectionScreen> createState() => _AddressSelectionScreenState();
}

class _AddressSelectionScreenState extends State<AddressSelectionScreen> {
  static const List<String> _labels = <String>[
    'Casa',
    'Oficina',
    'Reunión',
    'Otro',
  ];

  static const List<String> _districts = <String>[
    'Miraflores',
    'San Isidro',
    'Lince',
    'Jesus Maria',
    'Barranco',
    'Surco',
    'San Borja',
    'Magdalena',
    'Pueblo Libre',
    'San Miguel',
    'La Molina',
  ];

  static const List<_LimaStreetSuggestion> _streetSuggestions =
      <_LimaStreetSuggestion>[
    _LimaStreetSuggestion(
      street: 'Av. José Larco 450',
      district: 'Miraflores',
      latitude: -12.1211,
      longitude: -77.0293,
    ),
    _LimaStreetSuggestion(
      street: 'Av. Pardo y Aliaga 640',
      district: 'San Isidro',
      latitude: -12.0992,
      longitude: -77.0365,
    ),
    _LimaStreetSuggestion(
      street: 'Av. Javier Prado Este 890',
      district: 'San Isidro',
      latitude: -12.0910,
      longitude: -77.0226,
    ),
    _LimaStreetSuggestion(
      street: 'Jr. Risso 240',
      district: 'Lince',
      latitude: -12.0852,
      longitude: -77.0355,
    ),
    _LimaStreetSuggestion(
      street: 'Av. Arenales 1450',
      district: 'Lince',
      latitude: -12.0804,
      longitude: -77.0351,
    ),
    _LimaStreetSuggestion(
      street: 'Av. Salaverry 1620',
      district: 'Jesus Maria',
      latitude: -12.0752,
      longitude: -77.0498,
    ),
    _LimaStreetSuggestion(
      street: 'Av. Pedro de Osma 320',
      district: 'Barranco',
      latitude: -12.1449,
      longitude: -77.0218,
    ),
    _LimaStreetSuggestion(
      street: 'Av. Caminos del Inca 1200',
      district: 'Surco',
      latitude: -12.1292,
      longitude: -76.9918,
    ),
    _LimaStreetSuggestion(
      street: 'Av. San Borja Norte 550',
      district: 'San Borja',
      latitude: -12.0942,
      longitude: -76.9994,
    ),
    _LimaStreetSuggestion(
      street: 'Av. Brasil 3400',
      district: 'Magdalena',
      latitude: -12.0908,
      longitude: -77.0715,
    ),
    _LimaStreetSuggestion(
      street: 'Av. Antonio José de Sucre 780',
      district: 'Pueblo Libre',
      latitude: -12.0785,
      longitude: -77.0622,
    ),
  ];

  final _streetController = TextEditingController();
  final _interiorController = TextEditingController();
  final _intercomController = TextEditingController();
  final _referenceController = TextEditingController();
  final _phoneController = TextEditingController();

  late final GeolocationService _geolocationService;

  int _step = 0;
  String _label = 'Casa';
  String _district = 'Miraflores';
  double _pinLat = -12.1211;
  double _pinLng = -77.0293;
  int _mapZoom = 15;
  bool _isLocatingGps = false;
  bool _isSaving = false;
  List<Supplier> _suppliers = <Supplier>[];

  @override
  void initState() {
    super.initState();
    _geolocationService = widget.geolocationService ?? GeolocationService();
    _loadNearbySuppliers();
  }

  @override
  void dispose() {
    _streetController.dispose();
    _interiorController.dispose();
    _intercomController.dispose();
    _referenceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadNearbySuppliers() async {
    if (AppConfig.enableMocks) {
      return;
    }
    final appState = context.read<AppStateProvider>();
    if (!appState.isAuthenticated) {
      return;
    }
    try {
      final list =
          await SuppliersService(apiClient: appState.apiClient).getSuppliers();
      if (mounted) {
        setState(() {
          _suppliers = list;
        });
      }
    } catch (_) {
      // Silencioso si aun no hay sesion o conectividad en pruebas.
    }
  }

  int _nearbyStoreCount() {
    if (_suppliers.isEmpty) {
      return 2;
    }
    var nearby = 0;
    for (final s in _suppliers) {
      if (s.latitude != null && s.longitude != null) {
        final dist = GeolocationService.distanceKm(
          _pinLat,
          _pinLng,
          s.latitude!,
          s.longitude!,
        );
        if (dist <= 8.0) {
          nearby++;
        }
      } else {
        nearby++;
      }
    }
    return nearby > 0 ? nearby : _suppliers.length;
  }

  Future<void> _useCurrentGps() async {
    setState(() {
      _isLocatingGps = true;
    });
    try {
      final geo = await _geolocationService.getCurrentLocation();
      if (!mounted) {
        return;
      }
      final inferred = geo.district ??
          GeolocationService.inferLimaDistrict(geo.latitude, geo.longitude);
      setState(() {
        _pinLat = geo.latitude;
        _pinLng = geo.longitude;
        _district = _districts.contains(inferred) ? inferred : 'Miraflores';
        if (_streetController.text.trim().isEmpty) {
          _streetController.text = 'Ubicación actual (GPS)';
        }
        _step = 1;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = error is StateError
          ? error.message
          : 'Activa el permiso de ubicacion en tu dispositivo o escribe tu calle.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocatingGps = false;
        });
      }
    }
  }

  void _selectSuggestion(_LimaStreetSuggestion suggestion) {
    setState(() {
      _streetController.text = suggestion.street;
      _district = suggestion.district;
      _pinLat = suggestion.latitude;
      _pinLng = suggestion.longitude;
      _step = 1;
    });
  }

  void _goToMapVerificationFromText() {
    final street = _streetController.text.trim();
    if (street.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe tu calle o avenida en Lima para continuar.'),
        ),
      );
      return;
    }
    final fallback =
        GeolocationService.fallbackCoordinatesForDistrict(_district);
    setState(() {
      _pinLat = fallback.latitude;
      _pinLng = fallback.longitude;
      _step = 1;
    });
  }

  Future<void> _selectSavedAndFinish(DeliveryAddress address) async {
    await context.read<AppStateProvider>().selectAddress(address.id);
    if (!mounted) {
      return;
    }
    _exitToHomeOrBack();
  }

  Future<void> _saveAndOpenStores() async {
    final street = _streetController.text.trim();
    if (street.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una calle o avenida valida.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    await context.read<AppStateProvider>().addAddress(
          label: _label,
          street: street,
          district: _district,
          apartmentOrInterior: _interiorController.text,
          intercom: _intercomController.text,
          reference: _referenceController.text,
          contactPhone: _phoneController.text,
          latitude: _pinLat,
          longitude: _pinLng,
        );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Direccion guardada.')),
    );
    _exitToHomeOrBack();
  }

  void _exitToHomeOrBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushReplacementNamed(context, WaskRoutes.home);
  }

  List<_LimaStreetSuggestion> _filteredSuggestions() {
    final query = _streetController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _streetSuggestions.take(5).toList();
    }
    return _streetSuggestions
        .where((s) =>
            s.street.toLowerCase().contains(query) ||
            s.district.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle()),
        leading: _step > 0
            ? IconButton(
                tooltip: 'Volver',
                onPressed: () {
                  setState(() {
                    _step -= 1;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded),
              )
            : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Row(
                    children: List.generate(3, (index) {
                      final active = index <= _step;
                      return Expanded(
                        child: Container(
                          height: 4,
                          margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: active
                                ? WaskColors.electricBlue
                                : WaskColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: switch (_step) {
                    0 => _buildStepOneSearch(appState),
                    1 => _buildStepTwoMap(),
                    _ => _buildStepThreeDetails(),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case 1:
        return 'Verifica tu ubicación';
      case 2:
        return 'Detalles para el motorizado';
      case 0:
      default:
        return 'Tu dirección en Lima';
    }
  }

  Widget _buildStepOneSearch(AppStateProvider appState) {
    final suggestions = _filteredSuggestions();
    final typedStreet = _streetController.text.trim();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '¿A dónde llevamos tu pedido?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'Mostraremos las licorerías más cercanas a tu dirección en Lima.',
          style: TextStyle(color: WaskColors.secondaryText, fontSize: 13),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLocatingGps ? null : _useCurrentGps,
            icon: _isLocatingGps
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(
              _isLocatingGps
                  ? 'Obteniendo ubicacion GPS...'
                  : 'Usar mi ubicación actual (GPS)',
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _streetController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: 'Escribe tu calle o avenida en Lima',
            hintText: 'Ej: Av. Larco 450, Miraflores',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: typedStreet.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      _streetController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close_rounded),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: _district,
          items: _districts
              .map(
                (district) => DropdownMenuItem(
                  value: district,
                  child: Text(district),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _district = value;
            });
          },
          decoration: const InputDecoration(
            labelText: 'Distrito (Lima)',
            prefixIcon: Icon(Icons.map_outlined),
          ),
        ),
        if (typedStreet.isNotEmpty) ...[
          const SizedBox(height: 10),
          Material(
            color: WaskColors.electricBlue.withOpacity(0.14),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: WaskColors.electricBlue.withOpacity(0.45),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.add_location_alt_rounded,
                  color: WaskColors.electricBlue),
              title: Text(
                'Ubicar "$typedStreet"',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('Distrito: $_district'),
              trailing: const Icon(Icons.arrow_forward_rounded),
              onTap: _goToMapVerificationFromText,
            ),
          ),
        ],
        const SizedBox(height: 14),
        const Text(
          'Calles sugeridas en Lima',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: WaskColors.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        ...suggestions.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: WaskColors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: WaskColors.border),
              ),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.place_outlined,
                    color: WaskColors.iceBlue),
                title: Text(
                  item.street,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  item.district,
                  style: const TextStyle(color: WaskColors.secondaryText),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _selectSuggestion(item),
              ),
            ),
          ),
        ),
        if (appState.addresses.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            'Direcciones guardadas',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ...appState.addresses.map(
            (address) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: WaskColors.surface,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: appState.selectedAddress?.id == address.id
                        ? WaskColors.electricBlue
                        : WaskColors.border,
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    appState.selectedAddress?.id == address.id
                        ? Icons.check_circle_rounded
                        : Icons.bookmark_outline_rounded,
                    color: appState.selectedAddress?.id == address.id
                        ? WaskColors.emerald
                        : WaskColors.electricBlue,
                  ),
                  title: Text(
                    '${address.label} · ${address.district}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    address.formattedFullAddress,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: WaskColors.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                  onTap: () => _selectSavedAndFinish(address),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepTwoMap() {
    final nearbyCount = _nearbyStoreCount();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _step = 0;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Volver'),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Arrastra el mapa para ajustar el pin exacto',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: WaskColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: WaskOsmMap(
            centerLat: _pinLat,
            centerLng: _pinLng,
            zoom: _mapZoom,
            onPanDelta: (delta) {
              final updated = WaskWebMercator.panCoordinates(
                centerLat: _pinLat,
                centerLng: _pinLng,
                zoom: _mapZoom,
                deltaPixels: delta,
              );
              final inferred = GeolocationService.inferLimaDistrict(
                updated.lat,
                updated.lng,
              );
              setState(() {
                _pinLat = updated.lat;
                _pinLng = updated.lng;
                if (_districts.contains(inferred)) {
                  _district = inferred;
                }
              });
            },
            onZoomIn: _mapZoom < 18
                ? () => setState(() => _mapZoom += 1)
                : null,
            onZoomOut: _mapZoom > 13
                ? () => setState(() => _mapZoom -= 1)
                : null,
            onRecenter: () {
              final fallback =
                  GeolocationService.fallbackCoordinatesForDistrict(_district);
              setState(() {
                _pinLat = fallback.latitude;
                _pinLng = fallback.longitude;
                _mapZoom = 15;
              });
            },
            topLeftBanner: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.84),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: WaskColors.emerald.withOpacity(0.6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.storefront_rounded,
                    size: 16,
                    color: WaskColors.emerald,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '$nearbyCount tiendas cerca de aquí',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: WaskColors.emerald,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            overlayBuilder: (context, viewportSize, _, __) => <Widget>[
              Center(
                child: IgnorePointer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.86),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: WaskColors.energyOrange.withOpacity(0.75),
                          ),
                        ),
                        child: Text(
                          _district,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Icon(
                        Icons.location_on_rounded,
                        size: 40,
                        color: WaskColors.energyOrange,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: WaskColors.surface,
            border: Border(top: BorderSide(color: WaskColors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_streetController.text.trim()} · $_district',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _step = 2;
                  });
                },
                child: const Text('Confirmar ubicación'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStepThreeDetails() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: WaskColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: WaskColors.electricBlue.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: WaskColors.electricBlue),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _streetController.text.trim(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      _district,
                      style: const TextStyle(
                        color: WaskColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _step = 1),
                child: const Text('Editar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Etiqueta',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: WaskColors.secondaryText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _labels.map((label) {
            final selected = _label == label;
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              selectedColor: WaskColors.electricBlue,
              backgroundColor: WaskColors.surface,
              side: BorderSide(
                color: selected ? WaskColors.electricBlue : WaskColors.border,
              ),
              labelStyle: TextStyle(
                color: selected ? Colors.white : WaskColors.secondaryText,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              onSelected: (_) {
                setState(() {
                  _label = label;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _interiorController,
          decoration: const InputDecoration(
            labelText: 'Piso / Dpto / Interior (opcional)',
            hintText: 'Ej: Dpto 402, Piso 4',
            prefixIcon: Icon(Icons.apartment_rounded),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _intercomController,
          decoration: const InputDecoration(
            labelText: 'Timbre / Portón (opcional)',
            hintText: 'Ej: Marcar 402 o porton negro',
            prefixIcon: Icon(Icons.notifications_none_rounded),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _referenceController,
          decoration: const InputDecoration(
            labelText: 'Referencia rápida',
            hintText: 'Ej: Frente al parque, edificio blanco',
            prefixIcon: Icon(Icons.near_me_outlined),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Celular de contacto',
            hintText: 'Ej: 999 888 777',
            prefixIcon: Icon(Icons.phone_android_rounded),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveAndOpenStores,
          child: Text(
            _isSaving
                ? 'Guardando...'
                : 'Guardar dirección y ver tiendas',
          ),
        ),
      ],
    );
  }
}
