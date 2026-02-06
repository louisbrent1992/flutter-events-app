import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../components/custom_app_bar.dart';
import '../components/event_poster_card.dart';
import '../components/glass_surface.dart';
import '../components/pill_chip.dart';
import '../models/event.dart';
import '../providers/discover_provider.dart';
import '../services/google_maps_service.dart' hide LatLng;
import '../theme/theme.dart';

/// Map screen with Google Maps integration.
///
/// Features:
/// - Real Google Maps with custom styling
/// - Event markers with info windows
/// - Bottom sheet with event cards
/// - Category filtering
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  GoogleMapController? _mapController;
  Event? _selectedEvent;
  Timer? _debounce;
  List<PlacePrediction> _placePredictions = [];
  bool _showPredictions = false;
  String? _sessionToken;
  bool _isLoadingLocation = false;

  // Filter chips that match SeatGeek event categories
  final List<String> _chips = const [
    'All',
    'Sports',
    'Concerts',
    'Theater',
    'Comedy',
  ];
  String _chip = 'All';

  // Default to a central US location, adjust based on your target
  static const LatLng _defaultCenter = LatLng(
    37.7749,
    -122.4194,
  ); // San Francisco

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final discover = context.read<DiscoverProvider>();
      if (!discover.isLoading && discover.events.isEmpty) {
        discover.load(page: 1, limit: 30);
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Search for places with debouncing
  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _placePredictions = [];
        _showPredictions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      // Generate session token for cost optimization
      _sessionToken ??= DateTime.now().millisecondsSinceEpoch.toString();

      final predictions = await GoogleMapsService.searchPlaces(
        query,
        sessionToken: _sessionToken,
      );

      if (mounted) {
        setState(() {
          _placePredictions = predictions;
          _showPredictions = predictions.isNotEmpty;
        });
      }
    });
  }

  /// Handle place selection from autocomplete
  Future<void> _selectPlace(PlacePrediction prediction) async {
    setState(() {
      _showPredictions = false;
      _search.text = prediction.mainText;
    });
    _searchFocus.unfocus();

    // Get place details to get coordinates
    final details = await GoogleMapsService.getPlaceDetails(
      prediction.placeId,
      sessionToken: _sessionToken,
    );

    // Clear session token after place selection (billing optimization)
    _sessionToken = null;

    if (details != null &&
        details.latitude != null &&
        details.longitude != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(details.latitude!, details.longitude!),
          14.0,
        ),
      );
    }
  }

  /// Open directions to a location
  Future<void> _openDirections(Event event) async {
    if (event.latitude == null || event.longitude == null) return;

    final url = GoogleMapsService.getDirectionsUrl(
      destinationLat: event.latitude!,
      destinationLng: event.longitude!,
      destinationName: event.venueName ?? event.title,
    );

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Navigate to user's current location
  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission permanently denied. Enable in Settings.',
              ),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          13.0,
        ),
      );
    } catch (e) {
      debugPrint('Location error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  /// Filter events by category chip
  bool _matchesChip(Event e) {
    if (_chip == 'All') return true;
    final categories = e.categories.map((c) => c.toLowerCase()).toList();

    switch (_chip) {
      case 'Sports':
        return categories.any(
          (c) =>
              c.contains('nfl') ||
              c.contains('nba') ||
              c.contains('mlb') ||
              c.contains('nhl') ||
              c.contains('ncaa') ||
              c.contains('soccer') ||
              c.contains('mls') ||
              c.contains('sports') ||
              c.contains('racing') ||
              c.contains('motocross') ||
              c.contains('boxing') ||
              c.contains('mma') ||
              c.contains('wrestling') ||
              c.contains('tennis') ||
              c.contains('golf'),
        );
      case 'Concerts':
        return categories.any(
          (c) =>
              c.contains('concert') ||
              c.contains('music') ||
              c.contains('festival') ||
              c.contains('rock') ||
              c.contains('pop') ||
              c.contains('hip_hop') ||
              c.contains('country') ||
              c.contains('jazz') ||
              c.contains('classical'),
        );
      case 'Theater':
        return categories.any(
          (c) =>
              c.contains('theater') ||
              c.contains('broadway') ||
              c.contains('musical') ||
              c.contains('opera') ||
              c.contains('ballet') ||
              c.contains('dance'),
        );
      case 'Comedy':
        return categories.any(
          (c) =>
              c.contains('comedy') ||
              c.contains('stand_up') ||
              c.contains('comedian'),
        );
      default:
        return true;
    }
  }

  /// Filter events that have valid coordinates
  List<Event> _eventsWithLocation(List<Event> events) {
    return events
        .where(_matchesChip)
        .where((e) => e.latitude != null && e.longitude != null)
        .toList();
  }

  /// Build markers from events
  Set<Marker> _buildMarkers(List<Event> events) {
    return events.map((event) {
      return Marker(
        markerId: MarkerId(event.id.isNotEmpty ? event.id : event.title),
        position: LatLng(event.latitude!, event.longitude!),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _selectedEvent?.id == event.id
              ? BitmapDescriptor.hueAzure
              : BitmapDescriptor.hueRed,
        ),
        onTap: () {
          setState(() => _selectedEvent = event);
          // Center the map on the selected event
          _mapController?.animateCamera(
            CameraUpdate.newLatLng(LatLng(event.latitude!, event.longitude!)),
          );
        },
      );
    }).toSet();
  }

  /// Calculate initial camera position based on events
  LatLng _calculateCenter(List<Event> events) {
    if (events.isEmpty) return _defaultCenter;

    double sumLat = 0;
    double sumLng = 0;
    for (final e in events) {
      sumLat += e.latitude!;
      sumLng += e.longitude!;
    }
    return LatLng(sumLat / events.length, sumLng / events.length);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const CustomAppBar(title: 'Map'),
      body: SafeArea(
        bottom: false,
        child: Consumer<DiscoverProvider>(
          builder: (context, discover, _) {
            final events = _eventsWithLocation(discover.events);
            final markers = _buildMarkers(events);
            final center = _calculateCenter(events);

            return Stack(
              children: [
                // Google Map
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: center,
                      zoom: 11.0,
                    ),
                    markers: markers,
                    style: isDark ? _darkMapStyle : null,
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                  ),
                ),

                // Top controls
                Positioned(
                  left: AppSpacing.responsive(context),
                  right: AppSpacing.responsive(context),
                  top: AppSpacing.responsive(
                    context,
                    mobile: 10,
                    tablet: 16,
                    desktop: 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassSurface(
                        blurSigma: 18,
                        borderRadius: BorderRadius.circular(AppRadii.xl),
                        padding: EdgeInsets.zero,
                        child: TextField(
                          controller: _search,
                          focusNode: _searchFocus,
                          decoration: InputDecoration(
                            hintText: 'Search places or venues...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon:
                                _search.text.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(Icons.close_rounded),
                                      onPressed: () {
                                        _search.clear();
                                        setState(() {
                                          _placePredictions = [];
                                          _showPredictions = false;
                                        });
                                      },
                                    )
                                    : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                          ),
                          onChanged: _onSearchChanged,
                          onSubmitted: (_) {
                            setState(() => _showPredictions = false);
                          },
                        ),
                      ),
                      // Places Autocomplete Dropdown
                      if (_showPredictions && _placePredictions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: GlassSurface(
                            blurSigma: 20,
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                            padding: EdgeInsets.zero,
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: _placePredictions.length,
                              itemBuilder: (context, i) {
                                final prediction = _placePredictions[i];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.location_on_outlined,
                                    color: scheme.primary,
                                    size: 20,
                                  ),
                                  title: Text(
                                    prediction.mainText,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    prediction.secondaryText,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => _selectPlace(prediction),
                                );
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _chips.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            final label = _chips[i];
                            return PillChip(
                              label: label,
                              selected: _chip == label && label != 'All',
                              onTap: () => setState(() => _chip = label),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // My Location button
                Positioned(
                  right: AppSpacing.responsive(context),
                  top: 180,
                  child: GlassSurface(
                    blurSigma: 18,
                    borderRadius: BorderRadius.circular(AppRadii.full),
                    padding: EdgeInsets.zero,
                    child: IconButton(
                      onPressed:
                          _isLoadingLocation ? null : _goToCurrentLocation,
                      icon:
                          _isLoadingLocation
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Icon(
                                Icons.my_location_rounded,
                                color: scheme.primary,
                              ),
                      tooltip: 'My Location',
                    ),
                  ),
                ),

                // Bottom event cards
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Selected event card or horizontal list
                      if (_selectedEvent != null) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.responsive(context),
                          ),
                          child: _buildSelectedEventCard(context),
                        ),
                        const SizedBox(height: 12),
                      ],
                      // Horizontal scrolling list of nearby events
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).padding.bottom + 80,
                        ),
                        child: SizedBox(
                          height: 140,
                          child: ListView.separated(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.responsive(context),
                            ),
                            scrollDirection: Axis.horizontal,
                            itemCount: events.length > 12 ? 12 : events.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final e = events[i];
                              final isSelected = _selectedEvent?.id == e.id;
                              return SizedBox(
                                width: 260,
                                child: Opacity(
                                  opacity: isSelected ? 1 : 0.85,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _selectedEvent = e);
                                      _mapController?.animateCamera(
                                        CameraUpdate.newLatLng(
                                          LatLng(e.latitude!, e.longitude!),
                                        ),
                                      );
                                    },
                                    child: EventPosterCard(
                                      event: e,
                                      compact: true,
                                      onTap: () {
                                        Navigator.pushNamed(
                                          context,
                                          '/eventDetail',
                                          arguments: e,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Loading indicator
                if (discover.isLoading && events.isEmpty)
                  const Center(child: CircularProgressIndicator()),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSelectedEventCard(BuildContext context) {
    final event = _selectedEvent!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return GlassSurface(
      blurSigma: 20,
      borderRadius: BorderRadius.circular(AppRadii.xl),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Event image or placeholder
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.lg),
            child:
                event.imageUrl != null
                    ? Image.network(
                      event.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) => _buildImagePlaceholder(scheme),
                    )
                    : _buildImagePlaceholder(scheme),
          ),
          const SizedBox(width: 16),
          // Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (event.venueName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: scheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.venueName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Directions button
          IconButton.filledTonal(
            onPressed: () => _openDirections(event),
            tooltip: 'Get Directions',
            icon: const Icon(Icons.directions_rounded, size: 20),
          ),
          const SizedBox(width: 4),
          // View button
          IconButton.filled(
            onPressed: () {
              Navigator.pushNamed(context, '/eventDetail', arguments: event);
            },
            tooltip: 'View Event',
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(ColorScheme scheme) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      child: Icon(
        Icons.event_rounded,
        color: scheme.onSurface.withValues(alpha: 0.3),
      ),
    );
  }
}

/// Dark mode map style for Google Maps
const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#212121"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#212121"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#181818"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#2c2c2c"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8a8a8a"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [{"color": "#373737"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#3c3c3c"}]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry",
    "stylers": [{"color": "#4e4e4e"}]
  },
  {
    "featureType": "road.local",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "featureType": "transit",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#000000"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#3d3d3d"}]
  }
]
''';
