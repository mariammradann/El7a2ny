import 'package:flutter/material.dart';
import '../core/localization/app_strings.dart';
import '../services/session_service.dart';
import 'sponsors_page.dart';
import 'premium_subscription_page.dart';
import 'stat_card.dart';
import 'incident_analysis_page.dart';
import 'user_detail_screen.dart';
import '../services/api_service.dart';
import '../models/user_model.dart';
import '../models/admin_stats_model.dart';

class AdminScreen extends StatefulWidget {
  final bool isNested;
  const AdminScreen({super.key, this.isNested = false});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  AdminStats? _stats;
  List<UserModel> _users = [];
  List<dynamic> _sponsorRequests = [];
  bool _loadingStats = true;
  bool _loadingUsers = true;
  bool _loadingRequests = true;
  String? _statsError;
  String? _usersError;
  String? _requestsError;
  Map<String, bool> _actionLoading = {}; // Track loading state per user/request

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
    _loadUsers();
    _loadSponsorRequests();
  }

  Future<void> _loadSponsorRequests() async {
    try {
      setState(() {
        _loadingRequests = true;
        _requestsError = null;
      });
      final data = await ApiService.fetchSponsorRequests();
      if (mounted) {
        setState(() {
          _sponsorRequests = data;
          _loadingRequests = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _requestsError = e.toString();
          _loadingRequests = false;
        });
      }
    }
  }

  Future<void> _handleSponsorResponse(String requestId, String action) async {
    setState(() => _actionLoading[requestId] = true);
    try {
      final success = await ApiService.respondToSponsorRequest(requestId, action);
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                action == 'approve' ? 'Request approved successfully' : 'Request rejected successfully',
                style: const TextStyle(fontFamily: 'NotoSansArabic'),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: action == 'approve' ? Colors.green : const Color(0xFF8A1717),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        await _loadSponsorRequests();
      } else {
        throw Exception("Failed to respond to request");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFE61717),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionLoading[requestId] = false);
      }
    }
  }

  Future<void> _loadStats() async {
    try {
      setState(() {
        _loadingStats = true;
        _statsError = null;
      });
      final data = await ApiService.fetchAdminStats();
      if (mounted)
        setState(() {
          _stats = data;
          _loadingStats = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _statsError = e.toString();
          _loadingStats = false;
        });
    }
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _loadingUsers = true;
        _usersError = null;
      });
      final data = await ApiService.fetchUserList();
      if (mounted)
        setState(() {
          _users = data;
          _loadingUsers = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _usersError = e.toString();
          _loadingUsers = false;
        });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final primary = theme.primaryColor;

    if (widget.isNested) {
      return Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: primary,
            unselectedLabelColor: theme.colorScheme.onSurface.withValues(
              alpha: 0.5,
            ),
            indicatorColor: primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              fontFamily: 'NotoSansArabic',
            ),
            tabs: [
              Tab(text: loc.dashboard),
              Tab(text: loc.userManagement),
              Tab(text: loc.resources),
              Tab(text: loc.adminLogs),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  onRefresh: _loadStats,
                  color: primary,
                  child: _buildDashboardTab(context),
                ),
                RefreshIndicator(
                  onRefresh: _loadUsers,
                  color: primary,
                  child: _buildUsersTab(context),
                ),
                _buildResourcesTab(context),
                RefreshIndicator(
                  onRefresh: _loadSponsorRequests,
                  color: primary,
                  child: _buildLogsTab(context),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          loc.adminDashboard,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: 'NotoSansArabic',
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(
            alpha: 0.5,
          ),
          indicatorColor: primary,
          indicatorWeight: 3,
          tabs: [
            Tab(text: loc.dashboard),
            Tab(text: loc.userManagement),
            Tab(text: loc.resources),
            Tab(text: loc.adminLogs),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RefreshIndicator(
            onRefresh: _loadStats,
            color: primary,
            child: _buildDashboardTab(context),
          ),
          RefreshIndicator(
            onRefresh: _loadUsers,
            color: primary,
            child: _buildUsersTab(context),
          ),
          _buildResourcesTab(context),
          RefreshIndicator(
            onRefresh: _loadSponsorRequests,
            color: primary,
            child: _buildLogsTab(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(BuildContext context) {
    final loc = context.loc;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: loc.systemHealth),
          const SizedBox(height: 16),
          if (_loadingStats)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_statsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Error loading stats: $_statsError')),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: loc.totalUsers,
                    value: _stats?.totalUsers.toString() ?? '0',
                    unit: '',
                    gradientColors: const [
                      Color(0xFF6366F1),
                      Color(0xFF4F46E5),
                    ],
                    icon: Icons.people_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: loc.globalAlerts,
                    value: _stats?.activeAlerts.toString() ?? '0',
                    unit: '',
                    gradientColors: const [
                      Color(0xFFE61717),
                      Color(0xFF8A1717),
                    ],
                    icon: Icons.notifications_active_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: loc.responseTime,
                    value: _stats?.avgResponseTime ?? '0:00',
                    unit: loc.minute,
                    gradientColors: const [
                      Color(0xFF10B981),
                      Color(0xFF059669),
                    ],
                    icon: Icons.timer_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: loc.successRate,
                    value: ((_stats?.successRate ?? 0.0) * 100)
                        .toInt()
                        .toString(),
                    unit: '%',
                    gradientColors: const [
                      Color(0xFFFDC800),
                      Color(0xFFE95F32),
                    ],
                    icon: Icons.verified_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _SectionHeader(title: loc.responseEfficiency),
            const SizedBox(height: 20),
            _CustomBarChart(values: _stats?.weeklyEfficiency ?? []),
          ],
          const SizedBox(height: 32),
          _SectionHeader(title: loc.recentActivity),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: SessionService(),
            builder: (context, _) {
              final logs = SessionService().activityLog;
              if (logs.isEmpty) {
                return Text(
                  loc.noRecentActivity,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                );
              }
              return Column(
                children: logs
                    .take(3)
                    .map((log) => _buildActivityItem(log, ''))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 32),
          _buildRegionalInsights(context),
        ],
      ),
    );
  }

  Widget _buildRegionalInsights(BuildContext context) {
    final loc = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: loc.regionalInsights),
        const SizedBox(height: 16),
        _AreaStatusCard(
          title: loc.inactiveAreas,
          areas: const ['Suez', 'Fayoum', 'Beni Suef'],
          color: const Color(0xFFE61717),
          icon: Icons.location_off_rounded,
        ),
        const SizedBox(height: 12),
        _AreaStatusCard(
          title: loc.lowVolunteeringAreas,
          areas: const ['Alexandria (West)', 'Ismailia'],
          color: const Color(0xFFF18F34),
          icon: Icons.person_search_rounded,
        ),
        const SizedBox(height: 12),
        _AreaStatusCard(
          title: loc.activeVolunteeringAreas,
          areas: const ['Cairo (Central)', 'Giza', 'Mansoura'],
          color: Colors.green,
          icon: Icons.volunteer_activism_rounded,
        ),
      ],
    );
  }

  Widget _buildLogsTab(BuildContext context) {
    final loc = context.loc;
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: SessionService(),
      builder: (context, _) {
        final logs = SessionService().activityLog;

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            // --- Section 1: Partnership Requests ---
            _SectionHeader(title: loc.isAr ? 'طلبات الشراكة' : 'Partnership Requests'),
            const SizedBox(height: 16),
            if (_loadingRequests)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_requestsError != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: [
                    Text(
                      loc.isAr
                          ? 'خطأ في تحميل الطلبات: $_requestsError'
                          : 'Error loading requests: $_requestsError',
                      style: const TextStyle(color: Color(0xFFE61717)),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _loadSponsorRequests,
                      child: Text(loc.retry),
                    ),
                  ],
                ),
              )
            else if (_sponsorRequests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    loc.isAr ? 'لا توجد طلبات شراكة حالياً' : 'No partnership requests currently',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sponsorRequests.length,
                itemBuilder: (context, index) {
                  final req = _sponsorRequests[index];
                  final String requestId = req['request_id'] ?? '';
                  final String companyName = req['company_name'] ?? '';
                  final String contactPerson = req['contact_person'] ?? '';
                  final String phoneNumber = req['phone_number'] ?? '';
                  final String message = req['message'] ?? '';
                  final String status = req['status'] ?? 'pending';
                  final String createdAt = req['created_at'] ?? '';
                  final String? userName = req['user_name'];
                  
                  final isActionLoading = _actionLoading[requestId] ?? false;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  companyName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getSponsorStatusColor(status).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getSponsorStatusText(status, loc.isAr),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getSponsorStatusColor(status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            loc.isAr ? 'مسؤول التواصل: ' : 'Contact: ',
                            contactPerson,
                            theme,
                          ),
                          const SizedBox(height: 6),
                          _buildDetailRow(
                            loc.isAr ? 'رقم الهاتف: ' : 'Phone: ',
                            phoneNumber,
                            theme,
                          ),
                          if (userName != null) ...[
                            const SizedBox(height: 6),
                            _buildDetailRow(
                              loc.isAr ? 'المستخدم: ' : 'User: ',
                              userName,
                              theme,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            loc.isAr ? 'الرسالة:' : 'Message:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.dividerColor.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Text(
                              message,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              _formatDate(createdAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          if (status.toLowerCase() == 'pending') ...[
                            const SizedBox(height: 12),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isActionLoading)
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else ...[
                                  TextButton(
                                    onPressed: () => _handleSponsorResponse(requestId, 'reject'),
                                    child: Text(
                                      loc.isAr ? 'رفض' : 'Reject',
                                      style: const TextStyle(
                                        color: Color(0xFFE61717),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _handleSponsorResponse(requestId, 'approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      loc.isAr ? 'قبول' : 'Approve',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 32),
            // --- Section 2: Admin Logs ---
            _SectionHeader(title: loc.adminLogs),
            const SizedBox(height: 16),
            if (logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    loc.noRecentActivity,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return _buildActivityItem(logs[index], '');
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 13,
          color: theme.colorScheme.onSurface,
          fontFamily: 'NotoSansArabic',
        ),
        children: [
          TextSpan(
            text: label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }

  Color _getSponsorStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return const Color(0xFFE61717);
      case 'pending':
      default:
        return const Color(0xFFF18F34);
    }
  }

  String _getSponsorStatusText(String status, bool isAr) {
    switch (status.toLowerCase()) {
      case 'approved':
        return isAr ? 'تم القبول' : 'Approved';
      case 'rejected':
        return isAr ? 'تم الرفض' : 'Rejected';
      case 'pending':
      default:
        return isAr ? 'قيد الانتظار' : 'Pending';
    }
  }

  String _formatDate(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
    } catch (_) {
      if (isoString.length >= 10) {
        return isoString.substring(0, 10);
      }
      return isoString;
    }
  }

  Widget _buildResourcesTab(BuildContext context) {
    final loc = context.loc;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ResourceLink(
          title: loc.sponsorManagement,
          subtitle: loc.addEditRemoveSponsor,
          icon: Icons.handshake_rounded,
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SponsorsPage()));
          },
        ),
        const SizedBox(height: 16),
        _ResourceLink(
          title: loc.subscriptionPlans,
          subtitle: loc.modifyPricing,
          icon: Icons.card_membership_rounded,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PremiumSubscriptionPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        _ResourceLink(
          title: loc.incidentAnalysis,
          subtitle: loc.viewHeatmaps,
          icon: Icons.analytics_rounded,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const IncidentAnalysisPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUsersTab(BuildContext context) {
    final loc = context.loc;

    if (_loadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_usersError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: const Color(0xFFE61717),
              size: 48,
            ),
            const SizedBox(height: 12),
            Text('Error: $_usersError'),
            TextButton(onPressed: _loadUsers, child: Text(loc.retry)),
          ],
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(child: Text(loc.noUsersFound));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final isLoading = _actionLoading[user.id] ?? false;
        return GestureDetector(
          onTap: () async {
            final shouldRefresh = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
            );
            if (shouldRefresh == true) {
              _loadUsers();
            }
          },
          child: _AdminCard(
            title: user.name,
            subtitle: user.email,
            trailingText: user.role.toUpperCase(),
            statusText: user.status.toUpperCase(),
            icon: user.role == 'volunteer'
                ? Icons.volunteer_activism_rounded
                : Icons.person_rounded,
            actions: [
              _AdminAction(
                label: context.loc.actionVerify,
                color: Colors.green,
                isLoading: isLoading,
                onTap: isLoading ? null : () => _verifyUser(context, user),
              ),
              _AdminAction(
                label: context.loc.actionSuspend,
                color: const Color(0xFFE61717),
                isLoading: isLoading,
                onTap: isLoading ? null : () => _suspendUser(context, user),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _verifyUser(BuildContext context, UserModel user) async {
    final loc = context.loc;
    setState(() => _actionLoading[user.id] = true);
    try {
      await ApiService.adminVerifyUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.userVerifiedMsg,
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        _loadUsers(); // Refresh the user list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFE61717),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionLoading[user.id] = false);
      }
    }
  }

  Future<void> _suspendUser(BuildContext context, UserModel user) async {
    final loc = context.loc;

    // Show confirmation dialog
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              loc.confirmAction,
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            content: Text(
              'Are you sure you want to suspend ${user.name}?',
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(loc.cancel ?? 'Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  loc.confirm ?? 'Confirm',
                  style: const TextStyle(color: const Color(0xFFE61717)),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _actionLoading[user.id] = true);
    try {
      await ApiService.adminSuspendUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc.userSuspendedMsg,
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFF18F34),
            duration: const Duration(seconds: 2),
          ),
        );
        _loadUsers(); // Refresh the user list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFE61717),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _actionLoading[user.id] = false);
      }
    }
  }

  Widget _buildActivityItem(String text, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
          Text(
            time,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaStatusCard extends StatelessWidget {
  final String title;
  final List<String> areas;
  final Color color;
  final IconData icon;

  const _AreaStatusCard({
    required this.title,
    required this.areas,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: color,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: areas
                      .map(
                        (area) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            area,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.onSurface,
        fontFamily: 'NotoSansArabic',
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailingText;
  final String statusText;
  final IconData icon;
  final List<_AdminAction> actions;

  const _AdminCard({
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.statusText,
    required this.icon,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: theme.primaryColor),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                subtitle,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    trailingText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getStatusColor(context, statusText),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions
                    .map((a) => _buildActionButton(context, a))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BuildContext context, String status) {
    final loc = context.loc;
    if (status == loc.statusActiveAdmin || status == loc.statusResolvedAdmin)
      return Colors.green;
    if (status == loc.statusPending ||
        status == loc.statusDispatched ||
        status == loc.statusInProgress)
      return const Color(0xFFF18F34);
    return const Color(0xFFE61717);
  }

  Widget _buildActionButton(BuildContext context, _AdminAction action) {
    if (action.isLoading) {
      return SizedBox(
        width: 80,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(action.color),
            ),
          ),
        ),
      );
    }
    return TextButton(
      onPressed: action.onTap,
      child: Text(
        action.label,
        style: TextStyle(color: action.color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _AdminAction {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;
  _AdminAction({
    required this.label,
    required this.color,
    this.onTap,
    this.isLoading = false,
  });
}

class _ResourceLink extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ResourceLink({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _CustomBarChart extends StatelessWidget {
  final List<double> values;
  const _CustomBarChart({required this.values});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<String> days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (index) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                width: 20,
                height: 130 * (index < values.length ? values[index] : 0.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              if (index < days.length)
                Text(
                  days[index],
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }
}
