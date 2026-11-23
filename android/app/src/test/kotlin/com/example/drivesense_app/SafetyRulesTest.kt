package com.example.drivesense_app
import org.junit.Assert.*
import org.junit.Test

class SafetyRulesTest {
    @Test fun prolongedClosureRequiresContinuousEvidence() {
        val rule=ClosureRule()
        for(t in 0L..1400L step 200) assertFalse(rule.observe(t,true))
        assertTrue(rule.observe(1600,true))
        assertFalse(rule.observe(1800,false))
    }
    @Test fun cameraGapDoesNotCountAsClosedEyes() {
        val rule=ClosureRule()
        rule.observe(0,true); rule.observe(200,true)
        assertFalse(rule.observe(2000,true))
        assertFalse(rule.observe(2200,null))
        assertFalse(rule.observe(2400,true))
    }
    @Test fun ordinaryBlinkDoesNotTriggerAlarm() {
        val rule=ClosureRule()
        rule.observe(0,false); rule.observe(100,true)
        assertFalse(rule.observe(300,false))
    }
    @Test fun independentSignalsRequired() {
        assertFalse(CrashFusion.qualifies(true,false,false,false))
        assertTrue(CrashFusion.qualifies(false,true,true,true))
        assertFalse(CrashFusion.qualifies(false,false,true,false))
        assertTrue(CrashFusion.qualifies(true,false,false,true))
        assertTrue(CrashFusion.qualifies(true,true,false,false))
    }
    @Test fun compareWeightedAndCountedFusion() {
        // Both require independent groups; an uncalibrated weight can suppress a useful pair.
        assertTrue(CrashFusion.qualifies(true,true,false,false))
        assertFalse(CrashFusion.weighted(true,true,false,false))
        assertTrue(CrashFusion.weighted(true,false,false,true))
        assertTrue(CrashFusion.weighted(true,true,true,false))
        assertFalse(CrashFusion.weighted(true,false,false,false))
    }
    @Test fun overrideRequiresStrongIndependentEvidence() {
        assertFalse(CrashFusion.strongOverride(3.5,true,true))
        assertFalse(CrashFusion.strongOverride(6.0,true,false))
        assertTrue(CrashFusion.strongOverride(6.0,true,true))
    }
}
