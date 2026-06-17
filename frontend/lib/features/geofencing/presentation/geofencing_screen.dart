import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../data/models/geofence_model.dart';
import '../domain/geofencing_provider.dart';

class GeofencingScreen extends ConsumerStatefulWidget {
  final String vehicleId;

  const GeofencingScreen({super.key, required this.vehicleId});

  @override
  ConsumerState<GeofencingScreen> createState() => _GeofencingScreenState();
}

class _GeofencingScreenState extends ConsumerState<GeofencingScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedPoint;
  double _radius = AppConstants.defaultGeofenceRadius;
  bool _showAddForm = false;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _mapController?.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Set<Circle> _buildCircles(List<GeofenceModel> geofences) {
    final circles = <Circle>{};
    for (final g in geofences) {
      circles.add(Circle(
        circleId: CircleId(g.id),
        center: g.center,
        radius: g.radius,
        fillColor: (g.isActive ? AppColors.primary : AppColors.offline)
            .withOpacity(0.15),
        strokeColor: g.isActive ? AppColors.primary : AppColors.offline,
        strokeWidth: 2,
      ));
    }
    if (_selectedPoint != null) {
      circles.add(Circle(
        circleId: const CircleId('preview'),
        center: _selectedPoint!,
        radius: _radius,
        fillColor: AppColors.secondary.withOpacity(0.15),
        strokeColor: AppColors.secondary,
        strokeWidth: 2,
      ));
    }
    return circles;
  }

  Set<Marker> _buildMarkers(List<GeofenceModel> geofences) {
    return geofences
        .map((g) => Marker(
              markerId: MarkerId(g.id),
              position: g.center,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                g.isActive
                    ? BitmapDescriptor.hueBlue
                    : BitmapDescriptor.hueAzure,
              ),
              infoWindow: InfoWindow(
                title: g.name,
                snippet: '${g.radius.toInt()} متر',
              ),
            ))
        .toSet();
  }

  Future<void> _addGeofence() async {
    if (_selectedPoint == null) return;
    if (_nameController.text.trim().isEmpty) {
      context.showSnackBar('يرجى إدخال اسم المنطقة', isError: true);
      return;
    }

    final success =
        await ref.read(geofencingProvider(widget.vehicleId).notifier).addGeofence(
              name: _nameController.text.trim(),
              lat: _selectedPoint!.latitude,
              lng: _selectedPoint!.longitude,
              radius: _radius,
            );

    if (mounted) {
      if (success) {
        setState(() {
          _selectedPoint = null;
          _showAddForm = false;
          _nameController.clear();
        });
        context.showSnackBar('تمت إضافة المنطقة بنجاح');
      } else {
        context.showSnackBar('فشل إضافة المنطقة', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(geofencingProvider(widget.vehicleId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.geofencing),
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: state.isLoading
          ? const LoadingWidget()
          : state.error != null && state.geofences.isEmpty
              ? AppErrorWidget(
                  message: state.error,
                  onRetry: () => ref
                      .read(geofencingProvider(widget.vehicleId).notifier)
                      .refresh(),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(24.7136, 46.6753), // Riyadh
                        zoom: 12,
                      ),
                      circles: _buildCircles(state.geofences),
                      markers: _buildMarkers(state.geofences),
                      onMapCreated: (c) => _mapController = c,
                      onTap: (point) {
                        setState(() {
                          _selectedPoint = point;
                          _showAddForm = true;
                        });
                      },
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                    // Geofences list
                    if (!_showAddForm && state.geofences.isNotEmpty)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _GeofencesList(
                          geofences: state.geofences,
                          vehicleId: widget.vehicleId,
                        ),
                      ),
                    // Add form
                    if (_showAddForm)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: _AddGeofenceForm(
                          nameController: _nameController,
                          radius: _radius,
                          onRadiusChanged: (r) =>
                              setState(() => _radius = r),
                          onAdd: _addGeofence,
                          onCancel: () => setState(() {
                            _showAddForm = false;
                            _selectedPoint = null;
                            _nameController.clear();
                          }),
                        ),
                      ),
                    // Empty hint
                    if (state.geofences.isEmpty && !_showAddForm)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.touch_app_rounded,
                                  color: AppColors.primary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  AppStrings.tapMapToAdd,
                                  style: TextStyle(
                                    fontFamily: 'Cairo',
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _GeofencesList extends ConsumerWidget {
  final List<GeofenceModel> geofences;
  final String vehicleId;

  const _GeofencesList({required this.geofences, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                AppStrings.geofencing,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: geofences.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final g = geofences[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  trailing: Switch(
                    value: g.isActive,
                    activeColor: AppColors.primary,
                    onChanged: (v) => ref
                        .read(geofencingProvider(vehicleId).notifier)
                        .toggleGeofence(g.id, v),
                  ),
                  title: Text(
                    g.name,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.w600,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  subtitle: Text(
                    '${g.radius.toInt()} متر',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error),
                    onPressed: () => ref
                        .read(geofencingProvider(vehicleId).notifier)
                        .deleteGeofence(g.id),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _AddGeofenceForm extends StatelessWidget {
  final TextEditingController nameController;
  final double radius;
  final ValueChanged<double> onRadiusChanged;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  const _AddGeofenceForm({
    required this.nameController,
    required this.radius,
    required this.onRadiusChanged,
    required this.onAdd,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            AppStrings.addGeofence,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: nameController,
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Cairo'),
            decoration: InputDecoration(
              labelText: AppStrings.geofenceName,
              labelStyle: const TextStyle(fontFamily: 'Cairo'),
              prefixIcon: const Icon(Icons.edit_location_alt_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${radius.toInt()} متر',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const Text(
                AppStrings.radius,
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Slider(
            value: radius,
            min: 100,
            max: 5000,
            divisions: 49,
            activeColor: AppColors.primary,
            onChanged: onRadiusChanged,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.textSecondary),
                  ),
                  child: const Text(
                    AppStrings.cancel,
                    style: TextStyle(fontFamily: 'Cairo'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAdd,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text(
                    AppStrings.add,
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
