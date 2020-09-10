;----------------------------------------------------------------------
; PoE buff macro for AutoHotKey
; All times are in ms
;----------------------------------------------------------------------
#IfWinActive Path of Exile
#SingleInstance force
#NoEnv
#Warn
#Persistent

Buffs := []

; To add a new monitored buff, just add it here.
AddBuff(3, 4800)
AddBuff(4, 4200)
AddBuff(5, 4800)

UseBuffs := false
HoldAttack := false
LastAttack := 0

; Implementation details

AddBuff(key, duration)
{
    global Buffs
    
    Buffs[key] := new Buff(key, duration)
}

; Activate or deactivate automatic buff usage
; XButton2::
`::
    ToggleActive()
    return

~RButton::
    HoldAttack := true
    LastAttack := A_TickCount
    return

~RButton up::
    ; pass-through and release the attack
    HoldAttack := false
    return

UseAllReadyBuffs()
{
    global Buffs

    for key, value in Buffs {
        value.UseIfReady()
    }
}

CheckForAttacks()
{
    global HoldAttack
    global LastAttack

    if (((A_TickCount - LastAttack) < 500) or HoldAttack)
    {
        UseAllReadyBuffs()
    }
}

ToggleActive()
{
    global UseBuffs

    UseBuffs := not UseBuffs
    if (UseBuffs)
    {
        ; ToolTip, Buff Use On, 0, 0
        SetTimer, CheckForAttacks, 100
    }
    else
    {
        ; ToolTip, Buf Use Off, 0, 0
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
    __New(key, duration)
    {
        this.key := key
        this.duration := duration
        this.lastUsed := 0

        func := this.Use.Bind(this)

        HotKey, ~%key%, %func%, On
    }

    IsReady()
    {
        return ((A_TickCount - this.lastUsed) > this.duration)
    }

    UseIfReady()
    {
        if this.IsReady()
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
