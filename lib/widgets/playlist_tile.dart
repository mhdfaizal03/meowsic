import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/playlist_controller.dart';
import '../models/playlist_model.dart';
import '../core/theme.dart';
import 'glass_container.dart';

class PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const PlaylistTile({super.key, required this.playlist, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final playlistController = Get.find<PlaylistController>();

    return GlassContainer(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.queue_music,
            color: AppTheme.primary,
            size: 30,
          ),
        ),
        title: Text(
          playlist.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          "${playlist.songs.length} songs",
          style: TextStyle(
            color: AppTheme.textSecondary.withValues(alpha: 0.8),
            fontSize: 13,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white54),
          onPressed: () {
            Get.defaultDialog(
              title: "Delete Playlist",
              middleText: "Are you sure you want to delete '${playlist.name}'?",
              backgroundColor: AppTheme.surface,
              titleStyle: const TextStyle(color: Colors.white),
              middleTextStyle: const TextStyle(color: Colors.white70),
              textConfirm: "Delete",
              textCancel: "Cancel",
              confirmTextColor: Colors.white,
              onConfirm: () {
                playlistController.deletePlaylist(playlist.id);
                Get.back();
              },
            );
          },
        ),
      ),
    );
  }
}
