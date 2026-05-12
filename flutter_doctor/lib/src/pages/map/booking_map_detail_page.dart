import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../components/app_button.dart';
import '../../components/app_card.dart';
import '../../models/booking.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../utils/responsive.dart';

class BookingMapDetailPage extends StatefulWidget {
  final DoctorBooking booking;

  const BookingMapDetailPage({
    super.key,
    required this.booking,
  });

  @override
  State<BookingMapDetailPage> createState() => _BookingMapDetailPageState();
}

class _BookingMapDetailPageState extends State<BookingMapDetailPage> {
  late GoogleMapController _mapController;
  late Set<Marker> _markers;
  late Set<Circle> _circles;

  @override
  void initState() {
    super.initState();
    _initializeMapMarkers();
  }

  void _initializeMapMarkers() {
    _markers = {};
    _circles = {};

    final location = widget.booking.location;
    if (location.hasValidCoordinates) {
      final latLng = location.toLatLng()!;
      _markers.add(
        Marker(
          markerId: const MarkerId('booking_location'),
          position: latLng,
          infoWindow: InfoWindow(
            title: widget.booking.user?.name ?? 'Patient',
            snippet: location.addressText,
          ),
        ),
      );

      _circles.add(
        Circle(
          circleId: const CircleId('location_circle'),
          center: latLng,
          radius: 500,
          fillColor: AppColors.primary.withValues(alpha: 0.1),
          strokeColor: AppColors.primary.withValues(alpha: 0.3),
          strokeWidth: 2,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final location = booking.location;
    final hasLocation = location.hasValidCoordinates;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Location'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasLocation)
              SizedBox(
                height: 300,
                child: GoogleMap(
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  initialCameraPosition: CameraPosition(
                    target: location.toLatLng()!,
                    zoom: 15,
                  ),
                  markers: _markers,
                  circles: _circles,
                  mapType: MapType.normal,
                  zoomGesturesEnabled: true,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                ),
              )
            else
              Container(
                height: 200,
                color: AppColors.background,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No location coordinates available', style: AppTextStyles.body),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Appointment Details', style: AppTextStyles.headingSmall),
                    const SizedBox(height: 16),
                    _buildDetailRow('Patient', booking.user?.name ?? 'Unknown'),
                    _buildDetailRow('Visit Type', booking.visitType),
                    _buildDetailRow('Treatment', booking.treatment.type),
                    _buildDetailRow('Reason', booking.treatment.reason),
                    _buildDetailRow(
                      'Date & Time',
                      DateFormat('MMM dd, yyyy • hh:mm a').format(booking.treatment.date),
                    ),
                    _buildDetailRow('Status', booking.status),
                    if (booking.treatment.details.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildDetailRow('Additional Details', booking.treatment.details),
                    ],
                  ],
                ),
              ),
            ),
            if (hasLocation)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Location Coordinates', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Latitude: ${location.latitude?.toStringAsFixed(6)}',
                              style: AppTextStyles.caption,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Longitude: ${location.longitude?.toStringAsFixed(6)}',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (location.addressText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Address', style: AppTextStyles.headingSmall),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(location.addressText, style: AppTextStyles.caption),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppButton(
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption),
          Flexible(
            child: Text(
              value,
              style: AppTextStyles.title,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}
