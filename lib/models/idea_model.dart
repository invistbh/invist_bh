import 'package:cloud_firestore/cloud_firestore.dart';

class IdeaModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final String innovationDetails;
  final String investmentRequired;
  final List<String> investors;
  final String creatorId;
  final DateTime createdAt;

  IdeaModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.innovationDetails,
    required this.investmentRequired,
    required this.investors,
    required this.creatorId,
    required this.createdAt,
  });

  factory IdeaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IdeaModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      innovationDetails: data['innovationDetails'] ?? '',
      investmentRequired: data['investmentRequired'] ?? '',
      investors: List<String>.from(data['investors'] ?? []),
      creatorId: data['creatorId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'innovationDetails': innovationDetails,
      'investmentRequired': investmentRequired,
      'investors': investors,
      'creatorId': creatorId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
  
  IdeaModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? imageUrl,
    String? innovationDetails,
    String? investmentRequired,
    List<String>? investors,
    String? creatorId,
    DateTime? createdAt,
  }) {
    return IdeaModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      innovationDetails: innovationDetails ?? this.innovationDetails,
      investmentRequired: investmentRequired ?? this.investmentRequired,
      investors: investors ?? this.investors,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
