package com.example.drivesense_app

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import org.json.JSONArray
import org.json.JSONObject

class SafetyStore(context:Context) : SQLiteOpenHelper(context.applicationContext,"drivesense_real.db",null,1) {
    private val prefs=context.applicationContext.getSharedPreferences("safety_config",Context.MODE_PRIVATE)
    override fun onCreate(db:SQLiteDatabase) {
        db.execSQL("CREATE TABLE trips (id INTEGER PRIMARY KEY, data TEXT NOT NULL)")
        db.execSQL("CREATE TABLE events (id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT NOT NULL)")
        db.execSQL("CREATE TABLE points (id INTEGER PRIMARY KEY AUTOINCREMENT, trip INTEGER NOT NULL, lat REAL NOT NULL, lon REAL NOT NULL)")
    }
    override fun onUpgrade(db:SQLiteDatabase,old:Int,new:Int) {}
    fun settings():JSONObject {
        val saved=prefs.getString("settings",null)
        val defaults=JSONObject("""{"name":"","phone":"","vehicle":"motorcycle","plate":"","contact":"","autoDispatch":false,"countdown":30,"camera":true,"driverSide":"center","kmPerLitre":35,"volume":0.8,"testDestination":"placeholder","language":"en","smsLanguage":"en","onboarded":false,"languageChosen":false,"uiVersion":2}""")
        if(saved!=null) {
            val old=JSONObject(saved)
            old.keys().forEach { key -> defaults.put(key,old.get(key)) }
            if(old.optInt("uiVersion",0)<2) {
                defaults.put("autoDispatch",false).put("onboarded",false).put("languageChosen",false).put("uiVersion",2)
                prefs.edit().putString("settings",defaults.toString()).apply()
            }
        }
        return defaults
    }
    fun saveSettings(json:JSONObject) { prefs.edit().putString("settings",json.toString()).apply() }
    fun event(type:String,message:String,lat:Double?,lon:Double?,trip:Long=0) {
        val j=JSONObject().put("time",System.currentTimeMillis()).put("trip",trip).put("type",type).put("message",message).put("lat",lat ?: JSONObject.NULL).put("lon",lon ?: JSONObject.NULL)
        writableDatabase.execSQL("INSERT INTO events(data) VALUES (?)",arrayOf(j.toString()))
    }
    fun point(trip:Long,lat:Double,lon:Double) { writableDatabase.execSQL("INSERT INTO points(trip,lat,lon) VALUES (?,?,?)",arrayOf<Any>(trip,lat,lon)) }
    fun saveTrip(json:JSONObject) { writableDatabase.execSQL("INSERT OR REPLACE INTO trips(id,data) VALUES (?,?)",arrayOf<Any>(json.getLong("id"),json.toString())) }
    fun history():String {
        val trips=JSONArray(); val events=JSONArray()
        readableDatabase.rawQuery("SELECT data FROM trips ORDER BY id DESC LIMIT 100",null).use { c -> while(c.moveToNext()) trips.put(JSONObject(c.getString(0))) }
        readableDatabase.rawQuery("SELECT data FROM events ORDER BY id DESC LIMIT 200",null).use { c -> while(c.moveToNext()) events.put(JSONObject(c.getString(0))) }
        return JSONObject().put("trips",trips).put("events",events).toString()
    }
    fun route(trip:Long):JSONArray {
        val points=JSONArray()
        readableDatabase.rawQuery("SELECT lat,lon FROM points WHERE trip=? ORDER BY id",arrayOf(trip.toString())).use { c ->
            // Bound map rendering while retaining the complete trip's start and end.
            val stride=maxOf(1,(c.count+4998)/4999)
            var index=0
            while(c.moveToNext()) {
                if(index%stride==0 || index==c.count-1) points.put(JSONArray().put(c.getDouble(0)).put(c.getDouble(1)))
                index++
            }
        }
        return points
    }
    fun hotspots():JSONArray = JSONArray(prefs.getString("hotspots","[]")!!)
    fun importHotspots(text:String):String {
        val input=JSONArray(text); require(input.length()<=2000) { "Maximum 2000 hotspots per import" }
        val clean=JSONArray(); val ids=mutableSetOf<String>()
        for(i in 0 until input.length()) {
            val j=input.getJSONObject(i)
            val lat=j.getDouble("latitude"); val lon=j.getDouble("longitude")
            require(lat.isFinite() && lon.isFinite() && lat in 5.8..10.0 && lon in 79.0..82.0) { "Invalid Sri Lanka coordinates at record $i" }
            require(j.getString("source").isNotBlank() && j.getString("name").isNotBlank()) { "Each record needs name and source" }
            val id=j.getString("id"); require(ids.add(id) && id.isNotBlank()) { "Duplicate or missing ID" }
            clean.put(JSONObject().put("id",id).put("name",j.getString("name").take(150)).put("latitude",lat).put("longitude",lon).put("source",j.getString("source").take(500)).put("period",j.optString("period","Unknown observation period")))
        }
        prefs.edit().putString("hotspots",clean.toString()).apply()
        return "Imported ${clean.length()} sourced locations. Verify provenance before relying on warnings."
    }
    fun clearHistory() { writableDatabase.execSQL("DELETE FROM points"); writableDatabase.execSQL("DELETE FROM trips"); writableDatabase.execSQL("DELETE FROM events") }
    fun idleSnapshot():String = JSONObject().put("running",false).put("cameraStatus","Stopped").put("audioStatus","Stopped").put("hotspots",hotspots()).put("route",JSONArray()).put("warning","").put("countdown",-1).toString()
}
