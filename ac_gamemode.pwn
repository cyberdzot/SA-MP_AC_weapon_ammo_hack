/*

        Античит на оружие и патроны. [ver. 0.4]                    (By vovandolg)
        Специально для портала Pro-Pawn                            (http://www.pro-pawn.ru)


        Логи разработки:
        [0.4]
            - Патроны теперь записываются с каждого слота в отдельный массив
            (так будет правильнее и удобнее для дальнейшей разработки мода на оружейные механики)
            - Водительское место было зафиксено скрытием оружия из рук игрока
            (слишком много уязвимости на водительском месте)

        [0.3]
            - Проверка на подмену оружия в слоте (например: AK-47 можно было заменить на M4)
            - Более детальная проверка на наличие парашюта при десантировании с воздушных транспортов

        [0.2]
            - Фикс ложного вызова античита при смерти
            - Более детальная проверка на Infinity ammo
*/

#include <a_samp>
#include <foreach>

#define TIME_GLOBAL_UPDATE       (1000)  //кол-во миллисекунд для апдейта таймера античита
#define MAX_SLOT_WEAP            (13)    //кол-во слотов оружия у игрока
#define MAX_TICK_PAUSE_AC        (3)     //кол-во раз игнора античита на игрока, 3 - стабильно
#define SLOT_WEAPON_PARACHUTE    (11)    //id слота в котором у игрока находится парашют
#define FIX_SPAWN_RESET_WEAP             //закомментировать если фикс сброса оружия при смерти не нужен

#define FIX_DRIVER_WEAPONS               //закомментировать если фикс скрытия оружия у водителя не нужен

#if defined FIX_DRIVER_WEAPONS
    #define MAX_DHW_TIMER        (1500)
    //кол-во миллисекунд для таймера(скрытие оружия у водителя при посадке)
#endif


main(){}


new pPauseAC_one[MAX_PLAYERS char],
    pPauseAC_two[MAX_PLAYERS char],
    pState[MAX_PLAYERS char],
    pWeapon[MAX_SLOT_WEAP][MAX_PLAYERS char],
    pAmmo[MAX_SLOT_WEAP][MAX_PLAYERS],
    pUseVehicleID[MAX_PLAYERS],
    timglobal;

static const weapon_slot[47] =
{
    0, 0,
    1, 1, 1, 1, 1, 1, 1, 1,
    10, 10, 10, 10, 10, 10,
    8, 8, 8,
    0, 0, 0, //19-21
    2, 2, 2,
    3, 3, 3,
    4, 4,
    5, 5,
    4,
    6, 6,
    7, 7, 7, 7,
    8,
    12,
    9, 9, 9,
    11, 11, 11
};

//--------------------[ Перехватим-ка функции :3 ]------------------------------
stock GivePlayerWeaponAC(playerid, weaponid, amount)
{
    if(IsPlayerConnected(playerid) == 0) return 0;
    new w_slot = weapon_slot[weaponid];
    pPauseAC_one{playerid} = MAX_TICK_PAUSE_AC;
    pWeapon[w_slot]{playerid} = weaponid;
    pAmmo[w_slot][playerid] += amount;
    GivePlayerWeapon(playerid, weaponid, amount);
#if defined FIX_DRIVER_WEAPONS
    if(pState{playerid} == PLAYER_STATE_DRIVER)
    {
        SetTimerEx(!"DriverHidesWeapons", MAX_DHW_TIMER, false, "i", playerid);
    }
#endif
    return 1;
}
#if defined _ALS_GivePlayerWeapon
    #undef    GivePlayerWeapon
#else
    #define    _ALS_GivePlayerWeapon
#endif
#define    GivePlayerWeapon        GivePlayerWeaponAC

stock ResetPlayerWeaponsAC(playerid)
{
    if(IsPlayerConnected(playerid) == 0) return 0;
    pPauseAC_one{playerid} = MAX_TICK_PAUSE_AC;
    ResetPlayerWeapons(playerid);
    for(new i; i < MAX_SLOT_WEAP; i++)
    {
        pWeapon[i]{playerid} = 0;
        pAmmo[i][playerid] = 0;
    }
    return 1;
}
#if defined _ALS_ResetPlayerWeapons
    #undef    ResetPlayerWeapons
#else
    #define    _ALS_ResetPlayerWeapons
#endif
#define    ResetPlayerWeapons        ResetPlayerWeaponsAC

//Для перехвата можно ещё SetPlayerAmmo/SetSpawnInfo добавить,
//но на основе этих функций можете сами слепить ...
//------------------------------------------------------------------------------


public OnGameModeInit()
{
    SetGameModeText(!"AntiCheat Test");
    AddPlayerClass(0, 0.0, 0.0, 4.0, 0.0, -1,-1,-1,-1,-1,-1);
    CreateVehicle(411, 7.0, 7.0, 6.0, 0.0, 0, 0, 60, 1);
    CreateVehicle(425, 9.0, 8.0, 7.0, 0.0, 0, 0, 60, 1);
    CreateVehicle(461, 10.0, 9.0, 8.0, 0.0, 0, 0, 60, 1);
    timglobal = SetTimer(!"OnGlobalUpdate", TIME_GLOBAL_UPDATE, true);
    return 1;
}

public OnGameModeExit()
{
    KillTimer(timglobal);
    return 1;
}


public OnPlayerDisconnect(playerid)
{
    for(new i; i < MAX_SLOT_WEAP; i++)
    {
        pWeapon[i]{playerid} = 0;
        pAmmo[i][playerid] = 0;
    }
    return 0;
}

//Паблик затронут только для того чтобы выдать оружие
public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(newkeys & KEY_YES) // Y
    {
        GivePlayerWeapon(playerid, 24, 1);
        GivePlayerWeapon(playerid, 28, 2);
        GivePlayerWeapon(playerid, 31, 3);
        GivePlayerWeapon(playerid, 34, 4);
    }
    if(newkeys & KEY_NO) // N
    {
        GivePlayerWeapon(playerid, 23, 1);
        GivePlayerWeapon(playerid, 29, 2);
        GivePlayerWeapon(playerid, 30, 3);
        GivePlayerWeapon(playerid, 33, 4);
    }
    return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
    pState{playerid} = newstate;
    if(newstate == PLAYER_STATE_WASTED || (newstate == PLAYER_STATE_ONFOOT &&
    (oldstate == PLAYER_STATE_DRIVER || oldstate == PLAYER_STATE_PASSENGER)))
    {
        pUseVehicleID[playerid] = 0;
    }
#if defined FIX_DRIVER_WEAPONS
    if(newstate == PLAYER_STATE_DRIVER)
    {
        SetTimerEx(!"DriverHidesWeapons", MAX_DHW_TIMER, false, "i", playerid);
    }
#endif
    return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    //Точно не скажу нужен ли тут сброс оружия,
    //но на ранних версиях SA:MP наблюдался баг показания неверных данных в GPWD
#if defined FIX_SPAWN_RESET_WEAP
    ResetPlayerWeapons(playerid);
#else
    for(new i; i < MAX_SLOT_WEAP; i++)
    {
        pWeapon[i]{playerid} = 0;
        pAmmo[i][playerid] = 0;
    }
#endif
    return 1;
}

public OnPlayerEnterVehicle(playerid, vehicleid, ispassenger)
{
    pUseVehicleID[playerid] = vehicleid;
    return 1;
}

public OnPlayerExitVehicle(playerid)
{
    //Парашют при выходе с воздушного транспорта )-_-(
    if(IsAirTransport(GetVehicleModel(pUseVehicleID[playerid])) == 1)
    {
        pPauseAC_one{playerid} = MAX_TICK_PAUSE_AC - 1;
        pWeapon[SLOT_WEAPON_PARACHUTE]{playerid} = WEAPON_PARACHUTE;
        pAmmo[SLOT_WEAPON_PARACHUTE][playerid] = 1;
    }
    return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
    //Боремся с Infinity Ammo ^-^
    new wslot = weapon_slot[weaponid];
    if(pAmmo[wslot][playerid] > 0)
    {
        pPauseAC_two{playerid} = MAX_TICK_PAUSE_AC - 1;
        pAmmo[wslot][playerid]--;
    }
    else return 0;
    return 1;
}


forward OnGlobalUpdate();
public OnGlobalUpdate()
{
    new weaponid[MAX_SLOT_WEAP],
        weaponammo[MAX_SLOT_WEAP];
    foreach(new i: Player)
    {
        //Проверяем игрока на то что он живой и бегает по карте
        //Рекомендую сюда всунуть ещё свою проверку игроков на AFK
        if(pState{i} == 7 || pState{i} == 8) continue;

        if(pPauseAC_two{i} > 0) pPauseAC_two{i}--;
        if(pPauseAC_one{i} > 0)
        {
            pPauseAC_one{i}--;
            continue;
        }

        for(new s; s < MAX_SLOT_WEAP; s++)
        {
            //Начинаем записывать инфу оружия и б/п из слота
            GetPlayerWeaponData(i, s, weaponid[s], weaponammo[s]);

            //Проверяем на обход в минус или на Infinitiy ammo
            if(pAmmo[s][i] < 0 || weaponammo[s] < 0)
            {
                printf("[part] Player[%i] slot[%i] pAmmo[%i] weaponammo[%i], kick!", i, s, pAmmo[s][i], weaponammo[s]);
                SendClientMessage(i, -1, !"Айяй, бесконечные патроны юзаешь или обошёл?![#001]");
                ResetPlayerWeapons(i);
                //Kick(i);
                break;
            }

            //Совпало ли оружие в слоте с тем которое выдавал сервер
            if(weaponid[s] > 0 && weaponid[s] != pWeapon[s]{i})
            {
                printf("[part] Player[%i] pWeapon[%i] slot[%i] weaponid[%i], kick!", i, pWeapon[s]{i}, s, weaponid[s]);
                SendClientMessage(i, -1, !"Айяй, я тебе такой ствол не давал![#002]");
                ResetPlayerWeapons(i);
                //Kick(i);
                break;
            }

            if(pPauseAC_two{i} > 0) continue;

            //Если кол-во записанных патронов в слоте меньше чем найденных(хакнутых)
            if(pAmmo[s][i] < weaponammo[s])
            {
                if(pPauseAC_one{i} == 0 && pPauseAC_two{i} == 0)
                {
                    printf("[part] Player[%i] slot[%i] pAmmo[%i] weaponammo[%i], kick!", i, s, pAmmo[s][i], weaponammo[s]);
                    SendClientMessage(i, -1, !"Айяй, патроны воруешь![#003]");
                    ResetPlayerWeapons(i);
                    //Kick(i);
                    break;
                }
                else break;
            }

            //Если кол-во записанных патронов в слоте больше чем найденных,
            //то обновим кол-во патронов в переменной слота оружия
            else if(pAmmo[s][i] > weaponammo[s])
            {
                if(pPauseAC_one{i} == 0 && pPauseAC_two{i} == 0) pAmmo[s][i] = weaponammo[s];
                else break;
            }
            //Если кол-во записанных патронов в слоте равно найденным,
            //то не теребонькаем систему ;D
        }
    }
    return 1;
}

#if defined FIX_DRIVER_WEAPONS
    forward DriverHidesWeapons(playerid);
    public DriverHidesWeapons(playerid)
        return SetPlayerArmedWeapon(playerid, 0);
#endif

//Является ли указанный vehid воздушным транспортом, 1 - да | 0 - нет
stock IsAirTransport(vehid)
{
    switch(vehid)
    {
        case 417,425,447,460,469,476,487,488,497,511..513,
             519,520,548,553,563,577,592,593: return 1;
    }
    return 0;
}
