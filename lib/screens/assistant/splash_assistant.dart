import 'package:flutter/material.dart';
import 'package:cardioguardian/widgets/glass_container.dart';
import 'package:cardioguardian/core/app_theme.dart';
import 'package:cardioguardian/core/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {"role": "ai", "content": "I've analyzed your latest vitals. Your heart rate variability is within the professional athletic range. How can I help you today?"},
  ];
  bool _isTyping = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add({"role": "user", "content": text});
      _isTyping = true;
      _controller.clear();
    });

    final reply = await ApiService.getAssistantResponse(text);
    
    if (mounted) {
      setState(() {
        _messages.add({"role": "ai", "content": reply});
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding, vertical: 20),
              child: _buildHeader(),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.horizontalPadding),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  if (msg["role"] == "ai") {
                    return _buildAIBubble(msg["content"]!);
                  } else {
                    return _buildUserBubble(msg["content"]!);
                  }
                },
              ),
            ),
            if (_isTyping) 
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 8),
                child: Row(
                  children: [
                    Text("AI is thinking...", style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "AI CHATBOX",
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Health Assistant",
              style: AppTheme.darkTheme.textTheme.headlineMedium,
            ),
            const Icon(FontAwesomeIcons.microphone, color: AppTheme.primaryColor, size: 20),
          ],
        ),
      ],
    );
  }

  Widget _buildAIBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.surfaceColor, shape: BoxShape.circle, border: Border.all(color: Colors.white10)),
            child: const Icon(FontAwesomeIcons.robot, size: 14, color: AppTheme.accentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.all(16),
              opacity: 0.05,
              child: Text(
                text,
                style: GoogleFonts.outfit(color: Colors.white, height: 1.5, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildUserBubble(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 40),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                text,
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.surfaceColor,
            child: Icon(Icons.person, size: 16, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
      child: Row(
        children: [
          Expanded(
            child: GlassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              radius: 30,
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Inquire about your health...",
                  hintStyle: GoogleFonts.outfit(color: Colors.white24, fontSize: 14),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              height: 50,
              width: 50,
              decoration: const BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
