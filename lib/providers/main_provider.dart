import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invist_bh/models/user_model.dart';

class MainProviderState {
  final bool isLoading;
  final bool isUserLoggedIn;
  final UserModel? currentUser;
  final int selectedMainPageIndex;

  MainProviderState({
    this.isLoading = true,
    this.isUserLoggedIn = false,
    this.currentUser,
    this.selectedMainPageIndex = 0,
  });

  MainProviderState copyWith({
    bool? isLoading,
    bool? isUserLoggedIn,
    UserModel? currentUser,
    int? selectedMainPageIndex,
  }) {
    return MainProviderState(
      isLoading: isLoading ?? this.isLoading,
      isUserLoggedIn: isUserLoggedIn ?? this.isUserLoggedIn,
      currentUser: currentUser ?? this.currentUser,
      selectedMainPageIndex: selectedMainPageIndex ?? this.selectedMainPageIndex,
    );
  }
}

class MainProvider extends StateNotifier<MainProviderState> {
  MainProvider() : super(MainProviderState());

  void setIsLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void setSelectedPage(int index) {
    state = state.copyWith(selectedMainPageIndex: index);
  }

  Future<void> getIfUserLoggedIn() async {
    try {
      // Check if we already have a user in the state
      if (state.currentUser != null) {
        state = state.copyWith(isUserLoggedIn: true, isLoading: false);
        return;
      }
      
      // TODO: Implement proper persistence (e.g., SharedPreferences or secure storage)
      // For now, we'll just set isLoading to false without changing isUserLoggedIn
      // This prevents overriding the login state if the user has just logged in
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // In case of any error, set isLoading to false but don't change login state
      state = state.copyWith(isLoading: false);
    }
  }

  void setUser(UserModel? user) {
    state = state.copyWith(
      currentUser: user,
      isUserLoggedIn: user != null,
    );
  }

  void logout() {
    state = state.copyWith(
      currentUser: null,
      isUserLoggedIn: false,
      selectedMainPageIndex: 0,
    );
  }
}

final mainProvider =
    StateNotifierProvider<MainProvider, MainProviderState>((ref) {
  return MainProvider();
});

// Provider to access the current user
final userProvider = Provider<UserModel?>((ref) {
  final mainState = ref.watch(mainProvider);
  return mainState.currentUser;
});

