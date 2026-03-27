import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/theme.dart';
import '../widgets/glass_container.dart';
import '../controllers/spotify_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spotifyController = Get.find<SpotifyController>();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Avatar
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white10,
                    child: Icon(Icons.person, size: 50, color: Colors.white.withValues(alpha: 0.8)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Meowsic User",
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Premium Member",
                  style: TextStyle(color: AppTheme.primary, fontSize: 14),
                ),
                const SizedBox(height: 30),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat("128", "Songs"),
                    _buildStat("12", "Playlists"),
                    _buildStat("45", "Artists"),
                  ],
                ),
                const SizedBox(height: 40),

                // Settings Sections
                _buildSectionHeader("Account"),
                Obx(() => _buildSettingTile(
                  Icons.settings_input_component,
                  spotifyController.isLoggedIn.value ? "Spotify Connected" : "Connect Spotify",
                  () => spotifyController.isLoggedIn.value ? null : spotifyController.login(),
                  trailing: spotifyController.isLoggedIn.value 
                    ? IconButton(icon: const Icon(Icons.logout, color: Colors.white54), onPressed: spotifyController.logout)
                    : null,
                )),
                
                const SizedBox(height: 20),
                _buildSectionHeader("Appearance"),
                _buildSettingTile(Icons.palette, "Theme Customization", () {}),
                _buildSettingTile(Icons.animation, "Glassmorphism Effects", () {}, trailing: Switch(value: true, onChanged: (v) {}, activeColor: AppTheme.primary)),
                
                const SizedBox(height: 20),
                _buildSectionHeader("About"),
                _buildSettingTile(Icons.info_outline, "Version 2.0.1", () {}),
                _buildSettingTile(Icons.code, "Credits", () {}),
                
                const SizedBox(height: 180), // Space for player
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, VoidCallback onTap, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
            if (trailing != null) trailing else const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}
