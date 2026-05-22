import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../core/localization/app_strings.dart';
import '../services/api_service.dart';

class UserDetailScreen extends StatefulWidget {
  final UserModel user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  bool _isLoading = false;

  Future<void> _verifyUser() async {
    final loc = context.loc;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              loc.confirmAction,
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            content: Text(
              'Are you sure you want to verify ${widget.user.name}?',
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
                  style: const TextStyle(color: Colors.green),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _isLoading = true);
    try {
      await ApiService.adminVerifyUser(widget.user.id);
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
        Navigator.pop(context, true); // Return true to refresh the list
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
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _suspendUser() async {
    final loc = context.loc;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              loc.confirmAction,
              style: const TextStyle(fontFamily: 'NotoSansArabic'),
            ),
            content: Text(
              'Are you sure you want to suspend ${widget.user.name}?',
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

    setState(() => _isLoading = true);
    try {
      await ApiService.adminSuspendUser(widget.user.id);
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
        Navigator.pop(context, true); // Return true to refresh the list
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
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          loc.userDetails ?? 'User Details',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontFamily: 'NotoSansArabic',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Container(
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.user.role == 'volunteer'
                              ? Icons.volunteer_activism_rounded
                              : Icons.person_rounded,
                          size: 48,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.user.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'NotoSansArabic',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.user.role.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                            fontFamily: 'NotoSansArabic',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusBackgroundColor(
                                widget.user.status,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.user.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(widget.user.status),
                                fontFamily: 'NotoSansArabic',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getVerificationBackgroundColor(
                                widget.user.status,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              widget.user.status == 'verified'
                                  ? 'VERIFIED'
                                  : 'PENDING',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: widget.user.status == 'verified'
                                    ? Colors.green
                                    : const Color(0xFFF18F34),
                                fontFamily: 'NotoSansArabic',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Personal Information
                _buildSectionHeader(
                  loc.personalInformation ?? 'Personal Information',
                ),
                const SizedBox(height: 12),
                _buildDetailCard(
                  icon: Icons.email_rounded,
                  label: loc.email ?? 'Email',
                  value: widget.user.email,
                  theme: theme,
                ),
                _buildDetailCard(
                  icon: Icons.phone_rounded,
                  label: loc.phone ?? 'Phone',
                  value: widget.user.phone,
                  theme: theme,
                ),
                _buildDetailCard(
                  icon: Icons.badge_rounded,
                  label: loc.nationalId ?? 'National ID',
                  value: widget.user.nationalId,
                  theme: theme,
                ),
                _buildDetailCard(
                  icon: Icons.cake_rounded,
                  label: loc.dateOfBirth ?? 'Date of Birth',
                  value: widget.user.birthDate,
                  theme: theme,
                ),
                const SizedBox(height: 20),

                // Health Information
                if (widget.user.bloodType.isNotEmpty ||
                    widget.user.gender.isNotEmpty) ...[
                  _buildSectionHeader(
                    loc.healthInformation ?? 'Health Information',
                  ),
                  const SizedBox(height: 12),
                  if (widget.user.gender.isNotEmpty)
                    _buildDetailCard(
                      icon: Icons.wc_rounded,
                      label: loc.gender ?? 'Gender',
                      value: widget.user.gender,
                      theme: theme,
                    ),
                  if (widget.user.bloodType.isNotEmpty)
                    _buildDetailCard(
                      icon: Icons.bloodtype_rounded,
                      label: loc.bloodType ?? 'Blood Type',
                      value: widget.user.bloodType,
                      theme: theme,
                    ),
                  const SizedBox(height: 20),
                ],

                // Volunteer Information
                if (widget.user.role == 'volunteer') ...[
                  _buildSectionHeader(
                    loc.volunteerInformation ?? 'Volunteer Information',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    icon: Icons.directions_car_rounded,
                    label: loc.hasVehicle ?? 'Has Vehicle',
                    value: widget.user.hasVehicle ? 'Yes' : 'No',
                    theme: theme,
                  ),
                  if (widget.user.skills != null &&
                      widget.user.skills!.isNotEmpty)
                    _buildDetailCard(
                      icon: Icons.star_rounded,
                      label: loc.skills ?? 'Skills',
                      value: widget.user.skills!,
                      theme: theme,
                    ),
                  if (widget.user.smartWatchModel != null &&
                      widget.user.smartWatchModel!.isNotEmpty)
                    _buildDetailCard(
                      icon: Icons.watch_rounded,
                      label: 'Smart Watch Model',
                      value: widget.user.smartWatchModel!,
                      theme: theme,
                    ),
                  if (widget.user.sensorModel != null &&
                      widget.user.sensorModel!.isNotEmpty)
                    _buildDetailCard(
                      icon: Icons.sensors_rounded,
                      label: 'Sensor Model',
                      value: widget.user.sensorModel!,
                      theme: theme,
                    ),
                  const SizedBox(height: 20),
                ],

                // Subscription Information
                if (widget.user.isPlus) ...[
                  _buildSectionHeader(
                    loc.subscriptionInfo ?? 'Subscription Information',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailCard(
                    icon: Icons.card_membership_rounded,
                    label: 'Plan Type',
                    value: widget.user.planType ?? 'N/A',
                    theme: theme,
                  ),
                  if (widget.user.subscriptionDate != null)
                    _buildDetailCard(
                      icon: Icons.calendar_today_rounded,
                      label: 'Subscription Date',
                      value: widget.user.subscriptionDate.toString().split(
                        ' ',
                      )[0],
                      theme: theme,
                    ),
                  if (widget.user.renewalDate != null)
                    _buildDetailCard(
                      icon: Icons.calendar_today_rounded,
                      label: 'Renewal Date',
                      value: widget.user.renewalDate.toString().split(' ')[0],
                      theme: theme,
                    ),
                  const SizedBox(height: 20),
                ],

                // Emergency Contacts
                if (widget.user.emergencyContacts.isNotEmpty) ...[
                  _buildSectionHeader(
                    loc.emergencyContacts ?? 'Emergency Contacts',
                  ),
                  const SizedBox(height: 12),
                  ...widget.user.emergencyContacts.map((contact) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'NotoSansArabic',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            contact.phone,
                            style: TextStyle(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (contact.relationship.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              contact.relationship,
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                ],

                const SizedBox(height: 100), // Space for bottom actions
              ],
            ),
          ),
          // Bottom Actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _verifyUser,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(
                        loc.actionVerify ?? 'Verify',
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _suspendUser,
                      icon: const Icon(Icons.block_rounded),
                      label: Text(
                        loc.actionSuspend ?? 'Suspend',
                        style: const TextStyle(fontFamily: 'NotoSansArabic'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE61717),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.onSurface,
        fontFamily: 'NotoSansArabic',
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NotoSansArabic',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'NotoSansArabic',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return const Color(0xFFE61717);
      case 'pending':
        return const Color(0xFFF18F34);
      default:
        return Colors.grey;
    }
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green.withValues(alpha: 0.1);
      case 'inactive':
        return const Color(0xFFE61717).withValues(alpha: 0.1);
      case 'pending':
        return const Color(0xFFF18F34).withValues(alpha: 0.1);
      default:
        return Colors.grey.withValues(alpha: 0.1);
    }
  }

  Color _getVerificationBackgroundColor(String status) {
    return status == 'verified'
        ? Colors.green.withValues(alpha: 0.1)
        : const Color(0xFFF18F34).withValues(alpha: 0.1);
  }
}
