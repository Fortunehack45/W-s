import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/design_system/tokens.dart';
import '../../feed/view_models/feed_view_model.dart';

class CreateVideoView extends ConsumerStatefulWidget {
  const CreateVideoView({super.key});

  @override
  ConsumerState<CreateVideoView> createState() => _CreateVideoViewState();
}

class _CreateVideoViewState extends ConsumerState<CreateVideoView> {
  String _selectedDuration = '60s';
  String _selectedMode = 'CAMERA';
  bool _isFlashOn = false;
  String _selectedSpeed = '1x';
  bool _isRecording = false;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Viewfinder Simulation
          Container(
            color: Colors.black,
            child: Center(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E1E28), Color(0xFF0F0F14)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.videocam_outlined,
                        color: Colors.white.withOpacity(0.15),
                        size: 96,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: WsTokens.brandGold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: WsTokens.brandGold.withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_outline, color: WsTokens.brandGold, size: 14),
                            SizedBox(width: 6),
                            Text(
                              '0 W Cost • 100% Free to Post',
                              style: TextStyle(
                                color: WsTokens.brandGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Top Bar (Screenshot 3 inspired: Close, Add sound)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),

                  // Add sound button in top center
                  GestureDetector(
                    onTap: _showSoundPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.music_note, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Add sound',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 40), // Balance close button
                ],
              ),
            ),
          ),

          // 3. Right Rail Controls (Flip, Speed, Filters, Timer, Flash)
          Positioned(
            top: 70,
            right: 16,
            child: Column(
              children: [
                _CameraToolButton(
                  icon: Icons.flip_camera_ios_outlined,
                  label: 'Flip',
                  onTap: () {},
                ),
                const SizedBox(height: 18),
                _CameraToolButton(
                  icon: Icons.speed,
                  label: _selectedSpeed,
                  onTap: () {
                    setState(() {
                      if (_selectedSpeed == '1x') {
                        _selectedSpeed = '2x';
                      } else if (_selectedSpeed == '2x') {
                        _selectedSpeed = '0.5x';
                      } else {
                        _selectedSpeed = '1x';
                      }
                    });
                  },
                ),
                const SizedBox(height: 18),
                _CameraToolButton(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Filters',
                  onTap: () {},
                ),
                const SizedBox(height: 18),
                _CameraToolButton(
                  icon: Icons.timer_outlined,
                  label: 'Timer',
                  onTap: () {},
                ),
                const SizedBox(height: 18),
                _CameraToolButton(
                  icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                  label: 'Flash',
                  onTap: () => setState(() => _isFlashOn = !_isFlashOn),
                ),
              ],
            ),
          ),

          // 4. Bottom Controls: Duration Selector, Big Red Shutter Button, Mode Switcher
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Duration Picker: 10m, 60s, 15s, PHOTO, TEXT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: ['10m', '60s', '15s', 'PHOTO', 'TEXT'].map((dur) {
                      final isSel = _selectedDuration == dur;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDuration = dur),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: isSel
                              ? BoxDecoration(
                                  color: Colors.white24,
                                  borderRadius: BorderRadius.circular(12),
                                )
                              : null,
                          child: Text(
                            dur,
                            style: TextStyle(
                              color: isSel ? Colors.white : Colors.white60,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Shutter Button & Gallery Upload Thumbnail (Screenshot 3 style)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 36.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left placeholder / Effect icon
                        const SizedBox(width: 48),

                        // Center Big Red Shutter Button
                        GestureDetector(
                          onTap: () {
                            if (_isRecording) {
                              setState(() => _isRecording = false);
                              _openPublishModal();
                            } else {
                              setState(() => _isRecording = true);
                            }
                          },
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _isRecording ? 36 : 64,
                                height: _isRecording ? 36 : 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFE2C55), // Iconic red
                                  borderRadius: BorderRadius.circular(_isRecording ? 8 : 32),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Right Gallery Upload Picker
                        GestureDetector(
                          onTap: _openPublishModal,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF282835),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white38, width: 1.5),
                                ),
                                child: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 24),
                              ),
                              const SizedBox(height: 4),
                              const Text('Upload', style: TextStyle(color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bottom Mode Switcher: LIVE, CAMERA, CREATE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ModeTab(label: 'LIVE (Soon)', isSelected: _selectedMode == 'LIVE', onTap: () => setState(() => _selectedMode = 'LIVE')),
                      const SizedBox(width: 24),
                      _ModeTab(label: 'CAMERA', isSelected: _selectedMode == 'CAMERA', onTap: () => setState(() => _selectedMode = 'CAMERA')),
                      const SizedBox(width: 24),
                      _ModeTab(label: 'CREATE', isSelected: _selectedMode == 'CREATE', onTap: () => setState(() => _selectedMode = 'CREATE')),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSoundPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: WsTokens.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Sound', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.music_note, color: WsTokens.brandGold),
                title: const Text('Viral Track - STORM II', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Original W\'s Audio • 0:45', style: TextStyle(color: Colors.white60)),
                trailing: const Icon(Icons.check, color: WsTokens.brandEmerald),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.music_note, color: Colors.white70),
                title: const Text('Momentum Beats 2026', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Trending Audio • 1:00', style: TextStyle(color: Colors.white60)),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPublishModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: WsTokens.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Publish Video to FYP',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: WsTokens.brandGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('0 W COST', style: TextStyle(color: WsTokens.brandGold, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: WsTokens.surfaceCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Caption & Hashtags (#crypto #viral)',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: WsTokens.surfaceCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isUploading) ...[
                    LinearProgressIndicator(value: _uploadProgress, color: WsTokens.brandGold),
                    const SizedBox(height: 8),
                    Text(
                      'TUS Chunk Upload: ${(_uploadProgress * 100).toInt()}%',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: WsTokens.brandGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isUploading
                          ? null
                          : () async {
                              final title = _titleController.text.trim();
                              if (title.isEmpty) return;
                              setModalState(() => _isUploading = true);
                              for (int i = 1; i <= 10; i++) {
                                await Future.delayed(const Duration(milliseconds: 100));
                                setModalState(() => _uploadProgress = i / 10.0);
                              }
                              // Push to feed state
                              final newId = 'vid-${DateTime.now().millisecondsSinceEpoch}';
                              final feedNotifier = ref.read(feedViewModelProvider.notifier);
                              feedNotifier.prependVideo(
                                VideoFeedItem(
                                  id: newId,
                                  creatorUsername: 'you',
                                  title: title,
                                  description: _descController.text.trim(),
                                  wCount: 0,
                                  repostCount: 0,
                                  commentCount: 0,
                                ),
                              );
                              if (mounted) {
                                Navigator.pop(ctx);
                                context.go('/');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: WsTokens.brandEmerald,
                                    content: Text('Video published live to FYP! Pool started at 0 W. ⚡', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  ),
                                );
                              }
                            },
                      child: const Text('Post to FYP (Free)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CameraToolButton extends StatelessWidget {
  const _CameraToolButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({required this.label, required this.isSelected, required this.onTap});
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.white60,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }
}
