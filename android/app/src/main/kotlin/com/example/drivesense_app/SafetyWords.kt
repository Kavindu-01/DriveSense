package com.example.drivesense_app

object SafetyWords {
    private val sinhala=mapOf(
        "Readiness check. DriveSense alarm is working" to "DriveSense අනතුරු ඇඟවීම ක්‍රියා කරයි",
        "Driving irregularity. Stay alert" to "රිය පැදවීමේ හදිසි වෙනසක්. අවධානයෙන් සිටින්න",
        "Eyes closed. Stop safely and rest" to "ඇස් වැසී ඇත. ආරක්ෂිතව නවතා විවේක ගන්න",
        "Repeated head nodding. Take a break" to "හිස නැවත නැවත පහතට වැටේ. විවේකයක් ගන්න",
        "Possible fatigue. Stop safely for a break" to "ඔබට නිදිමත විය හැකියි. ආරක්ෂිතව නවතා විවේක ගන්න",
        "We cannot see your eyes clearly. Check your phone position when safe" to "ඔබේ ඇස් පැහැදිලිව පෙනෙන්නේ නැහැ. ආරක්ෂිත අවස්ථාවක දුරකථනය සකසන්න",
        "Crash hotspot within one hundred metres. Take care" to "අනතුරු බහුල ස්ථානයක් මීටර් සියයක් ඇතුළත. ප්‍රවේශමෙන් යන්න",
        "Approaching a known crash hotspot" to "අනතුරු බහුල ස්ථානයක් ඉදිරියෙන්",
        "Test emergency countdown. Press I'm OK to cancel" to "හදිසි ඇඟවීම පරීක්ෂා කරමින්. අවලංගු කිරීමට මම ආරක්ෂිතයි ඔබන්න",
        "Possible crash. Press I'm OK if you are safe" to "අනතුරක් සිදුවී ඇති බවට සැකයක්. ආරක්ෂිත නම් මම ආරක්ෂිතයි ඔබන්න",
        "Emergency test dispatch attempted. Check status" to "පරීක්ෂණ පණිවිඩ යැවීමට උත්සාහ කළා. තත්ත්වය බලන්න"
    )
    fun translate(text:String,language:String)=if(language=="si") sinhala[text] ?: "DriveSense දැනුම්දීමක්. යෙදුම බලන්න" else text
}
