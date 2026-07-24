import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/edge_theme.dart';
import 'device_fingerprint.dart';

class BenchScreen extends ConsumerWidget {
  const BenchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fingerprintAsync = ref.watch(deviceFingerprintProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('EDGEBENCH', style: EdgeTheme.monoTextStyle),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'DEVICE FINGERPRINT',
              style: EdgeTheme.monoTextStyle.copyWith(color: EdgeTheme.accentAction),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: EdgeTheme.surfaceRaised,
                borderRadius: BorderRadius.circular(8),
              ),
              child: fingerprintAsync.when(
                data: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('OS', data.osVersion),
                    _buildInfoRow('MODEL', data.model),
                    _buildInfoRow('MFG', data.manufacturer),
                    _buildInfoRow('PHYSICAL', data.isPhysicalDevice),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Text('Error loading fingerprint: $err'),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'TEST SURFACES',
              style: EdgeTheme.monoTextStyle.copyWith(color: EdgeTheme.accentAction),
            ),
            const SizedBox(height: 8),
            _buildActionCard(
              title: 'ORACLE',
              subtitle: 'LLM Text Generation & RAG',
              icon: Icons.chat_bubble_outline,
              onTap: () {
                // TODO: Navigate to Oracle
              },
            ),
            const SizedBox(height: 8),
            _buildActionCard(
              title: 'APERTURE',
              subtitle: 'Real-time Vision Pipeline',
              icon: Icons.camera_alt_outlined,
              onTap: () {
                // TODO: Navigate to Aperture
              },
            ),
            const SizedBox(height: 8),
            _buildActionCard(
              title: 'ECHO',
              subtitle: 'Offline Speech Command',
              icon: Icons.mic_none_outlined,
              onTap: () {
                // TODO: Navigate to Echo
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: EdgeTheme.monoTextStyle.copyWith(color: Colors.white70),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: EdgeTheme.monoTextStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: EdgeTheme.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: EdgeTheme.surfaceOverlay),
        ),
        child: Row(
          children: [
            Icon(icon, color: EdgeTheme.accentAction, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: EdgeTheme.monoTextStyle.copyWith(fontSize: 16)),
                  Text(subtitle, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
