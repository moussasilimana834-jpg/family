import 'package:flutter/material.dart';


class GroupModel {
  final String id;
  final String name;
  final String adminId;
  final List<String> members;
  final DateTime createdAt;


  GroupModel({
    required this.id,
    required this.name,
    required this.adminId,
    required this.members,
    required this.createdAt,
  });


  factory GroupModel.fromMap(String id, Map<String, dynamic> map) {
    return GroupModel(
      id: id,
      name: map['name'] ?? 'Groupe',
      adminId: map['admin'] ?? '',
      members: List<String>.from(map['members'] ?? []),
      createdAt: (map['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }
}