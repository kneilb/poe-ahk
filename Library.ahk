;----------------------------------------------------------------------
; PoE buff macro for AutoHotKey
; All times are in ms
;----------------------------------------------------------------------

; See other files in this directory for examples of usage.

;
; Implementation details
;

#IfWinActive Path of Exile
#SingleInstance force
#NoEnv
#Warn
#Persistent

; Key bindings (NB: "``" means `, seems to be an escape sequence)
; ACTIVATE_KEY := "XButton2" ; "forward" button on my mouse; I use "back" instead of middle for the alt attack
ACTIVATE_KEY := "``"
ATTACK_KEY := "RButton"

; Add a new monitored buff.
; Call this once for each buff that you want to be monitored by the script.
; 
; "key" is what we send to PoE activate the buff (e.g. "2", "r")
; "duration" is the time it lasts for, in milliseconds (e.g. 4800 = 4.8 seconds)
; "always" indicates whether this buff should always be active, regardless of our attacks.
;    This is handy for Quicksilver flasks and other "free" buffs.
;    Optional argument, defaults to false.
AddBuff(key, duration, always=false)
{
    global monitor

    ; NB. Just a convenience wrapper around singleton BuffMonitor instance
    monitor.AddBuff(key, duration, always)
}

; Bind functions to their keys
; We don't use :: notation because that messes up multi-file initialisation
; NB: ~ is needed so the "normal" event happens; without it the key is swallowed by the script and PoE doesn't see it
; TODO: singleton pattern with func? meh.
monitor := new BuffMonitor()

toggleActiveFunc := monitor.ToggleActive.Bind(monitor)
HotKey, ~%ACTIVATE_KEY%, %toggleActiveFunc%

attackDownFunc := monitor.AttackDown.Bind(monitor)
HotKey, ~%ATTACK_KEY%, %attackDownFunc%

attackUpFunc := monitor.AttackUp.Bind(monitor)
HotKey, ~%ATTACK_KEY% Up, %attackUpFunc%

; Monitors buffs & attacks, uses buffs when ready
class BuffMonitor
{
    __New()
    {
        this.buffs := []
        this.useBuffs := false
        this.holdAttack := false
        this.lastAttackTickCount := 0
        this.pollFunc := this.Poll.Bind(this)
    }

    AddBuff(key, duration, always=false)
    {
        this.buffs[key] := new Buff(key, duration, always)
    }

    AttackDown()
    {
        this.holdAttack := true
        this.lastAttackTickCount := A_TickCount
    }

    AttackUp()
    {
        this.holdAttack := false
    }

    UseAllReadyBuffs(attacked)
    {
        for key, value in this.buffs {
            value.UseIfReady(attacked)
        }
    }

    Poll()
    {
        attacked := this.holdAttack or ((A_TickCount - this.lastAttackTickCount) < 500)

        this.UseAllReadyBuffs(attacked)
    }

    ToggleActive()
    {
        pollFunc := this.pollFunc

        this.useBuffs := not this.useBuffs

        if (this.useBuffs)
        {
            ToolTip, Buff Use On, 1200, 10
            SetTimer, %pollFunc%, 100
        }
        else
        {
            ToolTip
            SetTimer, %pollFunc%, Off
        }
    }
}

; A buff
; Tracks duration and last time used (by user or automatically)
; Binds its Use() method to the specified key on creation via a closure
; Provides UseIfReady(), which is called on a timer to auto-trigger
;
class Buff
{
    __New(key, duration, always)
    {
        this.key := key
        this.duration := duration
        this.always := always
        this.lastUsedTickCount := 0

        useFunc := this.Use.Bind(this)

        HotKey, %key%, %useFunc%, On
    }

    IsReady()
    {
        return ((A_TickCount - this.lastUsedTickCount) > this.duration)
    }

    UseIfReady(attacked)
    {
        if this.IsReady() and (attacked or this.always)
        {
            this.Use()
        }
    }

    Use()
    {
        this.lastUsedTickCount := A_TickCount
        key := this.key
        Send %key%
    }
}
