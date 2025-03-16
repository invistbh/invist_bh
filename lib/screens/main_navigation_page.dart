import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invist_bh/models/user_model.dart';
import 'package:invist_bh/providers/main_provider.dart';
import 'package:invist_bh/screens/auth/auth_page.dart';
import 'package:invist_bh/screens/investor/investor_home_screen.dart';
import 'package:invist_bh/screens/investor/investor_ideas_screen.dart';
import 'package:invist_bh/screens/innovator/innovator_home_screen.dart';
import 'package:invist_bh/screens/innovator/innovator_ideas_screen.dart';
import 'package:invist_bh/screens/chat/chat_list_screen.dart';
import 'package:invist_bh/screens/profile/profile_screen.dart';
import 'package:invist_bh/utils/app_theme.dart';

class MainNavigationPage extends ConsumerStatefulWidget {
  const MainNavigationPage({super.key});

  @override
  ConsumerState<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends ConsumerState<MainNavigationPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(mainProvider.notifier).getIfUserLoggedIn();
    });
  }

  @override
  Widget build(BuildContext context) {
    final mainProviderData = ref.watch(mainProvider);
    final bool showNavBar = mainProviderData.isUserLoggedIn;
    final UserModel? user = mainProviderData.currentUser;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: mainProviderData.isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Stack(
                children: [
                  _buildBody(mainProviderData, user),
                  if (showNavBar)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildNavBar(user),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildBody(MainProviderState mainProviderData, UserModel? user) {
    if (!mainProviderData.isUserLoggedIn || user == null) {
      return const AuthPage();
    } else {
      return _getPageForUserRole(
        user.role,
        mainProviderData.selectedMainPageIndex,
      );
    }
  }

  Widget _buildNavBar(UserModel? user) {
    if (user == null) return const SizedBox();

    switch (user.role) {
      case UserRole.investor:
        return _buildInvestorNavBar();
      case UserRole.innovator:
        return _buildInnovatorNavBar();
    }
  }

  Widget _buildInvestorNavBar() {
    final mainProviderData = ref.watch(mainProvider);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 0, mainProviderData, 'Home'),
            _buildNavItem(Icons.lightbulb_outline, 1, mainProviderData, 'Ideas'),
            _buildNavItem(Icons.chat_outlined, 2, mainProviderData, 'Chat'),
            _buildNavItem(Icons.person_outline, 3, mainProviderData, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildInnovatorNavBar() {
    final mainProviderData = ref.watch(mainProvider);

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        width: double.infinity,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, 0, mainProviderData, 'Home'),
            _buildNavItem(Icons.lightbulb_outline, 1, mainProviderData, 'My Ideas'),
            _buildNavItem(Icons.chat_outlined, 2, mainProviderData, 'Chat'),
            _buildNavItem(Icons.person_outline, 3, mainProviderData, 'Profile'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    int index,
    MainProviderState mainProviderData,
    String label,
  ) {
    final isSelected = mainProviderData.selectedMainPageIndex == index;

    return GestureDetector(
      onTap: () => ref.read(mainProvider.notifier).setSelectedPage(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getPageForUserRole(UserRole role, int index) {
    switch (role) {
      case UserRole.investor:
        switch (index) {
          case 0:
            return const InvestorHomeScreen();
          case 1:
            return const InvestorIdeasScreen();
          case 2:
            return const ChatListScreen();
          case 3:
            return const ProfileScreen();
          default:
            return const InvestorHomeScreen();
        }

      case UserRole.innovator:
        switch (index) {
          case 0:
            return const InnovatorHomeScreen();
          case 1:
            return const InnovatorIdeasScreen();
          case 2:
            return const ChatListScreen();
          case 3:
            return const ProfileScreen();
          default:
            return const InnovatorHomeScreen();
        }
    }
  }
}
