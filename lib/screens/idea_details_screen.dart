import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:invist_bh/models/idea_model.dart';
import 'package:invist_bh/providers/idea_provider.dart';
import 'package:invist_bh/providers/main_provider.dart';
import 'package:invist_bh/utils/app_theme.dart';

class IdeaDetailsScreen extends ConsumerStatefulWidget {
  final IdeaModel idea;

  const IdeaDetailsScreen({super.key, required this.idea});

  @override
  ConsumerState<IdeaDetailsScreen> createState() => _IdeaDetailsScreenState();
}

class _IdeaDetailsScreenState extends ConsumerState<IdeaDetailsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _innovationDetailsController;
  late TextEditingController _investmentRequiredController;
  late String _selectedCategory;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.idea.title);
    _descriptionController = TextEditingController(
      text: widget.idea.description,
    );
    _innovationDetailsController = TextEditingController(
      text: widget.idea.innovationDetails,
    );
    _investmentRequiredController = TextEditingController(
      text: widget.idea.investmentRequired,
    );
    _selectedCategory = widget.idea.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _innovationDetailsController.dispose();
    _investmentRequiredController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Reset controllers if canceling edit
        _titleController.text = widget.idea.title;
        _descriptionController.text = widget.idea.description;
        _innovationDetailsController.text = widget.idea.innovationDetails;
        _investmentRequiredController.text = widget.idea.investmentRequired;
        _selectedCategory = widget.idea.category;
      }
    });
  }

  Future<void> _saveChanges() async {
    final user = ref.read(userProvider);
    if (user == null) {
      _showErrorMessage('User not authenticated');
      return;
    }

    if (user.id != widget.idea.creatorId) {
      _showErrorMessage('You can only edit your own ideas');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedIdea = widget.idea.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        innovationDetails: _innovationDetailsController.text.trim(),
        investmentRequired: _investmentRequiredController.text.trim(),
      );

      await ref.read(ideaNotifierProvider.notifier).updateIdea(updatedIdea);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
        _showSuccessMessage('Idea updated successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage('Error updating idea: ${e.toString()}');
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_isEditing ? 'Edit Idea' : 'Idea Details'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isEditing)
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('Cancel'),
                onPressed: _toggleEdit,
              )
            else
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('Edit'),
                onPressed: _toggleEdit,
              ),
            if (_isEditing)
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Text('Save'),
                onPressed: _saveChanges,
              ),
          ],
        ),
      ),
      child:
          _isLoading
              ? const Center(child: CupertinoActivityIndicator())
              : SafeArea(
                child: Material(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        if (widget.idea.imageUrl.isNotEmpty)
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(widget.idea.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey[300],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),

                        // Title
                        _buildSectionTitle('Title'),
                        _isEditing
                            ? CupertinoTextField(
                              controller: _titleController,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            )
                            : Text(
                              widget.idea.title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        const SizedBox(height: 16),

                        // Category
                        _buildSectionTitle('Category'),
                        _isEditing
                            ? _buildCategoryPicker()
                            : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                widget.idea.category,
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        const SizedBox(height: 16),

                        // Description
                        _buildSectionTitle('Description'),
                        _isEditing
                            ? CupertinoTextField(
                              controller: _descriptionController,
                              padding: const EdgeInsets.all(12),
                              maxLines: 5,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            )
                            : Text(widget.idea.description),
                        const SizedBox(height: 16),

                        // Innovation Details
                        _buildSectionTitle('Innovation Details'),
                        _isEditing
                            ? CupertinoTextField(
                              controller: _innovationDetailsController,
                              padding: const EdgeInsets.all(12),
                              maxLines: 5,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            )
                            : Text(widget.idea.innovationDetails),
                        const SizedBox(height: 16),

                        // Investment Required
                        _buildSectionTitle('Investment Required'),
                        _isEditing
                            ? CupertinoTextField(
                              controller: _investmentRequiredController,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            )
                            : Text(widget.idea.investmentRequired),
                        const SizedBox(height: 16),

                        // Interested Investors
                        _buildSectionTitle('Interested Investors'),
                        Text(
                          '${widget.idea.investors.length} investors interested',
                        ),
                        const SizedBox(height: 16),

                        // Date Created
                        _buildSectionTitle('Date Created'),
                        Text(_formatDate(widget.idea.createdAt)),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildCategoryPicker() {
    final categories = [
      'FinTech',
      'Sustainable Technology',
      'Healthcare',
      'Education',
      'E-commerce',
      'AI & Machine Learning',
      'Blockchain',
      'Other',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: _selectedCategory,
        isExpanded: true,
        underline: const SizedBox(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedCategory = newValue;
            });
          }
        },
        items:
            categories.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
