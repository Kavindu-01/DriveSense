class AppWords {
  final String language;
  const AppWords(this.language);
  bool get isSinhala => language == 'si';
  String call(String key, [Map<String, Object> values = const {}]) {
    final pair = phrases[key];
    var text = pair == null ? key : pair[isSinhala ? 1 : 0];
    for (final entry in values.entries) {
      text = text.replaceAll('{${entry.key}}', entry.value.toString());
    }
    return text;
  }

  static const phrases = <String, List<String>>{
    'loading': ['Getting ready…', 'සූදානම් වෙමින්…'],
    'chooseLanguage': ['Choose your language', 'ඔබේ භාෂාව තෝරන්න'],
    'chooseHint': [
      'You can change this later in Settings.',
      'පසුව සැකසුම් තුළින් මෙය වෙනස් කළ හැකියි.',
    ],
    'continue': ['Continue', 'ඉදිරියට'],
    'welcome': ['A calmer, safer drive', 'සැහැල්ලුවෙන්, ආරක්ෂිතව ගමන් යන්න'],
    'welcomeBody': [
      'DriveSense checks for signs of tiredness and possible crashes. Your trips stay on this phone.',
      'DriveSense නිදිමත හා අනතුරක ලකුණු සොයයි. ඔබේ ගමන් මේ දුරකථනයේ සුරකියි.',
    ],
    'vehicleQuestion': ['What do you drive?', 'ඔබ පදවන්නේ කුමක්ද?'],
    'motorcycle': ['Motorcycle', 'මෝටර් බයිසිකලයක්'],
    'threeWheeler': ['Three-wheeler', 'ත්‍රිරෝද රථයක්'],
    'setupPermissions': [
      'Allow the safety checks',
      'ආරක්ෂක පරීක්ෂා සඳහා අවසර දෙන්න',
    ],
    'setupPermissionsBody': [
      'Location records trips. The camera checks your eyes. The microphone checks sudden impact sounds. No photos, video or audio recordings are saved.',
      'ස්ථානයෙන් ගමන් සටහන් කරයි. කැමරාවෙන් ඇස් පරීක්ෂා කරයි. මයික්‍රෆෝනයෙන් හදිසි ගැටුම් හඬ සොයයි. ඡායාරූප, වීඩියෝ හෝ හඬ පටිගත කිරීම් සුරකින්නේ නැහැ.',
    ],
    'allowAndCheck': ['Allow & check camera', 'අවසර දී කැමරාව බලන්න'],
    'skipCamera': [
      'Continue without camera for now',
      'දැනට කැමරාව නොමැතිව ඉදිරියට යන්න',
    ],
    'drive': ['Drive', 'ගමන'],
    'trips': ['Trips', 'ගමන්'],
    'map': ['Map', 'සිතියම'],
    'settings': ['Settings', 'සැකසුම්'],
    'goodToGo': ['Ready for your next trip', 'ඊළඟ ගමනට සූදානම්'],
    'duringTrip': ['Your trip is being recorded', 'ඔබේ ගමන සටහන් වෙමින් පවතී'],
    'checksOff': ['Safety checks are off', 'ආරක්ෂක පරීක්ෂා නවතා ඇත'],
    'autoHint': [
      'Trips start automatically while safety checks are on.',
      'ආරක්ෂක පරීක්ෂා ක්‍රියාත්මක විට ගමන් ස්වයංක්‍රීයව ආරම්භ වේ.',
    ],
    'startHint': [
      'Turn checks on before you set off.',
      'ගමනට පෙර පරීක්ෂා ක්‍රියාත්මක කරන්න.',
    ],
    'speed': ['Current speed', 'දැන් වේගය'],
    'speedUnavailable': [
      'Waiting for your location',
      'ඔබේ ස්ථානය ලැබෙන තුරු රැඳී සිටියි',
    ],
    'distance': ['Distance', 'දුර'],
    'time': ['Trip time', 'ගමන් කාලය'],
    'startChecks': ['Turn on safety checks', 'ආරක්ෂක පරීක්ෂා අරඹන්න'],
    'stopChecks': ['Turn off safety checks', 'ආරක්ෂක පරීක්ෂා නවත්වන්න'],
    'startTrip': ['Start a trip', 'ගමනක් අරඹන්න'],
    'endTrip': ['Finish this trip', 'මේ ගමන අවසන් කරන්න'],
    'moreDetails': ['More about this drive', 'ගමන ගැන තවත්'],
    'phoneBattery': ['Phone battery', 'දුරකථනයේ බැටරිය'],
    'charging': ['Charging', 'චාජ් වෙමින්'],
    'notCharging': ['On battery', 'බැටරියෙන් ක්‍රියාත්මකයි'],
    'locationReady': ['Location found', 'ස්ථානය හමු විය'],
    'locationNeeded': [
      'Turn on location for speed and trips',
      'වේගය හා ගමන් සඳහා ස්ථානය ක්‍රියාත්මක කරන්න',
    ],
    'soundReady': ['Sound checks are on', 'හඬ පරීක්ෂා ක්‍රියාත්මකයි'],
    'soundUnavailable': [
      'Sound checks are unavailable',
      'හඬ පරීක්ෂා ලබාගත නොහැකියි',
    ],
    'movementReady': ['Movement checks are on', 'චලන පරීක්ෂා ක්‍රියාත්මකයි'],
    'movementUnavailable': [
      'Movement checks are unavailable',
      'චලන පරීක්ෂා ලබාගත නොහැකියි',
    ],
    'cameraCheck': ['Check your camera', 'කැමරාව පරීක්ෂා කරන්න'],
    'cameraCheckBody': [
      'Check that your eyes can be seen before driving.',
      'ගමනට පෙර ඔබේ ඇස් පෙනෙන බව බලන්න.',
    ],
    'emergency': ['Emergency help', 'හදිසි උදව්'],
    'help': ['Help & support', 'උදව් හා සහාය'],
    'cameraStarting': ['Opening your camera…', 'කැමරාව විවෘත වෙමින්…'],
    'cameraAnalysisWait': [
      'Camera is on. Eye checks are reconnecting…',
      'කැමරාව ක්‍රියාත්මකයි. ඇස් පරීක්ෂාව නැවත සම්බන්ධ කරමින්…',
    ],
    'cameraReady': ['Your eyes can be checked', 'ඔබේ ඇස් පරීක්ෂා කළ හැකියි'],
    'faceMissing': ['We can’t see your face', 'ඔබේ මුහුණ පෙනෙන්නේ නැහැ'],
    'eyesHidden': [
      'Your eyes aren’t clear enough',
      'ඔබේ ඇස් පැහැදිලිව පෙනෙන්නේ නැහැ',
    ],
    'cameraFailed': ['The camera couldn’t start', 'කැමරාව ආරම්භ කළ නොහැකි විය'],
    'cameraRetryBody': [
      'We’re reconnecting the camera. Tap Retry if it does not recover.',
      'කැමරාව නැවත සම්බන්ධ කරමින්. එය යථා තත්ත්වයට නොපැමිණේ නම් නැවත උත්සාහ කරන්න.',
    ],
    'cameraPermission': [
      'Allow camera access to check your eyes',
      'ඇස් පරීක්ෂා කිරීමට කැමරා අවසරය දෙන්න',
    ],
    'cameraHot': [
      'Camera paused while your phone cools',
      'දුරකථනය සිසිල් වන තුරු කැමරාව නවතා ඇත',
    ],
    'cameraOff': ['Camera checks are off', 'කැමරා පරීක්ෂා නවතා ඇත'],
    'cameraIdle': [
      'Camera starts when your trip begins',
      'ගමන ආරම්භ වන විට කැමරාව ක්‍රියාත්මක වේ',
    ],
    'cameraRest': [
      'Next camera check in {seconds}s',
      'මීළඟ කැමරා පරීක්ෂාව තත්පර {seconds}කින්',
    ],
    'cameraCurrent': [
      'Checking for signs of tiredness',
      'නිදිමත ලකුණු පරීක්ෂා කරමින්',
    ],
    'cameraSlow': ['The camera is catching up', 'කැමරාව සූදානම් වෙමින් පවතී'],
    'cameraAdvice': [
      'Face the camera in a bright place. Adjust glasses to reduce reflections.',
      'ආලෝකය ඇති තැනක කැමරාව දෙස බලන්න. කණ්ණාඩියේ දිලිසීම අඩු වන ලෙස සකසන්න.',
    ],
    'cameraPrivacy': [
      'This check stays live while this screen is open. Short checks during driving save battery. Nothing is recorded.',
      'මේ තිරය විවෘත විට කැමරාව දිගටම ක්‍රියාත්මකයි. ගමනේදී කෙටි පරීක්ෂාවලින් බැටරිය ඉතිරි කරයි. කිසිවක් පටිගත නොකරයි.',
    ],
    'cameraSafeTest': [
      'Only test closing your eyes when safely stopped.',
      'ඇස් වැසීම පරීක්ෂා කරන්න ආරක්ෂිතව නවතා ඇති විට පමණයි.',
    ],
    'retry': ['Try again', 'නැවත උත්සාහ කරන්න'],
    'finishSetup': ['Finish setup', 'සැකසීම අවසන් කරන්න'],
    'continueForNow': ['Continue for now', 'දැනට ඉදිරියට යන්න'],
    'back': ['Back', 'ආපසු'],
    'close': ['Close', 'වසන්න'],
    'done': ['Done', 'හරි'],
    'cancel': ['Cancel', 'අවලංගු කරන්න'],
    'save': ['Save', 'සුරකින්න'],
    'saved': ['Saved on this phone', 'මේ දුරකථනයේ සුරැකුණා'],
    'somethingStopped': [
      'Some checks need attention',
      'සමහර පරීක්ෂාවලට අවධානය අවශ්‍යයි',
    ],
    'recovering': [
      'We’re trying to restore them. Open Help if this continues.',
      'ඒවා නැවත අරඹමින් සිටියි. මෙය දිගටම සිදුවේ නම් උදව් වෙත යන්න.',
    ],
    'operationFailed': [
      'That didn’t work. Please try again.',
      'එය කළ නොහැකි විය. නැවත උත්සාහ කරන්න.',
    ],
    'androidOnly': [
      'Safety checks need the Android app.',
      'ආරක්ෂක පරීක්ෂා සඳහා Android යෙදුම අවශ්‍යයි.',
    ],
    'profile': ['Your details', 'ඔබේ තොරතුරු'],
    'profileHint': [
      'Used in emergency messages. Stored only on this phone.',
      'හදිසි පණිවිඩ සඳහා භාවිත කරයි. මේ දුරකථනයේ පමණක් සුරකියි.',
    ],
    'name': ['Your name', 'ඔබේ නම'],
    'phone': ['Your phone number', 'ඔබේ දුරකථන අංකය'],
    'plate': ['Vehicle number', 'වාහන අංකය'],
    'contact': ['Emergency contact number', 'හදිසියකදී අමතන අංකය'],
    'vehicle': ['Vehicle', 'වාහනය'],
    'driverPosition': [
      'Your position in the camera image',
      'කැමරා රූපයේ ඔබ සිටින පැත්ත',
    ],
    'left': ['Left', 'වම'],
    'center': ['Centre', 'මැද'],
    'right': ['Right', 'දකුණ'],
    'language': ['App language', 'යෙදුමේ භාෂාව'],
    'smsLanguage': ['Message language', 'පණිවිඩ භාෂාව'],
    'voiceEnglish': [
      'Spoken warnings stay in English.',
      'හඬ දැනුම්දීම් ඉංග්‍රීසියෙන් පවතී.',
    ],
    'autoArm': [
      'Resume checks when I open DriveSense',
      'DriveSense විවෘත කළ විට පරීක්ෂා නැවත අරඹන්න',
    ],
    'autoArmHint': [
      'Android may ask you to reopen the app after stopping it.',
      'යෙදුම නැවැත්වූ පසු නැවත විවෘත කිරීමට Android ඉල්ලා සිටිය හැකියි.',
    ],
    'cameraSwitch': [
      'Check tiredness with the camera',
      'කැමරාවෙන් නිදිමත ලකුණු බලන්න',
    ],
    'permissions': ['Phone permissions', 'දුරකථන අවසර'],
    'permissionsHint': [
      'Allow location, camera, microphone and notifications.',
      'ස්ථානය, කැමරාව, මයික්‍රෆෝනය සහ දැනුම්දීම් සඳහා අවසර දෙන්න.',
    ],
    'phoneSettings': ['Open phone settings', 'දුරකථන සැකසුම් විවෘත කරන්න'],
    'alarmTest': ['Check sound & vibration', 'හඬ හා කම්පනය පරීක්ෂා කරන්න'],
    'alarmHint': [
      'Check your phone’s alarm volume too.',
      'දුරකථනයේ ඇලාරම් හඬ මට්ටමත් බලන්න.',
    ],
    'speechVolume': ['Spoken warning volume', 'හඬ දැනුම්දීම් මට්ටම'],
    'emergencySettings': ['Calls & messages', 'ඇමතුම් හා පණිවිඩ'],
    'practiceDispatch': [
      'Allow test messages & calls',
      'පරීක්ෂණ පණිවිඩ හා ඇමතුම් ඉඩ දෙන්න',
    ],
    'practiceHint': [
      'An unanswered alert may SMS your saved contact and personal test number, then call the test number. Charges may apply.',
      'ප්‍රතිචාර නොදුන් ඇඟවීමකින් සුරැකි අංකයට හා පරීක්ෂණ අංකයට SMS යවා පරීක්ෂණ අංකයට ඇමතුමක් ඉල්ලිය හැකියි. ගාස්තු අය විය හැකියි.',
    ],
    'testNumber': ['Personal test number', 'පුද්ගලික පරීක්ෂණ අංකය'],
    'countdownSetting': [
      'Time to respond: {seconds}s',
      'ප්‍රතිචාරයට කාලය: තත්පර {seconds}',
    ],
    'phoneNumberError': [
      'Enter a complete phone number.',
      'සම්පූර්ණ දුරකථන අංකයක් යොදන්න.',
    ],
    'economy': ['Estimated km per litre', 'ලීටරයට කි.මී. ඇස්තමේන්තුව'],
    'economyError': [
      'Enter a number between 1 and 150.',
      '1 සිට 150 දක්වා අංකයක් යොදන්න.',
    ],
    'areYouSafe': ['Are you safe?', 'ඔබ ආරක්ෂිතද?'],
    'respondSeconds': [
      'Please respond within {seconds}s',
      'තත්පර {seconds}ක් ඇතුළත ප්‍රතිචාර දක්වන්න',
    ],
    'imSafe': ['I am safe — cancel alert', 'මම ආරක්ෂිතයි — ඇඟවීම අවලංගු කරන්න'],
    'alertOffHint': [
      'Messages and calls are off. This will not contact anyone.',
      'පණිවිඩ හා ඇමතුම් නවතා ඇත. මෙයින් කිසිවකු අමතන්නේ නැහැ.',
    ],
    'alertOnHint': [
      'An unanswered alert may contact the configured test numbers.',
      'ප්‍රතිචාර නොදුන්නොත් සැකසූ පරීක්ෂණ අංක අමතනු ලැබිය හැකියි.',
    ],
    'startAlert': ['Start emergency alert', 'හදිසි ඇඟවීම අරඹන්න'],
    'confirmAlert': ['Start an alert?', 'ඇඟවීමක් අරඹන්නද?'],
    'confirmAlertBody': [
      'This starts a countdown. Cancel if you are safe.',
      'මෙය ගණන් කිරීමක් අරඹයි. ආරක්ෂිත නම් අවලංගු කරන්න.',
    ],
    'practiceAlert': [
      'Practise cancelling an alert',
      'ඇඟවීම අවලංගු කිරීම පුහුණු වන්න',
    ],
    'noPublicCalls': [
      'This phone-test build does not automatically contact 119.',
      'මේ දුරකථන පරීක්ෂණ නිකුතුව ස්වයංක්‍රීයව 119 අමතන්නේ නැහැ.',
    ],
    'callTest': ['Open the test number', 'පරීක්ෂණ අංකය විවෘත කරන්න'],
    'callPermissions': [
      'Allow calls & messages',
      'ඇමතුම් හා පණිවිඩ අවසර දෙන්න',
    ],
    'tripHistory': ['Your journeys', 'ඔබේ ගමන්'],
    'tripHistoryHint': [
      'Saved only on this phone.',
      'මේ දුරකථනයේ පමණක් සුරකියි.',
    ],
    'noTrips': ['Your first journey starts here', 'ඔබේ පළමු ගමන මෙතැනින්'],
    'noTripsBody': [
      'Turn on checks and take a trip. Your route and summary will appear here.',
      'පරීක්ෂා අරඹා ගමනක් යන්න. මාර්ගය හා සාරාංශය මෙහි පෙනේවි.',
    ],
    'completed': ['Completed', 'අවසන්'],
    'interrupted': [
      'In progress or interrupted',
      'ක්‍රියාත්මක හෝ අතරමග නැවතුණු',
    ],
    'tripSummary': ['Trip summary', 'ගමන් සාරාංශය'],
    'drivingScore': ['Driving score', 'රිය පැදවීමේ ලකුණු'],
    'scoreHint': [
      'An estimate from recorded events. Missing checks can hide risks.',
      'සටහන් වූ සිදුවීම් මත ඇස්තමේන්තුවකි. පරීක්ෂා නොවූ විට අවදානම් මඟහැරිය හැකියි.',
    ],
    'drivingEvents': ['Driving changes', 'රිය පැදවීමේ වෙනස්කම්'],
    'tiredEvents': ['Tiredness warnings', 'නිදිමත ඇඟවීම්'],
    'eyeCoverage': [
      'Eyes observed for {seconds}s of this trip',
      'මේ ගමනේ තත්පර {seconds}ක් ඇස් නිරීක්ෂණය විය',
    ],
    'fuelEstimate': ['Estimated fuel', 'ඉන්ධන ඇස්තමේන්තුව'],
    'fuelHint': [
      'Based on your saved estimate, not measured fuel.',
      'සුරැකි ඇස්තමේන්තුව මතයි. සැබෑ ඉන්ධන මිනුමක් නොවේ.',
    ],
    'carbonEstimate': ['Estimated petrol CO₂', 'පෙට්‍රල් CO₂ ඇස්තමේන්තුව'],
    'mapTitle': ['Around your route', 'ඔබේ මාර්ගය අවට'],
    'mapHint': [
      'Map pictures need internet. Trips are still saved without it.',
      'සිතියම් රූප සඳහා අන්තර්ජාලය අවශ්‍යයි. එය නැතිවත් ගමන් සුරකියි.',
    ],
    'zones': ['Danger-zone alerts', 'අනතුරු බහුල ස්ථාන'],
    'noZones': [
      'No danger zones loaded yet',
      'තවම අනතුරු බහුල ස්ථාන එක් කර නැහැ',
    ],
    'noZonesHint': [
      'Add verified location data for nearby warnings.',
      'අසල ඇඟවීම් සඳහා තහවුරු කළ ස්ථාන දත්ත එක් කරන්න.',
    ],
    'zoneCount': ['{count} locations available', 'ස්ථාන {count}ක් ඇත'],
    'zoneHint': [
      'Warnings within 100 m, with an earlier reminder at higher speeds.',
      'මීටර් 100ක් ඇතුළත ඇඟවීමක් ලැබේ. වැඩි වේගයකදී ඊට පෙර මතක් කරයි.',
    ],
    'importZones': ['Add location file', 'ස්ථාන ගොනුව එක් කරන්න'],
    'imported': ['Locations added', 'ස්ථාන එක් කළා'],
    'importError': [
      'We couldn’t read that file. Check its format and try again.',
      'ගොනුව කියවිය නොහැකියි. ආකෘතිය බලා නැවත උත්සාහ කරන්න.',
    ],
    'source': ['Source', 'මූලාශ්‍රය'],
    'period': ['Recorded period', 'සටහන් කාලය'],
    'unknownPeriod': ['Period not provided', 'කාලය සඳහන් නැහැ'],
    'sourceInfo': ['Location details', 'ස්ථාන තොරතුරු'],
    'helpTitle': ['How can we help?', 'අපෙන් කුමන උදව්වක්ද?'],
    'helpCamera': [
      'The camera won’t show my face',
      'කැමරාවට මගේ මුහුණ පෙනෙන්නේ නැහැ',
    ],
    'helpCameraBody': [
      'Use a brighter place. Keep your face in the selected region, reduce reflections on glasses and close other camera apps. Use Try again if no picture appears.',
      'වැඩි ආලෝකයක් ඇති තැනකට යන්න. තෝරාගත් පැත්තේ මුහුණ තබා කණ්ණාඩි දිලිසීම අඩු කර වෙනත් කැමරා යෙදුම් වසන්න. රූපය නොපෙනේ නම් නැවත උත්සාහ කරන්න.',
    ],
    'helpAutomatic': [
      'Why must I reopen the app?',
      'යෙදුම නැවත විවෘත කළ යුත්තේ ඇයි?',
    ],
    'helpAutomaticBody': [
      'Android can stop background camera and microphone access. Reopen DriveSense to resume checks. Trips start automatically while checks stay on.',
      'Android පසුබිම් කැමරා හා මයික්‍රෆෝන ප්‍රවේශය නැවැත්විය හැකියි. නැවත පරීක්ෂා ඇරඹීමට DriveSense විවෘත කරන්න. පරීක්ෂා ක්‍රියාත්මක නම් ගමන් ස්වයංක්‍රීයව අරඹයි.',
    ],
    'helpEmergency': [
      'How do emergency alerts work?',
      'හදිසි ඇඟවීම් ක්‍රියා කරන්නේ කෙසේද?',
    ],
    'helpEmergencyBody': [
      'Supporting checks can start a countdown after a possible crash. “I am safe” cancels it. Test calls and messages happen only if enabled. The phone may block calls. Recorded location speech cannot be played into a normal phone call.',
      'අනතුරක ලකුණු හා අනෙකුත් පරීක්ෂා මත ප්‍රතිචාර කාලයක් අරඹයි. “මම ආරක්ෂිතයි” එය අවලංගු කරයි. ඉඩ දී තිබේ නම් පමණක් පරීක්ෂණ ඇමතුම් හා පණිවිඩ යවයි. දුරකථනය ඇමතුම් අවහිර කළ හැකියි. සාමාන්‍ය ඇමතුමකට පටිගත කළ ස්ථාන හඬ එක් කළ නොහැකියි.',
    ],
    'privacy': ['Your privacy', 'ඔබේ පෞද්ගලිකත්වය'],
    'privacyBody': [
      'No photos, video or audio recordings. Trips and warnings stay here. Maps request pictures online. Shared reports may contain locations and phone details.',
      'ඡායාරූප, වීඩියෝ හෝ හඬ පටිගත කිරීම් නැහැ. ගමන් හා ඇඟවීම් මෙහි පවතී. සිතියම් රූප අන්තර්ජාලයෙන් ගනී. බෙදාගන්නා වාර්තාවල ස්ථාන හා දුරකථන තොරතුරු තිබිය හැකියි.',
    ],
    'shareReport': ['Share a report', 'වාර්තාවක් බෙදාගන්න'],
    'shareHint': [
      'Includes phone information, recent trip locations and error details. Choose who receives it.',
      'දුරකථන තොරතුරු, මෑත ගමන් ස්ථාන හා දෝෂ විස්තර ඇතුළත් වේ. ලැබෙන්නේ කාටදැයි ඔබ තෝරන්න.',
    ],
    'share': ['Share', 'බෙදාගන්න'],
    'deleteHistory': ['Delete saved trips', 'සුරැකි ගමන් මකන්න'],
    'deleteHint': [
      'Turn off checks first. This cannot be undone.',
      'පළමුව පරීක්ෂා නවත්වන්න. මෙය නැවත ලබාගත නොහැකියි.',
    ],
    'deleteConfirm': ['Delete trips and warnings?', 'ගමන් හා ඇඟවීම් මකන්නද?'],
    'delete': ['Delete', 'මකන්න'],
    'version': ['DriveSense 1.2.0', 'DriveSense 1.2.0'],
    'warningEye': [
      'Your eyes stayed closed. Stop safely and rest.',
      'ඔබේ ඇස් වැසී තිබුණා. ආරක්ෂිතව නවතා විවේක ගන්න.',
    ],
    'warningNod': [
      'Your head keeps dropping. Take a break.',
      'ඔබේ හිස නැවත නැවත පහතට වැටේ. විවේකයක් ගන්න.',
    ],
    'warningFatigue': [
      'You may be getting tired. Stop safely for a break.',
      'ඔබට නිදිමත විය හැකියි. ආරක්ෂිතව නවතා විවේක ගන්න.',
    ],
    'warningEyesHidden': [
      'We can’t see your eyes clearly. Adjust the phone when safe.',
      'ඔබේ ඇස් පැහැදිලිව පෙනෙන්නේ නැහැ. ආරක්ෂිත විට දුරකථනය සකසන්න.',
    ],
    'warningMotion': [
      'A sudden driving change was noticed. Stay alert.',
      'රිය පැදවීමේ හදිසි වෙනසක් හඳුනාගත්තා. අවධානයෙන් සිටින්න.',
    ],
    'warningZone': [
      'A danger zone is within 100 m. Take care.',
      'අනතුරු බහුල ස්ථානයක් මීටර් 100ක් ඇතුළත. ප්‍රවේශමෙන් යන්න.',
    ],
    'warningZoneEarly': [
      'A danger zone is ahead. Take care.',
      'අනතුරු බහුල ස්ථානයක් ඉදිරියෙන්. ප්‍රවේශමෙන් යන්න.',
    ],
    'warningAlarm': ['Sound and vibration check', 'හඬ හා කම්පන පරීක්ෂාව'],
    'warningDispatch': [
      'An alert was attempted. Open Help for details.',
      'ඇඟවීමක් යැවීමට උත්සාහ කළා. විස්තර සඳහා උදව් බලන්න.',
    ],
    'eventTrip': ['Trip update', 'ගමන් තොරතුරක්'],
    'eventBraking': ['Sudden braking', 'හදිසි තිරිංග'],
    'eventMotion': ['Driving change', 'රිය පැදවීමේ වෙනසක්'],
    'eventFatigue': ['Tiredness warning', 'නිදිමත ඇඟවීමක්'],
    'eventYawn': ['Possible yawn', 'ඈනුමක ලකුණක්'],
    'eventLooking': ['Looked away', 'වෙනත් පැත්තක් බැලීම'],
    'eventZone': ['Danger zone nearby', 'අසල අනතුරු බහුල ස්ථානයක්'],
    'eventAlert': ['Emergency alert update', 'හදිසි ඇඟවීම් තොරතුරක්'],
    'eventOther': ['Safety check update', 'ආරක්ෂක පරීක්ෂා තොරතුරක්'],
    'recentEvents': ['Recent notices', 'මෑත දැනුම්දීම්'],
    'earlyEstimate': [
      'An estimate, not a guarantee of safety.',
      'ඇස්තමේන්තුවකි. ආරක්ෂාව සහතික කිරීමක් නොවේ.',
    ],
    'automatic': ['Automatic trips', 'ස්වයංක්‍රීය ගමන්'],
    'alertWaiting': ['Waiting for your response', 'ඔබේ ප්‍රතිචාරය බලා සිටියි'],
    'alertCancelled': [
      'Alert cancelled. Checks continue.',
      'ඇඟවීම අවලංගු කළා. පරීක්ෂා දිගටම ක්‍රියාත්මකයි.',
    ],
    'alertDisabled': [
      'No messages sent — sending is off.',
      'පණිවිඩ යැවීම නවතා ඇති නිසා යැව්වේ නැහැ.',
    ],
    'alertAttempted': [
      'Contact attempts are recorded in Help.',
      'ඇමතීමට කළ උත්සාහ උදව් තුළ සටහන් වී ඇත.',
    ],
  };
  String warning(String value) => call(switch (value) {
    'Eyes closed. Stop safely and rest' => 'warningEye',
    'Repeated head nodding. Take a break' => 'warningNod',
    'Possible fatigue. Stop safely for a break' => 'warningFatigue',
    'We cannot see your eyes clearly. Check your phone position when safe' =>
      'warningEyesHidden',
    'Driving irregularity. Stay alert' => 'warningMotion',
    'Crash hotspot within one hundred metres. Take care' => 'warningZone',
    'Approaching a known crash hotspot' => 'warningZoneEarly',
    'Readiness check. DriveSense alarm is working' => 'warningAlarm',
    'Emergency test dispatch attempted. Check status' => 'warningDispatch',
    _ => 'areYouSafe',
  });
  String event(String type) => call(switch (type) {
    'trip' => 'eventTrip',
    'braking' => 'eventBraking',
    'motion' => 'eventMotion',
    'fatigue' => 'eventFatigue',
    'yawn' => 'eventYawn',
    'looking_away' => 'eventLooking',
    'hotspot' => 'eventZone',
    'sos_countdown' ||
    'test_countdown' ||
    'sos_cancelled' ||
    'dispatch' => 'eventAlert',
    _ => 'eventOther',
  });
}
