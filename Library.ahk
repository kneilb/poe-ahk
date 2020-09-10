;----------------------------------------------------------------------
; PoE buff macro for AutoHotKey
; All times are in ms
;----------------------------------------------------------------------

; To use:
; Make a new AHK file for the new character, that looks like this:
; 
; #Include, Library.ahk

; AddBuff(3, 4800)
; AddBuff(4, 4200)
; AddBuff(5, 4800)

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
; TODO: How to bind to "`" using this method?! ``` generates one, but that's no good.
toggleActive := Func("ToggleActive").Bind()
HotKey, ~XButton2, %toggleActive%

attackDown := Func("AttackDown").Bind()
HotKey, ~RButton, %attackDown%

attackUp := Func("AttackUp").Bind()
HotKey, ~RButton up, %attackUp%

AddBuff(key, duration)
{
    global Buffs
    
    Buffs[key] := new Buff(key, duration)
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

; Activate or deactivate automatic buff usage
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

        useFunc := this.Use.Bind(this)

        HotKey, ~%key%, %useFunc%, On
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
