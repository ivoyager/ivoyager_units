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

## Singleton [IVQFormat] provides API for formatting numbers and unit quantities
## for GUI display.
##
## Methods here use [IVQConvert] API for unit conversions, which assumes (and
## helps ensure) that the calling project uses consistant internal units.[br][br]
##
## If using named numbers or "long form" units, you'll need to add translations
## to your project. An Engligh translation is included in the plugin in file
## [code]ivoyaber_units/text/unit_numbers_text.en.translation[/code].[br][br]
##
## This node "pre-translates" all relevant text keys. If modifying any arrays or
## dictionaries that contain text keys or if changing language at runtime, be
## sure to call [method retranslate] afterwards. The reason for this is that
## [method Object.tr] throws an error if called on thread (as of Godot 4.5).
## Pre-translation allows calling all of the String return methods here on threads.



## Defines display of unit symbols (versus unit names) and text case. Note that
## case is never altered in unit symbols.
enum TextFormat {
	# Note: We don't alter case in unit symbols!
	SHORT_MIXED_CASE, ## Examples: "1.00 Million", "1.00 kHz".
	SHORT_UPPER_CASE, ## Examples: "1.00 MILLION", "1.00 kHz".
	SHORT_LOWER_CASE, ## Examples: "1.00 million", "1.00 kHz".
	LONG_MIXED_CASE, ## Examples: "1.00 Million", "1.00 Kilohertz".
	LONG_UPPER_CASE, ## Examples: "1.00 MILLION", "1.00 KILOHERTZ".
	LONG_LOWER_CASE, ## Examples: "1.00 million", "1.00 kilohertz".
}

## Defines number format and the meaning of [param precision]. Note that
## [param precision] means significant digits except in the case of
## [member DECIMAL_PLACES].
enum NumberType {
	DYNAMIC, ## 0.01 to 99999 as non-scientific, otherwise scientific.
	SCIENTIFIC, ## Always scientific using precision as significant digits.
	PRECISION, ## Examples with precision == 3: "12300" (forces zeros), "1.23", "0.0000123".
	DECIMAL_PLACES, ## Decimal representation with decimal places equal to [param precision].
}

## Return format for latitude, longitude strings.
enum LatitudeLongitudeType {
	N_S_E_W, ## E.g., "55° S, 55° E"
	LAT_LONG, ## E.g., "-55° lat., 55° lon."
	PITCH_YAW, ## E.g., "-55° pitch, 55° yaw"
}



## String for formatting scientific notation. E.g., set to " × 10^" for "9.99 × 10^9".
var exponent_str := "e"

## 3rd magnitude prefixes (full names). If modifying, be sure to modify [member prefix_symbols]
## and [member prefix_offset] as needed.
var prefix_names: Array[String] = [ # e-30, ..., e30
	"Quecto", "Ronto", "Yocto", "Zepto", "Atto", "Femto", "Pico", "Nano", "Micro", "Milli",
	"", "Kilo", "Mega", "Giga", "Tera", "Peta", "Exa", "Zetta", "Yotta", "Ronna", "Quetta",
]
## 3rd magnitude prefixes (symbols). If modifying, be sure to modify [member prefix_names]
## and [member prefix_offset] as needed.
var prefix_symbols: Array[String] = [ # e-30, ..., e30
	"q", "r", "y", "z", "a", "f", "p", "n", "µ", "m",
	"", "k", "M", "G", "T", "P", "E", "Z", "Y", "R", "Q",
]
## Index of the non-prefixed element in [member prefix_names] and  [member prefix_symbols].
## Update if changing those arrays.
var prefix_offset := prefix_symbols.find("") # UPDATE if prefix_symbols changed!

## 3rd magnitude number names as text keys, starting with 10e6.[br][br]
##
## IMPORTANT! Call [method retranslate] after modifying.
var large_number_names: Array[StringName] = [
	&"TXT_MILLION", &"TXT_BILLION", &"TXT_TRILLION", &"TXT_QUADRILLION", &"TXT_QUINTILLION",
	&"TXT_SEXTILLION", &"TXT_SEPTILLION", &"TXT_OCTILLION", &"TXT_NONILLION", &"TXT_DECILLION"
] # e6, ..., e33

## "Long form" unit names as text keys. If a unit is missing here, code will fallback to
## [member short_forms] and then to the unit symbol itself.[br][br]
##
## Note that you can dynamically prefix any base unit (m, g, Hz, Wh, etc.)
## using [method prefixed_unit]. We have already-prefixed units here
## because it is common to want to display fixed units such as "3.00e9 km".[br][br]
##
## IMPORTANT! Call [method retranslate] after modifying.
var long_forms: Dictionary[StringName, StringName] = {
	
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
	&"g0" : &"TXT_STANDARD_GRAVITIES",
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

## "Short form" unit names. If a unit is missing here, code will fallback to the
## unit StringName itself, which is usually what we want: e.g., "km", "km/s", etc.
## This dictionary is needed only when the internal unit symbol is not the
## appropriate display symbol.
var short_forms: Dictionary[StringName, String] = {
	&"deg" : "°",
	&"degC" : "°C",
	&"degF" : "°F",
	&"deg/d" : "°/d",
	&"deg/a" : "°/a",
	&"deg/Cy" : "°/Cy",
	&"g0" : "g", # reused symbol for gravitational force equivalent
}

## Symbols that should not be preceded by a space. Possibly only units that
## display with the degree symbol (°) as first character.
var unspaced_units: Dictionary[StringName, bool] = {
	&"deg" : true,
	&"deg/d" : true,
	&"deg/a" : true,
	&"deg/Cy" : true,
}

## Contains quantity format Callables that can be specified in [method dynamic_unit].
## Callables can be added or replaced, but must follow method signature
## [code](x: float, precision: int, number_type: NumberType, text_format: TextFormat)[/code].
var dynamic_unit_callables: Dictionary[StringName, Callable] = {
	
	# m if < 1 km, else km
	length_m_km = func length_m_km(x: float, precision: int, number_type: NumberType,
			text_format: TextFormat) -> String:
		if x < IVUnits.KM:
			return fixed_unit(x, &"m", precision, number_type, text_format)
		return fixed_unit(x, &"km", precision, number_type, text_format),
	
	# km if < 0.1 au, else au.
	length_km_au = func length_km_au(x: float, precision: int, number_type: NumberType,
			text_format: TextFormat) -> String:
		if x < 0.1 * IVUnits.AU:
			return fixed_unit(x, &"km", precision, number_type, text_format)
		return fixed_unit(x, &"au", precision, number_type, text_format),
	
	# m if < 1 km, km if < 0.1 au, else au.
	length_m_km_au = func length_m_km_au(x: float, precision: int, number_type: NumberType,
			text_format: TextFormat) -> String:
		if x < IVUnits.KM:
			return fixed_unit(x, &"m", precision, number_type, text_format)
		if x < 0.1 * IVUnits.AU:
			return fixed_unit(x, &"km", precision, number_type, text_format)
		return fixed_unit(x, &"au", precision, number_type, text_format),
	
	# m if < 1 km, km if < 0.1 au, au if < 0.1 ly, else ly.
	length_m_km_au_ly = func length_m_km_au_ly(x: float, precision: int, number_type: NumberType,
			text_format: TextFormat) -> String:
		if x < IVUnits.KM:
			return fixed_unit(x, &"m", precision, number_type, text_format)
		if x < 0.1 * IVUnits.AU:
			return fixed_unit(x, &"km", precision, number_type, text_format)
		if x < 0.1 * IVUnits.LIGHT_YEAR:
			return fixed_unit(x, &"au", precision, number_type, text_format)
		return fixed_unit(x, &"ly", precision, number_type, text_format),
	
	# m if < 1 km, km if < 0.1 au, au if < 0.1 parsec, else pc, kpc, Mpc, Gpc, etc.
	length_m_km_au_prefixed_pc = func length_m_km_au_prefixed_pc(x: float, precision: int,
			number_type: NumberType, text_format: TextFormat) -> String:
		if x < IVUnits.KM:
			return fixed_unit(x, &"m", precision, number_type, text_format)
		if x < 0.1 * IVUnits.AU:
			return fixed_unit(x, &"km", precision, number_type, text_format)
		if x < 0.1 * IVUnits.PARSEC:
			return fixed_unit(x, &"au", precision, number_type, text_format)
		return prefixed_unit(x, &"pc", precision, number_type, text_format),
	
	# g if < 1 kg, else kg.
	mass_g_kg = func mass_g_kg(x: float, precision: int, number_type: NumberType,
			text_format: TextFormat) -> String:
		if x < IVUnits.KG:
			return fixed_unit(x, &"g", precision, number_type, text_format)
		return fixed_unit(x, &"kg", precision, number_type, text_format),
	
	# g if < 1 kg, kg if < 1 t, else t.
	mass_g_kg_t = func mass_g_kg_t(x: float, precision: int, number_type: NumberType,
			text_format: TextFormat) -> String:
		if x < IVUnits.KG:
			return fixed_unit(x, &"g", precision, number_type, text_format)
		if x < IVUnits.TONNE:
			return fixed_unit(x, &"kg", precision, number_type, text_format)
		return fixed_unit(x, &"t", precision, number_type, text_format),
	
	# g if < 1 kg, kg if < 1 t, else t, Mt, Gt, etc.
	mass_g_kg_prefixed_t = func mass_g_kg_prefixed_t(x: float, precision: int,
			number_type: NumberType, text_format: TextFormat) -> String:
		if x < IVUnits.KG:
			return fixed_unit(x, &"g", precision, number_type, text_format)
		if x < IVUnits.TONNE:
			return fixed_unit(x, &"kg", precision, number_type, text_format)
		return prefixed_unit(x, &"t", precision, number_type, text_format),
	
	# g/d, kg/d, t/d, kt/d, Mt/d, Gt/d, etc.
	mass_rate_g_kg_prefixed_t_per_d = func mass_rate_g_kg_prefixed_t_per_d(x: float, precision: int,
			number_type: NumberType, text_format: TextFormat) -> String:
		if x < IVUnits.KG:
			return fixed_unit(x, &"g", precision, number_type, text_format)
		if x < IVUnits.TONNE:
			return fixed_unit(x, &"kg", precision, number_type, text_format)
		return prefixed_unit(x, &"t", precision, number_type, text_format),
	
	# d if < 1000 d, else y.
	time_d_y = func time_d_y(x: float, precision: int, number_type: NumberType,
			text_format: TextFormat) -> String:
		if x <= 1000.0 * IVUnits.DAY:
			return fixed_unit(x, &"d", precision, number_type, text_format)
		return fixed_unit(x, &"y", precision, number_type, text_format),
	
	# h if < 24 h, d if < 1000 d, else y.
	time_h_d_y = func time_h_d_y(x: float, precision: int, number_type: NumberType,
			text_format: TextFormat) -> String:
		if x < 24.0 * IVUnits.HOUR:
			return fixed_unit(x, &"h", precision, number_type, text_format)
		if x <= 1000.0 * IVUnits.DAY:
			return fixed_unit(x, &"d", precision, number_type, text_format)
		return fixed_unit(x, &"y", precision, number_type, text_format),
	
	# m/s if < 1 km/s, else km/s.
	velocity_mps_kmps = func velocity_mps_kmps(x: float, precision: int, number_type: NumberType,
			text_format: TextFormat) -> String:
		const KMPS := IVUnits.KM / IVUnits.SECOND
		if x < KMPS:
			return fixed_unit(x, &"m/s", precision, number_type, text_format)
		return fixed_unit(x, &"km/s", precision, number_type, text_format),
	
	# m/s if < 1 km/s, km/s if < 0.1 c, else c.
	velocity_mps_kmps_c = func velocity_mps_kmps_c(x: float, precision: int, number_type: NumberType,
			text_format: TextFormat) -> String:
		const KMPS := IVUnits.KM / IVUnits.SECOND
		const ONE_TENTH_C := 0.1 * IVUnits.SPEED_OF_LIGHT
		if x < KMPS:
			return fixed_unit(x, &"m/s", precision, number_type, text_format)
		if x < ONE_TENTH_C:
			return fixed_unit(x, &"km/s", precision, number_type, text_format)
		return fixed_unit(x, &"c", precision, number_type, text_format),
}


var _large_number_names_tr: Array[String] = []
var _long_forms_tr: Dictionary[StringName, String] = {}
var _tr: Dictionary[StringName, String] = {}
var _to_localize: Array[StringName] = [&"TXT_NORTH", &"TXT_SOUTH", &"TXT_EAST", &"TXT_WEST",
		&"TXT_LATITUDE", &"TXT_LONGITUDE", &"TXT_PITCH", &"TXT_YAW",
		&"TXT_NORTH_SHORT", &"TXT_SOUTH_SHORT", &"TXT_EAST_SHORT", &"TXT_WEST_SHORT",
		&"TXT_LATITUDE_SHORT", &"TXT_LONGITUDE_SHORT"]



func _ready() -> void:
	retranslate()


## Call this method after modifying this class's arrays or dictionaries that
## contain translation text keys, or after changing language at runtime. This
## is necessary to allow threadsafe use of String return methods.
func retranslate() -> void:
	var large_number_names_size := large_number_names.size()
	_large_number_names_tr.resize(large_number_names_size)
	for i in large_number_names_size:
		_large_number_names_tr[i] = tr(large_number_names[i])
	for key in long_forms:
		_long_forms_tr[key] = tr(long_forms[key])
	for key in _to_localize:
		_tr[key] = tr(key)


## Returns a formatted number string specified by [param precision] and [param number_type].
## See [member NumberType].[br][br]
##
## If [param precision] is 0, return string will have 1 significant digit with a
## prepended "~" (e.g., "~1 km" or "~0.5 km"). If [param precision] < 0, return
## will be unformatted [code]str(x)[/code].[br][br]
##
## Returns "NAN" if [param x] is NAN.
func number(x: float, precision := 3, number_type := NumberType.DYNAMIC) -> String:
	const LOG_OF_10 := log(10.0)
	
	if is_nan(x):
		return "NAN"
	
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


## Returns a named number string such as "1.00 Million", "1.00 Billion", etc.,
## when abs(x) >= 1e6. Otherwise, returns the number as a string without decimal places
## (e.g., "999999").[br][br]
##
## Returns "NAN" if [param x] is NAN.
func named_number(x: float, precision := 3, text_format := TextFormat.SHORT_MIXED_CASE
		) -> String:
	# Returns integer string up to '999999', then '1.00 Million', etc.
	const LOG_OF_10 := log(10.0)
	
	if is_nan(x):
		return "NAN"
	
	if abs(x) < 1e6:
		return "%.f" % x
	var exp_3s_index := floori(log(absf(x)) / (LOG_OF_10 * 3.0))
	var lg_num_index := exp_3s_index - 2
	if lg_num_index < 0: # shouldn't happen but just in case
		return "%.f" % x
	if lg_num_index >= _large_number_names_tr.size():
		lg_num_index = _large_number_names_tr.size() - 1
		exp_3s_index = lg_num_index + 2
	x /= pow(10.0, exp_3s_index * 3)
	var lg_number_str: String = _large_number_names_tr[lg_num_index]
	match text_format:
		TextFormat.SHORT_UPPER_CASE, TextFormat.LONG_UPPER_CASE:
			lg_number_str = lg_number_str.to_upper()
		TextFormat.SHORT_LOWER_CASE, TextFormat.LONG_LOWER_CASE:
			lg_number_str = lg_number_str.to_lower()
	return number(x, precision, NumberType.DYNAMIC) + " " + lg_number_str


## This is a wrapper method for [method named_number] that allows attachment
## of [param prefix] or [param suffix], or specification of a value [param multiplier].
## It can be used to generate strings such as "$1.00 Billion", "1.00 Million Species", etc.[br][br]
##
## Returns "NAN" if [param x] is NAN.
func modified_named_number(x: float, precision := 3, text_format := TextFormat.SHORT_MIXED_CASE,
		prefix := "", suffix := "", multiplier := 1.0) -> String:
	if is_nan(x):
		return "NAN"
	return prefix + named_number(x * multiplier, precision, text_format) + suffix


## Calls a method specified in [member dynamic_unit_callables]. For example,
## [param dynamic_name] == &"length_m_km_au_prefixed_pc" will result in
## quantity strings with units "m", "km", "au", "pc", "kpc", "Mpc", "Gpc", etc.
## (or "Meters", "Kilometers", ...). See code for available dynamic formats.[br][br]
##
## The numerical part of the quantity string will be formatted as in [method number].[br][br]
##
## Returns "NAN" if [param x] is NAN.
func dynamic_unit(x: float, dynamic_name: StringName, precision := 3,
		number_type := NumberType.DYNAMIC, text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	assert(dynamic_unit_callables.has(dynamic_name))
	if is_nan(x):
		return "NAN"
	var callable := dynamic_unit_callables[dynamic_name]
	return callable.call(x, precision, number_type, text_format)


## Returns a formatted quantity string with a fixed unit as specified.[br][br]
##
## The numerical part of the quantity string will be formatted as in [method number].[br][br]
##
## Returns "NAN" if [param x] is NAN.
func fixed_unit(x: float, unit: StringName, precision := 3,
		number_type := NumberType.DYNAMIC, text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	if is_nan(x):
		return "NAN"
	
	x = IVQConvert.from_internal(x, unit)
	var number_str := number(x, precision, number_type)
	
	var unit_str: String
	var is_space := true
	
	match text_format:
		TextFormat.LONG_MIXED_CASE, TextFormat.LONG_UPPER_CASE, TextFormat.LONG_LOWER_CASE:
			if _long_forms_tr.has(unit):
				unit_str = _long_forms_tr[unit]
				if text_format == TextFormat.LONG_UPPER_CASE:
					unit_str = unit_str.to_upper()
				elif text_format == TextFormat.LONG_LOWER_CASE:
					unit_str = unit_str.to_upper()
	
	if !unit_str:
		is_space = !unspaced_units.has(unit)
		unit_str = short_forms[unit] if short_forms.has(unit) else String(unit)
	
	if is_space:
		return number_str + " " + unit_str
	return number_str + unit_str


## Returns a formatted quantity string with a dynamically prefixed unit.
## For example, with [param unit] == &"Hz", the return might be "1.00 Hz", "1.00 kHz",
## "1.00 MHz", "1.00 Hertz", "1.00 Kilohertz", or "1.00 Megahertz" (depending on other
## parameters).[br][br]
##
## Don't call with an already-prefixed unit such as "kg" (use "g" instead)
## or any composite unit where the leading unit has a power other than one
## (e.g., "m^3"). The result will look weird in the former case (e.g., "1.00 kkg")
## and be be wrong in the latter case (e.g., 1000.0 m^3 might be displayed as
## "1.00 km^3").[br][br]
##
## The numerical part of the quantity string will be formatted as in [method number].[br][br]
##
## Returns "NAN" if [param x] is NAN.
func prefixed_unit(x: float, unit: StringName, precision := 3,
		number_type := NumberType.DYNAMIC, text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	const LOG_OF_10 := log(10.0)
	
	if is_nan(x):
		return "NAN"
	if unit:
		x = IVQConvert.from_internal(x, unit)
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
			if _long_forms_tr.has(unit):
				unit_str = _long_forms_tr[unit]
				var prefix_name: String = prefix_names[si_index]
				if text_format == TextFormat.LONG_MIXED_CASE:
					if prefix_name != "":
						unit_str = prefix_name + unit_str.to_lower()
				elif text_format == TextFormat.LONG_UPPER_CASE:
					unit_str = (prefix_name + unit_str).to_upper()
				elif text_format == TextFormat.LONG_LOWER_CASE:
					unit_str = (prefix_name + unit_str).to_lower()
	
	if !unit_str:
		is_space = !unspaced_units.has(unit)
		var prefix_symbol: String = prefix_symbols[si_index]
		if short_forms.has(unit):
			unit_str = prefix_symbol + short_forms[unit]
		else:
			unit_str = prefix_symbol + String(unit)

	if is_space:
		return number_str + " " + unit_str
	return number_str + unit_str


## Returns a latitude-longitude string in format specified by [param lat_lon_type].
## See [member LatitudeLongitudeType]. Assumes internal use of radians.
func latitude_longitude(lat_lon: Vector2, decimal_pl := 0,
		lat_lon_type := LatitudeLongitudeType.N_S_E_W, text_format := TextFormat.SHORT_MIXED_CASE
		) -> String:
	return (latitude(lat_lon[0], decimal_pl, lat_lon_type, text_format) + " "
			+ longitude(lat_lon[1], decimal_pl, lat_lon_type, text_format))


## Returns a latitude string in format specified by [param lat_lon_type].
## See [member LatitudeLongitudeType]. Assumes internal use of radians.
func latitude(x: float, decimal_pl := 0, lat_lon_type := LatitudeLongitudeType.N_S_E_W,
		text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	const N_S_E_W := LatitudeLongitudeType.N_S_E_W
	const LAT_LONG := LatitudeLongitudeType.LAT_LONG
	const SHORT_MIXED_CASE := TextFormat.SHORT_MIXED_CASE
	const SHORT_UPPER_CASE := TextFormat.SHORT_UPPER_CASE
	const SHORT_LOWER_CASE := TextFormat.SHORT_LOWER_CASE
	const LONG_UPPER_CASE := TextFormat.LONG_UPPER_CASE
	const LONG_LOWER_CASE := TextFormat.LONG_LOWER_CASE
	const SHORT_FORMS: Array[TextFormat] = [SHORT_MIXED_CASE, SHORT_UPPER_CASE, SHORT_LOWER_CASE]
	
	x = rad_to_deg(x)
	
	var short_form := SHORT_FORMS.has(text_format)
	var suffix: String
	if lat_lon_type == N_S_E_W:
		if x > -0.0001: # prefer N if nearly 0 after conversion
			suffix = _tr[&"TXT_NORTH_SHORT"] if short_form else _tr[&"TXT_NORTH"]
		else:
			suffix = _tr[&"TXT_SOUTH_SHORT"] if short_form else _tr[&"TXT_SOUTH"]
		x = abs(x)
	elif lat_lon_type == LAT_LONG:
		suffix = _tr[&"TXT_LATITUDE_SHORT"] if short_form else _tr[&"TXT_LATITUDE"]
	else: # PITCH_YAW
		suffix = _tr[&"TXT_PITCH"]
	
	match text_format:
		LONG_UPPER_CASE, SHORT_UPPER_CASE:
			suffix = suffix.to_upper()
		LONG_LOWER_CASE:
			suffix = suffix.to_lower()
		SHORT_LOWER_CASE:
			if lat_lon_type != N_S_E_W: # don't lower case N, S
				suffix = suffix.to_lower()
	
	return "%.*f\u00B0 %s" % [decimal_pl, x, suffix]


## Returns a longitude string in format specified by [param lat_lon_type].
## See [member LatitudeLongitudeType]. Assumes internal use of radians.
func longitude(x: float, decimal_pl := 0, lat_lon_type := LatitudeLongitudeType.N_S_E_W,
		text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	const N_S_E_W := LatitudeLongitudeType.N_S_E_W
	const LAT_LONG := LatitudeLongitudeType.LAT_LONG
	const SHORT_MIXED_CASE := TextFormat.SHORT_MIXED_CASE
	const SHORT_UPPER_CASE := TextFormat.SHORT_UPPER_CASE
	const SHORT_LOWER_CASE := TextFormat.SHORT_LOWER_CASE
	const LONG_UPPER_CASE := TextFormat.LONG_UPPER_CASE
	const LONG_LOWER_CASE := TextFormat.LONG_LOWER_CASE
	const SHORT_FORMS: Array[TextFormat] = [SHORT_MIXED_CASE, SHORT_UPPER_CASE, SHORT_LOWER_CASE]
	
	x = rad_to_deg(x)
	
	var short_form := SHORT_FORMS.has(text_format)
	var suffix: String
	if lat_lon_type == N_S_E_W:
		if x > -0.0001 and x < 179.9999: # nearly 0 is E; nearly 180 is W
			suffix = _tr[&"TXT_EAST_SHORT"] if short_form else _tr[&"TXT_EAST"]
		else:
			suffix = _tr[&"TXT_WEST_SHORT"] if short_form else _tr[&"TXT_WEST"]
		x = abs(x)
	elif lat_lon_type == LAT_LONG:
		x = wrapf(x, 0.0, 360.0)
		suffix = _tr[&"TXT_LONGITUDE_SHORT"] if short_form else _tr[&"TXT_LONGITUDE"]
	else: # PITCH_YAW
		suffix = _tr[&"TXT_YAW"]
	
	match text_format:
		LONG_UPPER_CASE, SHORT_UPPER_CASE:
			suffix = suffix.to_upper()
		LONG_LOWER_CASE:
			suffix = suffix.to_lower()
		SHORT_LOWER_CASE:
			if lat_lon_type != LatitudeLongitudeType.N_S_E_W: # don't lower case E, W
				suffix = suffix.to_lower()
	
	return "%.*f\u00B0 %s" % [decimal_pl, x, suffix]
