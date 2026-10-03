String mapFirebaseAuthError(String code) {
  switch (code) {
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Incorrect email or password.';
    case 'invalid-email':
      return 'Enter a valid email address.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'too-many-requests':
      return 'Too many attempts. Try again later.';
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'weak-password':
      return 'Choose a stronger password (at least 6 characters).';
    default:
      return 'Something went wrong. Please try again.';
  }
}