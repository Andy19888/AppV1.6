import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import 'dart:async'; // Necesario para usar timeout

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document in Firestore
        final userModel = UserModel(
          id: credential.user!.uid,
          email: email,
          name: name,
          role: role,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(credential.user!.uid)
            .set(userModel.toJson());

        // Update display name
        await credential.user!.updateDisplayName(name);
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user data: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toJson());
    } catch (e) {
      throw Exception('Error updating user data: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No se encontró un usuario con este email.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Este email ya está registrado.';
      case 'weak-password':
        return 'La contraseña es muy débil.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }
}

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Provider for current user stream
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);

  // CORRECCIÓN CLAVE: Aplicar un timeout y resolver a null si tarda mucho.
  // Esto previene que la aplicación se quede en 'loading' si la conexión
  // inicial es lenta o inestable, forzando la redirección a la pantalla de login.
  return authService.authStateChanges.timeout(
    const Duration(seconds: 4), // 4 segundos de límite para la carga inicial
    onTimeout: (sink) {
      // Si hay timeout, cerramos el stream actual y enviamos null (no autenticado)
      sink.close();
      sink.add(null); 
    },
  );
});


// Provider for current user data
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final authService = ref.watch(authServiceProvider);
  
  return authState.when(
    data: (user) async {
      if (user != null) {
        // La línea que estaba marcada en rojo antes
        return await authService.getUserData(user.uid); 
      }
      return null;
    },
    loading: () => null,
    error: (_, __) => null,
  );
});
