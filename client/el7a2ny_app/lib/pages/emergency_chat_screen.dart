import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../data/models/chat_message.dart';
import '../data/models/emergency_contact.dart';
import '../services/api_service.dart';
import '../services/ai_service.dart';

class EmergencyChatScreen extends StatefulWidget {
  const EmergencyChatScreen({super.key});

  @override
  State<EmergencyChatScreen> createState() => _EmergencyChatScreenState();
}

class _EmergencyChatScreenState extends State<EmergencyChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<ChatMessage> _messages = [];
  List<EmergencyContact> _contacts = [];
  bool _loadingContacts = false;

  @override
  void initState() {
    super.initState();
    // Use post-frame to ensure context.loc is available if needed, 
    // but here we just initialize with a generic localized welcome
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: context.loc.isAr 
                ? 'مرحباً! أنا مساعد الطوارئ الذكي. كيف يمكنني مساعدتك اليوم؟' 
                : 'Hello! I am your AI Emergency Assistant. How can I help you today?',
            source: MessageSource.bot,
            timestamp: DateTime.now(),
          ));
        });
        _loadContacts();
      }
    });
  }

  Future<void> _loadContacts() async {
    try {
      setState(() => _loadingContacts = true);
      final data = await ApiService.fetchEmergencyContacts();
      if (mounted) {
        setState(() {
          _contacts = data;
          _loadingContacts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingContacts = false);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    final userText = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(
        text: userText,
        source: MessageSource.user,
        timestamp: DateTime.now(),
      ));
    });
    
    _messageController.clear();
    _scrollToBottom();

    // Show "Processing" message
    final botPlaceholder = ChatMessage(
      text: context.loc.isAr ? 'جاري التفكير...' : 'Thinking...',
      source: MessageSource.bot,
      timestamp: DateTime.now(),
    );
    
    setState(() => _messages.add(botPlaceholder));
    _scrollToBottom();

    // Get real response from Gemini
    final response = await AiService.getResponse(userText);
    
    if (!mounted) return;
    
    setState(() {
      // Replace the last message with the real response
      _messages.removeLast();
      _messages.add(ChatMessage(
        text: response,
        source: MessageSource.bot,
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            _buildHeader(context),
            _buildQuickMenu(context),
            Expanded(child: _buildChatList()),
            _buildInputArea(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 20,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surfaceContainer : const Color(0xFF2D3243),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 8),
              _PulseIndicator(),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.chatBotTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                  Text(
                    context.loc.chatBotSubtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                      fontFamily: 'NotoSansArabic',
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMenu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              context.loc.quickMenu,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                fontFamily: 'NotoSansArabic',
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildMenuCard(
                  context,
                  title: context.loc.servicesAction,
                  icon: Icons.phone_callback_rounded,
                  color: const Color(0xFF4A5568),
                  onTap: () => _showServicesPopup(context),
                ),
                _buildMenuCard(
                  context,
                  title: context.loc.contactsAction,
                  icon: Icons.people_outline_rounded,
                  color: const Color(0xFF0D9488),
                  onTap: () => _showContactsPopup(context),
                ),
                _buildMenuCard(
                  context,
                  title: context.loc.instructionsAction,
                  icon: Icons.menu_book_rounded,
                  color: const Color(0xFF4F46E5),
                  onTap: () => _showInstructionsPopup(context),
                ),
              ],
            ),
          ),
          const Divider(height: 32, thickness: 1, color: Color(0xFFF1F5F9)),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required String title,
      required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'NotoSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final m = _messages[index];
        final isBot = m.source == MessageSource.bot;
        return Align(
          alignment: isBot ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: isBot ? (isDark ? theme.colorScheme.primaryContainer : const Color(0xFF434D65)) : (isDark ? theme.colorScheme.surface : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isBot ? 16 : 0),
                bottomRight: Radius.circular(isBot ? 0 : 16),
              ),
              border: isBot ? null : Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.text,
                  style: TextStyle(
                    color: isBot ? (isDark ? theme.colorScheme.onPrimaryContainer : Colors.white) : theme.colorScheme.onSurface,
                    fontSize: 14,
                    height: 1.4,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${m.timestamp.hour}:${m.timestamp.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isBot ? Colors.white70 : Colors.black54,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 10,
        top: 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.mic_none_rounded, color: Theme.of(context).primaryColor),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.loc.isAr ? 'بدء تسجيل الرسالة الصوتية...' : 'Starting voice recording...')),
                  );
                },
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: context.loc.chatInputHint,
                      border: InputBorder.none,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.image_outlined, size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.loc.isAr ? 'فتح المعرض...' : 'Opening gallery...')),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.videocam_outlined, size: 20),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(context.loc.isAr ? 'فتح الكاميرا...' : 'Opening camera...')),
                              );
                            },
                          ),
                        ],
                      ),
                      hintStyle: TextStyle(
                        fontFamily: 'NotoSansArabic',
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(

                decoration: const BoxDecoration(
                  color: Color(0xFF434D65),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.loc.chatFooterNote,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 10, fontFamily: 'NotoSansArabic'),
          ),
        ],
      ),
    );
  }

  void _showServicesPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            context.loc.chooseService,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildServiceItem(context, '911', context.loc.policeService, const Color(0xFF0391DC)),
              const SizedBox(height: 12),
              _buildServiceItem(context, '997', context.loc.ambulanceService, const Color(0xFFFF2D55)),
              const SizedBox(height: 12),
              _buildServiceItem(context, '998', context.loc.fireService, const Color(0xFFE67E22)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem(BuildContext context, String number, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
              ),
              Text(number, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
          const Icon(Icons.info_outline_rounded, color: Colors.white70),
        ],
      ),
    );
  }

  void _showContactsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            context.loc.emergencyContactsTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: _loadingContacts 
              ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
              : _contacts.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(context.loc.isAr ? 'لا يوجد جهات اتصال' : 'No emergency contacts found', textAlign: TextAlign.center),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _contacts.length,
                    itemBuilder: (context, i) => Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_contacts[i].name, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic')),
                              Text(_contacts[i].phone, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            ],
                          ),
                          const Icon(Icons.people_outline, color: Color(0xFF14B8A6)),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showInstructionsPopup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            context.loc.emergencyInstructionsTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInstructionItem(context, context.loc.cprInstruction, Colors.pink.shade50, Colors.pink),
              const SizedBox(height: 8),
              _buildInstructionItem(context, context.loc.firstAidInstruction, Colors.green.shade50, Colors.green),
              const SizedBox(height: 8),
              _buildInstructionItem(context, context.loc.fireSafetyInstruction, Colors.orange.shade50, Colors.orange),
              const SizedBox(height: 8),
              _buildInstructionItem(context, context.loc.earthquakeSafetyInstruction, Colors.blue.shade50, Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(BuildContext context, String label, Color bg, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'NotoSansArabic')),
          Icon(Icons.menu_book_rounded, color: iconColor),
        ],
      ),
    );
  }
}

class _PulseIndicator extends StatefulWidget {
  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(seconds: 1), vsync: this)..repeat(reverse: true);
    _scale = Tween(begin: 1.0, end: 1.4).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(color: Color(0xFF00C853), shape: BoxShape.circle),
      ),
    );
  }
}
