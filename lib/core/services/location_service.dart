import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location_model.dart';
import '../models/authorization_request_model.dart';
import '../models/user_model.dart';
import 'package:uuid/uuid.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Get all provinces
  Future<List<String>> getProvinces() async {
    try {
      final snapshot = await _firestore
          .collection('locations')
          .orderBy('provincia')
          .get();
      
      final provinces = snapshot.docs
          .map((doc) => doc.data()['provincia'] as String)
          .toSet()
          .toList();
      
      return provinces;
    } catch (e) {
      throw Exception('Error fetching provinces: $e');
    }
  }

  // Get localities by province
  Future<List<String>> getLocalidades(String provincia) async {
    try {
      final snapshot = await _firestore
          .collection('locations')
          .where('provincia', isEqualTo: provincia)
          .orderBy('localidad')
          .get();
      
      final localidades = snapshot.docs
          .map((doc) => doc.data()['localidad'] as String)
          .toSet()
          .toList();
      
      return localidades;
    } catch (e) {
      throw Exception('Error fetching localidades: $e');
    }
  }

  // Get chains by province and locality
  Future<List<String>> getCadenas(String provincia, String localidad) async {
    try {
      final snapshot = await _firestore
          .collection('locations')
          .where('provincia', isEqualTo: provincia)
          .where('localidad', isEqualTo: localidad)
          .orderBy('cadena')
          .get();
      
      final cadenas = snapshot.docs
          .map((doc) => doc.data()['cadena'] as String)
          .toSet()
          .toList();
      
      return cadenas;
    } catch (e) {
      throw Exception('Error fetching cadenas: $e');
    }
  }

  // Get sucursales by province, locality and chain
  Future<List<LocationModel>> getSucursales(
    String provincia, 
    String localidad, 
    String cadena
  ) async {
    try {
      final snapshot = await _firestore
          .collection('locations')
          .where('provincia', isEqualTo: provincia)
          .where('localidad', isEqualTo: localidad)
          .where('cadena', isEqualTo: cadena)
          .orderBy('sucursal')
          .get();
      
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return LocationModel.fromJson({
              ...data,
              'sucursalId': doc.id,
              'name': data['name'] ?? data['sucursal'] ?? '',
            });
          })
          .toList();
    } catch (e) {
      throw Exception('Error fetching sucursales: $e');
    }
  }

  // Request authorization for a sucursal
  Future<void> requestAuthorization({
    required String repositorId,
    required String repositorName,
    required String repositorEmail,
    required LocationModel location,
  }) async {
    try {
      final request = AuthorizationRequestModel(
        id: _uuid.v4(),
        repositorId: repositorId,
        repositorName: repositorName,
        repositorEmail: repositorEmail,
        sucursalId: location.sucursalId ?? '',
        location: location,
        status: AuthorizationStatus.pending,
        requestedAt: DateTime.now(),
      );

      await _firestore
          .collection('authorization_requests')
          .doc(request.id)
          .set(request.toJson());
    } catch (e) {
      throw Exception('Error requesting authorization: $e');
    }
  }

  // Check if user is authorized for a sucursal
  Future<bool> isAuthorized(String userId, String sucursalId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (!userDoc.exists) return false;
      
      final user = UserModel.fromJson(userDoc.data()!);
      return user.authorizedSucursales.contains(sucursalId);
    } catch (e) {
      throw Exception('Error checking authorization: $e');
    }
  }

  // Get pending authorization requests
  Stream<List<AuthorizationRequestModel>> getPendingRequests() {
    return _firestore
        .collection('authorization_requests')
        .where('status', isEqualTo: AuthorizationStatus.pending.name)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AuthorizationRequestModel.fromJson(doc.data()))
            .toList());
  }

  // Approve or reject authorization request
  Future<void> respondToRequest({
    required String requestId,
    required String supervisorId,
    required AuthorizationStatus status,
    String? comment,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // Update request
      final requestRef = _firestore
          .collection('authorization_requests')
          .doc(requestId);
      
      batch.update(requestRef, {
        'status': status.name,
        'respondedAt': DateTime.now().toIso8601String(),
        'supervisorId': supervisorId,
        'comment': comment,
      });

      // If approved, add sucursal to user's authorized list
      if (status == AuthorizationStatus.approved) {
        final requestDoc = await requestRef.get();
        if (requestDoc.exists) {
          final request = AuthorizationRequestModel.fromJson(requestDoc.data()!);
          
          final userRef = _firestore
              .collection('users')
              .doc(request.repositorId);
          
          batch.update(userRef, {
            'authorizedSucursales': FieldValue.arrayUnion([request.sucursalId]),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error responding to request: $e');
    }
  }

  // Add sample locations (for testing)
  Future<void> addSampleLocations() async {
    final sampleLocations = [
      {
        'provincia': 'Buenos Aires',
        'localidad': 'La Plata',
        'cadena': 'Carrefour',
        'sucursal': 'Carrefour La Plata Centro',
      },
      {
        'provincia': 'Buenos Aires',
        'localidad': 'La Plata',
        'cadena': 'Carrefour',
        'sucursal': 'Carrefour La Plata Norte',
      },
      {
        'provincia': 'Buenos Aires',
        'localidad': 'Mar del Plata',
        'cadena': 'Walmart',
        'sucursal': 'Walmart Mar del Plata',
      },
      {
        'provincia': 'Córdoba',
        'localidad': 'Córdoba Capital',
        'cadena': 'Jumbo',
        'sucursal': 'Jumbo Córdoba Centro',
      },
    ];

    final batch = _firestore.batch();
    
    for (final location in sampleLocations) {
      final docRef = _firestore.collection('locations').doc();
      batch.set(docRef, location);
    }
    
    await batch.commit();
  }
}

// Provider for LocationService
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

// Provider for provinces
final provincesProvider = FutureProvider<List<String>>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return await locationService.getProvinces();
});

// Provider for localidades
final localidadesProvider = FutureProvider.family<List<String>, String>((ref, provincia) async {
  final locationService = ref.watch(locationServiceProvider);
  return await locationService.getLocalidades(provincia);
});

// Provider for cadenas
final cadenasProvider = FutureProvider.family<List<String>, Map<String, String>>((ref, params) async {
  final locationService = ref.watch(locationServiceProvider);
  return await locationService.getCadenas(params['provincia']!, params['localidad']!);
});

// Provider for sucursales
final sucursalesProvider = FutureProvider.family<List<LocationModel>, Map<String, String>>((ref, params) async {
  final locationService = ref.watch(locationServiceProvider);
  return await locationService.getSucursales(
    params['provincia']!, 
    params['localidad']!, 
    params['cadena']!
  );
});
