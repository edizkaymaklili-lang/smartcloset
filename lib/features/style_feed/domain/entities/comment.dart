import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Comment on a style post
class Comment extends Equatable {
  final String id;
  final String postId;
  final String userId;
  final String userDisplayName;
  final String? userAvatar;
  final String text;
  final DateTime createdAt;
  final int likes;
  final List<String> likedBy;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userDisplayName,
    this.userAvatar,
    required this.text,
    required this.createdAt,
    this.likes = 0,
    this.likedBy = const [],
  });

  /// Check if current user has liked this comment
  bool isLikedBy(String currentUserId) => likedBy.contains(currentUserId);

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'userId': userId,
        'userDisplayName': userDisplayName,
        'userAvatar': userAvatar,
        'text': text,
        'createdAt': Timestamp.fromDate(createdAt),
        'likes': likes,
        'likedBy': likedBy,
      };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        id: json['id'] as String,
        postId: json['postId'] as String,
        userId: json['userId'] as String,
        userDisplayName: json['userDisplayName'] as String,
        userAvatar: json['userAvatar'] as String?,
        text: json['text'] as String,
        createdAt: (json['createdAt'] as Timestamp).toDate(),
        likes: json['likes'] as int? ?? 0,
        likedBy: List<String>.from(json['likedBy'] as List? ?? []),
      );

  Comment copyWith({
    String? id,
    String? postId,
    String? userId,
    String? userDisplayName,
    String? userAvatar,
    String? text,
    DateTime? createdAt,
    int? likes,
    List<String>? likedBy,
  }) =>
      Comment(
        id: id ?? this.id,
        postId: postId ?? this.postId,
        userId: userId ?? this.userId,
        userDisplayName: userDisplayName ?? this.userDisplayName,
        userAvatar: userAvatar ?? this.userAvatar,
        text: text ?? this.text,
        createdAt: createdAt ?? this.createdAt,
        likes: likes ?? this.likes,
        likedBy: likedBy ?? this.likedBy,
      );

  @override
  List<Object?> get props => [
        id,
        postId,
        userId,
        userDisplayName,
        userAvatar,
        text,
        createdAt,
        likes,
        likedBy,
      ];
}
