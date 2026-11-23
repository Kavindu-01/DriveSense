package com.example.drivesense_app

class ClosureRule {
    private var since:Long?=null
    private var last:Long?=null
    fun reset() { since=null; last=null }
    fun observe(now:Long,closed:Boolean?):Boolean {
        if(closed==null || (last!=null && now-last!!>600)) since=null
        last=now
        if(closed!=true) { since=null; return false }
        if(since==null) since=now
        return now-since!!>=1500
    }
}
object CrashFusion {
    fun qualifies(impact:Boolean,gps:Boolean,audio:Boolean,immobile:Boolean):Boolean =
        listOf(impact,gps,audio,immobile).count { it }>=2
    fun weighted(impact:Boolean,gps:Boolean,audio:Boolean,immobile:Boolean):Boolean {
        val score=(if(impact) 1.0 else 0.0)+(if(gps) 1.0 else 0.0)+(if(audio) 0.5 else 0.0)+(if(immobile) 1.2 else 0.0)
        return qualifies(impact,gps,audio,immobile) && score>=2.2
    }
    fun strongOverride(peakG:Double,gps:Boolean,audio:Boolean):Boolean = peakG>=5.0 && gps && audio
}
