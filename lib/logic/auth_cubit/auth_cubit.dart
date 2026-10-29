import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final FirebaseAuth _firebaseAuth;

  // Constructor: بنمرر الـ Initial State للـ Cubit الأب (super)
  AuthCubit({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        super(AuthInitial());

  // -------------------------------------------------------------
  // 1. دالة تسجيل الدخول (Sign In)
  // -------------------------------------------------------------
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    // خطوة 1: ابعث حالة Loading للـ UI عشان يعرض شاشة التحميل
    emit(AuthLoading());

    try {
      // خطوة 2: نفذ الاتصال بـ Firebase
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // خطوة 3: لو العملية نجحت والـ User موجود، ابعث حالة النجاح
      if (userCredential.user != null) {
        emit(AuthSuccess(userCredential.user!));
      } else {
        emit(AuthFailure('User not found'));
      }
    } on FirebaseAuthException catch (e) {
      // خطوة 4: مسك أخطاء Firebase وتحويلها لرسائل واضحة
      emit(AuthFailure(_mapFirebaseAuthError(e.code)));
    } catch (e) {
      // خطوة 5: أي خطأ غير متوقع آخر
      emit(AuthFailure('An unexpected error occurred. Please try again.'));
    }
  }

  // -------------------------------------------------------------
  // 2. دالة إنشاء حساب جديد (Sign Up)
  // -------------------------------------------------------------
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());

    try {
      final userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        emit(AuthSuccess(userCredential.user!));
      } else {
        emit(AuthFailure('Failed to register user'));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseAuthError(e.code)));
    } catch (e) {
      emit(AuthFailure('An unexpected error occurred. Please try again.'));
    }
  }

  // -------------------------------------------------------------
  // 3. دالة تسجيل الخروج (Sign Out)
  // -------------------------------------------------------------
  Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await _firebaseAuth.signOut();
      emit(AuthInitial()); // بنرجع للحالة الابتدائية بعد الخروج
    } catch (e) {
      emit(AuthFailure('Failed to sign out. Please try again.'));
    }
  }

  // -------------------------------------------------------------
  // Helper Function: ترجمة أكواد أخطاء Firebase لرسائل مفهومة
  // -------------------------------------------------------------
  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}