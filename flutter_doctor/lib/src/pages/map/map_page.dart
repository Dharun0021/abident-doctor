import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../models/booking.dart';
import '../../services/doctor_api_service.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../utils/responsive.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController; // Made nullable to avoid dispose errors
  bool _mapReady = false;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  List<DoctorBooking> _bookings = [];
  final ValueNotifier<DoctorBooking?> _selectedBookingNotifier = ValueNotifier<DoctorBooking?>(null);
  bool _isLoading = true;
  String? _errorMessage;

  // Indian location (center of India)
  static const LatLng _defaultCenter = LatLng(20.5937, 78.9629); // Center of India
  static const LatLng _indiaMin = LatLng(8.0, 68.0); // Southwest corner of India
  static const LatLng _indiaMax = LatLng(35.0, 97.0); // Northeast corner of India
  static const double _defaultZoom = 4.5; // Zoom level to show all of India

  @override
  void initState() {
    super.initState();
    // Delay loading to ensure proper initialization
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadBookings();
      }
    });
  }

  Future<void> _loadBookings() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await DoctorApiService.getDoctorBookings();
      
      if (!mounted) return;

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final rawBookings = List.from(data['bookings'] as List<dynamic>? ?? []);
          
          final bookings = <DoctorBooking>[];
          for (var b in rawBookings) {
            try {
              bookings.add(DoctorBooking.fromJson(b as Map<String, dynamic>));
            } catch (e) {
              debugPrint('Error parsing booking: $e');
              // Continue with next booking instead of crashing
            }
          }

          if (!mounted) return;

          _bookings = bookings;
          _updateMarkers();
          
          if (_mapReady && bookings.isNotEmpty) {
            _fitMapToMarkers();
          }
        } catch (parseError) {
          debugPrint('Error parsing API response: $parseError');
          if (!mounted) return;
          setState(() {
            _errorMessage = 'Error parsing bookings data';
          });
        }
      } else {
        if (!mounted) return;
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>?;
          setState(() {
            _errorMessage = data?['message']?.toString() ?? 'Failed to load bookings';
          });
        } catch (e) {
          setState(() {
            _errorMessage = 'Failed to load bookings (Status: ${response.statusCode})';
          });
        }
      }
    } catch (e) {
      debugPrint('Error in _loadBookings: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error loading bookings: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateMarkers() {
    try {
      _markers.clear();
      _circles.clear();

      for (int i = 0; i < _bookings.length; i++) {
        final booking = _bookings[i];
        final location = booking.location;

        if (location.hasValidCoordinates) {
          final latLng = location.toLatLng()!;
          final markerId = MarkerId('booking_${booking.id ?? i}');
          final patientName = booking.user?.name ?? 'Patient';

          _markers.add(
            Marker(
              markerId: markerId,
              position: latLng,
              infoWindow: InfoWindow(
                title: patientName,
                snippet: '${booking.treatment.type} - ${booking.location.addressText}',
                onTap: () {
                  try {
                    if (mounted) {
                      _selectedBookingNotifier.value = booking;
                      _showAppointmentPopup(booking);
                    }
                  } catch (e) {
                    debugPrint('Error in info window tap: $e');
                  }
                },
              ),
              onTap: () {
                try {
                  if (mounted) {
                    _selectedBookingNotifier.value = booking;
                    _showAppointmentPopup(booking);
                  }
                } catch (e) {
                  debugPrint('Error in marker tap: $e');
                }
              },
            ),
          );

          _circles.add(
            Circle(
              circleId: CircleId('circle_${booking.id ?? i}'),
              center: latLng,
              radius: 500, // 500 meters
              fillColor: AppColors.primary.withValues(alpha: 0.1),
              strokeColor: AppColors.primary.withValues(alpha: 0.3),
              strokeWidth: 2,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error updating markers: $e');
    }
  }

  void _showAppointmentPopup(DoctorBooking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAppointmentBottomSheet(booking),
    );
  }

  void _fitMapToMarkers() {
    try {
      if (_markers.isEmpty || !_mapReady || _mapController == null) return;

      final positions = _markers.map((m) => m.position).toList();
      double minLat = positions.first.latitude;
      double maxLat = positions.first.latitude;
      double minLng = positions.first.longitude;
      double maxLng = positions.first.longitude;

      for (final pos in positions) {
        minLat = minLat > pos.latitude ? pos.latitude : minLat;
        maxLat = maxLat < pos.latitude ? pos.latitude : maxLat;
        minLng = minLng > pos.longitude ? pos.longitude : minLng;
        maxLng = maxLng < pos.longitude ? pos.longitude : maxLng;
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    } catch (e) {
      debugPrint('Error fitting map to markers: $e');
    }
  }

  void _resetToIndiaView() {
    try {
      if (!_mapReady || _mapController == null) return;

      final bounds = LatLngBounds(
        southwest: _indiaMin,
        northeast: _indiaMax,
      );

      _mapController?.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    } catch (e) {
      debugPrint('Error resetting to India view: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return _buildMapPage(context);
    } catch (e) {
      debugPrint('Error building map page: $e');
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading map', style: AppTextStyles.body),
              const SizedBox(height: 8),
              Text(e.toString(), style: AppTextStyles.caption, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              AppButton(
                label: 'Retry',
                onPressed: () {
                  setState(() {});
                },
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMapPage(BuildContext context) {
    final pad = pagePadding(context);

    return Padding(
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Appointment Locations', style: AppTextStyles.headingLarge),
                            const SizedBox(height: 8),
                            Text('Tap on any location to view appointment details.', style: AppTextStyles.body),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: 'Reset to India view',
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.location_on, color: Colors.white),
                            onPressed: _resetToIndiaView,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
                child: _isLoading
                    ? AppCard(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text('Loading appointments...', style: AppTextStyles.body),
                            ],
                          ),
                        ),
                      )
                    : _errorMessage != null
                        ? AppCard(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text(_errorMessage!, style: AppTextStyles.body, textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  AppButton(
                                    label: 'Retry',
                                    onPressed: _loadBookings,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _bookings.isEmpty
                            ? AppCard(
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.location_off, size: 48, color: Colors.grey),
                                      const SizedBox(height: 16),
                                      Text('No appointments with locations yet.', style: AppTextStyles.body),
                                    ],
                                  ),
                                ),
                              )
                            : AppCard(
                                padding: EdgeInsets.zero,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: GoogleMap(
                                    onMapCreated: (controller) {
                                      try {
                                        _mapController = controller;
                                        _mapReady = true;
                                        Future.delayed(const Duration(milliseconds: 500), () {
                                          try {
                                            if (mounted && _bookings.isNotEmpty && _mapController != null) {
                                              _fitMapToMarkers();
                                            }
                                          } catch (e) {
                                            debugPrint('Error fitting markers after map creation: $e');
                                          }
                                        });
                                      } catch (e) {
                                        debugPrint('Error in onMapCreated: $e');
                                      }
                                    },
                                    initialCameraPosition: const CameraPosition(
                                      target: _defaultCenter,
                                      zoom: _defaultZoom,
                                    ),
                                    markers: _markers,
                                    circles: _circles,
                                    mapType: MapType.normal,
                                    zoomGesturesEnabled: true,
                                    scrollGesturesEnabled: true,
                                    tiltGesturesEnabled: false,
                                    rotateGesturesEnabled: false,
                                  ),
                                ),
                              ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentBottomSheet(DoctorBooking booking) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Appointment Details', style: AppTextStyles.headingSmall),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Patient', booking.user?.name ?? 'Unknown'),
            _buildDetailRow('Type', booking.visitType),
            _buildDetailRow('Treatment', booking.treatment.type),
            _buildDetailRow('Reason', booking.treatment.reason),
            _buildDetailRow('Date & Time', DateFormat('MMM dd, yyyy • hh:mm a').format(booking.treatment.date)),
            _buildDetailRow('Status', booking.status),
            if (booking.location.hasValidCoordinates) ...[
              const SizedBox(height: 16),
              Text('Location Coordinates', style: AppTextStyles.title),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Latitude: ${booking.location.latitude?.toStringAsFixed(6)}', style: AppTextStyles.caption),
                    const SizedBox(height: 4),
                    Text('Longitude: ${booking.location.longitude?.toStringAsFixed(6)}', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
            if (booking.location.addressText.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Address', style: AppTextStyles.title),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(booking.location.addressText, style: AppTextStyles.caption),
              ),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: 'View in Appointments',
              icon: Icons.calendar_today,
              onPressed: () {
                Navigator.pop(context);
                // Navigate to Appointments page
                // You can use your routing here
                debugPrint('Navigate to appointments page for booking: ${booking.id}');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.caption),
          Text(value, style: AppTextStyles.title),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _selectedBookingNotifier.dispose();
    try {
      _mapController?.dispose();
    } catch (e) {
      debugPrint('Error disposing map controller: $e');
    }
    super.dispose();
  }
}
