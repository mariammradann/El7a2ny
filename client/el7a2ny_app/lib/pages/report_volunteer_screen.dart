import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/localization/app_strings.dart';
import '../app/main_shell_screen.dart';

class ReportVolunteerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> volunteers;

  const ReportVolunteerScreen({
    super.key,
    required this.volunteers,
  });

  @override
  State<ReportVolunteerScreen> createState() => _ReportVolunteerScreenState();
}

class _ReportVolunteerScreenState extends State<ReportVolunteerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedVolunteerId;
  bool _submitting = false;
  List<XFile> _attachedFiles = [];

  @override
  void initState() {
    super.initState();
    if (widget.volunteers.length == 1) {
      _selectedVolunteerId = widget.volunteers.first['id'].toString();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> media = await picker.pickMultipleMedia();
    
    if (media.isNotEmpty) {
      setState(() {
        _attachedFiles.addAll(media);
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _attachedFiles.removeAt(index);
    });
  }

  void _submitReport() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedVolunteerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.loc.isAr ? 'برجاء اختيار المتطوع' : 'Please select a volunteer',
            style: const TextStyle(fontFamily: 'NotoSansArabic'),
          ),
          backgroundColor: const Color(0xFFE61717),
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    // Mock API call delay
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.loc.isAr 
                ? 'تم إرسال الشكوى للإدارة بنجاح وسيتم التحقيق فيها.' 
                : 'Report submitted successfully for admin review.',
            style: const TextStyle(fontFamily: 'NotoSansArabic'),
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => MainShellScreen()),
        (route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;
    final isAr = loc.isAr;
    
    final title = isAr ? 'الإبلاغ عن متطوع' : 'Report Volunteer';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontFamily: 'NotoSansArabic')),
          backgroundColor: const Color(0xFFE95F32),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Volunteer Selection
                Text(
                  isAr ? 'المتطوع' : 'Volunteer',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'NotoSansArabic'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedVolunteerId,
                  decoration: InputDecoration(
                    hintText: isAr ? 'اختر المتطوع الذي تود الإبلاغ عنه' : 'Select volunteer to report',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: widget.volunteers.map((v) {
                    return DropdownMenuItem<String>(
                      value: v['id'].toString(),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: const Color(0xFFE95F32),
                            child: const Icon(Icons.person, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          Text(v['name'].toString()),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedVolunteerId = val;
                    });
                  },
                  validator: (val) => val == null 
                    ? (isAr ? 'يجب اختيار المتطوع' : 'You must select a volunteer')
                    : null,
                ),
                const SizedBox(height: 32),

                // Mandatory Description
                Text(
                  isAr ? 'تفاصيل الشكوى (إجباري)' : 'Complaint Details (Mandatory)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'NotoSansArabic'),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr 
                      ? 'يرجى توضيح ما حدث بالضبط مع المتطوع، لا يمكن ترك هذا الحقل فارغاً.' 
                      : 'Please explain what happened exactly, this field cannot be empty.',
                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'NotoSansArabic'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: isAr ? 'اكتب شكواك هنا بالتفصيل...' : 'Write your complaint here in detail...',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return isAr ? 'يجب كتابة تفاصيل الشكوى' : 'Complaint details are required';
                    }
                    if (value.trim().length < 10) {
                      return isAr ? 'الرجاء كتابة تفاصيل أكثر' : 'Please provide more details';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Optional Proof Attachment
                Text(
                  isAr ? 'إرفاق إثبات (اختياري)' : 'Attach Proof (Optional)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'NotoSansArabic'),
                ),
                const SizedBox(height: 8),
                Text(
                  isAr 
                      ? 'يمكنك إضافة صور، فيديو، أو تسجيل صوتي يثبت الشكوى' 
                      : 'You can attach photos, videos, or audio records as proof',
                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'NotoSansArabic'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickFiles,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.attach_file_rounded),
                  label: Text(
                    isAr ? 'اختيار ملفات' : 'Choose Files',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
                  ),
                ),
                
                if (_attachedFiles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _attachedFiles.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final file = _attachedFiles[index];
                        return ListTile(
                          leading: const Icon(Icons.insert_drive_file_outlined, color: Colors.blue),
                          title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.close_rounded, color: const Color(0xFFE61717)),
                            onPressed: () => _removeFile(index),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _submitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE95F32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isAr ? 'إرسال الشكوى' : 'Submit Complaint',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
