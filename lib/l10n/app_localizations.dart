import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Taadia'**
  String get appName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @orContinueWith.
  ///
  /// In en, this message translates to:
  /// **'Or continue with'**
  String get orContinueWith;

  /// No description provided for @continueAsGuest.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get continueAsGuest;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Enter your email to receive a password reset link.'**
  String get resetPasswordDesc;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLink;

  /// No description provided for @welcomeGuest.
  ///
  /// In en, this message translates to:
  /// **'Welcome, Guest!'**
  String get welcomeGuest;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @guest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// No description provided for @enterNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name to identify yourself in taadias.'**
  String get enterNameDesc;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your Name'**
  String get yourName;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @googleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In failed'**
  String get googleSignInFailed;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed'**
  String get signInFailed;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get invalidEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @google.
  ///
  /// In en, this message translates to:
  /// **'Google'**
  String get google;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Reset link sent to {email} — check your spam '**
  String resetLinkSent(Object email);

  /// No description provided for @failedToSendReset.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset link'**
  String get failedToSendReset;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @joinTaadia.
  ///
  /// In en, this message translates to:
  /// **'Join Taadia'**
  String get joinTaadia;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up with email or choose another method'**
  String get signUpSubtitle;

  /// No description provided for @signUpWithEmail.
  ///
  /// In en, this message translates to:
  /// **'Sign up with Email'**
  String get signUpWithEmail;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @orSignUpWith.
  ///
  /// In en, this message translates to:
  /// **'Or sign up with'**
  String get orSignUpWith;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @enterYourName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get enterYourName;

  /// No description provided for @enterAPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a password'**
  String get enterAPassword;

  /// No description provided for @atLeast6Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeast6Chars;

  /// No description provided for @confirmYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirmYourPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get displayName;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @updateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed'**
  String get updateFailed;

  /// No description provided for @manageUsers.
  ///
  /// In en, this message translates to:
  /// **'Manage Users'**
  String get manageUsers;

  /// No description provided for @taadiaManagement.
  ///
  /// In en, this message translates to:
  /// **'Taadia Management'**
  String get taadiaManagement;

  /// No description provided for @welcomeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeAdmin(Object name);

  /// No description provided for @manageYourTaadias.
  ///
  /// In en, this message translates to:
  /// **'Manage your Taadias'**
  String get manageYourTaadias;

  /// No description provided for @noTaadiasYet.
  ///
  /// In en, this message translates to:
  /// **'No Taadias yet'**
  String get noTaadiasYet;

  /// No description provided for @tapToCreateFirst.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first Taadia'**
  String get tapToCreateFirst;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\" and all evaluations?'**
  String deleteConfirm(Object title);

  /// No description provided for @editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Title'**
  String get editTitle;

  /// No description provided for @maxTalakin.
  ///
  /// In en, this message translates to:
  /// **'Max 2 Talakin per question'**
  String get maxTalakin;

  /// No description provided for @giveFeedback.
  ///
  /// In en, this message translates to:
  /// **'Give Feedback'**
  String get giveFeedback;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts to help us improve...'**
  String get feedbackHint;

  /// No description provided for @feedbackSent.
  ///
  /// In en, this message translates to:
  /// **'Feedback sent! Thank you.'**
  String get feedbackSent;

  /// No description provided for @viewFeedback.
  ///
  /// In en, this message translates to:
  /// **'View Feedback'**
  String get viewFeedback;

  /// No description provided for @noFeedback.
  ///
  /// In en, this message translates to:
  /// **'No feedback yet'**
  String get noFeedback;

  /// No description provided for @userFeedback.
  ///
  /// In en, this message translates to:
  /// **'Your Feedback'**
  String get userFeedback;

  /// No description provided for @noFeedbackHistory.
  ///
  /// In en, this message translates to:
  /// **'No previous feedback'**
  String get noFeedbackHistory;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @replyHint.
  ///
  /// In en, this message translates to:
  /// **'Type your reply...'**
  String get replyHint;

  /// No description provided for @replySent.
  ///
  /// In en, this message translates to:
  /// **'Reply sent'**
  String get replySent;

  /// No description provided for @adminReply.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get adminReply;

  /// No description provided for @confirmDeleteFeedback.
  ///
  /// In en, this message translates to:
  /// **'Delete this feedback?'**
  String get confirmDeleteFeedback;

  /// No description provided for @confirmDeleteReply.
  ///
  /// In en, this message translates to:
  /// **'Delete this reply?'**
  String get confirmDeleteReply;

  /// No description provided for @feedbackDeleted.
  ///
  /// In en, this message translates to:
  /// **'Feedback deleted'**
  String get feedbackDeleted;

  /// No description provided for @replyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reply deleted'**
  String get replyDeleted;

  /// No description provided for @createTaadia.
  ///
  /// In en, this message translates to:
  /// **'Create Taadia'**
  String get createTaadia;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeUser(Object name);

  /// No description provided for @selectTaadiaToEvaluate.
  ///
  /// In en, this message translates to:
  /// **'Select a Taadia to make'**
  String get selectTaadiaToEvaluate;

  /// No description provided for @noActiveTaadias.
  ///
  /// In en, this message translates to:
  /// **'No active Taadias'**
  String get noActiveTaadias;

  /// No description provided for @waitForAdmin.
  ///
  /// In en, this message translates to:
  /// **'Wait for an admin to create one'**
  String get waitForAdmin;

  /// No description provided for @tapToEvaluate.
  ///
  /// In en, this message translates to:
  /// **'Tap to see students taadia'**
  String get tapToEvaluate;

  /// No description provided for @studentEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Student taadia'**
  String get studentEvaluation;

  /// No description provided for @evaluatorName.
  ///
  /// In en, this message translates to:
  /// **'Mochref Name'**
  String get evaluatorName;

  /// No description provided for @yourNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameHint;

  /// No description provided for @studentName.
  ///
  /// In en, this message translates to:
  /// **'Student Name'**
  String get studentName;

  /// No description provided for @studentNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter student full name'**
  String get studentNameHint;

  /// No description provided for @selectGender.
  ///
  /// In en, this message translates to:
  /// **'Select Gender'**
  String get selectGender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @numberOfQuestions.
  ///
  /// In en, this message translates to:
  /// **'Number of Questions'**
  String get numberOfQuestions;

  /// No description provided for @numberOfAhzab.
  ///
  /// In en, this message translates to:
  /// **'Number of Ahzab'**
  String get numberOfAhzab;

  /// No description provided for @specialAhzab.
  ///
  /// In en, this message translates to:
  /// **'Special Ahzab'**
  String get specialAhzab;

  /// No description provided for @questions.
  ///
  /// In en, this message translates to:
  /// **'Questions'**
  String get questions;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @enterNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Enter taadia notes...'**
  String get enterNoteHint;

  /// No description provided for @saveEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Save taadia'**
  String get saveEvaluation;

  /// No description provided for @updateEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Update taadia'**
  String get updateEvaluation;

  /// No description provided for @startNewStudent.
  ///
  /// In en, this message translates to:
  /// **'Start New Student'**
  String get startNewStudent;

  /// No description provided for @cancelEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel Edit'**
  String get cancelEdit;

  /// No description provided for @myEvaluations.
  ///
  /// In en, this message translates to:
  /// **'My taadias'**
  String get myEvaluations;

  /// No description provided for @noEvaluationsYet.
  ///
  /// In en, this message translates to:
  /// **'No taadia yet'**
  String get noEvaluationsYet;

  /// No description provided for @taadiaClosed.
  ///
  /// In en, this message translates to:
  /// **'This Taadia is closed'**
  String get taadiaClosed;

  /// No description provided for @cannotEvaluateClosed.
  ///
  /// In en, this message translates to:
  /// **'Cannot make taadia: this Taadia is closed'**
  String get cannotEvaluateClosed;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @specialAhzabHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1-10, half, etc.'**
  String get specialAhzabHint;

  /// No description provided for @questionNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Note for this question (optional)'**
  String get questionNoteHint;

  /// No description provided for @ichaarat.
  ///
  /// In en, this message translates to:
  /// **'Ichaar'**
  String get ichaarat;

  /// No description provided for @taalakin.
  ///
  /// In en, this message translates to:
  /// **'Talkin'**
  String get taalakin;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @searchByEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by email...'**
  String get searchByEmail;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @noUsersFound.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get noUsersFound;

  /// No description provided for @admin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @removeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Remove admin'**
  String get removeAdmin;

  /// No description provided for @makeAdmin.
  ///
  /// In en, this message translates to:
  /// **'Make admin'**
  String get makeAdmin;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete user'**
  String get deleteUser;

  /// No description provided for @deleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUserTitle;

  /// No description provided for @deleteUserConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" and all their evaluations?'**
  String deleteUserConfirm(Object name);

  /// No description provided for @cannotDemoteSelf.
  ///
  /// In en, this message translates to:
  /// **'Cannot demote yourself'**
  String get cannotDemoteSelf;

  /// No description provided for @onlyPromoterCanDemote.
  ///
  /// In en, this message translates to:
  /// **'Only {name} who promoted them can demote this admin'**
  String onlyPromoterCanDemote(Object name);

  /// No description provided for @noUserFoundEmail.
  ///
  /// In en, this message translates to:
  /// **'No user found with that email'**
  String get noUserFoundEmail;

  /// No description provided for @userNowAdmin.
  ///
  /// In en, this message translates to:
  /// **'{name} is now an admin'**
  String userNowAdmin(Object name);

  /// No description provided for @userAlreadyAdmin.
  ///
  /// In en, this message translates to:
  /// **'{name} is already an admin'**
  String userAlreadyAdmin(Object name);

  /// No description provided for @cannotDeleteSelf.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete yourself'**
  String get cannotDeleteSelf;

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name...'**
  String get searchByName;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'students'**
  String get students;

  /// No description provided for @waitingForTeachers.
  ///
  /// In en, this message translates to:
  /// **'Waiting for 3aredhin to submit'**
  String get waitingForTeachers;

  /// No description provided for @evaluator.
  ///
  /// In en, this message translates to:
  /// **'el 3aredh'**
  String get evaluator;

  /// No description provided for @ahzab.
  ///
  /// In en, this message translates to:
  /// **'Ahzab'**
  String get ahzab;

  /// No description provided for @totalIchaarat.
  ///
  /// In en, this message translates to:
  /// **'Total Ichaarat'**
  String get totalIchaarat;

  /// No description provided for @totalTaalakin.
  ///
  /// In en, this message translates to:
  /// **'Total Taalakin'**
  String get totalTaalakin;

  /// No description provided for @deleteEvaluation.
  ///
  /// In en, this message translates to:
  /// **'Delete taadia'**
  String get deleteEvaluation;

  /// No description provided for @deleteEvalConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete taadia for {name}?'**
  String deleteEvalConfirm(Object name);

  /// No description provided for @hizb.
  ///
  /// In en, this message translates to:
  /// **'Ahzeb'**
  String get hizb;

  /// No description provided for @assessmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Taadia Title'**
  String get assessmentTitle;

  /// No description provided for @titleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Q1 2026 Taadia'**
  String get titleHint;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Brief description of this Taadia'**
  String get descriptionHint;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @enterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a title'**
  String get enterTitle;

  /// No description provided for @failedToCreate.
  ///
  /// In en, this message translates to:
  /// **'Failed to create'**
  String get failedToCreate;

  /// No description provided for @evaluated.
  ///
  /// In en, this message translates to:
  /// **'Taadia of {name} done!'**
  String evaluated(Object name);

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'{name} updated!'**
  String updated(Object name);

  /// No description provided for @question.
  ///
  /// In en, this message translates to:
  /// **'Question'**
  String get question;

  /// No description provided for @noteForQuestion.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteForQuestion;

  /// No description provided for @qPrefix.
  ///
  /// In en, this message translates to:
  /// **'Q'**
  String get qPrefix;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all taadias. This cannot be undone.'**
  String get deleteAccountWarning;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeleted;

  /// No description provided for @evaluateStudents.
  ///
  /// In en, this message translates to:
  /// **'Make Taadia For Students'**
  String get evaluateStudents;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortBy;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @evaluate.
  ///
  /// In en, this message translates to:
  /// **'Make Taadia'**
  String get evaluate;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @enterStudentName.
  ///
  /// In en, this message translates to:
  /// **'Enter student name'**
  String get enterStudentName;

  /// No description provided for @installApp.
  ///
  /// In en, this message translates to:
  /// **'Install App'**
  String get installApp;

  /// No description provided for @visitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit Our Website'**
  String get visitWebsite;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found with this email'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Wrong password'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorEmailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'Email already in use'**
  String get authErrorEmailAlreadyInUse;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Weak password'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get authErrorInvalidEmail;

  /// No description provided for @accountDeletedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted by the admin'**
  String get accountDeletedByAdmin;

  /// No description provided for @authErrorUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'User disabled'**
  String get authErrorUserDisabled;

  /// No description provided for @authErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many requests'**
  String get authErrorTooManyRequests;

  /// No description provided for @authErrorDefault.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed'**
  String get authErrorDefault;

  /// No description provided for @formula.
  ///
  /// In en, this message translates to:
  /// **'Formula'**
  String get formula;

  /// No description provided for @formulaDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose the formula to calculate student ranking'**
  String get formulaDesc;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAll;

  /// No description provided for @showClassement.
  ///
  /// In en, this message translates to:
  /// **'Show Ranking'**
  String get showClassement;

  /// No description provided for @hideClassement.
  ///
  /// In en, this message translates to:
  /// **'Hide Ranking'**
  String get hideClassement;

  /// No description provided for @filterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by'**
  String get filterBy;

  /// No description provided for @formulaName.
  ///
  /// In en, this message translates to:
  /// **'Formula Name'**
  String get formulaName;

  /// No description provided for @formulaNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Final Score'**
  String get formulaNameHint;

  /// No description provided for @operation.
  ///
  /// In en, this message translates to:
  /// **'Operation'**
  String get operation;

  /// No description provided for @coefIchaarat.
  ///
  /// In en, this message translates to:
  /// **'Ichaarat Weight'**
  String get coefIchaarat;

  /// No description provided for @coefTaalakin.
  ///
  /// In en, this message translates to:
  /// **'Taalakin Weight'**
  String get coefTaalakin;

  /// No description provided for @results.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get results;

  /// No description provided for @installAppAlready.
  ///
  /// In en, this message translates to:
  /// **'App is already installed'**
  String get installAppAlready;

  /// No description provided for @formulaErrorEmpty.
  ///
  /// In en, this message translates to:
  /// **'Expression cannot be empty'**
  String get formulaErrorEmpty;

  /// No description provided for @formulaErrorUnmatchedOpen.
  ///
  /// In en, this message translates to:
  /// **'Unmatched opening parenthesis'**
  String get formulaErrorUnmatchedOpen;

  /// No description provided for @formulaErrorUnmatchedClose.
  ///
  /// In en, this message translates to:
  /// **'Unmatched closing parenthesis'**
  String get formulaErrorUnmatchedClose;

  /// No description provided for @formulaErrorUnknownChar.
  ///
  /// In en, this message translates to:
  /// **'Unknown character in expression'**
  String get formulaErrorUnknownChar;

  /// No description provided for @formulaErrorConsecutiveOps.
  ///
  /// In en, this message translates to:
  /// **'Consecutive operators are not allowed'**
  String get formulaErrorConsecutiveOps;

  /// No description provided for @formulaErrorInvalidStart.
  ///
  /// In en, this message translates to:
  /// **'Expression cannot start with an operator'**
  String get formulaErrorInvalidStart;

  /// No description provided for @formulaErrorInvalidEnd.
  ///
  /// In en, this message translates to:
  /// **'Expression cannot end with an operator'**
  String get formulaErrorInvalidEnd;

  /// No description provided for @formulaErrorDivisionByZero.
  ///
  /// In en, this message translates to:
  /// **'Division by zero in formula'**
  String get formulaErrorDivisionByZero;

  /// No description provided for @formulaErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Invalid formula syntax'**
  String get formulaErrorGeneric;

  /// No description provided for @installAppIOS.
  ///
  /// In en, this message translates to:
  /// **'To install this app on iOS:\n1. Tap the Share button (📤) at the bottom of Safari\n2. Scroll down and tap \"Add to Home Screen\"\n3. Tap \"Add\" in the top right corner'**
  String get installAppIOS;

  /// No description provided for @installAppGeneric.
  ///
  /// In en, this message translates to:
  /// **'To install this app:\n• Open Chrome or Edge on desktop\n• Click the install icon (➕) in the address bar\n• Or open this page on Android Chrome and tap \"Install\"'**
  String get installAppGeneric;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how you\'d like to participate:'**
  String get homeSubtitle;

  /// No description provided for @joinTaadiaDesc.
  ///
  /// In en, this message translates to:
  /// **'Browse and join existing taadias to evaluate students'**
  String get joinTaadiaDesc;

  /// No description provided for @createOwnTaadia.
  ///
  /// In en, this message translates to:
  /// **'Create Your Own Taadia'**
  String get createOwnTaadia;

  /// No description provided for @createOwnTaadiaDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a private taadia visible only to you'**
  String get createOwnTaadiaDesc;

  /// No description provided for @privateTaadiaNotice.
  ///
  /// In en, this message translates to:
  /// **'This taadia is private — only you can see it.'**
  String get privateTaadiaNotice;

  /// No description provided for @myPrivateTaadias.
  ///
  /// In en, this message translates to:
  /// **'My Private Taadias'**
  String get myPrivateTaadias;

  /// No description provided for @taadia.
  ///
  /// In en, this message translates to:
  /// **'Taadia'**
  String get taadia;

  /// No description provided for @startTaadia.
  ///
  /// In en, this message translates to:
  /// **'Start Taadia'**
  String get startTaadia;

  /// No description provided for @manageTaadia.
  ///
  /// In en, this message translates to:
  /// **'Manage Taadia'**
  String get manageTaadia;

  /// No description provided for @publicTaadias.
  ///
  /// In en, this message translates to:
  /// **'Public Taadias'**
  String get publicTaadias;

  /// No description provided for @maxTwoTalakin.
  ///
  /// In en, this message translates to:
  /// **'Maximum two talakin per question'**
  String get maxTwoTalakin;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @manageGroups.
  ///
  /// In en, this message translates to:
  /// **'Manage Groups'**
  String get manageGroups;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get createGroup;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Q1 Reciters'**
  String get groupNameHint;

  /// No description provided for @renameGroup.
  ///
  /// In en, this message translates to:
  /// **'Rename Group'**
  String get renameGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String deleteGroupConfirm(Object name);

  /// No description provided for @noGroupsYet.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get noGroupsYet;

  /// No description provided for @tapToCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first group'**
  String get tapToCreateGroup;

  /// No description provided for @manageMembers.
  ///
  /// In en, this message translates to:
  /// **'Manage Members'**
  String get manageMembers;

  /// No description provided for @manageMembersFor.
  ///
  /// In en, this message translates to:
  /// **'Members of {name}'**
  String manageMembersFor(Object name);

  /// No description provided for @groupMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count} members'**
  String groupMemberCount(Object count);

  /// No description provided for @accessControl.
  ///
  /// In en, this message translates to:
  /// **'Access Control'**
  String get accessControl;

  /// No description provided for @accessControlDesc.
  ///
  /// In en, this message translates to:
  /// **'Choose who can access this Taadia'**
  String get accessControlDesc;

  /// No description provided for @selectGroups.
  ///
  /// In en, this message translates to:
  /// **'Select Groups'**
  String get selectGroups;

  /// No description provided for @selectGroupsDesc.
  ///
  /// In en, this message translates to:
  /// **'Only members of selected groups can access'**
  String get selectGroupsDesc;

  /// No description provided for @addGroups.
  ///
  /// In en, this message translates to:
  /// **'Add Groups'**
  String get addGroups;

  /// No description provided for @selectUsers.
  ///
  /// In en, this message translates to:
  /// **'Select Users'**
  String get selectUsers;

  /// No description provided for @selectUsersDesc.
  ///
  /// In en, this message translates to:
  /// **'Select individual users who can access'**
  String get selectUsersDesc;

  /// No description provided for @usersSelected.
  ///
  /// In en, this message translates to:
  /// **'users selected'**
  String get usersSelected;

  /// No description provided for @accessCode.
  ///
  /// In en, this message translates to:
  /// **'Access Code'**
  String get accessCode;

  /// No description provided for @accessCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Users who are not selected can enter this code to access'**
  String get accessCodeDesc;

  /// No description provided for @regenerateCode.
  ///
  /// In en, this message translates to:
  /// **'Generate new code'**
  String get regenerateCode;

  /// No description provided for @enterAccessCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Access Code'**
  String get enterAccessCode;

  /// No description provided for @accessCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter the 4-digit code'**
  String get accessCodeHint;

  /// No description provided for @joinWithCode.
  ///
  /// In en, this message translates to:
  /// **'Join with Code'**
  String get joinWithCode;

  /// No description provided for @joinWithCodeDesc.
  ///
  /// In en, this message translates to:
  /// **'Have an access code? Enter it here to join a taadia'**
  String get joinWithCodeDesc;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @accessGranted.
  ///
  /// In en, this message translates to:
  /// **'Access granted! You can now view this Taadia'**
  String get accessGranted;

  /// No description provided for @alreadyHaveAccess.
  ///
  /// In en, this message translates to:
  /// **'You already have access to this taadia'**
  String get alreadyHaveAccess;

  /// No description provided for @invalidCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid or expired code'**
  String get invalidCode;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied!'**
  String get copied;

  /// No description provided for @exitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit?'**
  String get exitConfirm;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @deletedAccountWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'This email belongs to a deleted account. Please use the original password to reclaim it.'**
  String get deletedAccountWrongPassword;

  /// No description provided for @rangeAllQuran.
  ///
  /// In en, this message translates to:
  /// **'All Quran'**
  String get rangeAllQuran;

  /// No description provided for @rangeQuarter.
  ///
  /// In en, this message translates to:
  /// **'Quarter'**
  String get rangeQuarter;

  /// No description provided for @rangeHizbRange.
  ///
  /// In en, this message translates to:
  /// **'Hizb Range'**
  String get rangeHizbRange;

  /// No description provided for @rangeSurahs.
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get rangeSurahs;

  /// No description provided for @rangeSurahPages.
  ///
  /// In en, this message translates to:
  /// **'Pages from Surah'**
  String get rangeSurahPages;

  /// No description provided for @rangeSurahAyahRange.
  ///
  /// In en, this message translates to:
  /// **'Verses from Surah'**
  String get rangeSurahAyahRange;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @fromAyah.
  ///
  /// In en, this message translates to:
  /// **'From ayah'**
  String get fromAyah;

  /// No description provided for @toAyah.
  ///
  /// In en, this message translates to:
  /// **'To ayah'**
  String get toAyah;

  /// No description provided for @fromPage.
  ///
  /// In en, this message translates to:
  /// **'From page'**
  String get fromPage;

  /// No description provided for @toPage.
  ///
  /// In en, this message translates to:
  /// **'To page'**
  String get toPage;

  /// No description provided for @selectSurah.
  ///
  /// In en, this message translates to:
  /// **'Select surah'**
  String get selectSurah;

  /// No description provided for @addSurah.
  ///
  /// In en, this message translates to:
  /// **'+ Add surah'**
  String get addSurah;

  /// No description provided for @addRange.
  ///
  /// In en, this message translates to:
  /// **'Add range'**
  String get addRange;

  /// No description provided for @generateQuestions.
  ///
  /// In en, this message translates to:
  /// **'Generate questions'**
  String get generateQuestions;

  /// No description provided for @generating.
  ///
  /// In en, this message translates to:
  /// **'Generating...'**
  String get generating;

  /// No description provided for @generateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to generate questions'**
  String get generateFailed;

  /// No description provided for @surah.
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get surah;

  /// No description provided for @previousRange.
  ///
  /// In en, this message translates to:
  /// **'Previous range: {text}'**
  String previousRange(Object text);

  /// No description provided for @quarterLabel.
  ///
  /// In en, this message translates to:
  /// **'Quarter {q}'**
  String quarterLabel(Object q);

  /// No description provided for @taadiaWithCode.
  ///
  /// In en, this message translates to:
  /// **'Taadia with code {code}'**
  String taadiaWithCode(Object code);

  /// No description provided for @pendingCodeMessage.
  ///
  /// In en, this message translates to:
  /// **'The supervisor has not created this taadia yet'**
  String get pendingCodeMessage;

  /// No description provided for @pendingTaadias.
  ///
  /// In en, this message translates to:
  /// **'Pending taadias'**
  String get pendingTaadias;

  /// No description provided for @resolvedCodes.
  ///
  /// In en, this message translates to:
  /// **'By code'**
  String get resolvedCodes;

  /// No description provided for @deletePendingTaadia.
  ///
  /// In en, this message translates to:
  /// **'Delete pending taadia'**
  String get deletePendingTaadia;

  /// No description provided for @codeAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This code is already in use'**
  String get codeAlreadyUsed;

  /// No description provided for @autoGenerate.
  ///
  /// In en, this message translates to:
  /// **'Auto-generate'**
  String get autoGenerate;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get enterManually;

  /// No description provided for @taadiaNotFound.
  ///
  /// In en, this message translates to:
  /// **'Taadia not found'**
  String get taadiaNotFound;

  /// No description provided for @enterAhzabRange.
  ///
  /// In en, this message translates to:
  /// **'Enter ahzab range'**
  String get enterAhzabRange;

  /// No description provided for @uncheckQuestionFirst.
  ///
  /// In en, this message translates to:
  /// **'You need to uncheck the question first'**
  String get uncheckQuestionFirst;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
