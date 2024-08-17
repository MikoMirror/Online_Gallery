import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../models/app_user.dart' as app_models;

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc() : super(AuthInitial()) {
    on<SignInRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
        
        // Fetch user data from Firestore
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(userCredential.user!.uid).get();
        
        app_models.AppUser user = app_models.AppUser(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          nickname: userDoc.get('nickname'),
        );
        
        emit(Authenticated(user));
      } catch (e) {
        emit(AuthError(e.toString()));
        emit(Unauthenticated());
      }
    });

    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        print("SignUpRequested event received"); // Add this line
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );
        
        // Save user data to Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': event.email,
          'nickname': event.nickname,
        });
        
        // Create an AppUser object with the nickname
        app_models.AppUser user = app_models.AppUser(
          uid: userCredential.user!.uid,
          email: userCredential.user!.email!,
          nickname: event.nickname,
        );
        
        emit(Authenticated(user));
      } catch (e) {
        print("Error in SignUpRequested: $e"); // Add this line
        emit(AuthError(e.toString()));
        emit(Unauthenticated());
      }
    });

    on<SignOutRequested>((event, emit) async {
      emit(AuthLoading());
      await _auth.signOut();
      emit(Unauthenticated());
    });
  }
}