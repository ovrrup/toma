import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/services/nostr_service.dart';
import '../../../../shared/widgets/animated_pressable.dart';
import '../../../../shared/widgets/frosted_glass_card.dart';

/// Serene, quiet community sanctuary where growers share quiet presence over Nostr.
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _activeChannelId = 'global_focus';
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<NostrChannelMessage>? _channelSub;
  StreamSubscription<bool>? _connectionSub;

  List<NostrChannelMessage> _messages = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initNostr();
  }

  void _initNostr() {
    final nostr = NostrService.instance;
    _isConnected = nostr.isConnected;
    _activeChannelId = nostr.activeChannelId;
    _messages = nostr.getMessagesForChannel(_activeChannelId);

    _channelSub = nostr.channelMessageStream.listen((msg) {
      if (msg.channelId == _activeChannelId && mounted) {
        setState(() {
          if (!_messages.any((m) => m.id == msg.id)) {
            _messages = nostr.getMessagesForChannel(_activeChannelId);
          }
        });
        _scrollToBottom();
      }
    });

    _connectionSub = nostr.connectionStream.listen((connected) {
      if (mounted) {
        setState(() => _isConnected = connected);
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _channelSub?.cancel();
    _connectionSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _switchChannel(String channelId) {
    setState(() {
      _activeChannelId = channelId;
      _messages = NostrService.instance.getMessagesForChannel(channelId);
    });
    NostrService.instance.setActiveChannel(channelId);
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    await NostrService.instance.sendChannelMessage(
      channelId: _activeChannelId,
      text: text,
    );
    setState(() {
      _messages = NostrService.instance.getMessagesForChannel(_activeChannelId);
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final channels = NostrService.focusChannels;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.sm),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sanctuary',
                    style: AppTypography.headlineMedium.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isConnected
                              ? AppColors.darkSuccess
                              : AppColors.darkPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _isConnected ? 'Nostr relays connected' : 'Offline / Ghost Mode',
                        style: const TextStyle(
                          color: AppColors.darkTextSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              AnimatedPressable(
                onTap: () => _showPairingModal(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkBorderGlass),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.qr_code, size: 14, color: AppColors.darkTextPrimary),
                      SizedBox(width: 5),
                      Text(
                        'Pair',
                        style: TextStyle(
                          color: AppColors.darkTextPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Channel Selector Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: channels.map((channel) {
                final isCurrent = channel.id == _activeChannelId;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0, top: 4, bottom: 8),
                  child: GestureDetector(
                    onTap: () => _switchChannel(channel.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.darkPrimary.withValues(alpha: 0.22)
                            : Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.darkPrimary.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Text(
                        channel.name,
                        style: TextStyle(
                          color: isCurrent ? Colors.white : AppColors.darkTextSecondary,
                          fontSize: 12,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),

          // Quiet Message Feed
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyChannelState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildMessageTile(msg);
                    },
                  ),
          ),

          // Quiet Message Input Bar
          Padding(
            padding: const EdgeInsets.only(bottom: 90.0, top: 4.0),
            child: FrostedGlassCard(
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Share a quiet thought...',
                        hintStyle: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  AnimatedPressable(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.darkPrimary.withValues(alpha: 0.8),
                      ),
                      child: const Icon(Icons.arrow_upward, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChannelState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.spa_outlined,
            size: 28,
            color: AppColors.darkSecondary,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Sanctuary is silent',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 3),
          Text(
            'A peaceful space to focus together.',
            style: TextStyle(
              color: AppColors.darkTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageTile(NostrChannelMessage msg) {
    final userPubkey = NostrService.instance.npub ?? '';
    final isSelf = msg.pubkey.isNotEmpty && userPubkey.contains(msg.pubkey);
    final displayAuthor = isSelf ? 'You' : _truncatePubkey(msg.pubkey);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: msg.isMilestone
            ? AppColors.darkPrimary.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: msg.isMilestone
              ? AppColors.darkPrimary.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayAuthor,
                style: TextStyle(
                  color: isSelf ? AppColors.darkPrimary : AppColors.darkSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatTime(msg.createdAt),
                style: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            msg.content,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  void _showPairingModal(BuildContext context) {
    final qrPayload = NostrService.instance.getPairingQr();
    final npub = NostrService.instance.npub ?? '';
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FrostedGlassCard(
        borderRadius: AppSpacing.radiusLg,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Peer Pairing',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Connect with a focus peer directly on Nostr.',
                style: TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.md),

              // QR Code
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: 150.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF130B0D),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF130B0D),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: npub));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Public key (npub) copied'),
                      backgroundColor: AppColors.darkPrimary,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.copy, size: 12, color: AppColors.darkSecondary),
                      const SizedBox(width: 5),
                      Text(
                        _truncatePubkey(npub),
                        style: const TextStyle(
                          color: AppColors.darkSecondary,
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Paste friend\'s npub...',
                  hintStyle: const TextStyle(color: AppColors.darkTextSecondary, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: AnimatedPressable(
                  onTap: () async {
                    final key = textController.text.trim();
                    if (key.isNotEmpty) {
                      await NostrService.instance.pairFriendFromQr(key);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connected with peer!'),
                            backgroundColor: AppColors.darkPrimary,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: AppColors.darkPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Follow Peer',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  String _truncatePubkey(String key) {
    if (key.length <= 16) return key;
    return '${key.substring(0, 8)}...${key.substring(key.length - 6)}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
