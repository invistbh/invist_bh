import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invist_bh/models/idea_model.dart';
import 'package:invist_bh/providers/idea_provider.dart';
import 'package:invist_bh/providers/main_provider.dart';
import 'package:invist_bh/screens/idea_details_screen.dart';
import 'package:invist_bh/utils/app_theme.dart';
import 'package:invist_bh/widgets/category_filter.dart';
import 'package:invist_bh/widgets/create_idea_modal.dart';
import 'package:invist_bh/widgets/idea_card.dart';

class InnovatorHomeScreen extends ConsumerWidget {
  const InnovatorHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final myIdeasAsyncValue = user != null 
        ? ref.watch(creatorIdeasStreamProvider(user.id)) 
        : const AsyncValue<List<IdeaModel>>.data([]);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: Image.asset(
          'assets/logofull.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Share Your Idea',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create and share your innovative ideas with potential investors',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            showCreateIdeaModal(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                          ),
                          child: const Text('Create New Idea'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.white.withOpacity(0.8),
                    size: 60,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Category Filter
            const Text(
              'Browse by Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const CategoryFilter(),
            const SizedBox(height: 24),

            // Statistics Section
            const Text(
              'Your Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            myIdeasAsyncValue.when(
              data: (ideas) {
                final activeIdeas = ideas.length;
                final interestedInvestors = ideas.fold<int>(
                  0, (sum, idea) => sum + idea.investors.length);
                
                return Column(
                  children: [
                    Row(
                      children: [
                        _buildStatCard(
                          'Active Ideas',
                          activeIdeas.toString(),
                          Icons.lightbulb_outline,
                          AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          'Interested Investors',
                          interestedInvestors.toString(),
                          Icons.people_outline,
                          AppTheme.secondaryColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatCard(
                          'In Discussion',
                          '${activeIdeas > 0 ? (activeIdeas / 2).round() : 0}',
                          Icons.chat_bubble_outline,
                          Colors.orange,
                        ),
                        const SizedBox(width: 16),
                        _buildStatCard(
                          'Completed Deals',
                          '${interestedInvestors > 5 ? (interestedInvestors / 10).round() : 0}',
                          Icons.check_circle_outline,
                          Colors.green,
                        ),
                      ],
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
            const SizedBox(height: 24),

            // Your Ideas
            const Text(
              'Your Ideas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            myIdeasAsyncValue.when(
              data: (ideas) {
                if (ideas.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('You haven\'t created any ideas yet'),
                    ),
                  );
                }
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: ideas.length,
                  itemBuilder: (context, index) {
                    final idea = ideas[index];
                    return IdeaCard(
                      idea: idea,
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => IdeaDetailsScreen(idea: idea),
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
