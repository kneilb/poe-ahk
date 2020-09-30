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

Buffs := []
UseBuffs := false
HoldAttack := false
LastAttack := 0

; Bind functions to their keys
; We don't use :: notation because that messes up multi-file initialisation
; TODO: How to bind to "`" using this method?! ``` generates one, but that doesn't seem to help
toggleActive := Func("ToggleActive").Bind()
HotKey, ~XButton2, %toggleActive%

attackDown := Func("AttackDown").Bind()
HotKey, ~RButton, %attackDown%

attackUp := Func("AttackUp").Bind()
HotKey, ~RButton up, %attackUp%

; Add a new monitored buff
; "key" is what we send to PoE activate it
; "duration" is the time it lasts for, in milliseconds (e.g. 4800 = 4.8 seconds)
; "always" indicates whether this buff should always be active, regardless of our attacks
;    this is handy for Quicksilvers and other "free" buffs
AddBuff(key, duration, always=False)
{
    global Buffs
    
    Buffs[key] := new Buff(key, duration, always)
}

AttackDown()
{
    global HoldAttack
    global LastAttack

    HoldAttack := true
    LastAttack := A_TickCount
}

AttackUp()
{
    global HoldAttack
    HoldAttack := false
}

UseAllReadyBuffs(attacked)
{
    global Buffs

    for key, value in Buffs {
        value.UseIfReady(attacked)
    }
}

CheckForAttacks()
{
    global HoldAttack
    global LastAttack

    attacked := (((A_TickCount - LastAttack) < 500) or HoldAttack)

    UseAllReadyBuffs(attacked)
}

; Activate or deactivate automatic buff usage
ToggleActive()
{
    global UseBuffs

    UseBuffs := not UseBuffs
    if (UseBuffs)
    {
        ToolTip, Buff Use On, 0, 0
        SetTimer, CheckForAttacks, 100
    }
    else
    {
        ToolTip, Buff Use Off, 0, 0
        SetTimer, CheckForAttacks, Off
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
        this.lastUsed := 0

        useFunc := this.Use.Bind(this)

        HotKey, %key%, %useFunc%, On
    }

    IsReady()
    {
        return ((A_TickCount - this.lastUsed) > this.duration)
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
        this.lastUsed := A_TickCount
        key := this.key
        Send %key%
    }
}
