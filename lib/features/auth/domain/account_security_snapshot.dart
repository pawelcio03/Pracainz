class AccountSecuritySnapshot {
  const AccountSecuritySnapshot({
    required this.email,
    required this.emailVerified,
    required this.providerIds,
    required this.hasPasswordProvider,
    required this.hasGoogleProvider,
  });

  final String email;
  final bool emailVerified;
  final List<String> providerIds;
  final bool hasPasswordProvider;
  final bool hasGoogleProvider;
}
