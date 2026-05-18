import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/l10n/app_l10n.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/pharmacy_provider.dart';

// Uzbekistan bounding box
const _uzSW = Point(latitude: 37.1, longitude: 55.9);
const _uzNE = Point(latitude: 45.6, longitude: 73.2);

class LocationPickerScreen extends ConsumerStatefulWidget {
  /// When provided, "Save" returns the address via this callback instead of
  /// calling the pharmacy profile API. Used for admin business address editing.
  final void Function(String address)? onAddressPicked;
  final String? initialAddress;

  /// When true, after saving clears the requiresLocation flag so the router
  /// redirects to /pharmacy/orders automatically.
  final bool isSetupMode;

  const LocationPickerScreen({
    super.key,
    this.onAddressPicked,
    this.initialAddress,
    this.isSetupMode = false,
  });

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  YandexMapController? _mapController;
  Point _center = const Point(latitude: 41.2995, longitude: 69.2401);
  String _address = '';
  bool _isGeocoding = false;
  bool _isSaving = false;
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  List<SuggestItem> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.onAddressPicked != null) {
      _address = widget.initialAddress ?? '';
    } else {
      final profile = ref.read(pharmacyProfileProvider).profile;
      if (profile?.lat != null && profile?.lng != null) {
        _center = Point(latitude: profile!.lat!, longitude: profile.lng!);
        _address = profile.address ?? '';
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _onCameraPositionChanged(
    CameraPosition position,
    CameraUpdateReason reason,
    bool finished,
  ) async {
    setState(() => _center = position.target);
    if (finished && !_isGeocoding) {
      await _reverseGeocode(position.target);
    }
  }

  Future<void> _reverseGeocode(Point point) async {
    setState(() => _isGeocoding = true);
    try {
      final sessionPair = await YandexSearch.searchByPoint(
        point: point,
        zoom: 18,
        searchOptions: const SearchOptions(searchType: SearchType.geo),
      );
      final result = await sessionPair.$2;
      final items = result.items;
      if (items != null && items.isNotEmpty && mounted) {
        final addr =
            items.first.toponymMetadata?.address.formattedAddress ?? '';
        setState(() => _address = addr);
      }
    } catch (_) {}
    if (mounted) setState(() => _isGeocoding = false);
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _getSuggestions(query.trim());
    });
  }

  Future<void> _getSuggestions(String query) async {
    try {
      final sessionPair = await YandexSuggest.getSuggestions(
        text: query,
        boundingBox: const BoundingBox(northEast: _uzNE, southWest: _uzSW),
        suggestOptions: const SuggestOptions(
          suggestType: SuggestType.geo,
          userPosition: Point(latitude: 41.2995, longitude: 69.2401),
        ),
      );
      final result = await sessionPair.$2;
      if (mounted) {
        setState(() {
          _suggestions = result.items ?? [];
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (_) {}
  }

  Future<void> _onSuggestionTap(SuggestItem item) async {
    _searchController.text = item.displayText;
    _searchFocus.unfocus();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    if (item.center != null) {
      await _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: item.center!, zoom: 16),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 0.5,
        ),
      );
    } else {
      await _searchAddress(item.searchText);
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final sessionPair = await YandexSearch.searchByText(
        searchText: query,
        geometry: Geometry.fromBoundingBox(
          const BoundingBox(northEast: _uzNE, southWest: _uzSW),
        ),
        searchOptions: const SearchOptions(
          searchType: SearchType.geo,
          resultPageSize: 1,
        ),
      );
      final result = await sessionPair.$2;
      final items = result.items;
      if (items != null && items.isNotEmpty) {
        for (final geo in items.first.geometry) {
          if (geo.point != null) {
            await _mapController?.moveCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: geo.point!, zoom: 15),
              ),
              animation: const MapAnimation(
                type: MapAnimationType.smooth,
                duration: 0.5,
              ),
            );
            break;
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _goToMyLocation() async {
    try {
      bool enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Включите службы геолокации')),
          );
        }
        return;
      }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final point = Point(latitude: pos.latitude, longitude: pos.longitude);
      await _mapController?.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: point, zoom: 16),
        ),
        animation: const MapAnimation(
          type: MapAnimationType.smooth,
          duration: 0.5,
        ),
      );
    } catch (_) {}
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (widget.onAddressPicked != null) {
      widget.onAddressPicked!(
          _address.isNotEmpty ? _address : '${_center.latitude}, ${_center.longitude}');
      if (mounted) Navigator.pop(context);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ApiClient.instance.put('/pharmacy/location', data: {
        'lat': _center.latitude,
        'lng': _center.longitude,
        if (_address.isNotEmpty) 'address': _address,
      });
      await ref.read(pharmacyProfileProvider.notifier).load();
      if (widget.isSetupMode) {
        await ref.read(authStateProvider.notifier).clearRequiresLocation();
        if (mounted) setState(() => _isSaving = false);
        return;
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.locationSaved)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.locationError)),
        );
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.locationTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                hintText: l10n.searchAddress,
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _suggestions = [];
                            _showSuggestions = false;
                          });
                        },
                      )
                    : null,
              ),
              onSubmitted: (q) {
                setState(() {
                  _suggestions = [];
                  _showSuggestions = false;
                });
                _searchAddress(q);
              },
              onChanged: (q) {
                setState(() {});
                _onSearchChanged(q);
              },
              textInputAction: TextInputAction.search,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Map
          YandexMap(
            onMapCreated: (controller) async {
              _mapController = controller;
              await controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(target: _center, zoom: 14),
                ),
              );
            },
            onCameraPositionChanged: _onCameraPositionChanged,
          ),

          // Center pin
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_pin, color: AppColors.primary, size: 48),
                SizedBox(height: 40),
              ],
            ),
          ),

          // Suggestions overlay
          if (_showSuggestions)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                elevation: 4,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4,
                  ),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: _suggestions.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, i) {
                      final item = _suggestions[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.location_on_outlined,
                            color: AppColors.primary, size: 20),
                        title: Text(item.title,
                            style:
                                Theme.of(context).textTheme.bodyMedium),
                        subtitle: item.subtitle != null && item.subtitle!.isNotEmpty
                            ? Text(item.subtitle!,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)
                            : null,
                        onTap: () { HapticService.selection(); _onSuggestionTap(item); },
                      );
                    },
                  ),
                ),
              ),
            ),

          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isGeocoding
                            ? Text(l10n.determiningAddress,
                                style: Theme.of(context).textTheme.bodyMedium)
                            : Text(
                                _address.isEmpty
                                    ? l10n.unknownAddress
                                    : _address,
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text(
                      '${_center.latitude.toStringAsFixed(6)}, ${_center.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    label: l10n.confirmLocation,
                    isLoading: _isSaving,
                    onPressed: _save,
                  ),
                ],
              ),
            ),
          ),

          // My location FAB
          Positioned(
            right: 16,
            bottom: 200,
            child: FloatingActionButton.small(
              onPressed: () { HapticService.light(); _goToMyLocation(); },
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: AppColors.primary,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
