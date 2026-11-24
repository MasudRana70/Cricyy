// lib/widgets/match_delete_helper.dart
//
// Shared creator-only match deletion dialog & button helper.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../models/match_model.dart';
import '../providers/match_provider.dart';

/// Prompts the creator to confirm deleting [match] and performs deletion.
/// Returns `true` if the match was deleted.
Future<bool> confirmAndDeleteMatch(BuildContext context, MatchModel match) async {
  final prov = context.read<MatchProvider>();
  if (!prov.canDeleteMatch(match)) return false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.neoBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Row(
        children: [
          const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Delete Match?', style: AppTextStyles.headline3),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to delete "${match.team1Name} vs ${match.team2Name}"? '
        'It will be removed for everyone watching.',
        style: AppTextStyles.body2,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: Colors.white,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return false;

  final deleted = await prov.deleteMatch(match.id);
  if (!context.mounted) return deleted;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        deleted
            ? 'Match deleted'
            : (prov.error ?? 'Could not delete match'),
      ),
      duration: const Duration(seconds: 2),
    ),
  );
  return deleted;
}
