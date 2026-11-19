import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/navigation/wask_routes.dart';
import '../../../core/theme/wask_theme.dart';
import '../../shared/models/app_models.dart';
import '../../shared/providers/app_state_provider.dart';
import '../../shop/providers/cart_provider.dart';
import '../../suppliers/data/suppliers_service.dart';

class _PaymentOption {
  const _PaymentOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    this.badge,
  });

  final String id;
  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final String? badge;
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.deliveryInstruction,
  });

  final String deliveryInstruction;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const String _fallbackWalletNumber = '999 888 777';

  static const List<_PaymentOption> _paymentOptions = <_PaymentOption>[
    _PaymentOption(
      id: 'Yape',
      title: 'Yape',
      subtitle: 'Pago al instante con QR o celular WASK',
      accentColor: WaskColors.yapeLavender,
      icon: Icons.qr_code_2_rounded,
      badge: 'Rapido',
    ),
    _PaymentOption(
      id: 'Plin',
      title: 'Plin',
      subtitle: 'Transferencia inmediata sin comision',
      accentColor: WaskColors.plinCyan,
      icon: Icons.bolt_rounded,
      badge: 'Inmediato',
    ),
    _PaymentOption(
      id: 'Efectivo contra entrega',
      title: 'Efectivo contra entrega',
      subtitle: 'Paga en soles al recibir al motorizado',
      accentColor: WaskColors.emerald,
      icon: Icons.payments_outlined,
    ),
    _PaymentOption(
      id: 'POS / Tarjeta',
      title: 'POS / Tarjeta',
      subtitle: 'Visa, Mastercard o Amex en tu puerta',
      accentColor: WaskColors.electricBlue,
      icon: Icons.credit_card_rounded,
    ),
  ];

  String _selectedPayment = 'Yape';
  bool _confirmAdult = true;
  final _couponController = TextEditingController();
  final _paymentOpController = TextEditingController();
  String _receiptType = 'Boleta simple';
  final _docController = TextEditingController();
  bool _isSubmitting = false;
  Supplier? _storeSupplier;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStorePaymentInfo());
  }

  Future<void> _loadStorePaymentInfo() async {
    if (AppConfig.enableMocks || !mounted) return;
    final cart = context.read<CartProvider>();
    final appState = context.read<AppStateProvider>();
    final storeId = cart.itemList
        .map((i) => i.supplierId)
        .whereType<String>()
        .firstWhere((id) => id.isNotEmpty, orElse: () => '');
    if (storeId.isEmpty || !appState.isAuthenticated) return;
    try {
      final shops =
          await SuppliersService(apiClient: appState.apiClient).getSuppliers();
      if (!mounted) return;
      for (final s in shops) {
        if (s.id == storeId) {
          setState(() => _storeSupplier = s);
          break;
        }
      }
    } catch (_) {
      // Fallback limpio al numero WASK si no carga
    }
  }

  @override
  void dispose() {
    _couponController.dispose();
    _paymentOpController.dispose();
    _docController.dispose();
    super.dispose();
  }

  bool get _isDigitalWallet =>
      _selectedPayment == 'Yape' || _selectedPayment == 'Plin';

  String get _resolvedWalletNumber {
    if (_selectedPayment == 'Plin' &&
        (_storeSupplier?.plinNumber ?? '').trim().isNotEmpty) {
      return _storeSupplier!.plinNumber!.trim();
    }
    if ((_storeSupplier?.yapeNumber ?? '').trim().isNotEmpty) {
      return _storeSupplier!.yapeNumber!.trim();
    }
    return _fallbackWalletNumber;
  }

  Future<void> _copyWaskNumber() async {
    final cleanDigits = _resolvedWalletNumber.replaceAll(' ', '');
    await Clipboard.setData(ClipboardData(text: cleanDigits));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Numero $_selectedPayment $_resolvedWalletNumber copiado.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final appState = context.watch<AppStateProvider>();

    final subtotal = cart.subtotal;
    final hasLoyaltyReward =
        appState.loyaltyStatus?.hasFreeDeliveryReward == true;
    final delivery = appState.calculateDeliveryFee(subtotal);
    final discount =
        _couponController.text.trim().toUpperCase() == 'WASK10' ? 10.0 : 0.0;
    final total = (subtotal + delivery - discount).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar pedido')),
      body: appState.selectedAddress == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No hay direccion seleccionada.',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text('Selecciona una direccion para continuar.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        WaskRoutes.addressSelect,
                      ),
                      child: const Text('Ir a direcciones'),
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _Section(
                      title: 'Entrega en Lima',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: WaskColors.electricBlue, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${appState.selectedAddress!.label} · ${appState.selectedAddress!.district}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            appState.selectedAddress!.formattedFullAddress,
                            style: const TextStyle(
                              color: WaskColors.secondaryText,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Tiempo estimado: 20-30 min',
                            style: TextStyle(
                              color: WaskColors.iceBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Metodo de pago peruano',
                      child: Column(
                        children: [
                          ..._paymentOptions.map((option) {
                            final selected = _selectedPayment == option.id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  setState(() {
                                    _selectedPayment = option.id;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? option.accentColor.withOpacity(0.14)
                                        : WaskColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selected
                                          ? option.accentColor
                                          : WaskColors.border,
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: option.accentColor
                                              .withOpacity(0.18),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          option.icon,
                                          color: option.accentColor,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    option.title,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                if (option.badge != null) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 7,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: option.accentColor
                                                          .withOpacity(0.22),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              999),
                                                    ),
                                                    child: Text(
                                                      option.badge!,
                                                      style: TextStyle(
                                                        color:
                                                            option.accentColor,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              option.subtitle,
                                              style: const TextStyle(
                                                color: WaskColors.secondaryText,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        selected
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        color: selected
                                            ? option.accentColor
                                            : WaskColors.secondaryText,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                          if (_isDigitalWallet)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (_selectedPayment == 'Yape'
                                        ? WaskColors.yapeLavender
                                        : WaskColors.plinCyan)
                                    .withOpacity(0.10),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (_selectedPayment == 'Yape'
                                          ? WaskColors.yapeLavender
                                          : WaskColors.plinCyan)
                                      .withOpacity(0.45),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.phone_iphone_rounded,
                                        color: _selectedPayment == 'Yape'
                                            ? WaskColors.yapeLavender
                                            : WaskColors.plinCyan,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '$_selectedPayment · $_resolvedWalletNumber',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                                fontFeatures: <FontFeature>[
                                                  FontFeature.tabularFigures(),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _storeSupplier != null
                                                  ? 'Paga a ${_storeSupplier!.name} y anota el N° de operacion.'
                                                  : 'Confirma tu pedido y realiza el pago al numero indicado.',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: WaskColors.secondaryText,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        onPressed: _copyWaskNumber,
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10, vertical: 8),
                                        ),
                                        child: const Text(
                                          'Copiar',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  TextField(
                                    controller: _paymentOpController,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      hintText:
                                          'N° operacion o nombre quien paga (opcional)',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Comprobante',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: const <String>[
                              'Boleta simple',
                              'Boleta (DNI)',
                              'Factura (RUC)',
                            ].map((kind) {
                              final selected = _receiptType == kind;
                              return ChoiceChip(
                                label: Text(kind),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() => _receiptType = kind);
                                },
                              );
                            }).toList(),
                          ),
                          if (_receiptType != 'Boleta simple') ...[
                            const SizedBox(height: 10),
                            TextField(
                              controller: _docController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: _receiptType == 'Factura (RUC)'
                                    ? 'Ingresa tu RUC (11 digitos)'
                                    : 'Ingresa tu DNI (8 digitos, opcional)',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Cupon de descuento',
                      child: TextField(
                        controller: _couponController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Ingresa tu cupon (ej: WASK10)',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _Section(
                      title: 'Detalle de pago',
                      child: Column(
                        children: [
                          _TotalRow(label: 'Subtotal', value: subtotal),
                          if (hasLoyaltyReward)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: WaskColors.emerald,
                                  ),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Delivery Gratis (Fidelizacion 10 pedidos)',
                                      style: TextStyle(
                                        color: WaskColors.emerald,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'S/ 0.00',
                                    style: TextStyle(
                                      color: WaskColors.emerald,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: <FontFeature>[
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (subtotal >= 80)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Delivery Gratis (compra >= S/ 80)',
                                      style: TextStyle(
                                        color: WaskColors.emerald,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'S/ 0.00',
                                    style: TextStyle(
                                      color: WaskColors.emerald,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: <FontFeature>[
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            _TotalRow(label: 'Costo de envio', value: delivery),
                          _TotalRow(label: 'Descuento', value: -discount),
                          const Divider(),
                          _TotalRow(
                              label: 'Total', value: total, isTotal: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: WaskColors.surface,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: WaskColors.border),
                      ),
                      child: SwitchListTile(
                        value: _confirmAdult,
                        activeColor: WaskColors.emerald,
                        onChanged: (val) {
                          setState(() {
                            _confirmAdult = val;
                          });
                        },
                        title: const Text(
                          'Confirmo tener +18 años al recibir el pedido',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: cart.itemList.isEmpty || _isSubmitting
                          ? null
                          : () => _submitOrder(
                                cart: cart,
                                subtotal: subtotal,
                                delivery: delivery,
                                discount: discount,
                                applyLoyaltyReward: hasLoyaltyReward,
                              ),
                      child: Text(
                        _isSubmitting
                            ? 'Procesando pedido...'
                            : 'Confirmar y pagar con $_selectedPayment',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submitOrder({
    required CartProvider cart,
    required double subtotal,
    required double delivery,
    required double discount,
    required bool applyLoyaltyReward,
  }) async {
    if (!_confirmAdult) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes confirmar ser mayor de 18 años para recibir bebidas alcoholicas.',
          ),
        ),
      );
      return;
    }

    final docText = _docController.text.trim();
    if (_receiptType == 'Factura (RUC)' &&
        !RegExp(r'^\d{11}$').hasMatch(docText)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Ingresa un RUC valido de exactamente 11 digitos numericos (ej. 20... o 10...).',
            ),
          ),
        );
      return;
    }

    if (_receiptType == 'Boleta (DNI)' &&
        docText.isNotEmpty &&
        !RegExp(r'^\d{8}$').hasMatch(docText)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Si ingresas DNI para tu boleta, debe tener exactamente 8 digitos numericos.',
            ),
          ),
        );
      return;
    }

    final appState = context.read<AppStateProvider>();
    // La tienda a la que se compra viene en cada item del carrito
    // (supplierId = businessId del backend).
    final storeIds = cart.itemList
        .map((item) => item.supplierId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    if (storeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar la tienda del pedido.'),
        ),
      );
      return;
    }

    if (storeIds.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El carrito tiene productos de varias tiendas. Deja productos de una sola tienda.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final items = cart.itemList
        .map(
          (item) => OrderLine(
            productId: item.productId,
            name: item.name,
            price: item.price,
            quantity: item.quantity,
          ),
        )
        .toList();

    final opText = _paymentOpController.text.trim();
    final noteParts = <String>[
      if (widget.deliveryInstruction.trim().isNotEmpty)
        widget.deliveryInstruction.trim(),
      if (_isDigitalWallet && opText.isNotEmpty) '[Pago Op: $opText]',
      if (_receiptType != 'Boleta simple')
        '[Comprobante: $_receiptType${docText.isNotEmpty ? ' - $docText' : ''}]',
    ];

    final order = await appState.placeOrder(
      items: items,
      storeName: cart.itemList.first.storeName ?? 'Licoreria Aliada WASK',
      paymentMethod: _selectedPayment,
      subtotal: subtotal,
      deliveryCost: delivery,
      discount: discount,
      deliveryNote: noteParts.join(' · '),
      businessId: storeIds.first,
      applyLoyaltyReward: applyLoyaltyReward,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    if (order == null) {
      final message =
          appState.errorMessage ?? 'No se pudo crear el pedido.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    if (!AppConfig.enableMocks) {
      await appState.loadOrders();
    }

    if (!mounted) {
      return;
    }

    context.read<CartProvider>().clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pedido creado con exito.')),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      WaskRoutes.orders,
      (route) => false,
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: WaskColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: WaskColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final double value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final normalized = value.abs() < 0.005 ? 0.0 : value;
    final formatted = normalized < 0
        ? '- S/ ${(-normalized).toStringAsFixed(2)}'
        : 'S/ ${normalized.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatted,
            style: TextStyle(
              color: isTotal ? WaskColors.energyOrange : Colors.white,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
