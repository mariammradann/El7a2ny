import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/localization/app_strings.dart';
import '../models/alert_model.dart';
import '../app/main_shell_screen.dart';

class ReportFakeIncidentScreen extends StatefulWidget {
  final String incidentId;
  final AlertModel? incidentDetails;

  const ReportFakeIncidentScreen({
    super.key,
    required this.incidentId,
    this.incidentDetails,
  });

  @override
  State<ReportFakeIncidentScreen> createState() => _ReportFakeIncidentScreenState();
}

class _ReportFakeIncidentScreenState extends State<ReportFakeIncidentScreen> {
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  List<XFile> _attachedFiles = [];

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
    setState(() => _submitting = true);

    // Mock API call delay
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.loc.isAr 
                ? 'تم إرسال بلاغك لمراجعة الإدارة بنجاح!' 
                : 'Report submitted for admin review successfully!',
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
    
    final incidentTypeStr = widget.incidentDetails?.getLocalizedType(loc) ?? (isAr ? 'بلاغ غير معروف' : 'Unknown Incident');
    final title = isAr ? 'الإبلاغ عن بلاغ كاذب' : 'Report Fake Incident';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title, style: const TextStyle(fontFamily: 'NotoSansArabic')),
          backgroundColor: const Color(0xFFE61717),
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Incident Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE61717).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE61717).withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: const Color(0xFFE61717)),
                        const SizedBox(width: 8),
                        Text(
                          isAr ? 'تفاصيل البلاغ المُبلّغ عنه' : 'Reported Incident Details',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFFE61717), fontFamily: 'NotoSansArabic'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${isAr ? "رقم البلاغ" : "Incident ID"}: #${widget.incidentId.substring(0, 8)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${isAr ? "النوع" : "Type"}: $incidentTypeStr',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                isAr ? 'تفاصيل إضافية (اختياري)' : 'Additional Details (Optional)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'NotoSansArabic'),
              ),
              const SizedBox(height: 8),
              Text(
                isAr 
                    ? 'يرجى كتابة سبب الإبلاغ أو أي ملاحظات تثبت أن البلاغ كاذب' 
                    : 'Please explain why you think this incident is fake',
                style: const TextStyle(fontSize: 14, color: Colors.grey, fontFamily: 'NotoSansArabic'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: isAr ? 'اكتب ملاحظاتك هنا...' : 'Write your notes here...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
              const SizedBox(height: 32),

              Text(
                isAr ? 'إرفاق إثبات (اختياري)' : 'Attach Proof (Optional)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'NotoSansArabic'),
              ),
              const SizedBox(height: 8),
              Text(
                isAr 
                    ? 'يمكنك إضافة صور، فيديو، أو تسجيل صوتي يثبت صحة موقفك' 
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
                  backgroundColor: const Color(0xFFE61717),
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
                        isAr ? 'إرسال التقرير للإدارة' : 'Submit Report to Admin',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'NotoSansArabic'),
                      ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
