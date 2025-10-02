import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import '../models/location_model.dart';
import 'package:uuid/uuid.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // User Management
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromJson(doc.data()))
            .toList());
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
      });
    } catch (e) {
      throw Exception('Error updating user status: $e');
    }
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role.name,
      });
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Location Management
  Stream<List<LocationModel>> getAllLocations() {
    return _firestore
        .collection('locations')
        .orderBy('provincia')
        .orderBy('localidad')
        .orderBy('cadena')
        .orderBy('sucursal')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromJson({
                  ...doc.data(),
                  'sucursalId': doc.id,
                }))
            .toList());
  }

  Future<void> addLocation(LocationModel location) async {
    try {
      await _firestore.collection('locations').add({
        'provincia': location.provincia,
        'localidad': location.localidad,
        'cadena': location.cadena,
        'sucursal': location.sucursal,
      });
    } catch (e) {
      throw Exception('Error adding location: $e');
    }
  }

  Future<void> updateLocation(LocationModel location) async {
    try {
      await _firestore.collection('locations').doc(location.sucursalId).update({
        'provincia': location.provincia,
        'localidad': location.localidad,
        'cadena': location.cadena,
        'sucursal': location.sucursal,
      });
    } catch (e) {
      throw Exception('Error updating location: $e');
    }
  }

  Future<void> deleteLocation(String locationId) async {
    try {
      await _firestore.collection('locations').doc(locationId).delete();
    } catch (e) {
      throw Exception('Error deleting location: $e');
    }
  }

  // Task Management
  Stream<List<TaskModel>> getAllTasks() {
    return _firestore
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskModel.fromJson(doc.data()))
            .toList());
  }

  Future<void> createTask({
    required String sucursalId,
    required String title,
    required String description,
  }) async {
    try {
      final task = TaskModel(
        id: _uuid.v4(),
        sucursalId: sucursalId,
        title: title,
        description: description,
        status: TaskStatus.pending,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('tasks').doc(task.id).set(task.toJson());
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).update(task.toJson());
    } catch (e) {
      throw Exception('Error updating task: $e');
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection('tasks').doc(taskId).delete();
    } catch (e) {
      throw Exception('Error deleting task: $e');
    }
  }

  // Analytics
  Future<Map<String, dynamic>> getAnalytics() async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      final tasksSnapshot = await _firestore.collection('tasks').get();
      final locationsSnapshot = await _firestore.collection('locations').get();

      final users = usersSnapshot.docs.map((doc) => UserModel.fromJson(doc.data())).toList();
      final tasks = tasksSnapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList();

      final repositorCount = users.where((u) => u.role == UserRole.repositor).length;
      final supervisorCount = users.where((u) => u.role == UserRole.supervisor).length;
      final activeUsers = users.where((u) => u.isActive).length;

      final pendingTasks = tasks.where((t) => t.status == TaskStatus.pending).length;
      final inProgressTasks = tasks.where((t) => t.status == TaskStatus.inProgress).length;
      final completedTasks = tasks.where((t) => t.status == TaskStatus.completed).length;
      final approvedTasks = tasks.where((t) => t.status == TaskStatus.approved).length;
      final rejectedTasks = tasks.where((t) => t.status == TaskStatus.rejected).length;

      return {
        'users': {
          'total': users.length,
          'repositors': repositorCount,
          'supervisors': supervisorCount,
          'active': activeUsers,
        },
        'tasks': {
          'total': tasks.length,
          'pending': pendingTasks,
          'inProgress': inProgressTasks,
          'completed': completedTasks,
          'approved': approvedTasks,
          'rejected': rejectedTasks,
        },
        'locations': {
          'total': locationsSnapshot.docs.length,
        },
      };
    } catch (e) {
      throw Exception('Error fetching analytics: $e');
    }
  }

  // Bulk operations
  Future<void> importTasksFromCSV(List<Map<String, dynamic>> csvData) async {
    try {
      final batch = _firestore.batch();
      
      for (final row in csvData) {
        final task = TaskModel(
          id: _uuid.v4(),
          sucursalId: row['sucursalId'] as String,
          title: row['title'] as String,
          description: row['description'] as String,
          status: TaskStatus.pending,
          createdAt: DateTime.now(),
        );

        final docRef = _firestore.collection('tasks').doc(task.id);
        batch.set(docRef, task.toJson());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error importing tasks: $e');
    }
  }

  Future<List<Map<String, dynamic>>> exportTasksToCSV() async {
    try {
      final snapshot = await _firestore.collection('tasks').get();
      final tasks = snapshot.docs.map((doc) => TaskModel.fromJson(doc.data())).toList();

      return tasks.map((task) => {
        'id': task.id,
        'sucursalId': task.sucursalId,
        'title': task.title,
        'description': task.description,
        'status': task.status.name,
        'repositorId': task.repositorId ?? '',
        'createdAt': task.createdAt.toIso8601String(),
        'completedAt': task.completedAt?.toIso8601String() ?? '',
        'cantidadRepuesta': task.cantidadRepuesta ?? 0,
        'observaciones': task.observaciones ?? '',
        'supervisorComment': task.supervisorComment ?? '',
      }).toList();
    } catch (e) {
      throw Exception('Error exporting tasks: $e');
    }
  }
}

// Provider for AdminService
final adminServiceProvider = Provider<AdminService>((ref) => AdminService());

// Provider for all users
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getAllUsers();
});

// Provider for all locations
final allLocationsProvider = StreamProvider<List<LocationModel>>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getAllLocations();
});

// Provider for all tasks
final allTasksProvider = StreamProvider<List<TaskModel>>((ref) {
  final adminService = ref.watch(adminServiceProvider);
  return adminService.getAllTasks();
});

// Provider for analytics
final analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final adminService = ref.watch(adminServiceProvider);
  return await adminService.getAnalytics();
});
