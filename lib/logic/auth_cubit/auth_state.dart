import 'package:firebase_auth/firebase_auth.dart';

// Abstract Class هي الأب لكل الحالات
abstract class AuthState {}

// 1. الحالة الابتدائية (قبل ما المستخدم يعمل أي حاجة)
class AuthInitial extends AuthState {}

// 2. حالة التحميل (عشان نظهر Loading Indicator في الـ UI)
class AuthLoading extends AuthState {}

// 3. حالة النجاح (لما يسجل بنجاح ورجعنا الـ User)
class AuthSuccess extends AuthState {
  final User user;
  AuthSuccess(this.user);
}

// 4. حالة الفشل (لما يحصل خطأ ونرجع رسالة الخطأ)
class AuthFailure extends AuthState {
  final String errorMessage;
  AuthFailure(this.errorMessage);
}