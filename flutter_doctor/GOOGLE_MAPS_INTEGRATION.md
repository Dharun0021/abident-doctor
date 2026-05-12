# 🗺️ Google Maps Integration Guide
## Complete Documentation: How Google Maps Was Integrated & Implemented

---

## Table of Contents
1. [Overview](#overview)
2. [Setup & Configuration](#setup--configuration)
3. [Implementation Details](#implementation-details)
4. [Code Structure](#code-structure)
5. [Features Explained](#features-explained)
6. [How It Works](#how-it-works)
7. [API Integration](#api-integration)
8. [Troubleshooting](#troubleshooting)

---

## Overview

### What is Google Maps in This App?
Google Maps displays all **appointment locations** for the doctor. Each appointment has a geographic location (latitude/longitude), and this feature visualizes all appointments on an interactive map with:
- 📍 Markers showing patient locations
- 👤 Patient names displayed on markers
- ⭕ 500m radius circles around each location
- 📋 Clickable markers showing appointment details
- 🔄 Refresh button to reset view to India

### Use Case
Instead of just seeing appointment details in a list, the doctor can:
- Quickly identify where their appointments are geographically
- See all appointment locations at once
- Plan travel routes more efficiently
- Click any location to see full appointment details

---

## Setup & Configuration

### Step 1: Get Google Maps API Key

#### 1.1 Create Google Cloud Project
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project
3. Enable the following APIs:
   - ✅ Maps SDK for Android
   - ✅ Maps SDK for iOS
   - ✅ Maps SDK for Web

#### 1.2 Create API Key
1. In Google Cloud Console → Credentials → Create Credential → API Key
2. Restrict it to Android, iOS, and Web applications
3. For Android: Add your app's SHA-1 fingerprint
4. Your key format: `AIzaSyBI19sifyXhch5c-MPfo19FEdmkusJFk94`

### Step 2: Android Configuration

#### 2.1 Update `android/app/build.gradle.kts`
```kotlin
// Import JvmTarget for Kotlin compilation
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

android {
    compileSdk = 34
    
    defaultConfig {
        targetSdk = 34
        minSdk = 21  // Minimum API level
    }
    
    // Use new Kotlin compiler options (replaces deprecated kotlinOptions)
    kotlin {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_11)
        }
    }
}

dependencies {
    // Google Maps plugin for Flutter
    // Already in pubspec.yaml: google_maps_flutter: ^2.14.2
}
```

#### 2.2 Update `android/settings.gradle.kts`
```kotlin
plugins {
    // Kotlin plugin version must match dependencies
    id("org.jetbrains.kotlin.android") version "2.3.10" apply false
}
```

**Why Kotlin 2.3.10?**
- Matches dependencies that were compiled with Kotlin 2.3
- Prevents "incompatible version" errors during build
- Supports JVM 11 compilation target

#### 2.3 Add API Key to `android/app/src/main/AndroidManifest.xml`
```xml
<manifest>
    <!-- Location permissions for map -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    
    <application>
        <!-- Google Maps API Key (from Google Cloud Console) -->
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="AIzaSyBI19sifyXhch5c-MPfo19FEdmkusJFk94" />
        
        <!-- Rest of your application config -->
    </application>
</manifest>
```

### Step 3: Add Flutter Dependencies

In `pubspec.yaml`:
```yaml
dependencies:
  google_maps_flutter: ^2.14.2  # Google Maps widget for Flutter
  intl: ^0.20.0                 # For date formatting
  geolocator: ^11.0.0           # Optional: for user's current location
```

Run: `flutter pub get`

---

## Implementation Details

### File: `lib/src/pages/map/map_page.dart`

#### Purpose
This file is the **main UI component** that displays the Google Map with appointment markers.

#### Key Components

```dart
class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;  // Controls the map (nullable to prevent dispose errors)
  bool _mapReady = false;               // Flag indicating map is initialized
  
  Set<Marker> _markers = {};            // Collection of markers (one per appointment)
  Set<Circle> _circles = {};            // Collection of radius circles
  List<DoctorBooking> _bookings = [];   // List of appointments with locations
  
  ValueNotifier<DoctorBooking?> _selectedBookingNotifier = ValueNotifier(null);  // Selected appointment state
  
  bool _isLoading = true;               // Loading state
  String? _errorMessage;                // Error message display
}
```

---

## Code Structure

### 1. **Initialization: `initState()`**

```dart
@override
void initState() {
  super.initState();
  // Delay loading to ensure proper widget initialization
  Future.delayed(const Duration(milliseconds: 100), () {
    if (mounted) {
      _loadBookings();  // Load appointments from API
    }
  });
}
```

**Why delay?**
- Ensures Flutter's widget tree is fully built before loading data
- Prevents errors from calling setState before first build

**Check `if (mounted)`?**
- Verifies widget is still in tree before updating
- Prevents "setState called after dispose" errors

---

### 2. **Load Appointments: `_loadBookings()`**

```dart
Future<void> _loadBookings() async {
  try {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Call API to get all doctor's bookings
    final response = await DoctorApiService.getDoctorBookings();
    
    if (response.statusCode == 200) {
      // Parse JSON response
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawBookings = List.from(data['bookings'] as List<dynamic>? ?? []);
      
      // Convert to DoctorBooking objects
      final bookings = <DoctorBooking>[];
      for (var b in rawBookings) {
        try {
          bookings.add(DoctorBooking.fromJson(b as Map<String, dynamic>));
        } catch (e) {
          debugPrint('Error parsing booking: $e');
          // Continue with next booking instead of crashing
        }
      }

      _bookings = bookings;
      _updateMarkers();  // Update map markers
      
      // Fit map to show all markers
      if (_mapReady && bookings.isNotEmpty) {
        _fitMapToMarkers();
      }
    } else {
      // Handle API error
      final data = jsonDecode(response.body) as Map<String, dynamic>?;
      _errorMessage = data?['message']?.toString() ?? 'Failed to load bookings';
    }
  } catch (e) {
    _errorMessage = 'Error loading bookings: ${e.toString()}';
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}
```

**Error Handling Strategy:**
- ✅ Individual booking parsing errors don't crash entire app
- ✅ Network errors show user-friendly messages
- ✅ Always displays loading/error state to user

---

### 3. **Create Markers: `_updateMarkers()`**

```dart
void _updateMarkers() {
  try {
    _markers.clear();
    _circles.clear();

    for (int i = 0; i < _bookings.length; i++) {
      final booking = _bookings[i];
      final location = booking.location;

      // Only add marker if location has valid coordinates
      if (location.hasValidCoordinates) {
        final latLng = location.toLatLng()!;
        final patientName = booking.user?.name ?? 'Patient';

        // Create Marker
        _markers.add(
          Marker(
            markerId: MarkerId('booking_${booking.id ?? i}'),
            position: latLng,
            infoWindow: InfoWindow(
              title: patientName,                    // Shows patient name
              snippet: '${booking.treatment.type}', // Shows treatment type
              onTap: () {
                _showAppointmentPopup(booking);     // Show details on tap
              },
            ),
            onTap: () {
              _showAppointmentPopup(booking);       // Also handle marker tap
            },
          ),
        );

        // Create Circle (500m radius around location)
        _circles.add(
          Circle(
            circleId: CircleId('circle_${booking.id ?? i}'),
            center: latLng,
            radius: 500,  // 500 meters
            fillColor: AppColors.primary.withValues(alpha: 0.1),    // Semi-transparent fill
            strokeColor: AppColors.primary.withValues(alpha: 0.3),  // Transparent border
            strokeWidth: 2,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {});  // Rebuild map with new markers/circles
    }
  } catch (e) {
    debugPrint('Error updating markers: $e');
  }
}
```

**What Each Marker Shows:**
- 📍 **Position**: Exact latitude/longitude from appointment
- 👤 **Title**: Patient name
- 📋 **Snippet**: Treatment type and address
- 🔵 **Circle**: 500m service radius

---

### 4. **Show Popup: `_showAppointmentPopup()`**

```dart
void _showAppointmentPopup(DoctorBooking booking) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,             // Allows popup to take full height if needed
    backgroundColor: Colors.transparent,  // Transparent background
    builder: (context) => _buildAppointmentBottomSheet(booking),
  );
}
```

**Why bottom sheet instead of full-screen card?**
- ✅ Keeps map visible behind popup
- ✅ User can see location while viewing details
- ✅ Better UX - no need to go back to see map again
- ✅ Draggable - user can scroll to see more details

---

### 5. **Fit Map to Markers: `_fitMapToMarkers()`**

```dart
void _fitMapToMarkers() {
  try {
    if (_markers.isEmpty || !_mapReady || _mapController == null) return;

    // Find boundary coordinates of all markers
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

    // Create bounds rectangle
    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    // Animate camera to show all markers
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  } catch (e) {
    debugPrint('Error fitting map to markers: $e');
  }
}
```

**What This Does:**
1. Finds the geographic boundaries of all appointment locations
2. Creates a rectangle (bounds) that contains all points
3. Animates map camera to fit entire rectangle on screen

**Example:**
- If appointments are in Mumbai (19.0760°N, 72.8777°E) and Delhi (28.7041°N, 77.1025°E)
- Map will zoom out to show both cities
- All markers visible at once

---

### 6. **Reset to India View: `_resetToIndiaView()`**

```dart
void _resetToIndiaView() {
  try {
    if (!_mapReady || _mapController == null) return;

    // India boundaries
    final bounds = LatLngBounds(
      southwest: LatLng(8.0, 68.0),      // Southwest corner of India
      northeast: LatLng(35.0, 97.0),     // Northeast corner of India
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  } catch (e) {
    debugPrint('Error resetting to India view: $e');
  }
}
```

**When is this called?**
- When user clicks the Refresh button (🔄 icon) in header
- Resets map view to show all of India
- Smooth animation over 100ms

---

### 7. **Default Location Constants**

```dart
// Center of India (approximate geographic center)
static const LatLng _defaultCenter = LatLng(20.5937, 78.9629);

// India boundaries for fitting map
static const LatLng _indiaMin = LatLng(8.0, 68.0);      // Southwest
static const LatLng _indiaMax = LatLng(35.0, 97.0);     // Northeast

// Initial zoom level (4.5 shows entire India)
static const double _defaultZoom = 4.5;
```

**Zoom Levels Explained:**
- 0 = Entire World
- 3 = Continent
- 4.5 = **India (current)**
- 8 = Region/State
- 12 = City
- 15 = Street
- 20 = Building

---

## Features Explained

### 🗺️ Interactive Map
```dart
GoogleMap(
  onMapCreated: (controller) {
    _mapController = controller;  // Get controller for programmatic control
    _mapReady = true;
  },
  initialCameraPosition: const CameraPosition(
    target: _defaultCenter,        // Center at India
    zoom: _defaultZoom,            // Zoom level 4.5
  ),
  markers: _markers,               // Show all appointment markers
  circles: _circles,               // Show 500m radius circles
  mapType: MapType.normal,         // Standard map (not satellite)
  zoomGesturesEnabled: true,       // User can pinch to zoom
  scrollGesturesEnabled: true,     // User can pan around
  tiltGesturesEnabled: false,      // Disable 3D tilt
  rotateGesturesEnabled: false,    // Disable rotation
)
```

**User Interactions:**
- 👆 **Tap marker** → Shows appointment details in bottom sheet
- 🤏 **Pinch to zoom** → In/out on locations
- 🖐️ **Drag to pan** → Move around map

---

### 👤 Markers with Patient Names

**Each marker shows:**
1. **Title**: Patient name (e.g., "John Doe")
2. **Snippet**: Treatment type and address
3. **Position**: Exact GPS coordinates
4. **Tap Callback**: Opens appointment details popup

```dart
Marker(
  markerId: MarkerId('booking_123'),
  position: LatLng(19.0760, 72.8777),  // Mumbai
  infoWindow: InfoWindow(
    title: "John Doe",                           // Patient name
    snippet: "Root Canal Treatment - Mumbai",    // Treatment + Location
    onTap: () => _showAppointmentPopup(booking),
  ),
  onTap: () => _showAppointmentPopup(booking),
)
```

---

### ⭕ Radius Circles

**500m service radius around each location:**
- Helps doctor see **service coverage area**
- Visual indication of reach from each appointment
- Overlapping circles show nearby appointments

```dart
Circle(
  circleId: CircleId('circle_123'),
  center: LatLng(19.0760, 72.8777),
  radius: 500,  // 500 meters
  fillColor: AppColors.primary.withValues(alpha: 0.1),    // Light fill
  strokeColor: AppColors.primary.withValues(alpha: 0.3),  // Dark border
  strokeWidth: 2,
)
```

---

### 📋 Bottom Sheet Popup

**When user clicks a marker:**
1. Bottom sheet slides up from bottom
2. Shows complete appointment details:
   - Patient name
   - Visit type
   - Treatment type & reason
   - Date & time
   - Appointment status
   - GPS coordinates
   - Full address
3. "View in Appointments" button to navigate to appointment detail page

**Features:**
- ✅ Draggable (scroll up/down)
- ✅ Map remains visible behind
- ✅ Close button to dismiss
- ✅ Scrollable content

---

### 🔄 Refresh Button

**Located in header (top right with 📍 icon)**
- Resets map to show entire India
- Smooth animation (100ms)
- Useful when zoomed into specific location
- One-tap reset to default view

---

## How It Works

### Step-by-Step Flow

```
User Opens Map Page
    ↓
initState() called
    ↓
100ms delay (ensure widget ready)
    ↓
_loadBookings() executed
    ↓
API call: GET /doctor/bookings
    ↓
Response with bookings list
    ↓
Parse booking JSON objects
    ↓
Create DoctorBooking models
    ↓
_updateMarkers() called
    ↓
For each booking:
  - Extract location (lat/lng)
  - Create marker with patient name
  - Create 500m circle
  - Add to markers/circles sets
    ↓
setState() → Map rebuilds
    ↓
GoogleMapController.onMapCreated called
    ↓
_fitMapToMarkers() called
    ↓
Calculate bounds of all markers
    ↓
Animate camera to fit bounds
    ↓
Map displays all appointments
```

### User Interaction Flow

```
User sees map with markers
    ↓
Taps on a marker
    ↓
onTap() callback triggered
    ↓
_showAppointmentPopup() called
    ↓
showModalBottomSheet() creates popup
    ↓
_buildAppointmentBottomSheet() builds content
    ↓
Appointment details shown in popup
    ↓
User can:
  - Scroll to see all details
  - Click "View in Appointments" button
  - Close popup to see map again
```

### Refresh Button Flow

```
User clicks Refresh button (📍)
    ↓
_resetToIndiaView() called
    ↓
Calculate India boundaries
    ↓
Create LatLngBounds for India
    ↓
animateCamera(newLatLngBounds) called
    ↓
Map smoothly zooms out
    ↓
Shows entire India
    ↓
All appointments visible
```

---

## API Integration

### Backend Endpoint: `GET /doctor/bookings`

**Request:**
```
GET /api/doctor/bookings
Authorization: Bearer {authToken}
```

**Response:**
```json
{
  "bookings": [
    {
      "id": "booking_1",
      "user": {
        "id": "user_1",
        "name": "John Doe"
      },
      "visitType": "Home Visit",
      "treatment": {
        "type": "Root Canal Treatment",
        "reason": "Tooth pain",
        "date": "2026-05-15T10:30:00Z"
      },
      "location": {
        "latitude": 19.0760,
        "longitude": 72.8777,
        "addressText": "123 Marine Drive, Mumbai, Maharashtra"
      },
      "status": "scheduled"
    }
  ]
}
```

**DoctorApiService Implementation:**
```dart
class DoctorApiService {
  static Future<http.Response> getDoctorBookings() async {
    final token = await _getAuthToken();
    
    return http.get(
      Uri.parse('$baseUrl/doctor/bookings'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }
}
```

---

## Data Model: `DoctorBooking`

```dart
class DoctorBooking {
  final String? id;
  final User? user;
  final String visitType;
  final Treatment treatment;
  final Location location;
  final String status;

  DoctorBooking({
    required this.id,
    required this.user,
    required this.visitType,
    required this.treatment,
    required this.location,
    required this.status,
  });

  factory DoctorBooking.fromJson(Map<String, dynamic> json) {
    return DoctorBooking(
      id: json['id'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      visitType: json['visitType'] ?? '',
      treatment: Treatment.fromJson(json['treatment']),
      location: Location.fromJson(json['location']),
      status: json['status'] ?? 'pending',
    );
  }
}

class Location {
  final double? latitude;
  final double? longitude;
  final String addressText;

  bool get hasValidCoordinates => latitude != null && longitude != null;

  LatLng? toLatLng() {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    return null;
  }
}
```

---

## Troubleshooting

### ❌ "API key not found" Error

**Symptom:**
```
E/Google Maps Android API: MapsInitializationException: The Google Maps Platform rejected your request.
```

**Solution:**
1. Check `AndroidManifest.xml` has API key:
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="AIzaSyBI19sifyXhch5c-MPfo19FEdmkusJFk94" />
   ```
2. Verify API key is valid in Google Cloud Console
3. Check API key has Android permission enabled
4. Check SHA-1 fingerprint matches (for Android)

---

### ❌ Kotlin Version Mismatch

**Symptom:**
```
Module was compiled with an incompatible version of Kotlin. 
The binary version of its metadata is 2.3.0, expected version is 2.1.0
```

**Solution:**
Update `android/settings.gradle.kts`:
```kotlin
id("org.jetbrains.kotlin.android") version "2.3.10" apply false
```

---

### ❌ Deprecated kotlinOptions Error

**Symptom:**
```
Using 'jvmTarget: String' is an error. 
Please migrate to the compilerOptions DSL
```

**Solution:**
Update `android/app/build.gradle.kts`:
```kotlin
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

kotlin {
    compilerOptions {
        jvmTarget.set(JvmTarget.JVM_11)
    }
}
```

---

### ❌ Map Not Showing

**Symptom:**
- Black/blank screen where map should be
- No error messages

**Checklist:**
1. ✅ API key in `AndroidManifest.xml`
2. ✅ Permissions declared (ACCESS_FINE_LOCATION)
3. ✅ `google_maps_flutter` in `pubspec.yaml`
4. ✅ Bookings loaded from API (check logs)
5. ✅ Bookings have valid locations (latitude/longitude not null)

**Debug:**
```dart
// Add to _updateMarkers()
debugPrint('Total bookings: ${_bookings.length}');
for (var b in _bookings) {
  debugPrint('Booking ${b.id}: ${b.location.latitude}, ${b.location.longitude}');
}
```

---

### ❌ Markers Not Appearing

**Symptom:**
- Map shows but no markers visible

**Causes:**
1. **API returned empty list** → No bookings for doctor
2. **Bookings have null coordinates** → Check Location data
3. **Markers created but not updated** → Check `_updateMarkers()` called

**Fix:**
```dart
// Ensure bookings have valid coordinates
if (location.hasValidCoordinates) {
  // Only add markers for valid locations
}
```

---

### ❌ Popup Not Showing When Clicking Marker

**Symptom:**
- Click marker but nothing happens
- No popup appears

**Solution:**
Check tap callbacks:
```dart
Marker(
  onTap: () {
    _showAppointmentPopup(booking);  // This must be defined
  },
),
```

Verify `_showAppointmentPopup()` and `_buildAppointmentBottomSheet()` exist.

---

### ❌ App Crashes When Clicking Marker

**Symptom:**
```
setState() called after dispose()
or
NullPointerException
```

**Solution:**
Add mounted checks:
```dart
onTap: () {
  try {
    if (mounted) {  // Check widget still in tree
      _showAppointmentPopup(booking);
    }
  } catch (e) {
    debugPrint('Error: $e');
  }
}
```

---

### ❌ Refresh Button Not Working

**Symptom:**
- Click refresh but map doesn't move

**Solution:**
Check map is ready:
```dart
void _resetToIndiaView() {
  if (!_mapReady || _mapController == null) return;
  // Rest of code...
}
```

---

## Summary

**Google Maps Integration in Abident Doctor App:**

✅ Shows appointment locations on interactive map
✅ Displays patient names on markers
✅ 500m service radius circles
✅ Clickable markers with appointment details popup
✅ Refresh button to reset to India view
✅ Comprehensive error handling
✅ Responsive design
✅ Smooth animations

**Key Technologies:**
- google_maps_flutter v2.14.2
- Google Cloud Maps API
- Flutter State Management (setState + ValueNotifier)
- Responsive UI with AppCard, AppButton
- Error handling with try-catch blocks

**Files Modified:**
- `android/settings.gradle.kts` - Kotlin version
- `android/app/build.gradle.kts` - Compiler options
- `android/app/src/main/AndroidManifest.xml` - API key & permissions
- `lib/src/pages/map/map_page.dart` - Map UI & logic
- `pubspec.yaml` - Dependencies

---

**Ready to Deploy! 🚀**
Test on Android device with `flutter run`
