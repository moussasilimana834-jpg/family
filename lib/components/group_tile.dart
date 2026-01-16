

import 'package:flutter/material.dart';


class GroupTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;


  const GroupTile({Key? key, required this.name, required this.subtitle, required this.onTap, this.trailing}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}