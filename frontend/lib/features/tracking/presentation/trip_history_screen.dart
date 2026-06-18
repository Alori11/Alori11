import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/location_model.dart';
import '../domain/tracking_provider.dart';

class TripHistoryScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const TripHistoryScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends ConsumerState<TripHistoryScreen> {
  TripModel? _selectedTrip;
  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final state = ref.read(tripHistoryProvider(widget.vehicleId));
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: state.from, end: state.to),
      locale: const Locale('ar'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      await ref
          .read(tripHistoryProvider(widget.vehicleId).notifier)
          .setDateRange(range.start, range.end);
    }
  }

  Set<Polyline> _buildPolylines() {
    if (_selectedTrip == null) return {};
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _selectedTrip!.points,
        color: AppColors.primary,
        width: 4,
      ),
    };
  }

  Set<Marker> _buildMarkers() {
    if (_selectedTrip == null || _selectedTrip!.points.isEmpty) return {};
    final markers = <Marker>{};
    final points = _selectedTrip!.points;
    markers.add(Marker(
      markerId: const MarkerId('start'),
      position: points.first,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(
        title: 'البداية',
        snippet: _selectedTrip!.startTime.toShortTime(),
      ),
    ));
    markers.add(Marker(
      markerId: const MarkerId('end'),
      position: points.last,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: 'النهاية',
        snippet: _selectedTrip!.endTime.toShortTime(),
      ),
    ));
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(tripHistoryProvider(widget.vehicleId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.tripHistory),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded),
            onPressed: _pickDateRange,
            tooltip: AppStrings.selectDateRange,
          ),
        ],
      ),
      body: Column(
        children: [
          // Map
          if (_selectedTrip != null)
            SizedBox(
              height: 250,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedTrip!.points.isNotEmpty
                      ? _selectedTrip!.points.first
                      : const LatLng(24.7136, 46.6753),
                  zoom: 14,
                ),
                polylines: _buildPolylines(),
                markers: _buildMarkers(),
                onMapCreated: (c) {
                  _mapController = c;
                  if (_selectedTrip!.points.isNotEmpty) {
                    final bounds = _boundsFromPoints(_selectedTrip!.points);
                    c.animateCamera(
                      CameraUpdate.newLatLngBounds(bounds, 48),
                    );
                  }
                },
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          // Date range chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ActionChip(
                  label: Text(
                    '${historyState.from.toShortDate()} - ${historyState.to.toShortDate()}',
                    style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                  ),
                  avatar: const Icon(Icons.calendar_today_rounded, size: 16),
                  onPressed: _pickDateRange,
                  backgroundColor: AppColors.primary.withOpacity(0.08),
                  side: const BorderSide(color: AppColors.primary, width: 0.5),
                ),
              ],
            ),
          ),
          // Trip list
          Expanded(
            child: historyState.isLoading
                ? const LoadingWidget()
                : historyState.error != null
                    ? AppErrorWidget(
                        message: historyState.error,
                        onRetry: () => ref
                            .read(tripHistoryProvider(widget.vehicleId).notifier)
                            .refresh(),
                      )
                    : historyState.trips.isEmpty
                        ? const EmptyWidget(
                            message: AppStrings.noTrips,
                            icon: Icons.route_rounded,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: historyState.trips.length,
                            itemBuilder: (context, index) {
                              final trip = historyState.trips[index];
                              final isSelected = _selectedTrip?.id == trip.id;
                              return _TripTile(
                                trip: trip,
                                isSelected: isSelected,
                                onTap: () {
                                  setState(() {
                                    _selectedTrip =
                                        isSelected ? null : trip;
                                  });
                                },
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  LatLngBounds _boundsFromPoints(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

class _TripTile extends StatelessWidget {
  final TripModel trip;
  final bool isSelected;
  final VoidCallback onTap;

  const _TripTile({
    required this.trip,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: isSelected ? 1.5 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date
                Text(
                  trip.startTime.toShortDate(),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                // Route icon
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.route_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MetricItem(
                  icon: Icons.straighten_rounded,
                  value: trip.distance.toKmString(),
                  label: AppStrings.distance,
                ),
                _MetricItem(
                  icon: Icons.timer_rounded,
                  value: trip.duration.toArabicDuration(),
                  label: AppStrings.duration,
                ),
                _MetricItem(
                  icon: Icons.speed_rounded,
                  value: trip.maxSpeed.toSpeedString(),
                  label: 'أقصى سرعة',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trip.endTime.toShortTime(),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
                Text(
                  trip.startTime.toShortTime(),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
