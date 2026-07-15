// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'تعدية';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get orContinueWith => 'أو تابع مع';

  @override
  String get continueAsGuest => 'المتابعة كزائر';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get resetPassword => 'إعادة تعيين كلمة المرور';

  @override
  String get resetPasswordDesc =>
      'أدخل بريدك الإلكتروني لاستلام رابط إعادة تعيين كلمة المرور.';

  @override
  String get cancel => 'إلغاء';

  @override
  String get sendResetLink => 'إرسال رابط إعادة التعيين';

  @override
  String get welcomeGuest => 'مرحباً أيها الزائر!';

  @override
  String get welcome => 'مرحباً';

  @override
  String get guest => 'زائر';

  @override
  String get enterNameDesc => 'الرجاء إدخال اسمك للتعرف عليك في التقييمات.';

  @override
  String get yourName => 'اسمك';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get googleSignInFailed => 'فشل تسجيل الدخول عبر Google';

  @override
  String get signInFailed => 'فشل تسجيل الدخول';

  @override
  String get enterEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get invalidEmail => 'بريد إلكتروني غير صالح';

  @override
  String get enterPassword => 'أدخل كلمة المرور';

  @override
  String get google => 'Google';

  @override
  String resetLinkSent(Object email) {
    return '(spam) تحقق من البريد الخاص بيك ';
  }

  @override
  String get failedToSendReset => 'فشل إرسال رابط إعادة التعيين';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get joinTaadia => 'انضم إلى تعدية';

  @override
  String get signUpSubtitle =>
      'سجل باستخدام البريد الإلكتروني أو اختر طريقة أخرى';

  @override
  String get signUpWithEmail => 'التسجيل بالبريد الإلكتروني';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get orSignUpWith => 'أو سجل مع';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟';

  @override
  String get enterYourName => 'أدخل اسمك';

  @override
  String get enterAPassword => 'أدخل كلمة المرور';

  @override
  String get atLeast6Chars => '6 أحرف على الأقل';

  @override
  String get confirmYourPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordsDoNotMatch => 'كلمات المرور غير متطابقة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get displayName => 'الاسم المعروض';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get areYouSure => 'هل أنت متأكد؟';

  @override
  String get profileUpdated => 'تم تحديث الملف الشخصي';

  @override
  String get updateFailed => 'فشل التحديث';

  @override
  String get manageUsers => 'إدارة المستخدمين';

  @override
  String get taadiaManagement => 'إدارة التعديات';

  @override
  String welcomeAdmin(Object name) {
    return 'مرحباً، $name';
  }

  @override
  String get manageYourTaadias => 'إدارة تعدياتك';

  @override
  String get noTaadiasYet => 'لا توجد تعديات بعد';

  @override
  String get tapToCreateFirst => 'اضغط + لإنشاء أول تعدية';

  @override
  String get open => 'مفتوحة';

  @override
  String get close => 'مغلقة';

  @override
  String get delete => 'حذف';

  @override
  String deleteConfirm(Object title) {
    return 'حذف \"$title\" وجميع التقييمات؟';
  }

  @override
  String get editTitle => 'تعديل العنوان';

  @override
  String get maxTalakin => 'الحد الأقصى تلقينين لكل سؤال';

  @override
  String get giveFeedback => 'رأيك يهمنا';

  @override
  String get feedbackHint => 'شاركنا رأيك لمساعدتنا في التحسين...';

  @override
  String get feedbackSent => 'تم إرسال ملاحظتك! شكراً لك.';

  @override
  String get viewFeedback => ' عرض ملاحظات المستخدمين';

  @override
  String get noFeedback => 'لا توجد ملاحظات بعد';

  @override
  String get userFeedback => 'ملاحظاتك';

  @override
  String get noFeedbackHistory => 'لا توجد ملاحظات سابقة';

  @override
  String get reply => 'الرد';

  @override
  String get replyHint => 'اكتب ما تريد ارساله...';

  @override
  String get replySent => 'تم الإرسال ';

  @override
  String get adminReply => 'المشرف';

  @override
  String get confirmDeleteFeedback => 'حذف هذه الملاحظة؟';

  @override
  String get confirmDeleteReply => 'حذف هذا الرد؟';

  @override
  String get feedbackDeleted => 'تم حذف الملاحظة';

  @override
  String get replyDeleted => 'تم حذف الرد';

  @override
  String get createTaadia => 'إنشاء تعدية';

  @override
  String welcomeUser(Object name) {
    return 'مرحباً، $name';
  }

  @override
  String get selectTaadiaToEvaluate => 'اختر تعدية';

  @override
  String get noActiveTaadias => 'لا توجد تعديات نشطة';

  @override
  String get waitForAdmin => 'انتظر حتى يقوم المشرف بإنشاء واحدة';

  @override
  String get tapToEvaluate => 'اضغط لبدأ تعدية ';

  @override
  String get studentEvaluation => 'تعدية الطالب';

  @override
  String get evaluatorName => 'اسم العارض';

  @override
  String get yourNameHint => 'اسمك';

  @override
  String get studentName => 'اسم الطالب';

  @override
  String get studentNameHint => 'أدخل الاسم الكامل للطالب';

  @override
  String get selectGender => 'اختر الجنس';

  @override
  String get male => 'ذكر';

  @override
  String get female => 'أنثى';

  @override
  String get selectCategory => 'اختر التصنيف';

  @override
  String get gender => 'الجنس';

  @override
  String get numberOfQuestions => 'عدد الأسئلة';

  @override
  String get numberOfAhzab => 'عدد الأحزاب';

  @override
  String get specialAhzab => 'أحزاب خاصة';

  @override
  String get questions => 'الأسئلة';

  @override
  String get note => 'ملاحظة';

  @override
  String get enterNoteHint => ' أدخل ملاحظات التعدية...';

  @override
  String get saveEvaluation => 'حفظ التعدية';

  @override
  String get updateEvaluation => 'تحديث التعدية';

  @override
  String get startNewStudent => 'بدء طالب جديد';

  @override
  String get cancelEdit => 'إلغاء التعديل';

  @override
  String get myEvaluations => 'تعدياتي';

  @override
  String get noEvaluationsYet => 'لم تقم بأي تعدية بعد';

  @override
  String get taadiaClosed => 'هذه التعدية مغلقة';

  @override
  String get cannotEvaluateClosed => 'لا يمكن التقييم: هذه التعدية مغلقة';

  @override
  String get goBack => 'العودة';

  @override
  String get specialAhzabHint => 'مثال: 1-10 , نصف، إلخ.';

  @override
  String get questionNoteHint => 'ملاحظة لهذا السؤال (اختياري)';

  @override
  String get ichaarat => 'اشعار';

  @override
  String get taalakin => 'تلقين';

  @override
  String get select => 'اختيار';

  @override
  String get searchByEmail => 'البحث بالبريد الإلكتروني...';

  @override
  String get search => 'بحث';

  @override
  String get noUsersFound => 'لم يتم العثور على مستخدمين';

  @override
  String get admin => 'مشرف';

  @override
  String get user => 'مستخدم';

  @override
  String get removeAdmin => 'إزالة المشرف';

  @override
  String get makeAdmin => 'تعيين مشرف';

  @override
  String get deleteUser => 'حذف المستخدم';

  @override
  String get deleteUserTitle => 'حذف المستخدم';

  @override
  String deleteUserConfirm(Object name) {
    return 'حذف \"$name\" وجميع تعدياتهم ؟';
  }

  @override
  String get cannotDemoteSelf => 'لا يمكنك خفض رتبة نفسك';

  @override
  String onlyPromoterCanDemote(Object name) {
    return 'فقط $name الذي رقاهم يمكنه خفض رتبتهم';
  }

  @override
  String get noUserFoundEmail =>
      'لم يتم العثور على مستخدم بهذا البريد الإلكتروني';

  @override
  String userNowAdmin(Object name) {
    return '$name أصبح مشرفاً الآن';
  }

  @override
  String userAlreadyAdmin(Object name) {
    return '$name مشرف بالفعل';
  }

  @override
  String get cannotDeleteSelf => 'لا يمكنك حذف نفسك';

  @override
  String get searchByName => 'البحث بالاسم...';

  @override
  String get other => 'آخر';

  @override
  String get students => '  : عدد الطلاب';

  @override
  String get waitingForTeachers => 'بانتظار ارسال العارضين لتعدياتهم';

  @override
  String get evaluator => 'العارض';

  @override
  String get ahzab => 'الأحزاب';

  @override
  String get totalIchaarat => 'إجمالي الإشعارات';

  @override
  String get totalTaalakin => 'إجمالي التلاقين';

  @override
  String get deleteEvaluation => 'حذف التعدية';

  @override
  String deleteEvalConfirm(Object name) {
    return 'حذف تعدية $name؟';
  }

  @override
  String get hizb => 'حزب';

  @override
  String get assessmentTitle => 'عنوان التعدية';

  @override
  String get titleHint => 'مثال: تعدية صيف 2026';

  @override
  String get descriptionOptional => 'الوصف (اختياري)';

  @override
  String get descriptionHint => 'وصف مختصر لهذه التعدية';

  @override
  String get create => 'إنشاء';

  @override
  String get enterTitle => 'أدخل عنواناً';

  @override
  String get failedToCreate => 'فشل الإنشاء';

  @override
  String evaluated(Object name) {
    return 'تم تقييم $name!';
  }

  @override
  String updated(Object name) {
    return 'تم تحديث $name!';
  }

  @override
  String get question => 'سؤال';

  @override
  String get noteForQuestion => 'ملاحظة';

  @override
  String get qPrefix => 'س';

  @override
  String get unknown => 'غير معروف';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountConfirm => 'حذف حسابك؟';

  @override
  String get deleteAccountWarning =>
      'سيؤدي هذا إلى حذف حسابك وجميع التعديات بشكل دائم. لا يمكن التراجع عن هذا.';

  @override
  String get accountDeleted => 'تم حذف الحساب';

  @override
  String get evaluateStudents => 'ابدأ تعدية ';

  @override
  String get sortBy => 'ترتيب حسب';

  @override
  String get all => 'الكل';

  @override
  String get evaluate => 'تقييم';

  @override
  String get name => 'الاسم';

  @override
  String get ascending => 'تصاعدي';

  @override
  String get descending => 'تنازلي';

  @override
  String get enterStudentName => 'أدخل اسم الطالب';

  @override
  String get installApp => 'تثبيت التطبيق';

  @override
  String get visitWebsite => 'قم بزيارة موقعنا';

  @override
  String get authErrorUserNotFound => 'لم يتم العثور على مستخدم بهذا البريد';

  @override
  String get authErrorWrongPassword => 'كلمة المرور خاطئة';

  @override
  String get authErrorEmailAlreadyInUse => 'البريد الإلكتروني مستخدم بالفعل';

  @override
  String get authErrorWeakPassword => 'كلمة المرور ضعيفة';

  @override
  String get authErrorInvalidEmail => 'صيغة البريد الإلكتروني غير صالحة';

  @override
  String get accountDeletedByAdmin => 'تم حذف حسابك من قبل المشرف';

  @override
  String get authErrorUserDisabled => 'المستخدم معطل';

  @override
  String get authErrorTooManyRequests => 'طلبات كثيرة جداً';

  @override
  String get authErrorDefault => 'فشل المصادقة';

  @override
  String get formula => 'المعادلة';

  @override
  String get formulaDesc => 'اختر المعادلة لحساب ترتيب الطلاب';

  @override
  String get save => 'ارسال';

  @override
  String get selectAll => 'تحديد الكل';

  @override
  String get showClassement => 'إظهار التصنيف';

  @override
  String get hideClassement => 'إخفاء التصنيف';

  @override
  String get filterBy => 'تصفية حسب';

  @override
  String get formulaName => 'اسم المعادلة';

  @override
  String get formulaNameHint => 'مثال: الدرجة النهائية';

  @override
  String get operation => 'العملية الحسابية';

  @override
  String get coefIchaarat => 'وزن الإشارات';

  @override
  String get coefTaalakin => 'وزن التلقين';

  @override
  String get results => 'النتائج';

  @override
  String get installAppAlready => 'التطبيق مثبت بالفعل';

  @override
  String get formulaErrorEmpty => 'التعبير لا يمكن أن يكون فارغاً';

  @override
  String get formulaErrorUnmatchedOpen => 'قوس افتتاح غير متطابق';

  @override
  String get formulaErrorUnmatchedClose => 'قوس إغلاق غير متطابق';

  @override
  String get formulaErrorUnknownChar => 'حرف غير معروف في التعبير';

  @override
  String get formulaErrorConsecutiveOps => 'لا يُسمح بالعوامل المتتالية';

  @override
  String get formulaErrorInvalidStart => 'التعبير لا يمكن أن يبدأ بعامل';

  @override
  String get formulaErrorInvalidEnd => 'التعبير لا يمكن أن ينتهي بعامل';

  @override
  String get formulaErrorDivisionByZero => 'قسمة على صفر في المعادلة';

  @override
  String get formulaErrorGeneric => 'صيغة المعادلة غير صالحة';

  @override
  String get installAppIOS =>
      'لتثبيت التطبيق على iOS:\n1. اضغط على زر المشاركة (📤) في أسفل سفاري\n2. اسحب لأسفل واضغط على \"إضافة إلى الشاشة الرئيسية\"\n3. اضغط على \"إضافة\" في الزاوية العلوية اليمنى';

  @override
  String get installAppGeneric =>
      'لتثبيت هذا التطبيق:\n• افتح Chrome أو Edge على سطح المكتب\n• انقر على أيقونة التثبيت (➕) في شريط العنوان\n• أو افتح هذه الصفحة على Android Chrome واضغط \"تثبيت\"';

  @override
  String get homeSubtitle => 'اختر كيف تريد المشاركة:';

  @override
  String get joinTaadiaDesc => 'تصفح وانضم إلى التعديات الموجودة لتقييم الطلاب';

  @override
  String get createOwnTaadia => 'إنشاء تعديتك الخاصة';

  @override
  String get createOwnTaadiaDesc => 'إنشاء تعدية خاصة لك فقط';

  @override
  String get privateTaadiaNotice =>
      'هذه التعدية خاصة — أنت فقط من يمكنك رؤيتها.';

  @override
  String get myPrivateTaadias => 'تعدياتي الخاصة';

  @override
  String get taadia => 'Taadia';

  @override
  String get startTaadia => 'بدأ تعدية';

  @override
  String get manageTaadia => 'إدارة التعديات';

  @override
  String get publicTaadias => 'التعديات العامة';

  @override
  String get maxTwoTalakin => 'الحد الأقصى تلقنين لكل سؤال';

  @override
  String get add => 'إضافة سؤال';

  @override
  String get remove => 'إزالة سؤال';

  @override
  String get manageGroups => 'إدارة المجموعات';

  @override
  String get createGroup => 'إنشاء مجموعة';

  @override
  String get groupName => 'اسم المجموعة';

  @override
  String get groupNameHint => 'مثال:قروب الحبيب  ';

  @override
  String get renameGroup => 'إعادة تسمية المجموعة';

  @override
  String get deleteGroup => 'حذف المجموعة';

  @override
  String deleteGroupConfirm(Object name) {
    return 'حذف \"$name\"؟';
  }

  @override
  String get noGroupsYet => 'لا توجد مجموعات بعد';

  @override
  String get tapToCreateGroup => 'اضغط + لإنشاء أول مجموعة';

  @override
  String get manageMembers => 'إدارة الأعضاء';

  @override
  String manageMembersFor(Object name) {
    return 'أعضاء $name';
  }

  @override
  String groupMemberCount(Object count) {
    return '$count أعضاء';
  }

  @override
  String get accessControl => 'اختر من يمكنه رؤية التعدية ';

  @override
  String get accessControlDesc => 'اختر من يمكنه الوصول إلى هذه التعدية';

  @override
  String get selectGroups => 'اختيار المجموعات      ';

  @override
  String get selectGroupsDesc => 'فقط أعضاء المجموعات المحددة يمكنهم الوصول';

  @override
  String get addGroups => 'إضافة مجموعات';

  @override
  String get selectUsers => 'اختيار العارضين';

  @override
  String get selectUsersDesc => 'اختيار مستخدمين محددين يمكنهم الوصول';

  @override
  String get usersSelected => 'مستخدمين محددين';

  @override
  String get accessCode => 'رمز التعدية';

  @override
  String get accessCodeDesc =>
      'يمكن للمستخدمين غير المحددين إدخال هذا الرمز للوصول';

  @override
  String get regenerateCode => 'توليد رمز جديد';

  @override
  String get enterAccessCode => 'أدخل رمز التعدية';

  @override
  String get accessCodeHint => 'أدخل الرمز المكون من 4 أرقام';

  @override
  String get joinWithCode => 'انضم بالرمز';

  @override
  String get joinWithCodeDesc =>
      'هل لديك رمز تعدية؟ أدخله هنا للانضمام إلى تعدية';

  @override
  String get verify => 'تحقق';

  @override
  String get accessGranted => '!تم ادخالك الى التعدية ';

  @override
  String get alreadyHaveAccess => 'لديك مسبقا حق الدخول إلى هذه التعدية';

  @override
  String get invalidCode => 'رمز غير صالح أو منتهي الصلاحية';

  @override
  String get done => 'تم';

  @override
  String get copy => 'نسخ';

  @override
  String get copied => 'تم النسخ!';

  @override
  String get exitConfirm => 'هل أنت متأكد من الخروج؟';

  @override
  String get exit => 'خروج';

  @override
  String get deletedAccountWrongPassword =>
      'هذا البريد الإلكتروني يتبع حساباً محذوفاً. الرجاء استخدام كلمة المرور الأصلية لاستعادته.';

  @override
  String get rangeAllQuran => 'كامل القرآن :';

  @override
  String get rangeQuarter => 'ربع :';

  @override
  String get rangeHizbRange => 'أحزاب :';

  @override
  String get rangeSurahs => 'سور :';

  @override
  String get rangeSurahPages => 'صفحات من سورة :';

  @override
  String get rangeSurahAyahRange => 'آيات من سورة :';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get fromAyah => 'من الآية';

  @override
  String get toAyah => 'إلى الآية';

  @override
  String get fromPage => 'من صفحة';

  @override
  String get toPage => 'إلى صفحة';

  @override
  String get selectSurah => 'اختر سورة';

  @override
  String get addSurah => '+ إضافة سورة';

  @override
  String get addRange => 'إضافة أحزاب أو سور';

  @override
  String get generateQuestions => 'إنشاء الأسئلة';

  @override
  String get generating => 'جارٍ التوليد...';

  @override
  String get generateFailed => 'فشل في إنشاء الأسئلة';

  @override
  String get surah => 'سورة';

  @override
  String previousRange(Object text) {
    return ':الأحزاب المختارة $text';
  }

  @override
  String quarterLabel(Object q) {
    return 'الربع $q';
  }

  @override
  String taadiaWithCode(Object code) {
    return 'تعدية برمز $code';
  }

  @override
  String get pendingCodeMessage => 'لم يقم المشرف بإنشاء هذه التعدية بعد';

  @override
  String get pendingTaadias => 'التعديات المعلقة';

  @override
  String get resolvedCodes => 'برمز الدخول';

  @override
  String get deletePendingTaadia => 'حذف التعدية المعلقة';

  @override
  String get codeAlreadyUsed => 'هذا الرمز مستخدم بالفعل';

  @override
  String get autoGenerate => 'توليد تلقائي';

  @override
  String get enterManually => 'إدخال يدوي';

  @override
  String get taadiaNotFound => 'التعدية غير موجودة';

  @override
  String get enterAhzabRange => 'أدخل نطاق الأحزاب';

  @override
  String get uncheckQuestionFirst => 'قم بإلغاء تحديد السؤال أولاً';

  @override
  String get wtPublicTaadiaBanner =>
      'اضغط هنا لإدخال رمز من 4 أرقام والانضمام للتعديات الخاصة';

  @override
  String get wtPrivateNewEval => 'اضغط هنا لإنشاء تقييم جديد';

  @override
  String get wtPrivateFormula => 'اضغط هنا للتبديل بين أنواع الصيغ';

  @override
  String get wtEvalRange => 'ابدأ باختيار نطاق الآيات المراد تقييمها';

  @override
  String get wtEvalAddRange => 'أضف نطاقات أخرى إذا لزم الأمر';

  @override
  String get wtEvalGenerateSwitch =>
      'فعّل هذا لإنشاء أسئلة تلقائياً، أو أطفئه للإدخال اليدوي';

  @override
  String get wtEvalQuranPages => 'افتح قارئ القرآن لمتابعة الآيات';

  @override
  String get wtEvalQuestionAdd => 'أضف أو احذف الأسئلة من هنا';

  @override
  String get wtEvalQuestionCheck => 'حدد السؤال كمكتمل عندما تنتهي منه';

  @override
  String get wtEvalSwipe => 'اسحب يميناً أو يساراً للتنقل بين الأسئلة';

  @override
  String get wtEvalSave => 'احفظ تقييمك عندما تنتهي';

  @override
  String get wtGenQuran => 'افتح القرآن لمتابعة الآية التي تقيّمها';

  @override
  String get wtGenRegenerate => 'اضغط لإنشاء سؤال مختلف';

  @override
  String get wtGenVerseNav => 'تنقل بين الآيات بأزرار';

  @override
  String get wtNext => 'التالي';

  @override
  String get wtSkip => 'تخطي';
}
