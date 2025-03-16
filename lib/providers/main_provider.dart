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
    // TODO: Implement user authentication check
    state = state.copyWith(isUserLoggedIn: false, isLoading: false);
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
