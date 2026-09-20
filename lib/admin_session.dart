class AdminSession {
  static String? currentAdmin;

  static bool get isLoggedIn =>
      currentAdmin != null && currentAdmin!.isNotEmpty;

  static void login(String adminEmail) {
    currentAdmin = adminEmail.trim();
  }

  static void logout() {
    currentAdmin = null;
  }
}
