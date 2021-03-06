/*
	VEMF System Functions
	by Vampire
*/

diag_log text "[VEMF]: Loading ExecVM Functions.";

VEMFSpawnAI = "\VEMF\Scripts\VSpawnAI.sqf";

diag_log text "[VEMF]: Loading Compiled Functions.";

// Gets the Map's Hardcoded CenterPOS and Radius
VEMFMapCenter = {
	private ["_mapName","_centerPos","_mapRadii","_fin"];
	
	// Get the map name again to prevent interfering
	_mapName = toLower format ["%1", worldName];
	
	/*
		- Still based on code by Halv
	
			If the map does not have a _mapRadii,
		it has a guessed center that may not be accurate.
		You can contact me if you have issues with a
		"less supported" map, so I can fully support it.
	*/
	switch (_mapName) do {
		/* Arma 3 Maps */
		case "altis":{_centerPos = [15440, 15342, 0];_mapRadii = 17000;);
		case "stratis":{_centerPos = [4042, 4093, 0];_mapRadii = 4100;);

		/* Arma 2 Maps (May Need Updating) */
		case "chernarus":{_centerPos = [7100, 7750, 0];_mapRadii = 5500;};
		case "utes":{_centerPos = [3500, 3500, 0];_mapRadii = 3500;};
		case "zargabad":{_centerPos = [4096, 4096, 0];_mapRadii = 4096;};
		case "fallujah":{_centerPos = [3500, 3500, 0];_mapRadii = 3500;};
		case "takistan":{_centerPos = [5500, 6500, 0];_mapRadii = 5000;};
		case "tavi":{_centerPos = [10370, 11510, 0];_mapRadii = 14090;};
		case "lingor":{_centerPos = [4400, 4400, 0];_mapRadii = 4400;};
		case "namalsk":{_centerPos = [4352, 7348, 0]};
		case "napf":{_centerPos = [10240, 10240, 0];_mapRadii = 10240;};
		case "mbg_celle2":{_centerPos = [8765.27, 2075.58, 0]};
		case "oring":{_centerPos = [1577, 3429, 0]};
		case "panthera2":{_centerPos = [4400, 4400, 0];_mapRadii = 4400;};
		case "isladuala":{_centerPos = [4400, 4400, 0];_mapRadii = 4400;};
		case "smd_sahrani_a2":{_centerPos = [13200, 8850, 0]};
		case "sauerland":{_centerPos = [12800, 12800, 0];_mapRadii = 12800;};
		case "trinity":{_centerPos = [6400, 6400, 0];_mapRadii = 6400;};
		default {_centerPos = [0,0,0];_mapRadii = 5500;};
	};
	
	if ((_centerPos select 0) == 0) then {
		diag_log text format ["[VEMF]: POSFinder: %1 is not a Known Map. Please Inform Vampire.", _mapName];
	};
	
	// Return our results, or the default
	_fin = [_centerPos,_mapRadii];
	_fin
};

// Finds a Random Map Location for a Mission
VEMFRandomPos = {
	private ["_centerLoc","_findRun","_testPos","_hardX","_hardY","_posX","_posY","_feel1","_feel2","_feel3","_feel4","_noWater","_okDis","_isBlack","_plyrNear","_fin"];
	
	// The DayZ "Novy Sobor" bug still exists in Arma 3.
	// This means we still need to input our map specific centers.
	_centerLoc = call VEMFMapCenter;
	
	// Now we run a loop to check the position against our requirements
	_findRun = true;
	while {_findRun} do
	{
		// Get our Candidate Position
		_testPos = [(_centerLoc select 0),0,(_centerLoc select 1),60,0,20,0] call BIS_fnc_findSafePos;

		// Get values to compare
		_hardX = ((_centerLoc select 0) select 0);
        _hardY = ((_centerLoc select 0) select 1);
        _posX = _testPos select 0;
        _posY = _testPos select 1;

        // Water Feelers. Checks for nearby water within 50meters.
        _feel1 = [_posX, _posY+50, 0]; // North
        _feel2 = [_posX+50, _posY, 0]; // East
        _feel3 = [_posX, _posY-50, 0]; // South
        _feel4 = [_posX-50, _posY, 0]; // West
		
		// Water Check
		_noWater = (!surfaceIsWater _testPos && !surfaceIsWater _feel1 && !surfaceIsWater _feel2 && !surfaceIsWater _feel3 && !surfaceIsWater _feel4);
	
		// Check for Mission Separation Distance
		{
			_okDis = true;
			if ((_testPos distance _x) < 1500) exitWith
			{
				// Another Mission is too close
				_okDis = false;
			};
		} forEach VEMFMissionLocs;
		
		// Blacklist Check
        {
			_isBlack = false;
            if ((_testPos distance (_x select 0)) <= (_x select 1)) exitWith
			{
				// Position is too close to a Blacklisted Location
				_isBlack = true;
			};
        } forEach VEMFBlacklistZones;
		
		_plyrNear = {isPlayer _x} count (_testPos nearEntities [["Epoch_Male_F", "Epoch_Female_F"], 500]) > 0;
		
		// Let's Compare all our Requirements
		if ((_posX != _hardX) AND (_posY != _hardY) AND _noWater AND _okDis AND !_isBlack AND !_plyrNear) then {
			_findRun = false;
        };
		
		//diag_log text format ["[VEMF]: MISSDEBUG: Pos:[%1,%2] / noWater?:%3 / okDistance?:%4 / isBlackListed:%5 / isPlayerNear:%6", _posX, _posY, _noWater, _okDis, _isBlack, _plyrNear];
        
		uiSleep 2;
	};
	
	_fin = [(_testPos select 0), (_testPos select 1), 0];
    _fin
};

// Finds a Random Town on the Map
VEMFFindTown = {
	private ["_cntr","_townArr","_sRandomTown","_townPos","_townName","_ret"];
	
	// Map Incorrect Center (but center-ish)
	_cntr = getArray(configFile >> "CfgWorlds" >> worldName >> "centerPosition");

	// Get a list of towns
	// Shouldn't cause lag because of the infrequency it runs (Needs Testing)
	_townArr = nearestLocations [_cntr, ["NameVillage","NameCity","NameCityCapital"], 30000];
	
	// Pick a random town
	_townArr = _townArr call BIS_fnc_arrayShuffle;
	_sRandomTown = _townArr call BIS_fnc_selectRandom;
	
	// Return Name and POS
	_townPos = [((getposATL _sRandomTown) select 0), ((getposATL _sRandomTown) select 1), 0];
	_townName = (text _sRandomTown);

	_ret = [_townName, _townPos];
	_ret
};

// Finds House Positions for Units
VEMFHousePositions = {
	private ["_pos","_cnt","_houseArr","_fin","_loop","_bNum","_tmpArr","_bPos"];
	
	// CenterPOS and House Count
	_pos = _this select 0;
	_cnt = _this select 1;
	
	// Get Nearby Houses in Array
	_houseArr = nearestObjects [_pos, ["house"], 150];
	
	{
		if (str _houseArr == "[0,0,0]") then {
			// Not a Valid House
			_houseArr = _houseArr - [_x];
		};
	} forEach _houseArr;
	
	// Randomize Valid Houses
	_houseArr = _houseArr call BIS_fnc_arrayShuffle;
	
	// Only return the amount of houses we wanted
	_houseArr resize _cnt;
	
	_fin = [];
	
	{
		// Keep locations separated by house for unit groups
		_loop = true;
		_bNum = 0;
		_tmpArr = [];
		while {_loop} do {
			_bPos = _x buildingPos _bNum;
			if (str _bPos == "[0,0,0]") then {
				// All Positions Found
				_loop = false;
			} else {
				_tmpArr = _tmpArr + _bPos;
				_bNum = _bNum + 1;
			};
		};
		
		_fin = _fin + [_tmpArr];
	} forEach _houseArr;
	
	// Returns in the following format
	// Nested Array = [[HousePos1,Pos2,Pos3],[Pos1,Pos2],[Pos1,Pos2]];
	_fin
};

// Temporary Vehicle Setup
// Assume to NOT Work at This Time
// Server "May" Have an AutoSave Loop
VEMFSetupVic = {
	private ["_vehicle","_vClass","_ranFuel","_config","_textureSelectionIndex","_selections","_colors","_textures","_color","_count"];
	_vehicle = _this select 0;
	_vClass = (typeOf _vehicle);
	
	waitUntil {(!isNull _vehicle)};
	
	// Set Vehicle Token
	// Will Delete if Not Set
	_vehicle call EPOCH_server_setVToken;
	
	// Add to A3 Cleanup
	addToRemainsCollector [_vehicle];
	
	// Disable Thermal/NV for Vehicle
	_vehicle disableTIEquipment true;
	
	// Empty Vehicle
	clearWeaponCargoGlobal _vehicle;
	clearMagazineCargoGlobal _vehicle;
	clearBackpackCargoGlobal  _vehicle;
	clearItemCargoGlobal _vehicle;
	
	// Set the Vehicle Lock Time (0 Seconds)
	// Vehicle Will Spawn Unlocked
	_vehicle lock true;
	_vehicle setVariable["LOCK_OWNER", "-1"];
	_vehicle setVariable["LOCKED_TILL", serverTime];
	
	// Pick a Random Color if Available
	_config = configFile >> "CfgVehicles" >> _vClass >> "availableColors";
	if (isArray(_config)) then {
		_textureSelectionIndex = configFile >> "CfgVehicles" >> _vClass >> "textureSelectionIndex";
		_selections = if (isArray(_textureSelectionIndex)) then {
			getArray(_textureSelectionIndex)
		} else {
			[0]
		};
		
		_colors = getArray(_config);
		_textures = _colors select 0;
		_color = floor(random(count _textures));
		_count = (count _colors)-1;
		{
			if (_count >=_forEachIndex) then {
				_textures = _colors select _forEachIndex;
			};
			_vehicle setObjectTextureGlobal [_x,(_textures select _color)];
		} forEach _selections;
		
		_vehicle setVariable ["VEHICLE_TEXTURE", _color];
	};
	
	// Set Vehicle Init
	_vehicle call EPOCH_server_vehicleInit;
	
	// Set a Random Fuel Amount
	_ranFuel = random 1;
	if (_ranFuel < 0.1) then {_ranFuel = 0.1;};
	_vehicle setFuel _ranFuel;
	_vehicle setVelocity [0,0,1];
	_vehicle setDir (round(random 360));
	
	// If the Vehicle is Temporary, Warn Players
	if (!(VEMFSaveVehicles)) then {
		_vehicle addEventHandler ["GetIn",{
			_nil = ["Warning: Vehicle Will Disappear on Restart!","systemChat",(_this select 2),false,true] call BIS_fnc_MP;
		}];
	};

	true
};

// Alerts Players With a Random Radio Type
VEMFBroadcast = {
	private ["_msg","_eRads","_rad","_sent"];
	_msg = _this select 0;
	_eRads = ["0","1","2","3","4","5","6","7","8","9"];
	_eRads = _eRads call BIS_fnc_arrayShuffle;
	
	if (typeName _msg != "STRING") then {
		_msg = str(_msg);
	};
	
	// Pick a Radio to Broadcast On
	_rad = _eRads call BIS_fnc_selectRandom;
	_rad = "EpochRadio" + _rad;
	
	// Broadcast to Each Player
	_sent = false;
	_allUnits = allUnits;
	
	// Remove Non-Players
	{ if (!isPlayer _x) then {_allUnits = _allUnits - (_x);}; } forEach _allUnits;
	
	// Broadcast on Every Radio Randomly Until Someone Hears Us
	{
		_n = 0;
		while {true} do {
			_unit = (_allUnits select _n);
		
			if (isPlayer _unit) then {
				if (_rad in (assignedItems _unit)) then {
					[(_msg),"systemChat",(_x),false,true] call BIS_fnc_MP;
					_sent = true;
				};
			};
			
			if ((count _allUnits) == _n) exitWith {
				// Through AllUnits
			};
		};
		
		if (_sent == true) exitWith {
			// We Broadcast to a Radio with Someone on it
		};
	} forEach _eRads;
	
	// Return if Message was Received by Someone
	// If FALSE, Nobody has a Radio Equipped
	_sent
};

/* ================================= End Of Functions ================================= */
diag_log text "[VEMF]: Loading: All Functions Loaded.";