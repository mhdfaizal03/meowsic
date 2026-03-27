import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../models/song_model.dart';
import '../core/theme.dart';
import '../widgets/glass_container.dart';
import '../controllers/playlist_controller.dart';
import '../services/download_service.dart';

class SongTile extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;

  const SongTile({super.key, required this.song, required this.onTap});

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'youtube':
        return Colors.redAccent;
      case 'gaana':
        return Colors.blueAccent;
      case 'local':
        return Colors.greenAccent;
      default:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 80,
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: song.image,
            width: 55,
            height: 55,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: AppTheme.surface,
              width: 55,
              height: 55,
              child: const Icon(
                Icons.music_note,
                color: AppTheme.textSecondary,
              ),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getSourceColor(song.source).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                song.source.toUpperCase(),
                style: TextStyle(
                  color: _getSourceColor(song.source),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                song.artist,
                style: TextStyle(
                  color: AppTheme.textSecondary.withValues(alpha: 0.8),
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
          color: const Color(0xFF2B254E), // Match drawer/theme
          onSelected: (value) {
            if (value == 'playlist') {
              Get.find<PlaylistController>().showAddToPlaylistDialog(song);
            } else if (value == 'download') {
              DownloadService.downloadSong(song);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'playlist',
              child: Row(
                children: [
                  Icon(Icons.playlist_add, color: Colors.white70),
                  SizedBox(width: 10),
                  Text("Add to Playlist", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download, color: Colors.white70),
                  SizedBox(width: 10),
                  Text("Download", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, curve: Curves.easeOut);
  }
}
