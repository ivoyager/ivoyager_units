# qformat.gd
# This file is part of I, Voyager
# https://ivoyager.dev
# *****************************************************************************
# Copyright 2017-2025 Charlie Whitfield
# I, Voyager is a registered trademark of Charlie Whitfield in the US
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# *****************************************************************************
extends Node

## This node is added as singleton "IVQFormat"
##
## Provides functions for formatting numbers or unit quantities.[br][br]
##
## If using named numbers or 'long_form' units, you'll need to add localized
## text/unit_numbers_text.en.translation to your Project.


enum TextFormat {
	# Note: We don't alter case in unit symbols!
	SHORT_MIXED_CASE, # '1.00 Million', '1.00 kHz'
	SHORT_UPPER_CASE, # '1.00 MILLION', '1.00 kHz'
	SHORT_LOWER_CASE, # '1.00 million', '1.00 kHz'
	LONG_MIXED_CASE, # '1.00 Million', '1.00 Kilohertz'
	LONG_UPPER_CASE, # '1.00 MILLION', '1.00 KILOHERTZ'
	LONG_LOWER_CASE, # '1.00 million', '1.00 kilohertz'
}

enum NumberType {
	DYNAMIC, # 0.01 to 99999 as non-scientific, otherwise scientific
	SCIENTIFIC, # always scientific using precision as significant digits
	PRECISION, # e.g., precision = 3 -> '12300' (forces zeros), '1.23', '0.0000123'
	DECIMAL_PLACES, # use 'precision' for decimal places rather than significant digits
}

enum DynamicUnitType {
	# length
	LENGTH_M_KM, # m if x < 1.0 km
	LENGTH_KM_AU, # au if x > 0.1 au
	LENGTH_M_KM_AU,
	LENGTH_M_KM_AU_LY, # ly if x > 0.1 ly
	LENGTH_M_KM_AU_PREFIXED_PARSEC, # if > 0.1 pc, pc, kpc, Mpc, Gpc, etc.
	# mass
	MASS_G_KG, # g if < 1.0 kg
	MASS_G_KG_T, # g if < 1.0 kg; t if x >= 1000.0 kg 
	MASS_G_KG_PREFIXED_T, # g, kg, t, kt, Mt, Gt, Tt, Pt etc.
	# mass rate
	MASS_RATE_G_KG_PREFIXED_T_PER_D, # g/d, kg/d, t/d, kt/d, Mt/d, Gt/d, etc.
	# time
	TIME_D_Y, # d if < 1000 d, else y
	# velocity
	VELOCITY_MPS_KMPS, # km/s if >= 1.0 km/s
	VELOCITY_MPS_KMPS_C, # km/s if >= 1.0 km/s; c if >= 0.1 c
}

enum LatitudeLongitudeType {
	N_S_E_W,
	LAT_LONG,
	PITCH_YAW,
}


const LOG_OF_10 := log(10.0)


# project vars

var exponent_str := "e" # likely alternatives: "E", "x10^" or " x 10^"

# The next three vars MUST be updated together!
var prefix_names: Array[String] = [ # e-30, ..., e30
	"Quecto", "Ronto", "Yocto", "Zepto", "Atto", "Femto", "Pico", "Nano", "Micro", "Milli",
	"", "Kilo", "Mega", "Giga", "Tera", "Peta", "Exa", "Zetta", "Yotta", "Ronna", "Quetta",
]
var prefix_symbols: Array[String] = [ # e-30, ..., e30
	"q", "r", "y", "z", "a", "f", "p", "n", char(181), "m",
	"", "k", "M", "G", "T", "P", "E", "Z", "Y", "R", "Q",
]
var prefix_offset := prefix_symbols.find("") # UPDATE if prefix_symbols changed!


var large_number_names: Array[StringName] = [
	&"TXT_MILLION", &"TXT_BILLION", &"TXT_TRILLION", &"TXT_QUADRILLION", &"TXT_QUINTILLION",
	&"TXT_SEXTILLION", &"TXT_SEPTILLION", &"TXT_OCTILLION", &"TXT_NONILLION", &"TXT_DECILLION"
] # e6, ..., e33


var long_forms: Dictionary[StringName, StringName] = {
	# If missing here, we fallback to 'short_forms', then the unit StringName
	# itself.
	#
	# Note that you can dynamically prefix any base unit (m, g, Hz, Wh, etc.)
	# using prefixed_unit(). We have commonly used already-prefixed here
	# because it is common to want to display fixed units such as '3.00e9 km'.
	
	# time
	&"s" : &"TXT_SECONDS",
	&"min" : &"TXT_MINUTES",
	&"h" : &"TXT_HOURS",
	&"d" : &"TXT_DAYS",
	&"a" : &"TXT_YEARS",
	&"y" : &"TXT_YEARS",
	&"yr" : &"TXT_YEARS",
	&"Cy" : &"TXT_CENTURIES",
	# length
	&"mm" : &"TXT_MILIMETERS",
	&"cm" : &"TXT_CENTIMETERS",
	&"m" : &"TXT_METERS",
	&"km" : &"TXT_KILOMETERS",
	&"au" : &"TXT_ASTRONOMICAL_UNITS",
	&"ly" : &"TXT_LIGHT_YEARS",
	&"pc" : &"TXT_PARSECS",
	&"Mpc" : &"TXT_MEGAPARSECS",
	# mass
	&"g" : &"TXT_GRAMS",
	&"kg" : &"TXT_KILOGRAMS",
	&"t" : &"TXT_TONNES",
	# angle
	&"rad" : &"TXT_RADIANS",
	&"deg" : &"TXT_DEGREES",
	# temperature
	&"K" : &"TXT_KELVIN",
	&"degC" : &"TXT_DEGREES_CELSIUS",
	&"degF" : &"TXT_DEGREES_FAHRENHEIT",
	# frequency
	&"Hz" : &"TXT_HERTZ",
	&"d^-1" : &"TXT_PER_DAY",
	&"a^-1" : &"TXT_PER_YEAR",
	&"y^-1" : &"TXT_PER_YEAR",
	&"yr^-1" : &"TXT_PER_YEAR",
	# area
	&"m^2" : &"TXT_SQUARE_METERS",
	&"km^2" : &"TXT_SQUARE_KILOMETERS",
	&"ha" : &"TXT_HECTARES",
	# volume
	&"l" : &"TXT_LITER",
	&"L" : &"TXT_LITER",
	&"m^3" : &"TXT_CUBIC_METERS",
	&"km^3" : &"TXT_CUBIC_KILOMETERS",
	# velocity
	&"m/s" : &"TXT_METERS_PER_SECOND",
	&"km/s" : &"TXT_KILOMETERS_PER_SECOND",
	&"km/h" : &"TXT_KILOMETERS_PER_HOUR",
	&"c" : &"TXT_SPEED_OF_LIGHT",
	# acceleration/gravity
	&"m/s^2" : &"TXT_METERS_PER_SECOND_SQUARED",
	&"_g" : &"TXT_STANDARD_GRAVITIES",
	# angular velocity
	&"deg/d" : &"TXT_DEGREES_PER_DAY",
	&"deg/a" : &"TXT_DEGREES_PER_YEAR",
	&"deg/Cy" : &"TXT_DEGREES_PER_CENTURY",
	# particle density
	&"m^-3" : &"TXT_PER_CUBIC_METER",
	# mass density
	&"g/cm^3" : &"TXT_GRAMS_PER_CUBIC_CENTIMETER",
	# mass rate
	&"kg/d" : &"TXT_KILOGRAMS_PER_DAY",
	&"t/d" : &"TXT_TONNES_PER_DAY",
	# force
	&"N" : &"TXT_NEWTONS",
	# pressure
	&"Pa" : &"TXT_PASCALS",
	&"atm" : &"TXT_ATMOSPHERES",
	# energy
	&"J" : &"TXT_JOULES",
	&"Wh" : &"TXT_WATT_HOURS",
	&"kWh" : &"TXT_KILOWATT_HOURS",
	&"MWh" : &"TXT_MEGAWATT_HOURS",
	&"eV" : &"TXT_ELECTRONVOLTS",
	# power
	&"W" : &"TXT_WATTS",
	&"kW" : &"TXT_KILOWATTS",
	&"MW" : &"TXT_MEGAWATTS",
	# luminous intensity / luminous flux
	&"cd" : &"TXT_CANDELAS",
	&"lm" : &"TXT_LUMENS",
	# luminance
	&"cd/m^2" : &"TXT_CANDELAS_PER_SQUARE_METER",
	# electric potential
	&"V" : &"TXT_VOLTS",
	# electric charge
	&"C" :  &"TXT_COULOMBS",
	# magnetic flux
	&"Wb" : &"TXT_WEBERS",
	# magnetic flux density
	&"T" : &"TXT_TESLAS",
}

var short_forms: Dictionary[StringName, String] = {
	# If missing here, we fallback to the unit StringName itself (that's
	# usually what we want: 'km', 'km/s', etc.).
	&"deg" : "\u00B0",
	&"degC" : "\u00B0C",
	&"degF" : "\u00B0F",
	&"deg/d" : "\u00B0/d",
	&"deg/a" : "\u00B0/a",
	&"deg/Cy" : "\u00B0/Cy",
	&"_g" : "g", # reused symbol ('_g' is the unit name; 'g' is GUI display)
}

var skip_space: Dictionary[StringName, bool] = {
	# No space before short_forms or StringName (possibly only degrees symbol).
	&"deg" : true,
	&"deg/d" : true,
	&"deg/a" : true,
	&"deg/Cy" : true,
}



func dynamic_unit(x: float, dynamic_unit_type: DynamicUnitType, precision := 3,
		number_type := NumberType.DYNAMIC, text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	
	match dynamic_unit_type:
		DynamicUnitType.LENGTH_M_KM: # m if x < 1.0 km
			if x < IVUnits.KM:
				return fixed_unit(x, &"m", precision, number_type, text_format)
			return fixed_unit(x, &"km", precision, number_type, text_format)
		DynamicUnitType.LENGTH_KM_AU: # au if x > 0.1 au
			if x < 0.1 * IVUnits.AU:
				return fixed_unit(x, &"km", precision, number_type, text_format)
			return fixed_unit(x, &"au", precision, number_type, text_format)
		DynamicUnitType.LENGTH_M_KM_AU:
			if x < IVUnits.KM:
				return fixed_unit(x, &"m", precision, number_type, text_format)
			elif x < 0.1 * IVUnits.AU:
				return fixed_unit(x, &"km", precision, number_type, text_format)
			return fixed_unit(x, &"au", precision, number_type, text_format)
		DynamicUnitType.LENGTH_M_KM_AU_LY:
			if x < IVUnits.KM:
				return fixed_unit(x, &"m", precision, number_type, text_format)
			elif x < 0.1 * IVUnits.AU:
				return fixed_unit(x, &"km", precision, number_type, text_format)
			elif x < 0.1 * IVUnits.LIGHT_YEAR:
				return fixed_unit(x, &"au", precision, number_type, text_format)
			return fixed_unit(x, &"ly", precision, number_type, text_format)
		DynamicUnitType.LENGTH_M_KM_AU_PREFIXED_PARSEC:
			if x < IVUnits.KM:
				return fixed_unit(x, &"m", precision, number_type, text_format)
			elif x < 0.1 * IVUnits.AU:
				return fixed_unit(x, &"km", precision, number_type, text_format)
			elif x < 0.1 * IVUnits.PARSEC:
				return fixed_unit(x, &"au", precision, number_type, text_format)
			return prefixed_unit(x, &"pc", precision, number_type, text_format)
		DynamicUnitType.MASS_G_KG: # g if < 1.0 kg
			if x < IVUnits.KG:
				return fixed_unit(x, &"g", precision, number_type, text_format)
			return fixed_unit(x, &"kg", precision, number_type, text_format)
		DynamicUnitType.MASS_G_KG_T: # g if < 1.0 kg; t if x >= 1000.0 kg 
			if x < IVUnits.KG:
				return fixed_unit(x, &"g", precision, number_type, text_format)
			elif x < IVUnits.TONNE:
				return fixed_unit(x, &"kg", precision, number_type, text_format)
			return fixed_unit(x, &"t", precision, number_type, text_format)
		DynamicUnitType.MASS_G_KG_PREFIXED_T: # g, kg, t, kt, Mt, Gt, Tt, etc.
			if x < IVUnits.KG:
				return fixed_unit(x, &"g", precision, number_type, text_format)
			elif x < IVUnits.TONNE:
				return fixed_unit(x, &"kg", precision, number_type, text_format)
			return prefixed_unit(x, &"t", precision, number_type, text_format)
		DynamicUnitType.MASS_RATE_G_KG_PREFIXED_T_PER_D: # g/d, kg/d, t/d, kt/d, Mt/d, Gt/d, etc.
			if x < IVUnits.KG / IVUnits.DAY:
				return fixed_unit(x, &"g/d", precision, number_type, text_format)
			elif x < IVUnits.TONNE / IVUnits.DAY:
				return fixed_unit(x, &"kg/d", precision, number_type, text_format)
			return prefixed_unit(x, &"t/d", precision, number_type, text_format)
		DynamicUnitType.TIME_D_Y:
			if x <= 1000.0 * IVUnits.DAY:
				return fixed_unit(x, &"d", precision, number_type, text_format)
			else:
				return fixed_unit(x, &"y", precision, number_type, text_format)
		DynamicUnitType.VELOCITY_MPS_KMPS: # km/s if >= 1.0 km/s
			if x < IVUnits.KM / IVUnits.SECOND:
				return fixed_unit(x, &"m/s", precision, number_type, text_format)
			return fixed_unit(x, &"km/s", precision, number_type, text_format)
		DynamicUnitType.VELOCITY_MPS_KMPS_C: # c if >= 0.1 c
			if x < IVUnits.KM / IVUnits.SECOND:
				return fixed_unit(x, &"m/s", precision, number_type, text_format)
			elif x < 0.1 * IVUnits.SPEED_OF_LIGHT:
				return fixed_unit(x, &"c", precision, number_type, text_format)
			return fixed_unit(x, &"km/s", precision, number_type, text_format)
			
	assert(false, "Unknown dynamic_unit_type: %s" % dynamic_unit_type)
	return str(x)


## precision == 0 displays 1 significant digit with a prepended "~". E.g., "~1 km".
## precision < 0 displays float using Godot str(float) with no processing.
func number(x: float, precision := 3, number_type := NumberType.DYNAMIC) -> String:
	
	if precision < 0:
		return (str(x))
	
	var prepend := ""
	if precision == 0:
		prepend = "~"
		precision = 1
		
	# specified decimal places
	if number_type == NumberType.DECIMAL_PLACES:
		return ("%s%.*f" % [prepend, precision, x])
	
	# All below use significant digits, not decimal places!
	# handle 0.0 case
	if x == 0.0: # don't do '0.00e0' even if NUM_SCIENTIFIC
		return "%s%.*f" % [prepend, precision - 1, 0.0] # e.g., '0.00' for precision 3
		
	var abs_x := absf(x)
	var pow10 := floorf(log(abs_x) / LOG_OF_10)
	var divisor: float
	
	if number_type == NumberType.PRECISION:
		var decimal_pl := precision - int(pow10) - 1
		if decimal_pl > 0:
			return "%s%.*f" % [prepend, decimal_pl, x] # e.g., '0.0555'
		if decimal_pl == 0:
			return "%s%.f" % [prepend, x] # whole number, '555'
		else: # remove over-precision
			divisor = pow(10.0, -decimal_pl)
			x = round(x / divisor)
			return "%s%.f" % [prepend, x * divisor] # '555000'
	
	# handle 0.01 - 99999 for NUM_DYNAMIC
	if number_type == NumberType.DYNAMIC and abs_x < 99999.5 and abs_x > 0.01:
		var decimal_pl := precision - int(pow10) - 1
		if decimal_pl > 0:
			return "%s%.*f" % [prepend, decimal_pl, x] # e.g., '0.0555'
		else:
			return "%s%.f" % [prepend, x] # whole number, allow over-precision
	
	# scientific
	divisor = pow(10.0, pow10)
	x = x / divisor if !is_zero_approx(divisor) else 1.0
	var exp_precision := pow(10.0, precision - 1)
	var precision_rounded := roundf(x * exp_precision) / exp_precision
	if precision_rounded == 10.0: # prevent '10.00e3' after rounding
		x /= 10.0
		pow10 += 1
	return "%s%.*f%s%.f" % [prepend, precision - 1, x, exponent_str, pow10] # e.g., '5.55e5'


func named_number(x: float, precision := 3, text_format := TextFormat.SHORT_MIXED_CASE
		) -> String:
	# Returns integer string up to '999999', then '1.00 Million', etc.
	if abs(x) < 1e6:
		return "%.f" % x
	var exp_3s_index := floori(log(absf(x)) / (LOG_OF_10 * 3.0))
	var lg_num_index := exp_3s_index - 2
	if lg_num_index < 0: # shouldn't happen but just in case
		return "%.f" % x
	if lg_num_index >= large_number_names.size():
		lg_num_index = large_number_names.size() - 1
		exp_3s_index = lg_num_index + 2
	x /= pow(10.0, exp_3s_index * 3)
	var lg_number_str: String = tr(large_number_names[lg_num_index])
	match text_format:
		TextFormat.SHORT_UPPER_CASE, TextFormat.LONG_UPPER_CASE:
			lg_number_str = lg_number_str.to_upper()
		TextFormat.SHORT_LOWER_CASE, TextFormat.LONG_LOWER_CASE:
			lg_number_str = lg_number_str.to_lower()
	return number(x, precision, NumberType.DYNAMIC) + " " + lg_number_str


func modified_named_number(x: float, precision := 3, text_format := TextFormat.SHORT_MIXED_CASE,
		prefix := "", suffix := "", multiplier := 1.0) -> String:
	# Same as named_number() but add prefix and/or suffix & apply
	# multiplier: e.g., '$1.00 Billion', '1.00 Million Species', etc.
	return prefix + named_number(x * multiplier, precision, text_format) + suffix


func prefixed_named_number(x: float, prefix: String, precision := 3,
		text_format := TextFormat.SHORT_MIXED_CASE, multiplier := 1.0) -> String:
	# DEPRECIATE: Use modified_named_number()
	return prefix + named_number(x * multiplier, precision, text_format)


func fixed_unit(x: float, unit: StringName, precision := 3,
		number_type := NumberType.DYNAMIC, text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	# Use for fixed unit irrespective of value, e.g., '5.97e24 kg'.
	
	x = IVQConvert.convert_quantity(x, unit, false, false)
	var number_str := number(x, precision, number_type)
	
	var unit_str: String
	var is_space := true
	
	match text_format:
		TextFormat.LONG_MIXED_CASE, TextFormat.LONG_UPPER_CASE, TextFormat.LONG_LOWER_CASE:
			var long_form: StringName = long_forms.get(unit, &"")
			if long_form:
				unit_str = tr(long_form)
				if text_format == TextFormat.LONG_UPPER_CASE:
					unit_str = unit_str.to_upper()
				elif text_format == TextFormat.LONG_LOWER_CASE:
					unit_str = unit_str.to_upper()
	
	if !unit_str:
		is_space = !skip_space.has(unit)
		unit_str = short_forms[unit] if short_forms.has(unit) else String(unit)
	
	if is_space:
		return number_str + " " + unit_str
	return number_str + unit_str


func prefixed_unit(x: float, unit: StringName, precision := 3,
		number_type := NumberType.DYNAMIC, text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	# Example results with unit == 't': '5.00 Gt' or '5.00 Gigatonnes',
	# depending on text_format.
	# WARNING: Don't try to prefix an already-prefixed unit (e.g., 'km') or any
	# composite unit where the first unit has a power other than 1 (eg, 'm^3').
	# The result will look weird and/or be wrong (eg, 1000 m^3 -> 1.00 km^3).
	# unit == &"" ok; otherwise, unit must be in multipliers or lamdas dicts
	# in IVQConvert.
	if unit:
		x = IVQConvert.convert_quantity(x, unit, false, false)
	var exp_3s_index := 0
	if x != 0.0:
		exp_3s_index = floori(log(absf(x)) / (LOG_OF_10 * 3.0))
	var si_index := exp_3s_index + prefix_offset
	if si_index < 0:
		si_index = 0
		exp_3s_index = -prefix_offset
	elif si_index >= prefix_symbols.size():
		si_index = prefix_symbols.size() - 1
		exp_3s_index = si_index - prefix_offset
	x /= pow(10.0, exp_3s_index * 3)
	var number_str := number(x, precision, number_type)
	
	var unit_str: String
	var is_space := true
	
	match text_format:
		TextFormat.LONG_MIXED_CASE, TextFormat.LONG_UPPER_CASE, TextFormat.LONG_LOWER_CASE:
			var long_form: StringName = long_forms.get(unit, &"")
			if long_form:
				unit_str = tr(long_form)
				var prefix_name: String = prefix_names[si_index]
				if text_format == TextFormat.LONG_MIXED_CASE:
					if prefix_name != "":
						unit_str = prefix_name + unit_str.to_lower()
				elif text_format == TextFormat.LONG_UPPER_CASE:
					unit_str = (prefix_name + unit_str).to_upper()
				elif text_format == TextFormat.LONG_LOWER_CASE:
					unit_str = (prefix_name + unit_str).to_lower()
	
	if !unit_str:
		is_space = !skip_space.has(unit)
		var prefix_symbol: String = prefix_symbols[si_index]
		if short_forms.has(unit):
			unit_str = prefix_symbol + short_forms[unit]
		else:
			unit_str = prefix_symbol + String(unit)

	if is_space:
		return number_str + " " + unit_str
	return number_str + unit_str


func latitude_longitude(lat_long: Vector2, decimal_pl := 0,
		lat_long_type := LatitudeLongitudeType.N_S_E_W, text_format := TextFormat.SHORT_MIXED_CASE
		) -> String:
	return (latitude(lat_long[0], decimal_pl, lat_long_type, text_format) + " "
			+ longitude(lat_long[1], decimal_pl, lat_long_type, text_format))


func latitude(x: float, decimal_pl := 0, lat_long_type := LatitudeLongitudeType.N_S_E_W,
		text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	
	x = rad_to_deg(x)
	x = wrapf(x, -180.0, 180.0)
	
	var long_form := false
	match text_format:
		TextFormat.LONG_MIXED_CASE, TextFormat.LONG_UPPER_CASE, TextFormat.LONG_LOWER_CASE:
			long_form = true
	
	var suffix: String
	if lat_long_type == LatitudeLongitudeType.N_S_E_W:
		if x > -0.0001: # prefer N if nearly 0 after conversion
			suffix = tr(&"TXT_NORTH") if long_form else tr(&"TXT_NORTH_SHORT")
		else:
			suffix = tr(&"TXT_SOUTH") if long_form else tr(&"TXT_SOUTH_SHORT")
		x = abs(x)
	elif lat_long_type == LatitudeLongitudeType.LAT_LONG:
		suffix = tr(&"TXT_LATITUDE") if long_form else tr(&"TXT_LATITUDE_SHORT")
	else: # PITCH_YAW
		suffix = tr(&"TXT_PITCH")
	
	match text_format:
		TextFormat.LONG_UPPER_CASE, TextFormat.SHORT_UPPER_CASE:
			suffix = suffix.to_upper()
		TextFormat.LONG_LOWER_CASE:
			suffix = suffix.to_lower()
		TextFormat.SHORT_LOWER_CASE:
			if lat_long_type != LatitudeLongitudeType.N_S_E_W: # don't lower case N, S
				suffix = suffix.to_lower()
	
	return "%.*f\u00B0 %s" % [decimal_pl, x, suffix]


func longitude(x: float, decimal_pl := 0, lat_long_type := LatitudeLongitudeType.N_S_E_W,
		text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	
	x = rad_to_deg(x)
	
	var long_form := false
	match text_format:
		TextFormat.LONG_MIXED_CASE, TextFormat.LONG_UPPER_CASE, TextFormat.LONG_LOWER_CASE:
			long_form = true
	
	var suffix: String
	if lat_long_type == LatitudeLongitudeType.N_S_E_W:
		x = wrapf(x, -180.0, 180.0)
		if x > -0.0001 and x < 179.9999: # nearly 0 is E; nearly 180 is W
			suffix = tr(&"TXT_EAST") if long_form else tr(&"TXT_EAST_SHORT")
		else:
			suffix = tr(&"TXT_WEST") if long_form else tr(&"TXT_WEST_SHORT")
		x = abs(x)
	elif lat_long_type == LatitudeLongitudeType.LAT_LONG:
		x = wrapf(x, 0.0, 360.0)
		suffix = tr(&"TXT_LONGITUDE") if long_form else tr(&"TXT_LONGITUDE_SHORT")
	else: # PITCH_YAW
		x = wrapf(x, -180.0, 180.0)
		suffix = tr(&"TXT_YAW")
	
	match text_format:
		TextFormat.LONG_UPPER_CASE, TextFormat.SHORT_UPPER_CASE:
			suffix = suffix.to_upper()
		TextFormat.LONG_LOWER_CASE:
			suffix = suffix.to_lower()
		TextFormat.SHORT_LOWER_CASE:
			if lat_long_type != LatitudeLongitudeType.N_S_E_W: # don't lower case E, W
				suffix = suffix.to_lower()
	
	return "%.*f\u00B0 %s" % [decimal_pl, x, suffix]
