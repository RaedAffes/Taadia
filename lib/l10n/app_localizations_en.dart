// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Taadia';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordDesc =>
      'Enter your email to receive a password reset link.';

  @override
  String get cancel => 'Cancel';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get welcomeGuest => 'Welcome, Guest!';

  @override
  String get welcome => 'Welcome';

  @override
  String get guest => 'Guest';

  @override
  String get enterNameDesc =>
      'Please enter your name to identify yourself in taadias.';

  @override
  String get yourName => 'Your Name';

  @override
  String get continueLabel => 'Continue';

  @override
  String get googleSignInFailed => 'Google Sign-In failed';

  @override
  String get signInFailed => 'Sign in failed';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get google => 'Google';

  @override
  String resetLinkSent(Object email) {
    return 'Reset link sent to $email — check your spam ';
  }

  @override
  String get failedToSendReset => 'Failed to send reset link';

  @override
  String get createAccount => 'Create Account';

  @override
  String get joinTaadia => 'Join Taadia';

  @override
  String get signUpSubtitle => 'Sign up with email or choose another method';

  @override
  String get signUpWithEmail => 'Sign up with Email';

  @override
  String get fullName => 'Full Name';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get orSignUpWith => 'Or sign up with';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get enterAPassword => 'Enter a password';

  @override
  String get atLeast6Chars => 'At least 6 characters';

  @override
  String get confirmYourPassword => 'Confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get displayName => 'Display Name';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get logout => 'Logout';

  @override
  String get areYouSure => 'Are you sure?';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String get updateFailed => 'Update failed';

  @override
  String get manageUsers => 'Manage Users';

  @override
  String get taadiaManagement => 'Taadia Management';

  @override
  String welcomeAdmin(Object name) {
    return 'Welcome, $name';
  }

  @override
  String get manageYourTaadias => 'Manage your Taadias';

  @override
  String get noTaadiasYet => 'No Taadias yet';

  @override
  String get tapToCreateFirst => 'Tap + to create your first Taadia';

  @override
  String get open => 'Open';

  @override
  String get close => 'Close';

  @override
  String get delete => 'Delete';

  @override
  String deleteConfirm(Object title) {
    return 'Delete \"$title\" and all evaluations?';
  }

  @override
  String get editTitle => 'Edit Title';

  @override
  String get maxTalakin => 'Max 2 Talakin per question';

  @override
  String get giveFeedback => 'Give Feedback';

  @override
  String get feedbackHint => 'Share your thoughts to help us improve...';

  @override
  String get feedbackSent => 'Feedback sent! Thank you.';

  @override
  String get viewFeedback => 'View Feedback';

  @override
  String get noFeedback => 'No feedback yet';

  @override
  String get userFeedback => 'Your Feedback';

  @override
  String get noFeedbackHistory => 'No previous feedback';

  @override
  String get reply => 'Reply';

  @override
  String get replyHint => 'Type your reply...';

  @override
  String get replySent => 'Reply sent';

  @override
  String get adminReply => 'Admin';

  @override
  String get confirmDeleteFeedback => 'Delete this feedback?';

  @override
  String get confirmDeleteReply => 'Delete this reply?';

  @override
  String get feedbackDeleted => 'Feedback deleted';

  @override
  String get replyDeleted => 'Reply deleted';

  @override
  String get createTaadia => 'Create Taadia';

  @override
  String welcomeUser(Object name) {
    return 'Welcome, $name';
  }

  @override
  String get selectTaadiaToEvaluate => 'Select a Taadia to make';

  @override
  String get noActiveTaadias => 'No active Taadias';

  @override
  String get waitForAdmin => 'Wait for an admin to create one';

  @override
  String get tapToEvaluate => 'Tap to see students taadia';

  @override
  String get studentEvaluation => 'Student taadia';

  @override
  String get evaluatorName => 'Mochref Name';

  @override
  String get yourNameHint => 'Your name';

  @override
  String get studentName => 'Student Name';

  @override
  String get studentNameHint => 'Enter student full name';

  @override
  String get selectGender => 'Select Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get gender => 'Gender';

  @override
  String get numberOfQuestions => 'Number of Questions';

  @override
  String get enterNumberOfQuestions => 'Enter number of questions';

  @override
  String get numberOfAhzab => 'Number of Ahzab';

  @override
  String get specialAhzab => 'Special Ahzab';

  @override
  String get questions => 'Questions';

  @override
  String get note => 'Note';

  @override
  String get enterNoteHint => 'Enter taadia notes...';

  @override
  String get saveEvaluation => 'Save taadia';

  @override
  String get updateEvaluation => 'Update taadia';

  @override
  String get startNewStudent => 'Start New Student';

  @override
  String get cancelEdit => 'Cancel Edit';

  @override
  String get myEvaluations => 'My taadias';

  @override
  String get noEvaluationsYet => 'No taadia yet';

  @override
  String get taadiaClosed => 'This Taadia is closed';

  @override
  String get cannotEvaluateClosed =>
      'Cannot make taadia: this Taadia is closed';

  @override
  String get goBack => 'Go Back';

  @override
  String get specialAhzabHint => 'e.g. 1-10, half, etc.';

  @override
  String get questionNoteHint => 'Note for this question (optional)';

  @override
  String get ichaarat => 'Ichaar';

  @override
  String get taalakin => 'Talkin';

  @override
  String get select => 'Select';

  @override
  String get searchByEmail => 'Search by email...';

  @override
  String get search => 'Search';

  @override
  String get noUsersFound => 'No users found';

  @override
  String get admin => 'Admin';

  @override
  String get user => 'User';

  @override
  String get removeAdmin => 'Remove admin';

  @override
  String get makeAdmin => 'Make admin';

  @override
  String get deleteUser => 'Delete user';

  @override
  String get deleteUserTitle => 'Delete User';

  @override
  String deleteUserConfirm(Object name) {
    return 'Delete \"$name\" and all their evaluations?';
  }

  @override
  String get cannotDemoteSelf => 'Cannot demote yourself';

  @override
  String onlyPromoterCanDemote(Object name) {
    return 'Only $name who promoted them can demote this admin';
  }

  @override
  String get noUserFoundEmail => 'No user found with that email';

  @override
  String userNowAdmin(Object name) {
    return '$name is now an admin';
  }

  @override
  String userAlreadyAdmin(Object name) {
    return '$name is already an admin';
  }

  @override
  String get cannotDeleteSelf => 'Cannot delete yourself';

  @override
  String get searchByName => 'Search by name...';

  @override
  String get other => 'Other';

  @override
  String get students => 'students';

  @override
  String get waitingForTeachers => 'Waiting for 3aredhin to submit';

  @override
  String get evaluator => 'el 3aredh';

  @override
  String get ahzab => 'Ahzab';

  @override
  String get totalIchaarat => 'Total Ichaarat';

  @override
  String get totalTaalakin => 'Total Taalakin';

  @override
  String get deleteEvaluation => 'Delete taadia';

  @override
  String deleteEvalConfirm(Object name) {
    return 'Delete taadia for $name?';
  }

  @override
  String get hizb => 'Ahzeb';

  @override
  String get assessmentTitle => 'Taadia Title';

  @override
  String get titleHint => 'e.g. Q1 2026 Taadia';

  @override
  String get descriptionOptional => 'Description (optional)';

  @override
  String get descriptionHint => 'Brief description of this Taadia';

  @override
  String get create => 'Create';

  @override
  String get enterTitle => 'Enter a title';

  @override
  String get failedToCreate => 'Failed to create';

  @override
  String evaluated(Object name) {
    return 'Taadia of $name done!';
  }

  @override
  String updated(Object name) {
    return '$name updated!';
  }

  @override
  String get question => 'Question';

  @override
  String get noteForQuestion => 'Note';

  @override
  String get qPrefix => 'Q';

  @override
  String get unknown => 'Unknown';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountConfirm => 'Delete your account?';

  @override
  String get deleteAccountWarning =>
      'This will permanently delete your account and all taadias. This cannot be undone.';

  @override
  String get accountDeleted => 'Account deleted';

  @override
  String get evaluateStudents => 'Make Taadia For Students';

  @override
  String get sortBy => 'Sort by';

  @override
  String get all => 'All';

  @override
  String get evaluate => 'Make Taadia';

  @override
  String get name => 'Name';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get enterStudentName => 'Enter student name';

  @override
  String get installApp => 'Install App';

  @override
  String get visitWebsite => 'Visit Our Website';

  @override
  String get authErrorUserNotFound => 'No user found with this email';

  @override
  String get authErrorWrongPassword => 'Wrong password';

  @override
  String get authErrorEmailAlreadyInUse => 'Email already in use';

  @override
  String get authErrorWeakPassword => 'Weak password';

  @override
  String get authErrorInvalidEmail => 'Invalid email format';

  @override
  String get accountDeletedByAdmin =>
      'Your account has been deleted by the admin';

  @override
  String get authErrorUserDisabled => 'User disabled';

  @override
  String get authErrorTooManyRequests => 'Too many requests';

  @override
  String get authErrorDefault => 'Authentication failed';

  @override
  String get formula => 'Formula';

  @override
  String get formulaDesc => 'Choose the formula to calculate student ranking';

  @override
  String get save => 'Save';

  @override
  String get selectAll => 'Select All';

  @override
  String get showClassement => 'Show Ranking';

  @override
  String get hideClassement => 'Hide Ranking';

  @override
  String get filterBy => 'Filter by';

  @override
  String get formulaName => 'Formula Name';

  @override
  String get formulaNameHint => 'e.g. Final Score';

  @override
  String get operation => 'Operation';

  @override
  String get coefIchaarat => 'Ichaarat Weight';

  @override
  String get coefTaalakin => 'Taalakin Weight';

  @override
  String get results => 'Results';

  @override
  String get installAppAlready => 'App is already installed';

  @override
  String get formulaErrorEmpty => 'Expression cannot be empty';

  @override
  String get formulaErrorUnmatchedOpen => 'Unmatched opening parenthesis';

  @override
  String get formulaErrorUnmatchedClose => 'Unmatched closing parenthesis';

  @override
  String get formulaErrorUnknownChar => 'Unknown character in expression';

  @override
  String get formulaErrorConsecutiveOps =>
      'Consecutive operators are not allowed';

  @override
  String get formulaErrorInvalidStart =>
      'Expression cannot start with an operator';

  @override
  String get formulaErrorInvalidEnd => 'Expression cannot end with an operator';

  @override
  String get formulaErrorDivisionByZero => 'Division by zero in formula';

  @override
  String get formulaErrorGeneric => 'Invalid formula syntax';

  @override
  String get installAppIOS =>
      'To install this app on iOS:\n1. Tap the Share button (📤) at the bottom of Safari\n2. Scroll down and tap \"Add to Home Screen\"\n3. Tap \"Add\" in the top right corner';

  @override
  String get installAppGeneric =>
      'To install this app:\n• Open Chrome or Edge on desktop\n• Click the install icon (➕) in the address bar\n• Or open this page on Android Chrome and tap \"Install\"';

  @override
  String get homeSubtitle => 'Choose how you\'d like to participate:';

  @override
  String get joinTaadiaDesc =>
      'Browse and join existing taadias to evaluate students';

  @override
  String get createOwnTaadia => 'Create Your Own Taadia';

  @override
  String get createOwnTaadiaDesc =>
      'Create a private taadia visible only to you';

  @override
  String get privateTaadiaNotice =>
      'This taadia is private — only you can see it.';

  @override
  String get myPrivateTaadias => 'My Private Taadias';

  @override
  String get taadia => 'Taadia';

  @override
  String get startTaadia => 'Start Taadia';

  @override
  String get manageTaadia => 'Manage Taadia';

  @override
  String get publicTaadias => 'Public Taadias';

  @override
  String get maxTwoTalakin => 'Maximum two talakin per question';

  @override
  String get add => 'Add';

  @override
  String get remove => 'Remove';

  @override
  String get manageGroups => 'Manage Groups';

  @override
  String get createGroup => 'Create Group';

  @override
  String get groupName => 'Group Name';

  @override
  String get groupNameHint => 'e.g. Q1 Reciters';

  @override
  String get renameGroup => 'Rename Group';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String deleteGroupConfirm(Object name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get noGroupsYet => 'No groups yet';

  @override
  String get tapToCreateGroup => 'Tap + to create your first group';

  @override
  String get manageMembers => 'Manage Members';

  @override
  String manageMembersFor(Object name) {
    return 'Members of $name';
  }

  @override
  String groupMemberCount(Object count) {
    return '$count members';
  }

  @override
  String get accessControl => 'Access Control';

  @override
  String get accessControlDesc => 'Choose who can access this Taadia';

  @override
  String get selectGroups => 'Select Groups';

  @override
  String get selectGroupsDesc => 'Only members of selected groups can access';

  @override
  String get addGroups => 'Add Groups';

  @override
  String get selectUsers => 'Select Users';

  @override
  String get selectUsersDesc => 'Select individual users who can access';

  @override
  String get usersSelected => 'users selected';

  @override
  String get accessCode => 'Access Code';

  @override
  String get accessCodeDesc =>
      'Users who are not selected can enter this code to access';

  @override
  String get regenerateCode => 'Generate new code';

  @override
  String get enterAccessCode => 'Enter Access Code';

  @override
  String get accessCodeHint => 'Enter the 4-digit code';

  @override
  String get joinWithCode => 'Join with Code';

  @override
  String get joinWithCodeDesc =>
      'Have an access code? Enter it here to join a taadia';

  @override
  String get verify => 'Verify';

  @override
  String get accessGranted => 'Access granted! You can now view this Taadia';

  @override
  String get alreadyHaveAccess => 'You already have access to this taadia';

  @override
  String get invalidCode => 'Invalid or expired code';

  @override
  String get done => 'Done';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied!';

  @override
  String get exitConfirm => 'Are you sure you want to exit?';

  @override
  String get exit => 'Exit';

  @override
  String get deletedAccountWrongPassword =>
      'This email belongs to a deleted account. Please use the original password to reclaim it.';

  @override
  String get rangeAllQuran => 'All Quran';

  @override
  String get rangeQuarter => 'Quarter';

  @override
  String get rangeHizbRange => 'Hizb Range';

  @override
  String get rangeSurahs => 'Surahs';

  @override
  String get rangeSurahPages => 'Pages from Surah';

  @override
  String get rangeSurahAyahRange => 'Verses from Surah';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get fromAyah => 'From ayah';

  @override
  String get toAyah => 'To ayah';

  @override
  String get fromPage => 'From page';

  @override
  String get toPage => 'To page';

  @override
  String get selectSurah => 'Select surah';

  @override
  String get addSurah => '+ Add surah';

  @override
  String get addRange => 'Add range';

  @override
  String get collapseAll => 'Collapse all';

  @override
  String get expandAll => 'Expand all';

  @override
  String get generateQuestions => 'Generate questions';

  @override
  String get generating => 'Generating...';

  @override
  String get generateFailed => 'Failed to generate questions';

  @override
  String get surah => 'Surah';

  @override
  String previousRange(Object text) {
    return 'Previous range: $text';
  }

  @override
  String quarterLabel(Object q) {
    return 'Quarter $q';
  }

  @override
  String taadiaWithCode(Object code) {
    return 'Taadia with code $code';
  }

  @override
  String get pendingCodeMessage =>
      'The supervisor has not created this taadia yet';

  @override
  String get pendingTaadias => 'Pending taadias';

  @override
  String get resolvedCodes => 'By code';

  @override
  String get deletePendingTaadia => 'Delete pending taadia';

  @override
  String get codeAlreadyUsed => 'This code is already in use';

  @override
  String get autoGenerate => 'Auto-generate';

  @override
  String get enterManually => 'Enter manually';

  @override
  String get taadiaNotFound => 'Taadia not found';

  @override
  String get enterAhzabRange => 'Enter ahzab range';

  @override
  String get uncheckQuestionFirst => 'You need to uncheck the question first';

  @override
  String get wtPublicTaadiaBanner =>
      'Tap here to enter a 4-digit code and join private taadias';

  @override
  String get wtPrivateNewEval => 'Tap here to create a new evaluation';

  @override
  String get wtPrivateFormula => 'Tap here to switch between formula types';

  @override
  String get wtEvalRange =>
      'Start by selecting the range of verses to evaluate';

  @override
  String get wtEvalAddRange => 'Add more ranges if needed';

  @override
  String get wtEvalGenerateSwitch =>
      'Turn this on to auto-generate questions, or leave off for manual entry';

  @override
  String get wtEvalQuranPages =>
      'Open the Quran reader to follow along with verses';

  @override
  String get wtEvalQuestionAdd => 'Add or remove questions here';

  @override
  String get wtEvalQuestionCheck =>
      'Mark a question as complete when you finish it';

  @override
  String get wtEvalSwipe => 'Swipe left or right to navigate between questions';

  @override
  String get wtEvalSave => 'Save your evaluation when finished';

  @override
  String get wtGenQuran =>
      'Open the Quran to follow the verse you are evaluating';

  @override
  String get wtGenRegenerate => 'Tap to regenerate a different question';

  @override
  String get wtGenVerseNav => 'Navigate between verses with these buttons';

  @override
  String get wtNext => 'Next';

  @override
  String get wtSkip => 'Skip';

  @override
  String get manageOrganizations => 'Manage Organizations';

  @override
  String get createOrganization => 'Create Organization';

  @override
  String get joinOrganization => 'Join Organization';

  @override
  String get organizationName => 'Organization Name';

  @override
  String get organizationPassword => 'Organization Password';

  @override
  String get confirmOrganizationPassword => 'Confirm Password';

  @override
  String get pendingApproval => 'Pending super admin approval';

  @override
  String get organizationApproved => 'Organization approved!';

  @override
  String get organizationRejected => 'Organization rejected';

  @override
  String get alreadyMember => 'Already a member';

  @override
  String get incorrectPassword => 'Incorrect password';

  @override
  String get noOrganizations => 'No organizations available';

  @override
  String membersCount(Object count) {
    return '$count members';
  }

  @override
  String get approving => 'Approving...';

  @override
  String get rejecting => 'Rejecting...';

  @override
  String get joinOrCreateOrg => 'Join or Create an Organization';

  @override
  String get orgGateSubtitle =>
      'You need to join or create a جمعية to get started';

  @override
  String get joinOrgCardTitle => 'Join جمعية';

  @override
  String get joinOrgCardDesc => 'Join an existing جمعية using a password';

  @override
  String get createOrgCardTitle => 'Create جمعية';

  @override
  String get createOrgCardDesc => 'Create a new جمعية and invite members';

  @override
  String get manageOrganization => 'Manage جمعية';

  @override
  String get manageOrgDesc =>
      'View and manage your جمعية details, members, and settings';

  @override
  String get orgDetails => 'Organization Details';

  @override
  String get orgMembers => 'Members';

  @override
  String get removeMember => 'Remove Member';

  @override
  String removeMemberConfirm(Object name) {
    return 'Remove $name from this جمعية?';
  }

  @override
  String get memberRemoved => 'Member removed';

  @override
  String get editOrgName => 'Edit Organization Name';

  @override
  String get editOrgPassword => 'Edit Organization Password';

  @override
  String get orgNameUpdated => 'Organization name updated';

  @override
  String get orgPasswordUpdated => 'Organization password updated';

  @override
  String get noMembers => 'No members yet';

  @override
  String get adminRole => 'Admin';

  @override
  String get userRole => 'Member';

  @override
  String get tapToReveal => 'Tap to reveal password';

  @override
  String get dangerZone => 'Danger Zone';

  @override
  String get dangerZoneDesc =>
      'Permanently delete this organization and all its data';

  @override
  String get createdOn => 'Created on';

  @override
  String get joinCode => 'Join Code';

  @override
  String get orgSettings => 'Settings';

  @override
  String get rename => 'Rename';

  @override
  String get changePassword => 'Change Password';

  @override
  String get adminBadge => 'Admin';

  @override
  String get youBadge => 'You';

  @override
  String get noMembersYet => 'No members have joined yet';

  @override
  String get ownerLabel => 'Owner';

  @override
  String get confirmPasswordLabel => 'Confirm new password';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get passwordUpdated => 'Password updated successfully';

  @override
  String get myOrganizations => 'My Organizations';

  @override
  String get switchOrganization => 'Switch Organization';

  @override
  String get leaveOrganization => 'Leave Organization';

  @override
  String get leave => 'Leave';

  @override
  String leaveOrgConfirm(Object name) {
    return 'Leave \"$name\"?';
  }

  @override
  String get leaveOrgConsequence =>
      'You will lose access to this organization\'s taadias and groups. You can rejoin anytime with the password.';

  @override
  String get ownerLeaveWarning =>
      'You are the owner of this organization. To leave, add another admin first or delete the organization.';

  @override
  String get switchToOrg => 'Switch';

  @override
  String get manage => 'Manage';

  @override
  String get currentOrg => 'Current';

  @override
  String get currentOrganization => 'Current Organization';

  @override
  String get noOrganizationsYet => 'No organizations yet';

  @override
  String get joinAnotherOrg => 'Join Another Organization';

  @override
  String get pendingOrgs => 'Pending Approval';

  @override
  String get approvedOrgs => 'Approved Organizations';

  @override
  String get rejectedOrgs => 'Rejected';

  @override
  String get approve => 'Approve';

  @override
  String get reject => 'Reject';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get rejected => 'Rejected';

  @override
  String get membersTab => 'Members';

  @override
  String get resetPasswordTab => 'Reset Password';

  @override
  String get promoteToAdmin => 'Promote to Admin';

  @override
  String get demoteFromAdmin => 'Demote from Admin';

  @override
  String get removeFromOrg => 'Remove from Organization';

  @override
  String get confirm => 'Confirm';

  @override
  String get deleteOrganization => 'Delete Organization';

  @override
  String deleteOrgConfirm(Object name) {
    return 'Delete \"$name\" and all its data permanently?';
  }

  @override
  String get typeNameToConfirm => 'Type the organization name to confirm';

  @override
  String taadiaCount(Object count) {
    return '$count taadias';
  }

  @override
  String get member => 'Member';

  @override
  String get createdBy => 'Created by';

  @override
  String get you => 'You';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get updatedSuccess => 'Updated successfully';

  @override
  String get organizationDeleted => 'Organization deleted';

  @override
  String get searchMembers => 'Search members...';

  @override
  String get info => 'Info';

  @override
  String get joinPasswordHint =>
      'The join password is used to join this organization. Share it with new members.';
}
