-- ToritaLuaDisarm v1.0.0

-- add parameters
local PARAM_TABLE_KEY = 78
local PARAM_TABLE_PREFIX = "TOR_"
assert(param:add_table(PARAM_TABLE_KEY, PARAM_TABLE_PREFIX, 5), 'could not add param table')
assert(param:add_param(PARAM_TABLE_KEY, 1,  'DIST_SENS', 10), 'could not add param 1')
assert(param:add_param(PARAM_TABLE_KEY, 2,  'DIST_CONT', 2), 'could not add param2')
assert(param:add_param(PARAM_TABLE_KEY, 3,  'LANDING_ALT', 50), 'could not add param3')
assert(param:add_param(PARAM_TABLE_KEY, 4,  'ALTITUDE_DIFF', 200), 'could not add param4')
assert(param:add_param(PARAM_TABLE_KEY, 5,  'DEBUG_ENABLE', 1), 'could not add param5')

-- define parameters
local TOR_DIST_SENS = Parameter() 
local TOR_DIST_CONT = Parameter() 
local TOR_LANDING_ALT = Parameter() 
local TOR_ALTITUDE_DIFF = Parameter() 
local TOR_DEBUG_ENABLE = Parameter() 

-- initialise parameters
assert(TOR_DIST_SENS:init('TOR_DIST_SENS'), 'could not find TOR_DIST_SENS parameter')
assert(TOR_DIST_CONT:init('TOR_DIST_CONT'), 'could not find TOR_DIST_CONT parameter')
assert(TOR_LANDING_ALT:init('TOR_LANDING_ALT'), 'could not find TOR_LANDING_ALT parameter')
assert(TOR_ALTITUDE_DIFF:init('TOR_ALTITUDE_DIFF'), 'could not find TOR_ALTITUDE_DIFF parameter')
assert(TOR_DEBUG_ENABLE:init('TOR_DEBUG_ENABLE'), 'could not find TOR_DEBUG_ENABLE parameter')

-- define stages
local AC_LANDED = 0
local AC_TAKING_OFF = 1
local AC_FLYING = 2
local AC_LANDING = 3

-- define conditions
local ac_state = AC_LANDED
local cond_armed = false
local cond_alt = false
local cond_landed_state = false
local cond_mode = false

-- define vars
local distance_sensor = 0
local distance_count = 0
local debug_time = 0
local last_healthy_altitude = 0

-- define flight modes
local cond_flight_modes = {
	10, -- PLANE_MODE_AUTO
    11,	-- PLANE_MODE_RTL
    20, -- PLANE_MODE_QLAND
    21, -- PLANE_MODE_QRTL
    19, -- PLANE_MODE_QLOITER
    18, -- PLANE_MODE_QHOVER
    17	-- PLANE_MODE_QSTABILIZE
}

function rangefinder_distance  ()
	local rangefinder_rotation = 25
	local distance = 0
	if rangefinder:has_data_orient(rangefinder_rotation) then
		distance = rangefinder:distance_cm_orient(rangefinder_rotation)
	end
	return distance 
end

function estimated_altitude ()
	local dist
	local altitude
	if ahrs:healthy() then
		dist = ahrs:get_relative_position_NED_home()
		altitude = -1*dist:z()
		last_healthy_altitude = altitude
	else
		altitude = last_healthy_altitude
	end
	return altitude
end

function setCondAlt (value)
  altitude = estimated_altitude()
  if value == false then
    cond_alt = false;
  elseif TOR_ALTITUDE_DIFF:get() > 0 and math.abs(altitude - distance_sensor) >= TOR_ALTITUDE_DIFF:get() then
      cond_alt = false
  else
      cond_alt = true
  end
end

--local rngfnd_init_alt = rangefinder_distance()

function update ()
	
	-- evaluate disarm
    if cond_armed == true and cond_mode == true and cond_alt == true and cond_landed_state == true then
        arming:disarm()
        cond_armed = false
    end
	
	cond_armed = arming:is_armed()
	
	distance_sensor = rangefinder_distance() -- - rngfnd_init_alt
	
	cond_alt = (distance_sensor <= TOR_DIST_SENS:get())
	
	-- evaluate cond_mode
	local flight_mode = vehicle:get_mode()
	
	for i = 1, 7 do
		if cond_flight_modes[i] == flight_mode then
			cond_mode = true
			break 
		else
			cond_mode = false
		end
	end
	
	-- evaluate cond_alt
	if distance_sensor < TOR_DIST_SENS:get() then
		if distance_count >= TOR_DIST_CONT:get() then
			setCondAlt(true);
			distance_count = TOR_DIST_CONT:get()
		else
			distance_count = distance_count + 1
		end
	else
		setCondAlt(false)
		distance_count = 0
	end
		
	-- evaluate cond_land_state
	if ac_state == AC_LANDED and cond_armed == false and cond_alt == true then 
	  cond_landed_state = false
	elseif ac_state == AC_LANDED and cond_armed == true and cond_alt == false then
	  ac_state = AC_TAKING_OFF
	elseif ac_state == AC_TAKING_OFF and cond_armed == true and cond_alt == false then
	  ac_state = AC_FLYING
	elseif ac_state == AC_FLYING and cond_armed == true and cond_alt == false and distance_sensor <= TOR_LANDING_ALT:get() then
	  ac_state = AC_LANDING
	elseif ac_state == AC_LANDING and cond_armed == true and cond_alt == false and distance_sensor > TOR_LANDING_ALT:get() then
	  ac_state = AC_FLYING
	elseif ac_state == AC_LANDING and cond_armed == true and cond_alt == true then
	  ac_state = AC_LANDED
	  if cond_mode == true then
		cond_landed_state = true
	  end
	end
	
	if millis() - debug_time >= 1000 then
		if TOR_DEBUG_ENABLE:get() == 1 then
			gcs:send_text(0, "Torito: " .. string.format("sta=%d arm=%s mod=%s alt:%s", ac_state, cond_armed, cond_mode, cond_alt))
		end
		debug_time = millis()
	end
	return update, 100
end

return update, 1000