import 'package:flutter/material.dart';
import 'locale_provider.dart';

extension LocalizationExtension on BuildContext {
  AppStrings get loc {
    final isAr = LocaleProvider.of(this).isArabic;
    return AppStrings(isAr);
  }
}

class AppStrings {
  final bool isAr;
  const AppStrings(this.isAr);

  String get appName => 'El7a2ny App';

  // Landing
  String get landingTitle =>
      isAr ? 'أهلاً بك في تطبيق إلحقني' : 'Welcome to El7a2ny App';
  String get landingSubtitle => isAr
      ? 'رفيقك الأمثل في أوقات الأزمات والطوارئ'
      : 'Your ultimate companion in times of crisis and emergencies';
  String get loginBtn => isAr ? 'تسجيل الدخول' : 'Login';
  String get createAccountBtn =>
      isAr ? 'إنشاء حساب جديد' : 'Create a New Account';

  // Landing specific
  String get landingAppName => 'الحقني';
  String get landingAppDesc =>
      isAr ? 'تطبيق الاستجابة للطوارئ' : 'Emergency Response App';
  String get landingEmergency => isAr ? 'بلاغ طوارئ' : 'Emergency Report';
  String get landingEmergencyDesc => isAr
      ? 'بلاغ طوارئ سريع من غير تسجيل'
      : 'Quick emergency report without registration';
  String get landingCreateAccount => isAr ? 'انشاء حساب' : 'Create Account';
  String get landingCreateAccountDesc => isAr
      ? 'سجل حساب عشان تستخدم كل المميزات'
      : 'Register an account to use all features';
  String get landingHaveAccount => isAr ? 'عندك اكونت؟ ' : 'Have an account? ';
  String get landingLoginBtn => isAr ? 'تسجيل دخول' : 'Login';

  // Welcome
  String get welcomeSystem => isAr ? 'نظام الطوارئ' : 'Emergency System';
  String get welcomeTag =>
      isAr ? 'منصة الاستجابة الذكية 🚨' : 'Smart Response Platform 🚨';
  String get welcomeSlogan => isAr
      ? 'سرعة في الاستجابة,\nأمان في كل لحظة.'
      : 'Fast Response,\nSafety in Every Moment.';
  String get welcomeDesc => isAr
      ? 'نظام متكامل يربطك بخدمات الطوارئ والمسعفين لحظياً لضمان سلامتك أنت وعائلتك.'
      : 'An integrated system connecting you to emergency services and paramedics instantly to ensure your and your family’s safety.';
  String get getStartedBtn => isAr ? 'ابدأ الآن' : 'Get Started';

  // Shared Auth
  String get email => isAr ? 'البريد الإلكتروني' : 'Email Address';
  String get emailHint => isAr ? 'أدخل بريدك الإلكتروني' : 'Enter your email';
  String get emailOrMobile => isAr ? 'البريد الإلكتروني أو رقم الموبايل' : 'Email or Mobile Number';
  String get emailOrMobileHint => isAr ? 'أدخل البريد أو رقم الموبايل' : 'Enter email or mobile number';
  String get requiredField => isAr ? 'مطلوب' : 'Required';
  String get password => isAr ? 'كلمة السر' : 'Password';
  String get passwordHint => isAr ? 'أدخل كلمة السر' : 'Enter your password';

  String get currentReading => isAr ? 'القراءة الحالية' : 'Current Reading';
  String get heatLabel => isAr ? 'الحرارة' : 'Heat';
  String get locationLabel => isAr ? 'الموقع' : 'Location';
  String get okBtn => isAr ? 'تم' : 'OK';
  String get yourLocation => isAr ? 'موقعك' : 'Your Location';
  String get timeLabel => isAr ? 'الوقت' : 'Time';

  String get ambulanceSupport => isAr ? 'دعم الإسعاف' : 'Ambulance Support';

  String get safetyDrillTitle => isAr ? 'تدريب السلامة' : 'Safety Drill';
  String get safetyDrillDesc => isAr ? 'تدريب افتراضي لحالات الطوارئ' : 'Virtual emergency drill';




  // Main Shell Menu
  String get menu => isAr ? 'القائمة' : 'Menu';
  String get settings => isAr ? 'الإعدادات' : 'Settings';
  String get logout => isAr ? 'تسجيل الخروج' : 'Log Out';
  String get help => isAr ? 'المساعدة — قريباً' : 'Help — Coming Soon';

  // Tabs
  String get tabHome => isAr ? 'الرئيسية' : 'Home';
  String get tabCommunity => isAr ? 'المجتمع' : 'Community';
  String get tabIstighatha => isAr ? 'استغاثة' : 'SOS';
  String get tabProfile => isAr ? 'حسابي' : 'Profile';
  String get tabInsights => isAr ? 'الإحصائيات' : 'Insights';

  // Home Tab Page
  String get connError => isAr ? 'تعذر الاتصال بالخادم.' : 'Connection failed.';
  String get retry => isAr ? 'إعادة المحاولة' : 'Retry';
  String get currentSystem =>
      isAr ? 'نظام الحالي للطوارئ' : 'Current Emergency System';
  String get responsePlatform => isAr
      ? 'منصة الاستجابة الذكية للطوارئ'
      : 'Smart Emergency Response Platform';
  String get deviceStatus => isAr ? 'حالة الأجهزة' : 'Device Status';
  String get quickAccess => isAr ? 'وصول سريع' : 'Quick Access';
  String get triggerAlert =>
      isAr ? 'تفعيل تنبيه الطوارئ 🚨' : 'Trigger Emergency 🚨';
  String get sensors => isAr ? 'حساسات' : 'Sensors';
  String get homeSensor => isAr ? 'حساس المنزل' : 'Home Sensor';
  String get theWatch => isAr ? 'الساعة' : 'Watch';
  String get smartWatch => isAr ? 'الساعة الذكية' : 'Smart Watch';
  String get sponsors => isAr ? 'الرعاة' : 'Sponsors';
  String get premiumSub => isAr ? 'اشتراك Premium' : 'Premium Subscription';
  String get emergencyDashboard =>
      isAr ? 'لوحة التحكم والطوارئ' : 'Dashboard & Emergency';
  String get alerts => isAr ? 'البلاغات' : 'Reports';
  String get allSystemsOperational =>
      isAr ? 'كل الأنظمة شغالة' : 'All systems operational';

  // Dashboard Tab
  String get responseTime => isAr ? 'وقت الاستجابة' : 'Response Time';
  String get minute => isAr ? 'دقيقة' : 'min';
  String get successRate => isAr ? 'معدل النجاح' : 'Success Rate';
  String get activeUnits => isAr ? 'الوحدات النشطة' : 'Active Units';
  String get emergencyServices => isAr ? 'خدمات الطوارئ' : 'Emergency Services';
  String get police => isAr ? 'الشرطة' : 'Police';
  String get ambulance => isAr ? 'الإسعاف' : 'Ambulance';
  String get fireDept => isAr ? 'المطافي' : 'Fire Dept';
  String get callNow => isAr ? 'جاري الاتصال' : 'Calling Now';
  String get callingPrefix => isAr ? 'جاري الاتصال بـ' : 'Calling';
  String get cannotOpenLog => isAr
      ? 'لا يمكن فتح شاشة الاتصال أو قراءة سجل المكالمات'
      : 'Could not open dialer or read call log';
  String get safetyTips => isAr ? 'إرشادات السلامة' : 'Safety Tips';
  String get safetyTipsDesc => isAr
      ? 'معلومات أساسية للاستعداد للطوارئ'
      : 'Basic emergency preparedness info';

  String get importantNumbers => isAr ? 'أرقام مهمة' : 'Important Numbers';


  String get additionalImportantNumbers =>
      isAr ? 'أرقام مهمة إضافية' : 'Additional Important Numbers';
  String get cannotCall => isAr ? 'تعذر الاتصال بـ ' : 'Could not call ';
  String get errorOccurred => isAr ? 'حدث خطأ: ' : 'An error occurred: ';
  String get cannotReachServer =>
      isAr ? 'مش قادر يوصل للسيرفر' : 'Cannot reach server';
  String get tryAgain => isAr ? 'حاول تاني' : 'Try Again';

  String get tip1Title => isAr ? 'الاستعداد للطوارئ' : 'Emergency Preparedness';
  String get tip1Desc => isAr
      ? 'احفظ أرقام الطوارئ في مكان سهل الوصول'
      : 'Keep emergency numbers easily accessible';
  String get tip2Title => isAr ? 'اعرف موقعك' : 'Know Your Location';
  String get tip2Desc => isAr
      ? 'كن دايماً عارف مكانك بالظبط عشان استجابة أسرع'
      : 'Always know your exact location for a faster response';
  String get tip3Title => isAr ? 'اهدى' : 'Stay Calm';
  String get tip3Desc => isAr
      ? 'اتكلم بوضوح وقول معلومات صحيحة وقت الطوارئ'
      : 'Speak clearly and provide accurate info during emergencies';

  String get civilDefense => isAr ? 'الحماية المدنية' : 'Civil Defense';
  String get antiDrugs => isAr ? 'مكافحة المخدرات' : 'Anti-Drugs';
  String get rescue => isAr ? 'النجدة' : 'Rescue';

  // Alerts Tab
  String get activeAlerts => isAr ? 'البلاغات النشطة' : 'Active Alerts';
  String get myAlerts => isAr ? 'بلاغاتي' : 'My Alerts';
  String get noAlerts => isAr ? 'مفيش بلاغات متسجلة' : 'No alerts recorded';
  String get completed => isAr ? 'مكتمل' : 'Completed';
  String get activeStatus => isAr ? ' نشط' : ' Active';
  String get pastAlert => isAr ? ' - بلاغ سابق' : ' - Past Alert';
  String get justNow => isAr ? 'حالا' : 'Just now';
  String get volunteers => isAr ? 'المتطوعون' : 'Volunteers';
  String get outOfLabel => isAr ? 'من' : 'out of';

  // Alert Details Page
  String get activeStatusNow => isAr ? 'نشط الآن' : 'Active Now';
  String get volunteeringRate => isAr ? 'نسبة التطوع' : 'Volunteering Rate';
  String get alertDetails => isAr ? 'تفاصيل البلاغ' : 'Alert Details';
  String get contactForInquiry => isAr ? 'للاستفسار والتواصل' : 'Contact for Inquiry';
  String get joinedBtn => isAr ? 'تم التسجيل' : 'Joined';

  // Severity
  String get severityHigh => isAr ? 'عالية' : 'High';
  String get severityMedium => isAr ? 'متوسطة' : 'Medium';
  String get severityLow => isAr ? 'منخفضة' : 'Low';

  // SOS Tab
  String get weGotYourBack => isAr ? 'احنا في ضهرك !' : 'We got your back!';
  String get pressSOSDesc => isAr
      ? 'دوس الحقني واحنا كلنا معاك .........'
      : 'Press SOS, we are all with you...';
  String get sosButton => isAr ? 'الحقني' : 'SOS';
  String get constantVibration => isAr ? 'اهتزاز دائم' : 'Constant Vibration';

  // Emergency Report
  String get enablePermissionsFirst => isAr
      ? 'فعّلي أذونات الكاميرا والموقع والميكروفون أولاً'
      : 'Enable camera, location, and mic permissions first';
  String get reportSubmitted =>
      isAr ? 'تم إرسال البلاغ' : 'Report submitted successfully';
  String get takePhoto => isAr ? 'التقط صورة' : 'Take a photo';
  String get chooseFromGallery =>
      isAr ? 'اختر من المعرض' : 'Choose from gallery';
  String get emergencyReportTitle => isAr ? 'بلاغ طوارئ' : 'Emergency Report';
  String get quickAccidentReport =>
      isAr ? 'بلاغ سريع عن حادث' : 'Quick accident report';
  String get requiredPermissions =>
      isAr ? 'الأذونات المطلوبة' : 'Required Permissions';
  String get camera => isAr ? 'الكاميرا' : 'Camera';
  String get location => isAr ? 'الموقع' : 'Location';
  String get mic => isAr ? 'الميكروفون' : 'Mic';
  String get theName => isAr ? 'الاسم' : 'Name';
  String get typeNameHint => isAr ? 'اكتب اسمك' : 'Type your name';
  String get mobileNum => isAr ? 'رقم الموبايل' : 'Mobile Number';
  String get enterValidMobile =>
      isAr ? 'أدخل رقم موبايل صحيح' : 'Enter a valid mobile number';
  String get emergencyDesc => isAr ? 'وصف الطوارئ' : 'Emergency Description';
  String get describeStateShort =>
      isAr ? 'اوصف الحالة باختصار' : 'Briefly describe the situation';
  String get describeMin8 => isAr
      ? 'اوصف الحالة باختصار (٨ أحرف على الأقل)'
      : 'Briefly describe the situation (min 8 chars)';
  String get evidenceMedia =>
      isAr ? 'إرفاق صورة أو فيديو (اختياري)' : 'Attach photo/video (Optional)';
  String get mediaFileAdded => isAr ? 'تم إرفاق ملف:' : 'Media attached:';
  String get sendReport => isAr ? 'إرسال البلاغ' : 'Send Report';
  String get phoneFormatHint => isAr ? '01xxxxxxxxx' : '01xxxxxxxxx';

  // Auth Screens
  String get welcomeBack => isAr ? 'حمدلله على السلامة' : 'Welcome Back';
  String get loginDesc => isAr
      ? 'سجل دخول عشان تتابع بلاغاتك وتساعد غيرك'
      : 'Login to track your reports and help others';
  String get rememberMe => isAr ? 'تذكرني' : 'Remember Me';
  String get forgotPasswordQ => isAr ? 'نسيت كلمة السر؟' : 'Forgot Password?';
  String get loginBtnMain => isAr ? 'تسجيل الدخول' : 'Login';
  String get noAccountQ => isAr ? 'معندكش حساب؟ ' : 'Don’t have an account? ';
  String get registerNow => isAr ? 'سجل الآن' : 'Register Now';
  String get orLoginWith => isAr ? 'أو سجل دخول بـ' : 'Or login with';
  String get socialLoginSuccess =>
      isAr ? 'تم تسجيل الدخول بنجاح عبر' : 'Successfully logged in via';
  String get socialLoginFail =>
      isAr ? 'فشل التسجيل عبر' : 'Failed to register via';

  String get recoveryTitle =>
      isAr ? 'طريقة استرجاع الباسورد' : 'Password Recovery Method';
  String get phoneOption => isAr ? 'الموبايل' : 'Phone';
  String get emailOption => isAr ? 'الإيميل' : 'Email';
  String get phoneFieldLabel => isAr ? 'رقم الموبايل' : 'Phone Number';
  String get emailFieldLabel =>
      isAr ? 'عنوان البريد الإلكتروني' : 'Email Address';
  String get sendVerificationCode =>
      isAr ? 'ارسال كود التحقق' : 'Send Verification Code';
  String get enterValidEmail =>
      isAr ? 'أدخل إيميل صحيح' : 'Enter a valid email';

  String get otpTitle => isAr ? 'كود التحقق' : 'Verification Code';
  String get otpSentMsg =>
      isAr ? 'دخل الكود اللي بعتناه ليك على' : 'Enter the code we sent to';
  String get otpInvalid => isAr ? 'كود غير صحيح' : 'Invalid code';
  String get sendBtn => isAr ? 'إرسال' : 'Send';
  String get didntReceiveCode =>
      isAr ? 'موصليش كود؟ ' : 'Didn’t receive a code? ';
  String get resendCode => isAr ? 'إعادة إرسال' : 'Resend Code';
  String get contactMissing => isAr
      ? 'بيانات الاتصال غير متوفرة — ارجعي للخطوة السابقة'
      : 'Contact info missing — go back to previous step';
  String get verifiedSuccess =>
      isAr ? 'تم التحقق من الكود' : 'Code verified successfully';
  String get resendSuccess =>
      isAr ? 'تم طلب إعادة الإرسال' : 'Resend requested successfully';

  // Password Change
  String get enterCurrentPassword =>
      isAr ? 'أدخل كلمة السر الحالية' : 'Enter Current Password';
  String get currentPasswordLabel =>
      isAr ? 'كلمة السر الحالية' : 'Current Password';
  String get newPasswordLabel => isAr ? 'كلمة السر الجديدة' : 'New Password';
  String get confirmNewPasswordLabel =>
      isAr ? 'تأكيد كلمة السر الجديدة' : 'Confirm New Password';
  String get passwordIncorrect =>
      isAr ? 'كلمة السر غير صحيحة' : 'Incorrect Password';
  String get passwordChangedSuccess =>
      isAr ? 'تم تغيير كلمة السر بنجاح' : 'Password changed successfully';

  // Settings
  String get account => isAr ? 'الحساب' : 'Account';
  String get editProfile => isAr ? 'تعديل الملف الشخصي' : 'Edit Profile';
  String get changePassword => isAr ? 'تغيير كلمة المرور' : 'Change Password';
  String get preferences => isAr ? 'التفضيلات' : 'Preferences';
  String get darkMode => isAr ? 'الوضع الليلي' : 'Dark Mode';
  String get notifications => isAr ? 'الإشعارات' : 'Notifications';
  String get language => isAr ? 'اللغة' : 'Language';
  String get arabicOrEnglish => isAr ? 'العربية' : 'English';
  String get helpAndSupport => isAr ? 'المساعدة والدعم' : 'Help & Support';
  String get helpCenter => isAr ? 'مركز المساعدة' : 'Help Center';
  String get aboutApp => isAr ? 'عن التطبيق' : 'About App';
  String get aboutAppDesc => isAr
      ? 'تطبيق لحالات الطوارئ والمساعدة المجتمعية، تم تصميمه بعناية.'
      : 'App for emergency situations and community help, designed carefully.';
  String get comingSoon => isAr ? 'قريباً' : 'Coming Soon';

  // Social Auth
  String get errorTitle => isAr ? 'خطأ' : 'Error';
  String get googleBtn => isAr ? 'Google' : 'Google';
  String get facebookBtn => isAr ? 'Facebook' : 'Facebook';
  String get twitterBtn => isAr ? 'X' : 'X';
  String get instagramBtn => isAr ? 'Instagram' : 'Instagram';

  // Sign Up Screen
  String get signUpTitle => isAr ? 'إنشاء حساب' : 'Create Account';
  String get signUpSubtitle => isAr
      ? 'سجل بياناتك للتمتع بكافة المميزات'
      : 'Enter your details to enjoy all features';
  String get basicInfo => isAr ? 'المعلومات الأساسية' : 'Basic Information';
  String get allowContactAccess => isAr
      ? 'يرجى منح إذن الوصول لجهات الاتصال'
      : 'Please grant contacts access';
  String get accountCreated =>
      isAr ? 'تم إنشاء الحساب' : 'Account created successfully';
  String get uploadPhotoHint => isAr
      ? 'رفع الصورة — ربط المعرض لاحقاً'
      : 'Upload photo — Gallery link later';
  String get uploadPhotoBtn => isAr ? 'رفع الصورة' : 'Upload Photo';
  String get basicInfoSub => isAr
      ? 'معلوماتك الشخصية لسهولة التواصل'
      : 'Your personal info for easy communication';
  String get firstNameLabel => isAr ? 'الاسم الأول' : 'First Name';
  String get lastNameLabel => isAr ? 'اسم العائلة' : 'Last Name';
  String get emailLabel => isAr ? 'البريد الإلكتروني' : 'Email Address';
  String get emailValidationAt =>
      isAr ? 'يجب أن يحتوي على @' : 'Must contain @';
  String get mobileLabel => isAr ? 'رقم الموبايل' : 'Mobile Number';
  String get mobileValidation11 => isAr
      ? 'يجب أن يكون رقم الموبايل ١١ رقماً'
      : 'Mobile number must be 11 digits';
  String get nationalIdLabel =>
      isAr ? 'رقم البطاقة (١٤ رقم)' : 'National ID (14 digits)';
  String get nationalIdValidation => isAr
      ? 'يجب أن يكون الرقم القومي ١٤ رقماً'
      : 'National ID must be 14 digits';
  String get birthDateLabel => isAr ? 'تاريخ الميلاد' : 'Date of Birth';
  String get dayLabel => isAr ? 'يوم' : 'Day';
  String get monthLabel => isAr ? 'شهر' : 'Month';
  String get yearLabel => isAr ? 'سنة' : 'Year';
  String get invalidVal => isAr ? 'غير صالح' : 'Invalid';
  String get genderLabel => isAr ? 'النوع' : 'Gender';
  String get maleOption => isAr ? 'ذكر' : 'Male';
  String get femaleOption => isAr ? 'أنثى' : 'Female';
  String get bloodTypeLabel => isAr ? 'فصيلة الدم' : 'Blood Type';
  String get hasVehicleLabel => isAr ? 'هل لديك سيارة؟' : 'Do you have a car?';
  String get min6Chars => isAr ? '٦ أحرف على الأقل' : 'At least 6 characters';
  String get noMatch => isAr ? 'غير متطابقة' : 'No match';
  String get confirmPassword => isAr ? 'تأكيد كلمة السر' : 'Confirm Password';
  String get addContactsLabel =>
      isAr ? 'إضافة جهات اتصال' : 'Add Emergency Contacts';
  String get smartWatchLabel =>
      isAr ? 'الساعة الذكية (اختياري)' : 'Smart Watch (Optional)';
  String get selectModel => isAr ? 'اختر الطراز' : 'Select Model';
  String get otherModel => isAr ? 'أخرى' : 'Other';
  String get sensorLabel => isAr ? 'الحساس (اختياري)' : 'Sensor (Optional)';
  String get pulseSensor => isAr ? 'حساس نبض' : 'Pulse Sensor';
  String get glucoseSensor => isAr ? 'حساس سكر' : 'Glucose Sensor';
  String get volunteerLabel => isAr ? 'متطوع' : 'Volunteer';
  String get volunteerConsent => isAr
      ? 'أرغب في التطوع لمساعدة الآخرين في الطوارئ'
      : 'I want to volunteer to help others in emergencies';
  String get addSkillsHint => isAr ? 'أضف مهاراتك' : 'Add your skills';
  String get registerBtn => isAr ? 'تسجيل' : 'Register';
  String get contactNLabel => isAr ? 'جهة اتصال' : 'Emergency Contact';
  String get requiredSymbol => isAr ? '(إجباري)' : '(Required)';
  String get relationLabel => isAr ? 'صلة القرابة' : 'Relationship';
  String get chooseBtn => isAr ? 'اختيار' : 'Choose';
  String get successfullySelected =>
      isAr ? 'تم الاختيار بنجاح' : 'Successfully Selected';
  String get uploadCertLabel =>
      isAr ? 'أضف الشهادات الخاصة بك' : 'Upload your certificates';
  String get downloadCertLabel =>
      isAr ? 'تحميل الشهادات' : 'Certificates Upload';
  String get selectHint => isAr ? 'اختر' : 'Select';

  // Submit
  String get submitSignUp => isAr ? 'إنشاء حساب جديد' : 'Create New Account';

  String get yes => isAr ? 'نعم' : 'Yes';
  String get no => isAr ? 'لا' : 'No';
  String get emergencyContacts =>
      isAr ? 'جهات الاتصال الطارئة' : 'Emergency Contacts';

  // Chatbot
  String get chatBotTitle => isAr ? 'مساعد الطوارئ' : 'Emergency Assistant';
  String get chatBotSubtitle =>
      isAr ? 'متاح 24/7 لمساعدتك' : 'Available 24/7 to assist you';
  String get chatInputHint =>
      isAr ? 'اكتب رسالتك هنا...' : 'Type your message here...';
  String get quickMenu => isAr ? 'قائمة سريعة:' : 'Quick Menu:';
  String get callAssistant => isAr ? 'اتصل بالمساعد' : 'Call Assistant';

  // Chatbot Actions
  String get servicesAction => isAr ? 'خدمات الطوارئ' : 'Emergency Services';
  String get contactsAction => isAr ? 'جهات اتصال' : 'Contacts';
  String get instructionsAction => isAr ? 'إرشادات' : 'Instructions';

  // Popups
  String get chooseService =>
      isAr ? 'اختر خدمة الطوارئ' : 'Choose Emergency Service';
  String get emergencyContactsTitle =>
      isAr ? 'جهات الاتصال الطارئة' : 'Emergency Contacts';
  String get emergencyInstructionsTitle =>
      isAr ? 'إرشادات الطوارئ' : 'Emergency Instructions';

  // Services
  String get policeService => isAr ? 'الشرطة' : 'Police';
  String get ambulanceService => isAr ? 'الإسعاف' : 'Ambulance';
  String get fireService => isAr ? 'المطافي' : 'Fire Dept';

  // Instructions
  String get cprInstruction =>
      isAr ? 'الإنعاش القلبي الرئوي (CPR)' : 'CPR Instructions';
  String get firstAidInstruction => isAr ? 'الإسعافات الأولية' : 'First Aid';
  String get fireSafetyInstruction =>
      isAr ? 'التعامل مع الحرائق' : 'Fire Safety';
  String get earthquakeSafetyInstruction =>
      isAr ? 'التعامل مع الزلازل' : 'Earthquake Safety';

  // Footer
  String get chatFooterNote => isAr
      ? 'في حالة الطوارئ القصوى، اتصل مباشرة على 911'
      : 'In extreme emergencies, call 911 immediately';

  // Home Screen
  String get dashboard => isAr ? 'لوحة التحكم' : 'Dashboard';
  String get emergencyCall => isAr ? 'مكالمة طوارئ' : 'Emergency Call';
  String get safetyInfo => isAr ? 'معلومات السلامة' : 'Safety Info';
  String get activeAlertsTab => isAr ? 'البلاغات النشطة' : 'Active Alerts';
  String get sensorsTab => isAr ? 'الحساسات' : 'Sensors';
  String get emergencySystemTitle => isAr ? 'نظام الطوارئ' : 'Emergency System';
  String get emergencyServices24_7 =>
      isAr ? 'خدمات الطوارئ 24/7' : 'Emergency Services 24/7';
  String get allSystemsOperationalStatus =>
      isAr ? 'كل الأنظمة شغالة' : 'All systems operational';

  // Emergency Tab
  String get emergencyLine => isAr ? 'خط الطوارئ' : 'Emergency Line';
  String get emergencyServiceDesc => isAr
      ? 'خدمة طوارئ متاحة 24/7. المشغلين جاهزين\nلمساعدتك في أي حالة طارئة.'
      : 'Emergency service available 24/7. Operators are ready\nto assist you in any emergency.';
  String get callEmergencyServicesBtn =>
      isAr ? 'اتصل بخدمات الطوارئ' : 'Call Emergency Services';
  String get callingEmergencyServices =>
      isAr ? 'جاري الاتصال بخدمات الطوارئ...' : 'Calling emergency services...';
  String get shareLocationTitle => isAr ? 'شارك موقعك' : 'Share Location';
  String get shareLocationDesc => isAr
      ? 'ابعت موقعك بالظبط لخدمات الطوارئ عشان استجابة أسرع'
      : 'Send your exact location to emergency services for a faster response';
  String get sendLocationBtn => isAr ? 'ابعت الموقع' : 'Send Location';
  String get notifyContactsTitle =>
      isAr ? 'جهات الاتصال للطوارئ' : 'Emergency Contacts';
  String get notifyContactsDesc => isAr
      ? 'بلغ جهات الاتصال بتاعتك عن حالتك أوتوماتيكي'
      : 'Automatically notify your contacts about your status';
  String get notifyContactsBtn => isAr ? 'بلغ جهات الاتصال' : 'Notify Contacts';

  // Data / Statuses
  String get statusActive => isAr ? 'نشط' : 'Active';
  String get statusInWay => isAr ? 'في الطريق' : 'En route';
  String get statusResolved => isAr ? 'تم الحل' : 'Resolved';
  String get statusDealing => isAr ? 'جاري التعامل' : 'Handling';

  // Data / Locations (Common Mocks)
  String get locDowntown =>
      isAr ? 'وسط البلد، شارع طلعت حرب' : 'Downtown, Talaat Harb St.';
  String get locNasrCity =>
      isAr ? 'مدينة نصر، شارع عباس العقاد' : 'Nasr City, Abbas El Akkad St.';
  String get locMaadi =>
      isAr ? 'المعادي، كورنيش النيل' : 'Maadi, Nile Corniche';

  // Data / Types
  String get typeFire => isAr ? 'حريق' : 'Fire';
  String get typeMedical => isAr ? 'حالة طبية' : 'Medical';
  String get typeSecurity => isAr ? 'أمن' : 'Security';

  // Sponsors
  String get showAllSponsors =>
      isAr ? 'عرض جميع شركاء موثوقين' : 'Show all trusted partners';
  String get premiumPartner => isAr ? 'شريك مميز' : 'Premium Partner';
  String get carCenter => isAr ? 'مركز سيارات' : 'Car Center';
  String get insurance => isAr ? 'تأمين' : 'Insurance';
  String get roadAssistance => isAr ? 'مساعدة على الطريق' : 'Road Assistance';
  String get emergencyTow => isAr ? 'ونش طوارئ' : 'Emergency Tow';
  String get freeInspection => isAr ? 'فحص مجاني' : 'Free Inspection';
  String get support24_7 => isAr ? 'دعم 24/7' : '24/7 Support';

  // Sensors
  String get gasSensor => isAr ? 'حساس الغاز' : 'Gas Sensor';
  String get heatSensor => isAr ? 'حساس الحرارة' : 'Heat Sensor';
  String get sensorDangerTitleGas =>
      isAr ? 'تسريب غاز خطير 💨' : 'Dangerous Gas Leak 💨';
  String get sensorDangerTitleHeat =>
      isAr ? 'حريق محتمل 🔥' : 'Potential Fire 🔥';
  String get gasDangerStep1 =>
      isAr ? 'افتح الشبابيك فوراً' : 'Open windows immediately';
  String get gasDangerStep2 =>
      isAr ? 'أطفي أي مصدر للنار' : 'Turn off any fire source';
  String get gasDangerStep3 =>
      isAr ? 'إخلي المكان لو الوضع ساء' : 'Evacuate if the situation worsens';
  String get heatDangerStep1 => isAr
      ? 'ابتعد عن مصدر الحرارة فوراً'
      : 'Move away from the heat source immediately';
  String get heatDangerStep2 =>
      isAr ? 'بلغ المطافي على 180' : 'Call Fire Dept on 180';
  String get heatDangerStep3 => isAr
      ? 'إخلي المكان وسكر الأبواب ورايك'
      : 'Evacuate and close doors behind you';
  String get sensorMonitoringSystem =>
      isAr ? 'نظام مراقبة الحساسات' : 'Sensor Monitoring System';
  String get emergencyAlert => isAr ? 'تنبيه طوارئ!' : 'Emergency Alert!';
  String get locationUpdating =>
      isAr ? 'موقعك: يتم التحديث من GPS...' : 'Location: Updating from GPS...';
  String get safeStatus => isAr ? 'آمن ✅' : 'Safe ✅';
  String get noProblemsTitle =>
      isAr ? 'مفيش مشاكل دلوقتي' : 'No problems right now';
  String get allNormalDesc => isAr
      ? 'الحساس شغال كويس وكل القراءات في المعدل الطبيعي'
      : 'All sensors are working well and readings are normal';
  String get imSafeBtn =>
      isAr ? 'أنا بخير (إلغاء التنبيه)' : 'I am Safe (Cancel Alert)';
  String get needHelpBtn =>
      isAr ? 'محتاج مساعدة الآن! 🆘' : 'I need help now! 🆘';
  String get autoReportStatusUrgent =>
      isAr ? '⚡ هيتم الإبلاغ خلال ثواني!' : '⚡ Will report in seconds!';
  String get timeRemaining =>
      isAr ? 'وقت متبقي للإستجابة للطوارئ' : 'Time remaining to respond';
  String get locationDetails => isAr ? 'تفاصيل الموقع' : 'Location Details';
  String get longitudeLabel => isAr ? 'خط الطول:' : 'Longitude:';
  String get latitudeLabel => isAr ? 'خط العرض:' : 'Latitude:';
  String get autoReportWarning => isAr
      ? 'سيتم إرسال الموقع تلقائياً للطوارئ'
      : 'Location will be sent automatically';
  String get emergencyContactsHeader =>
      isAr ? 'جهات الإتصال الطوارئ' : 'Emergency Contacts';
  String get everythingFineSafe =>
      isAr ? 'تمام! ربنا يسترك 💚' : 'Great! Stay safe 💚';
  String get cancelAlertSuccess => isAr
      ? 'تم إلغاء التنبيه بنجاح.\nكل حاجة كويسة دلوقتي.'
      : 'Alert cancelled successfully.\nEverything is fine now.';
  String get reportedAuto =>
      isAr ? 'تم الإبلاغ تلقائياً! 🚨' : 'Auto Reported! 🚨';
  String get reportedManual => isAr
      ? 'تم إرسال إشعار عاجل للطوارئ مع موقعك!'
      : 'Urgent alert sent with your location!';
  String get authoritiesOnWay => isAr
      ? 'الجهات المختصة في طريقها إليك! 🆘'
      : 'Authorities are on the way! 🆘';
  String get okGotIt => isAr ? 'حسناً، فاهم' : 'OK, I understand';

  // Sponsors
  String get trustedSponsors => isAr ? 'الرعاة الموثوقون' : 'Trusted Sponsors';
  String get sponsorsSubtitle => isAr
      ? 'شركاء متميزون لاحتياجات الطوارئ'
      : 'Premium partners for emergency needs';
  String get allSponsors => isAr ? 'جميع الرعاة' : 'All Sponsors';
  String get carCenters => isAr ? 'مراكز السيارات' : 'Car Centers';
  String get insuranceSponsors => isAr ? 'التأمين الصحي' : 'Health Insurance';
  String get featuredPartner => isAr ? 'شريك مميز' : 'Featured Partner';
  String get carCenterBadge => isAr ? 'مركز سيارات' : 'Car Center';
  String get insuranceBadge => isAr ? 'تأمين' : 'Insurance';
  String get bavarianTitle =>
      isAr ? 'بافاريان أوتو جروب' : 'Bavarian Auto Group';
  String get ghabbourTitle => isAr ? 'غبور أوتو' : 'Ghabbour Auto';
  String get allianzTitle => isAr ? 'أليانز مصر' : 'Allianz Egypt';
  String get egyptInsuranceTitle => isAr ? 'مصر للتأمين' : 'Misr Insurance';
  String get servicesProvided =>
      isAr ? 'الخدمات المقدمة:' : 'Services Provided:';
  String get callNowBtn => isAr ? 'اتصل الآن' : 'Call Now';
  String get becomePartner => isAr ? 'كن شريكاً' : 'Become a Partner';
  String get partnerProgramDesc => isAr
      ? 'انضم لبرنامج الشركاء وتمتع بوصول أسرع إلى العملاء الموثوقين'
      : 'Join our partner program and reach more trusted customers faster';
  String get applyForPartnership =>
      isAr ? 'التقدم للشراكة' : 'Apply for Partnership';
  String get viewAllPartners =>
      isAr ? 'عرض جميع الشركاء الموثوقين' : 'View all trusted partners';
  String get viewCarCentersCount =>
      isAr ? 'عرض مراكز السيارات' : 'View Car Centers';
  String get viewInsuranceCount =>
      isAr ? 'عرض شركات التأمين' : 'View Insurance Companies';

  // Community Tab
  String get helpInitiativesHeaderTitle =>
      isAr ? 'مبادرات المساعدة' : 'Help Initiatives';
  String get helpInitiativesHeaderSubtitle => isAr
      ? 'شبكة وصل ومساعدة بين أفراد المجتمع بطريقة منظمة ومبنية على الموقع'
      : 'A network of connection and help between community members in an organized way based on location';
  String get allLabel => isAr ? 'الكل' : 'All';
  String get casesResolved => isAr ? 'حالات تم حلها' : 'Cases Resolved';
  String participantsLabel(int count) => isAr ? 'مشارك' : 'participants';
  String get contactNow => isAr ? 'تواصل الآن' : 'Contact Now';

  String helpCategoryName(String key) {
    final k = key.toLowerCase();
    if (isAr) {
      return switch (k) {
        'food' => 'طعام',
        'clothing' => 'ملابس',
        'financial' => 'مالي',
        'medical' => 'طبي',
        'education' => 'تعليمي',
        _ => 'أخرى',
      };
    }
    return switch (k) {
      'food' => 'Food',
      'clothing' => 'Clothing',
      'financial' => 'Financial',
      'medical' => 'Medical',
      'education' => 'Education',
      _ => 'Other',
    };
  }

  String helpCategoryDisplayName(String key) {
    final k = key.toLowerCase();
    if (isAr) {
      return switch (k) {
        'food' => 'وجبات مجانية',
        'clothing' => 'ملابس للمحتاجين',
        'financial' => 'مساعدة مالية',
        'medical' => 'مساعدة طبية',
        'education' => 'مساعدة تعليمية',
        _ => 'أخرى',
      };
    }
    return switch (k) {
      'food' => 'Free Meals',
      'clothing' => 'Clothing Support',
      'financial' => 'Financial Help',
      'medical' => 'Medical Help',
      'education' => 'Education Support',
      _ => 'Other',
    };
  }
  String get communityTitle => isAr ? 'مجتمع إلحقني' : 'El7a2ny Community';
  String get communityDesc => isAr ? 'شارك وساعد في إنقاذ الأرواح' : 'Share and help save lives';
  String get activeVolunteers => isAr ? 'المتطوعون النشطون' : 'Active Volunteers';
  String get communityPosts => isAr ? 'آخر التحديثات' : 'Latest Updates';
  String get helpInitiatives => isAr ? 'مبادرات المساعدة' : 'Help Initiatives';

  // Profile Tab
  String get profileSubtitle => isAr ? 'إدارة حسابك وتفضيلات الأمان' : 'Manage your account and security';
  String get personalInfo => isAr ? 'المعلومات الشخصية' : 'Personal Information';
  String get securitySettings => isAr ? 'إعدادات الأمان' : 'Security Settings';
  String get appPreferences => isAr ? 'تفضيلات التطبيق' : 'App Preferences';

  // Payment
  String get paymentTitle => isAr ? 'دفع الاشتراك' : 'Subscription Payment';
  String get paymentCard => isAr ? 'بطاقة' : 'Card';
  String get paymentFawry => isAr ? 'فوري' : 'Fawry';
  String get paymentWallet => isAr ? 'محفظة' : 'Wallet';

  // Smart Watch
  String get watchMonitoring => isAr ? 'مراقبة الساعة الذكية' : 'Smart Watch Monitoring';
  String get vitalSignsUnstable => isAr ? 'علامات حيوية غير مستقرة ⚠️' : 'Vital signs unstable ⚠️';
  String get lifeDanger => isAr ? 'خطر على الحياة 🚨' : 'Life in danger 🚨';
  String get stableHealthStatus => isAr ? 'الحالة الصحية مستقرة' : 'Health status stable';
  String get heartRate => isAr ? 'نبض القلب' : 'Heart Rate';
  String get oxygenLevel => isAr ? 'مستوى الأكسجين' : 'Oxygen Level';
  String get caloriesBurned => isAr ? 'السعرات الحرارية' : 'Calories Burned';

  String get paymentOther => isAr ? 'أخرى' : 'Other';
  String get cardNumber => isAr ? 'رقم البطاقة' : 'Card Number';
  String get cardExpiry => isAr ? 'تاريخ الانتهاء' : 'Expiry Date';
  String get cardCvc => isAr ? 'CVC' : 'CVC';
  String get paymentCountry => isAr ? 'البلد' : 'Country';
  String get paymentEgypt => isAr ? 'مصر' : 'Egypt';
  String get paymentPostalCode => isAr ? 'الرمز البريدي' : 'Postal Code';
  String get paymentTotal => isAr ? 'المجموع' : 'Total';
  String get paymentMonthlyPrice => isAr ? '299 جنيه / شهرياً' : '299 EGP / Month';
  String get paymentYearlySavings => isAr ? 'أو 2,990 جنيه سنوياً (وفر 17%)' : 'or 2,990 EGP / Year (Save 17%)';
  String get payNow => isAr ? 'دفع الآن' : 'Pay Now';

  // Premium Subscription
  String get premiumPlusTitle => isAr ? 'إلحقني بلس' : 'El7a2ny Plus';
  String get premiumPlusSubtitle => isAr ? 'خدمات الطوارئ المميزة' : 'Premium Emergency Services';
  String get exclusiveFeaturesTitle => isAr ? 'المميزات الحصرية' : 'Exclusive Features';
  String get instantResponse => isAr ? 'استجابة فورية' : 'Instant Response';
  String get instantResponseDesc => isAr ? 'توصيل بخدمات الطوارئ أسرع 10 مرات' : 'Connect to emergency services 10x faster';
  String get premiumInsurance => isAr ? 'تأمين مميز' : 'Premium Insurance';
  String get premiumInsuranceDesc => isAr ? 'تغطية موسعة مع أفضل شركات التأمين' : 'Expanded coverage with top partners';
  String get support24_7Title => isAr ? 'دعم 24/7' : '24/7 Support';
  String get support24_7Desc => isAr ? 'استشارات طبية متاحة على مدار الساعة' : 'Medical consultations available 24/7';
  String get familyProtection => isAr ? 'حماية العائلة' : 'Family Protection';
  String get familyProtectionDesc => isAr ? 'تغطية تصل لـ 5 أفراد من العائلة' : 'Coverage for up to 5 family members';
  String get liveTrackingTitle => isAr ? 'تتبع مباشر' : 'Live Tracking';
  String get liveTrackingDesc => isAr ? 'تتبع الإسعاف والخدمات في الوقت الفعلي' : 'Real-time tracking of ambulance & services';
  String get healthRecordsTitle => isAr ? 'السجلات الصحية' : 'Health Records';
  String get healthRecordsDesc => isAr ? 'الوصول للتاريخ الطبي والتقارير الكاملة' : 'Access full medical history & reports';
  String get serviceCategoriesTitle => isAr ? 'فئات الخدمات' : 'Service Categories';
  String get medicalServicesTitle => isAr ? 'الخدمات الطبية' : 'Medical Services';
  String get transportServicesTitle => isAr ? 'النقل الطارئ' : 'Emergency Transport';
  String get insuranceCoverageTitle => isAr ? 'التأمين والتغطية' : 'Insurance & Coverage';
  String get supportServicesTitle => isAr ? 'خدمات الدعم' : 'Support Services';
  String get testimonialText => isAr 
      ? '"إلحقني بلس أنقذ حياتي. الاستجابة السريعة وصلتني للمستشفى في وقت قياسي."'
      : '"El7a2ny Plus saved my life. The quick response got me to the hospital in record time."';
  String get upgradeToPlus => isAr ? 'الترقية لالحقني بلس' : 'Upgrade to El7a2ny Plus';
  String get maybeLater => isAr ? 'ربما لاحقاً' : 'Maybe Later';
  String get moneyBackGuarantee => isAr 
      ? 'ضمان استرجاع المال لمدة 30 يوم • يمكن الإلغاء في أي وقت'
      : '30-day money-back guarantee • Cancel anytime';
  String get monthlyLabelSmall => isAr ? 'شهرياً' : 'Monthly';

  // Report Incident
  String get reportIncidentTitle => isAr ? 'تبليغ عن مشكلة' : 'Report an Incident';
  String get incidentQuestion => isAr ? 'ايه المشكله اللي بتواجهك؟' : 'What problem are you facing?';
  String get typeAccident => isAr ? 'حادث' : 'Accident';
  String get typeFireAlt => isAr ? 'حريق' : 'Fire';
  String get typeMedicalAlt => isAr ? 'طبي' : 'Medical';
  String get typeFlood => isAr ? 'فيضان' : 'Flood';
  String get typeEarthquake => isAr ? 'زلزال' : 'Earthquake';
  String get typeTheft => isAr ? 'سرقة' : 'Theft';
  String get typeAssault => isAr ? 'اعتداء' : 'Assault';
  String get typeOtherAlt => isAr ? 'أخرى' : 'Other';
  String get otherTypeHint => isAr ? 'مثال: محبوس في الأسانسير...' : 'e.g. Stuck in elevator...';
  String get volunteersNeededLabel => isAr ? 'عدد المتطوعين المطلوب (تقريبي)' : 'Number of volunteers needed (approx)';
  String get volunteersNeededHint => isAr ? 'مثال: 5' : 'e.g. 5';
  String get addEvidenceLabel => isAr ? 'زود دليل' : 'Add Evidence';
  String get evidencePhoto => isAr ? 'صورة' : 'Photo';
  String get evidenceVideo => isAr ? 'فيديو' : 'Video';
  String get evidenceRecord => isAr ? 'ريكورد' : 'Record';
  String get selectProblemFirst => isAr ? 'اختار المشكلة الأول' : 'Select problem first';
  String get reportBtn => isAr ? 'بلغ' : 'Report';
  String get helpOnWayTitle => isAr ? 'المساعدة في الطريق' : 'Help is on the way';
  String get helpOnWayDesc => isAr ? 'اقرأ التعليمات لحد ما المساعدة توصل' : 'Read instructions until help arrives';
  String get readInstructionsBtn => isAr ? 'اقرأ التعليمات' : 'Read Instructions';
  
  // Location Selector
  String get locationPickerTitle => isAr ? 'لوكيشن' : 'Location';
  String get searchAddressHint => isAr ? 'ابحث عن عنوان' : 'Search Address';
  String get findMyLocation => isAr ? 'حدد موقفي الحالي' : 'Locate my position';
  String get cityLabel => isAr ? 'المدينة' : 'City';
  String get govLabel => isAr ? 'محافظة' : 'Governorate';
  String get buildingLabel => isAr ? 'رقم المبنى' : 'Building/Street';
  String get confirmLocationBtn => isAr ? 'تأكيد' : 'Confirm';
  String get recordVideo => isAr ? 'تصوير فيديو' : 'Record Video';
  String get changeLocation => isAr ? 'تغيير' : 'Change';

  // Admin Dashboard
  String get adminDashboard => isAr ? 'لوحة تحكم الأدمن' : 'Admin Dashboard';
  String get systemStats => isAr ? 'إحصائيات النظام' : 'System Stats';
  String get userManagement => isAr ? 'إدارة المستخدمين' : 'User Management';
  String get incidentMonitoring => isAr ? 'مراقبة البلاغات' : 'Incident Monitoring';
  String get totalUsers => isAr ? 'إجمالي المستخدمين' : 'Total Users';
  String get globalAlerts => isAr ? 'البلاغات العالمية' : 'Global Alerts';
  String get systemHealth => isAr ? 'صحة النظام' : 'System Health';
  String get viewReports => isAr ? 'عرض التقارير' : 'View Reports';
  String get manageUsers => isAr ? 'إدارة الأعضاء' : 'Manage Members';
  String get adminAuthTitle => isAr ? 'دخول الأدمن' : 'Admin Access';

  // Admin Specific Content
  String get roleCitizen => isAr ? 'مواطن' : 'Citizen';
  String get roleVolunteer => isAr ? 'متطوع' : 'Volunteer';
  String get statusActiveAdmin => isAr ? 'نشط' : 'Active';
  String get statusPending => isAr ? 'قيد الانتظار' : 'Pending';
  String get statusSuspended => isAr ? 'موقوف' : 'Suspended';
  String get statusInProgress => isAr ? 'قيد التنفيذ' : 'In Progress';
  String get statusDispatched => isAr ? 'تم الإرسال' : 'Dispatched';
  String get statusResolvedAdmin => isAr ? 'تم الحل' : 'Resolved';
  String get actionVerify => isAr ? 'توثيق' : 'Verify';
  String get actionSuspend => isAr ? 'إيقاف' : 'Suspend';
  String get actionViewLogs => isAr ? 'سجل العمليات' : 'View Logs';
  String get actionResolve => isAr ? 'إنهاء البلاغ' : 'Resolve';
  String get actionMonitor => isAr ? 'مراقبة حية' : 'Monitor';
  String get actionCancelAlert => isAr ? 'إلغاء البلاغ' : 'Cancel Alert';
  String get actionDeleteIncident => isAr ? 'حذف من السجل' : 'Delete Incident';
  String get adminActivityLog => isAr ? 'سجل نشاط الأدمن' : 'Admin Activity Log';
  String get userVerifiedMsg => isAr ? 'تم توثيق المستخدم' : 'User Verified';
  String get userSuspendedMsg => isAr ? 'تم إيقاف الحساب' : 'User Suspended';
  String get incidentResolvedMsg => isAr ? 'تم إنهاء البلاغ بنجاح' : 'Incident Resolved';
  String get incidentCancelledMsg => isAr ? 'تم إلغاء البلاغ وتنبيه الجهات المختصة' : 'Incident cancelled and authorities notified';
  String get incidentDeletedMsg => isAr ? 'تم حذف السجل نهائياً' : 'Incident deleted permanently';
  String get monitoringStartedMsg => isAr ? 'جاري المراقبة الحية وتتبع الموقع' : 'Live monitoring and location tracking started';
}
