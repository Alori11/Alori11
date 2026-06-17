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

class LiveTrackingScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const LiveTrackingScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends ConsumerState<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  bool _followVehicle = true;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _centerOnVehicle(LocationModel location) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location.latLng,
          zoom: 16,
          bearing: location.heading,
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers(LocationModel location) {
    return {
      Marker(
        markerId: const MarkerId('vehicle'),
        position: location.latLng,
        rotation: location.heading,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          location.isMoving
              ? BitmapDescriptor.hueBlue
              : BitmapDescriptor.hueGreen,
        ),
        infoWindow: InfoWindow(
          title: '${location.speed.toStringAsFixed(0)} ${AppStrings.kmhUnit}',
          snippet: location.address,
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final locationStream = ref.watch(liveLocationProvider(widget.vehicleId));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          AppStrings.liveTrackingTitle,
          style: TextStyle(
            fontFamily: 'Cairo',
            fontWeight: FontWeight.w700,
            shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
          ),
        ),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.primary, size: 18),
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: TextButton.icon(
              onPressed: () =>
                  context.push('/tracking/${widget.vehicleId}/history'),
              icon: const Icon(Icons.history_rounded,
                  color: AppColors.primary, size: 18),
              label: const Text(
                AppStrings.tripHistory,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  color: AppColors.primary,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: locationStream.when(
        loading: () => const Center(child: LoadingWidget()),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(liveLocationProvider(widget.vehicleId)),
        ),
        data: (location) {
          if (_followVehicle && _mapController != null) {
            _centerOnVehicle(location);
          }
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: location.latLng,
                  zoom: 16,
                ),
                markers: _buildMarkers(location),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _centerOnVehicle(location);
                },
                onCameraMoveStarted: () {
                  setState(() => _followVehicle = false);
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                mapType: MapType.normal,
              ),
              // Bottom info sheet
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _InfoBottomSheet(location: location),
              ),
              // Center FAB
              Positioned(
                bottom: 220,
                left: 16,
                child: FloatingActionButton.small(
                  heroTag: 'center',
                  backgroundColor: Colors.white,
                  onPressed: () {
                    setState(() => _followVehicle = true);
                    _centerOnVehicle(location);
                  },
                  child: Icon(
                    _followVehicle
                        ? Icons.my_location_rounded
                        : Icons.location_searching_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoBottomSheet extends StatelessWidget {
  final LocationModel location;

  const _InfoBottomSheet({required this.location});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Status row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ignition
              _InfoChip(
                icon: Icons.power_settings_new_rounded,
                label: location.ignition
                    ? AppStrings.ignitionOn
                    : AppStrings.ignitionOff,
                color: location.ignition ? AppColors.success : AppColors.error,
              ),
              // Speed
              _InfoMetric(
                value: location.speed.toStringAsFixed(0),
                unit: AppStrings.kmhUnit,
                label: AppStrings.speed,
                icon: Icons.speed_rounded,
                color: AppColors.primary,
              ),
              // Heading
              _InfoMetric(
                value: '${location.heading.toStringAsFixed(0)}°',
                unit: '',
                label: 'الاتجاه',
                icon: Icons.navigation_rounded,
                color: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Address / last update
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'آخر تحديث: ${location.dateTime.toTimeAgo()}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              Expanded(
                child: Text(
                  location.address ?? 'جاري تحديد الموقع...',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.location_pin, color: AppColors.error, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoMetric extends StatelessWidget {
  final String value;
  final String unit;
  final String label;
  final IconData icon;
  final Color color;

  const _InfoMetric({
    required this.value,
    required this.unit,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
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
