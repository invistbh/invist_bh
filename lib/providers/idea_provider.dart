import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invist_bh/models/idea_model.dart';
import 'package:invist_bh/services/idea_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final ideaServiceProvider = Provider<IdeaService>((ref) => IdeaService());

final ideasStreamProvider = StreamProvider<List<IdeaModel>>((ref) {
  final ideaService = ref.watch(ideaServiceProvider);
  return ideaService.getIdeas();
});

final categoryIdeasStreamProvider = StreamProvider.family<List<IdeaModel>, String>(
  (ref, category) {
    if (category == 'All') {
      return ref.watch(ideaServiceProvider).getIdeas();
    } else {
      return ref.watch(ideaServiceProvider).getIdeasByCategory(category);
    }
  },
);

final creatorIdeasStreamProvider = StreamProvider.family<List<IdeaModel>, String>(
  (ref, creatorId) {
    return ref.watch(ideaServiceProvider).getIdeasByCreator(creatorId);
  },
);

final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

final categoriesProvider = Provider<List<String>>((ref) {
  return [
    'All',
    'FinTech',
    'Sustainable Technology',
    'Artificial Intelligence',
    'Green Business',
    'Blockchain',
    'Healthcare',
    'Education',
  ];
});

class IdeaNotifier extends StateNotifier<AsyncValue<String>> {
  final IdeaService _ideaService;

  IdeaNotifier(this._ideaService) : super(const AsyncValue.data(''));

  Future<void> updateIdea(IdeaModel idea) async {
    state = const AsyncValue.loading();
    try {
      await _ideaService.updateIdea(idea);
      state = const AsyncValue.data('Idea updated successfully');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> requestIdeaAccess(String ideaId, String investorId) async {
    state = const AsyncValue.loading();
    try {
      await _ideaService.requestIdeaAccess(ideaId, investorId);
      state = const AsyncValue.data('Access requested successfully');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> approveAccessRequest(String ideaId, String investorId) async {
    state = const AsyncValue.loading();
    try {
      await _ideaService.approveAccessRequest(ideaId, investorId);
      state = const AsyncValue.data('Access approved successfully');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<void> rejectAccessRequest(String ideaId, String investorId) async {
    state = const AsyncValue.loading();
    try {
      await _ideaService.rejectAccessRequest(ideaId, investorId);
      state = const AsyncValue.data('Access rejected successfully');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
  
  Future<bool> checkInvestorAccess(String ideaId, String investorId) async {
    try {
      return await _ideaService.checkInvestorAccess(ideaId, investorId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }

  Future<void> addIdea({
    required String title,
    required String description,
    required String category,
    File? imageFile,
    required String innovationDetails,
    required String investmentRequired,
    required String creatorId,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Handle the image upload only if an image is provided
      String imageUrl = '';
      if (imageFile != null) {
        // Use a simple, short filename for upload
        // The actual unique filename will be generated in the uploadImage method
        final fileName = 'idea.jpg';
        imageUrl = await _ideaService.uploadImage(imageFile, fileName);
      }
      
      final idea = IdeaModel(
        id: '',
        title: title,
        description: description,
        category: category,
        imageUrl: imageUrl,
        innovationDetails: innovationDetails,
        investmentRequired: investmentRequired,
        investors: [],
        creatorId: creatorId,
        createdAt: DateTime.now(),
      );
      
      final ideaId = await _ideaService.addIdea(idea);
      state = AsyncValue.data(ideaId);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addInvestorToIdea(String ideaId, String investorId) async {
    state = const AsyncValue.loading();
    try {
      await _ideaService.addInvestorToIdea(ideaId, investorId);
      state = const AsyncValue.data('');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final ideaNotifierProvider = StateNotifierProvider<IdeaNotifier, AsyncValue<String>>(
  (ref) => IdeaNotifier(ref.watch(ideaServiceProvider)),
);

final accessRequestsProvider = StreamProvider.family<QuerySnapshot, String>((ref, ideaId) {
  final ideaService = ref.watch(ideaServiceProvider);
  return ideaService.getIdeaAccessRequests(ideaId);
});

final investorRequestsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, investorId) {
  final ideaService = ref.watch(ideaServiceProvider);
  return ideaService.getInvestorAccessRequests(investorId);
});
