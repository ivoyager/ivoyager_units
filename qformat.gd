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

## Singleton IVQFormat provides API for formatting numbers and unit quantities
## for GUI display.
##
## Methods here use [IVQConvert] for unit conversions, which assumes (and
## helps ensure) that the calling project uses consistant internal units.[br][br]
## 
## If using named numbers or "long form" units, you'll need to add translations
## to your project. An Engligh translation is included in the plugin in file
## [code]ivoyager_units/text/unit_numbers_text.en.translation[/code].[br][br]
##
## Some array and dictionary properties require a [method reset] call after
## modifying; see property comments. [method reset] is also required if language
## changes at runtime.



## Specifies use of unit symbols or full unit names, and text case.
## Note that case is never altered in unit symbols.
enum TextFormat {
	# WARNING: Some code assumes first 3 are "short".
	SHORT_MIXED_CASE, ## Examples: "1.00 Million", "1.00 kHz".
	SHORT_UPPER_CASE, ## Examples: "1.00 MILLION", "1.00 kHz".
	SHORT_LOWER_CASE, ## Examples: "1.00 million", "1.00 kHz".
	LONG_MIXED_CASE, ## Examples: "1.00 Million", "1.00 Kilohertz".
	LONG_UPPER_CASE, ## Examples: "1.00 MILLION", "1.00 KILOHERTZ".
	LONG_LOWER_CASE, ## Examples: "1.00 million", "1.00 kilohertz".
}

## Defines number format and the meaning of [param precision] in method calls.
## Note that precision always means significant digits (NOT decimal places)
## except in the case of DECIMAL_PLACES.
enum NumberType {
	## Scientific notation if absolute value is greater than [member dynamic_large]
	## or less than [member dynamic_small]. Otherwise, standard numbers with
	## zeros after the decimal as needed for precision. E.g., "1.00" with precision 3.
	## Allows over-precision in the case of non-scientific whole numbers. E.g.,
	## "555555" rather than "556000" with precision 3.
	DYNAMIC,
	## Scientific notation with significant digits as specified by precision.
	SCIENTIFIC,
	## Standard (non-scientific) numbers with zeros after the decimal as
	## needed for precision. E.g., "1.00" with precision 3.
	## Allows over-precision in the case of whole numbers. E.g.,
	## "555555" rather than "556000" with precision 3.
	MIN_PRECISION,
	## Standard (non-scientific) numbers with zeros as needed for exact precision.
	## E.g., "1.00" or "556000" (not "555555") with precision 3.
	PRECISION,
	## Generates scientific notation as DYNAMIC. In the non-scientific range,
	## generates exact precision as PRECISION.
	DYNAMIC_PRECISION,
	## Decimal representation using "precision" as number of decimal places.
	DECIMAL_PLACES,
}

## Return format for latitude, longitude strings.
enum LatitudeLongitudeType {
	N_S_E_W, ## E.g., "30° S, 30° W"
	LAT_LON, ## E.g., "-30° lat, 330° lon"
	PITCH_YAW, ## E.g., "-30° pitch, -30° yaw"
}


## String for formatting scientific notation. Displays numbers in "9.99e9" format
## by default. Set to " ×10^" for "9.99 ×10^9" instead.
var exponent_str := "e"
## For number_type == [enum NumberType].DYNAMIC, this sets the minimum absolute
## value to format "large" numbers in scientific notation.
var dynamic_large := 99999.5
## For number_type == [enum NumberType].DYNAMIC, this sets the maximum absolute
## value to format "small" numbers in scientific notation.
var dynamic_small := 0.01

## 3rd magnitude prefixes (full names). If modifying, be sure to modify [member prefix_symbols]
## as needed. Note: code requires one array element to be "" for indexing.
##
## Call [method reset] after modifying.
var prefix_names: Array[String] = [ # e-30, ..., e30
	"Quecto", "Ronto", "Yocto", "Zepto", "Atto", "Femto", "Pico", "Nano", "Micro", "Milli",
	"", "Kilo", "Mega", "Giga", "Tera", "Peta", "Exa", "Zetta", "Yotta", "Ronna", "Quetta",
]

## 3rd magnitude prefixes (symbols). If modifying, be sure to modify [member prefix_names]
## as needed. Note: code requires one array element to be "" for indexing.
##
## Call [method reset] after modifying.
var prefix_symbols: Array[String] = [ # e-30, ..., e30
	"q", "r", "y", "z", "a", "f", "p", "n", "µ", "m",
	"", "k", "M", "G", "T", "P", "E", "Z", "Y", "R", "Q",
]

## 3rd magnitude number names as text keys, starting with 1e3.[br][br]
##
## Call [method reset] after modifying.
var large_number_names: Array[StringName] = [
	&"TXT_THOUSAND", 
	&"TXT_MILLION", &"TXT_BILLION", &"TXT_TRILLION", &"TXT_QUADRILLION", &"TXT_QUINTILLION",
	&"TXT_SEXTILLION", &"TXT_SEPTILLION", &"TXT_OCTILLION", &"TXT_NONILLION", &"TXT_DECILLION"
]

## "Long form" unit names as text keys. If a unit is missing here, code will fallback to
## "short form" symbol dictionaries and then to the internal unit StringName itself.[br][br]
##
## Note that you can dynamically prefix any base unit (m, g, Hz, Wh, etc.)
## using [method prefixed_unit]. We have already-prefixed units here
## because it is common to want to display fixed units such as "3.00e9 km".[br][br]
##
## Call [method reset] after modifying.
var unit_names: Dictionary[StringName, StringName] = {
	
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
	# misc
	&"percent" : &"TXT_PERCENT",
	&"ppm" : &"TXT_PPM",
	&"ppb" : &"TXT_PPB",
}

## "Short form" unit symbols with standard spacing. See also [member unspaced_unit_symbols]. 
## This dictionary is needed only where the display symbol differs from
## the internal unit StringName.
var spaced_unit_symbols: Dictionary[StringName, String] = {
	&"g0" : "g", # g-force equivalent can't have same internal symbol as gram
}

## "Short form" unit symbols not preceded by a space, including ° and % as units.
## Note that "1/<unit>" units can be added here so that, for example, unit "1/s"
## will be displayed as "59.94/s" rather than "59.94 1/s".
## See also [member spaced_unit_symbols].
var unspaced_unit_symbols: Dictionary[StringName, String] = {
	&"deg" : "°",
	&"degC" : "°C",
	&"degF" : "°F",
	&"deg/d" : "°/d",
	&"deg/a" : "°/a",
	&"deg/Cy" : "°/Cy",
	&"percent" : "%",
	# Add more "1/<unit>" units as needed. It doesn't matter if they result from
	# compound unit parsing and are not in unit_multipliers at init.
	&"1/s" : "/s",
	&"1/min" : "/min",
	&"1/h" : "/h",
	&"1/d" : "/d",
	&"1/y" : "/y",
	&"1/Cy" : "/Cy",
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


var _n_prefixes: int
var _prefix_offset: int
var _large_number_names_tr: Array[String] = []
var _n_large_number_names: int
var _long_forms_tr: Dictionary[StringName, String] = {}
var _tr: Dictionary[StringName, String] = {}
var _to_localize: Array[StringName] = [&"TXT_NORTH", &"TXT_SOUTH", &"TXT_EAST", &"TXT_WEST",
		&"TXT_LATITUDE", &"TXT_LONGITUDE", &"TXT_PITCH", &"TXT_YAW",
		&"TXT_NORTH_SHORT", &"TXT_SOUTH_SHORT", &"TXT_EAST_SHORT", &"TXT_WEST_SHORT",
		&"TXT_LATITUDE_SHORT", &"TXT_LONGITUDE_SHORT"]


func _ready() -> void:
	reset()
	
	# TODO: More tests...
	
	#print(named_number(-1.5, 3))
	#print(named_number(99.4, 3, TextFormat.SHORT_MIXED_CASE, 50.5))
	#print(named_number(9.9999999e5, 3))
	#print(named_number(1e6, 3))
	#print(named_number(2e6, 3))
	#print(named_number(2e9, 3))
	#print(named_number(2e12, 3))
	#print(named_number(2e15, 3))
	#print(named_number(2e18, 3))
	#print(named_number(-2e37, 3))


## Some array and dictionary properties require a reset() call after modifying;
## see property comments. reset() is also required if language
## changes at runtime.[br][br]
##
## The reason for reset() is for indexing and also for "pre-translation" of
## text keys. All text keys are pre-translated because [method Object.tr]
## throws an error if called on thread (as of Godot 4.5). Pre-translation
## allows calling String-return methods on threads.
func reset() -> void:
	_n_prefixes = prefix_names.size()
	assert(prefix_symbols.size() == _n_prefixes)
	_prefix_offset = prefix_symbols.find("")
	_n_large_number_names = large_number_names.size()
	_large_number_names_tr.resize(_n_large_number_names)
	for i in _n_large_number_names:
		_large_number_names_tr[i] = tr(large_number_names[i])
	for key in unit_names:
		_long_forms_tr[key] = tr(unit_names[key])
	for key in _to_localize:
		_tr[key] = tr(key)



## Returns a number string as specified by [param precision] and [param number_type].
## See [enum NumberType] for format options.[br][br]
##
## If [param precision] is -1, return will be [code]String.num(x)[/code].[br][br]
##
## If [param precision] is 0 and number_type != DECIMAL_PLACES, return string
## will have 1 significant digit with a prepended "~". E.g., "~1 km" or "~0.5 km".[br][br]
##
## Returns "NAN" if [param x] is NAN.
func number(x: float, precision := 3, number_type := NumberType.DYNAMIC) -> String:
	const DYNAMIC := NumberType.DYNAMIC
	const SCIENTIFIC := NumberType.SCIENTIFIC
	const MIN_PRECISION := NumberType.MIN_PRECISION
	const PRECISION := NumberType.PRECISION
	const DECIMAL_PLACES := NumberType.DECIMAL_PLACES
	const LOG_MULTIPLIER := 1.0 / log(10.0)
	const DECIMAL_UNICODE := ord(".")
	
	assert(precision >= -1)
	if is_nan(x):
		return "NAN"
	if number_type == DECIMAL_PLACES or precision == -1:
		return String.num(x, precision)
	
	# approximate "~" prepend for zero precision
	var prepend := ""
	if precision == 0:
		prepend = "~"
		precision = 1
	
	# handle 0.0 case (avoids math error below and we don't want "0.00e0" even if SCIENTIFIC)
	if x == 0.0:
		return "%s%.*f" % [prepend, precision - 1, 0.0] # e.g., "0.00" for precision 3
	
	var abs_x := absf(x)
	var exponent := floori(log(abs_x) * LOG_MULTIPLIER)
	
	# Note: Due to imprecision in equationa above AND to round up below (to 10,
	# 100, etc.), exponent is sometimes one less than it should be. This is
	# handled below where needed.
	
	if (number_type == MIN_PRECISION or number_type == PRECISION
			or (number_type != SCIENTIFIC and abs_x < dynamic_large and abs_x > dynamic_small)):
		var decimal_pl := precision - exponent - 1
		if decimal_pl > 0: # has decimal part
			var number_str := "%.*f" % [decimal_pl, x]
			# Fix excess precision (e.g., 0.999999 w/ precision 3 -> "1.000").
			if number_str[-1] == "0":
				if number_str.remove_char(DECIMAL_UNICODE).lstrip("-0").length() > precision:
					number_str = number_str.left(-1)
			return prepend + number_str
		elif number_type == DYNAMIC or number_type == MIN_PRECISION or decimal_pl == 0:
			return prepend + String.num(x, 0) # whole number
		else: # PRECISION or DYNAMIC_PRECISION whole number w/ too much precision
			return prepend + str(snappedi(x, 10 ** -decimal_pl), 0) # "555000"
	
	# scientific
	var sign_str := "-" if x < 0.0 else ""
	var divisor := 10.0 ** exponent # need float for 0.1, 0.01, ...!
	var mantissa := abs_x / divisor if divisor != 0.0 else 1.0
	var mantissa_str := "%.*f" % [precision - 1, mantissa]
	if mantissa_str.length() > 1 and mantissa_str[1] == "0": # fix "10"
		mantissa_str = "%.*f" % [precision - 1, 1.0]
		exponent += 1
	
	return prepend + sign_str + mantissa_str + exponent_str + str(exponent)


## Returns a named number string such as "1.00 Million", "1.00 Billion", etc.
## Returns small numbers as [method number] with number_type == MIN_PRECISION.[br][br]
##
## [param min_named] is the minimum abs([param x]) to be named (999999.5 by default,
## which accounts for rounding). Set to 999.5 to name numbers starting at
## "Thousand".[br][br]
##
## Returns "NAN" if [param x] is NAN.
func named_number(x: float, precision := 3, text_format := TextFormat.SHORT_MIXED_CASE,
		min_named := 999999.5) -> String:
	const SCIENTIFIC := NumberType.SCIENTIFIC
	const MIN_PRECISION := NumberType.MIN_PRECISION
	const LOG_MULTIPLIER_3_ORDERS := 1.0 / (3.0 * log(10.0))
	
	if is_nan(x):
		return "NAN"
	
	var number_type := MIN_PRECISION # unless we go past "Decillion" below
	
	var abs_x := absf(x)
	if abs_x < min_named:
		return number(x, precision, number_type)
	
	var exponent_triples := floori(log(abs_x) * LOG_MULTIPLIER_3_ORDERS)
	if exponent_triples < 1: # possible due to imprecission in equation above
		exponent_triples = 1
	elif exponent_triples > _n_large_number_names:
		exponent_triples = _n_large_number_names
		number_type = SCIENTIFIC
	x /= 10.0 ** (exponent_triples * 3) # requires float operation! (not int ** int)
	
	# Fix bump up to next triplet due to imprecision and rounding
	if roundi(x) == 1000 and exponent_triples < _n_large_number_names:
		x /= 1000
		exponent_triples += 1
	
	var number_name := _large_number_names_tr[exponent_triples - 1]
	match text_format:
		TextFormat.SHORT_UPPER_CASE, TextFormat.LONG_UPPER_CASE:
			number_name = number_name.to_upper()
		TextFormat.SHORT_LOWER_CASE, TextFormat.LONG_LOWER_CASE:
			number_name = number_name.to_lower()
	
	return number(x, precision, number_type) + " " + number_name


## This is a wrapper method for [method named_number] that allows attachment
## of [param prefix] or [param suffix], or specification of a value [param multiplier].
## It can be used to generate strings such as "$1.00 Billion", "1.00 Million Species",
## etc.[br][br]
##
## Returns "NAN" if [param x] is NAN.
func modified_named_number(x: float, precision := 3, text_format := TextFormat.SHORT_MIXED_CASE,
		prefix := "", suffix := "", multiplier := 1.0) -> String:
	if is_nan(x):
		return "NAN"
	return prefix + named_number(x * multiplier, precision, text_format) + suffix


## Calls a method specified in [member dynamic_unit_callables]. For example,
## [param callable_name] "length_m_km_au_prefixed_pc" will result in quantity
## strings in units m, km, au, pc, kpc, Mpc, Gpc, etc. depending on the size of
## [param x]. See code file for available dynamic unit callables.[br][br]
##
## The numerical part of the quantity string will be formatted as in [method number].[br][br]
##
## Returns "NAN" if [param x] is NAN.
func dynamic_unit(x: float, callable_name: StringName, precision := 3,
		number_type := NumberType.DYNAMIC, text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	assert(dynamic_unit_callables.has(callable_name))
	if is_nan(x):
		return "NAN"
	var callable := dynamic_unit_callables[callable_name]
	return callable.call(x, precision, number_type, text_format)


## Returns a formatted quantity string with a fixed unit as specified.[br][br]
##
## The numerical part of the quantity string will be formatted as in [method number].[br][br]
##
## Returns "NAN" if [param x] is NAN.
func fixed_unit(x: float, unit: StringName, precision := 3,
		number_type := NumberType.DYNAMIC, text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	const LONG_UPPER_CASE := TextFormat.LONG_UPPER_CASE
	const LONG_LOWER_CASE := TextFormat.LONG_LOWER_CASE
	
	if is_nan(x):
		return "NAN"
	
	x = IVQConvert.from_internal(x, unit)
	var number_str := number(x, precision, number_type)
	
	var unit_str: String
	
	if text_format >= 3 and _long_forms_tr.has(unit): # long format
		unit_str = " " + _long_forms_tr[unit]
		if text_format == LONG_UPPER_CASE:
			unit_str = unit_str.to_upper()
		elif text_format == LONG_LOWER_CASE:
			unit_str = unit_str.to_lower()
	
	else: # short format (no case changes)
		if unspaced_unit_symbols.has(unit):
			unit_str = unspaced_unit_symbols[unit]
		elif spaced_unit_symbols.has(unit):
			unit_str = " " + spaced_unit_symbols[unit]
		else:
			unit_str = " " + unit
	
	return number_str + unit_str


## Returns a formatted quantity string with a number (with absolute value
## between "1.00" and "999") and a dynamically prefixed unit. Numbers will be
## less than 1.00 or greater than 999 only if the absolute value goes out of
## range of SI prefixes, currently q (1e-30) to Q (1e30).[br][br]
##
## E.g., unit "m" will generate quantity strings in qm, ..., µm, mm, m, km, Mm, ..., Qm.
## Or use [method dynamic_unit] if you want more control. Don't call with an
## already-prefixed unit such as "km" or you'll see results like "1.00 mkm"
## and "1.00 kkm".[br][br]
##
## Compound units are ok as long as the leading unit has power one. Otherwise,
## the generated string may look ok but be incorrect. E.g., 1000.0 m^3 would
## generate something like "1.00 km^3".[br][br]
##
## The numerical part of the quantity string will be formatted as in [method number].
## Use of DYNAMIC or DYNAMIC_PRECISION makes the most sense here, so that scientific
## notation will happen only for quantities outside the range of SI units.[br][br]
##
## Returns "NAN" if [param x] is NAN.
func prefixed_unit(x: float, unit: StringName, precision := 3,
		number_type := NumberType.DYNAMIC, text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	const LONG_MIXED_CASE := TextFormat.LONG_MIXED_CASE
	const LONG_UPPER_CASE := TextFormat.LONG_UPPER_CASE
	const LOG_MULTIPLIER_3_ORDERS := 1.0 / (3.0 * log(10.0))
	
	if is_nan(x):
		return "NAN"
	if unit:
		x = IVQConvert.from_internal(x, unit)
	var exponent_triples := 0
	if x != 0.0:
		exponent_triples = floori(log(absf(x)) * LOG_MULTIPLIER_3_ORDERS)
	var si_index := exponent_triples + _prefix_offset
	if si_index < 0:
		si_index = 0
		exponent_triples = -_prefix_offset
	elif si_index >= _n_prefixes:
		si_index = _n_prefixes - 1
		exponent_triples = si_index - _prefix_offset
	x /= 10.0 ** (exponent_triples * 3) # possibly negative exponent, need float
	
	var number_str := number(x, precision, number_type)
	if number_str == "1000" and si_index < _n_prefixes - 1:
		# Sometimes get results like "1000 MWh" due to imprecision and round up
		number_str = number(1.0, precision, number_type)
		si_index += 1
	
	var unit_str: String
	
	if text_format >= 3 and _long_forms_tr.has(unit): # long format
		var prefix_name: String = prefix_names[si_index]
		if text_format == LONG_MIXED_CASE:
			if prefix_name == "":
				unit_str = " " + _long_forms_tr[unit]
			else:
				unit_str = " " + prefix_name + _long_forms_tr[unit].to_lower()
		elif text_format == LONG_UPPER_CASE:
			unit_str = " " + (prefix_name + _long_forms_tr[unit]).to_upper()
		else: # LONG_LOWER_CASE
			unit_str = " " + (prefix_name + _long_forms_tr[unit]).to_lower()
	
	else: # short format (no case changes for prefix or symbols)
		var prefix_symbol: String = prefix_symbols[si_index]
		if unspaced_unit_symbols.has(unit):
			if prefix_symbol == "":
				unit_str = unspaced_unit_symbols[unit]
			else: # prefix needs a space!
				unit_str = " " + prefix_symbol + unspaced_unit_symbols[unit]
		elif spaced_unit_symbols.has(unit):
			unit_str = " " + prefix_symbol + spaced_unit_symbols[unit]
		else:
			unit_str = " " + prefix_symbol + unit
	
	return number_str + unit_str


## Returns a latitude-longitude string in degrees (°) in format specified by
## [param lat_lon_type]. See [member LatitudeLongitudeType]. Assumes internal
## use of radians.
func latitude_longitude(lat_lon: Vector2, decimal_pl := 0,
		lat_lon_type := LatitudeLongitudeType.N_S_E_W, text_format := TextFormat.SHORT_MIXED_CASE,
		spacer := " ") -> String:
	const N_S_E_W := LatitudeLongitudeType.N_S_E_W
	const LAT_LON := LatitudeLongitudeType.LAT_LON
	
	var lat := wrapf(rad_to_deg(lat_lon[0]), -180.0, 180.0)
	var lon := rad_to_deg(lat_lon[1])
	var is_short := text_format < 3
	var lat_label: String
	var lon_label: String
	if lat_lon_type == N_S_E_W:
		if lat > -0.0001: # prefer N if nearly 0 after conversion
			lat_label = _tr[&"TXT_NORTH_SHORT"] if is_short else _tr[&"TXT_NORTH"]
		else:
			lat_label = _tr[&"TXT_SOUTH_SHORT"] if is_short else _tr[&"TXT_SOUTH"]
		lat = absf(lat)
		lon = wrapf(lon, -180.0, 180.0)
		if lon > -0.0001 and lon < 179.9999: # nearly 0 is E; nearly 180 is W
			lon_label = _tr[&"TXT_EAST_SHORT"] if is_short else _tr[&"TXT_EAST"]
		else:
			lon_label = _tr[&"TXT_WEST_SHORT"] if is_short else _tr[&"TXT_WEST"]
		lon = absf(lon)
	elif lat_lon_type == LAT_LON:
		lat_label = _tr[&"TXT_LATITUDE_SHORT"] if is_short else _tr[&"TXT_LATITUDE"]
		lon = wrapf(lon, 0.0, 360.0)
		lon_label = _tr[&"TXT_LONGITUDE_SHORT"] if is_short else _tr[&"TXT_LONGITUDE"]
	else: # PITCH_YAW
		lat_label = _tr[&"TXT_PITCH"]
		lon = wrapf(lon, -180.0, 180.0)
		lon_label = _tr[&"TXT_YAW"]
	
	match text_format:
		TextFormat.LONG_UPPER_CASE, TextFormat.SHORT_UPPER_CASE:
			lat_label = lat_label.to_upper()
			lon_label = lon_label.to_upper()
		TextFormat.LONG_LOWER_CASE:
			lat_label = lat_label.to_lower()
			lon_label = lon_label.to_lower()
		TextFormat.SHORT_LOWER_CASE:
			if lat_lon_type != N_S_E_W: # don't lower case N, S, E, W
				lat_label = lat_label.to_lower()
				lon_label = lon_label.to_lower()
	
	return "%.*f° %s%s%.*f° %s" % [decimal_pl, lat, lat_label, spacer, decimal_pl, lon, lon_label]


## Returns a latitude string in degrees (°) in format specified by [param lat_lon_type].
## See [member LatitudeLongitudeType]. Assumes internal use of radians.
func latitude(x: float, decimal_pl := 0, lat_lon_type := LatitudeLongitudeType.N_S_E_W,
		text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	const N_S_E_W := LatitudeLongitudeType.N_S_E_W
	const LAT_LON := LatitudeLongitudeType.LAT_LON
	
	x = rad_to_deg(x)
	x = wrapf(x, -180.0, 180.0)
	var is_short := text_format < 3
	var label: String
	if lat_lon_type == N_S_E_W:
		if x > -0.0001: # prefer N if nearly 0 after conversion
			label = _tr[&"TXT_NORTH_SHORT"] if is_short else _tr[&"TXT_NORTH"]
		else:
			label = _tr[&"TXT_SOUTH_SHORT"] if is_short else _tr[&"TXT_SOUTH"]
		x = absf(x)
	elif lat_lon_type == LAT_LON:
		label = _tr[&"TXT_LATITUDE_SHORT"] if is_short else _tr[&"TXT_LATITUDE"]
	else: # PITCH_YAW
		label = _tr[&"TXT_PITCH"]
	
	match text_format:
		TextFormat.LONG_UPPER_CASE, TextFormat.SHORT_UPPER_CASE:
			label = label.to_upper()
		TextFormat.LONG_LOWER_CASE:
			label = label.to_lower()
		TextFormat.SHORT_LOWER_CASE:
			if lat_lon_type != N_S_E_W: # don't lower case N, S
				label = label.to_lower()
	
	return "%.*f° %s" % [decimal_pl, x, label]


## Returns a longitude string in degrees (°) in format specified by [param lat_lon_type]
## See [member LatitudeLongitudeType]. Assumes internal use of radians.
func longitude(x: float, decimal_pl := 0, lat_lon_type := LatitudeLongitudeType.N_S_E_W,
		text_format := TextFormat.SHORT_MIXED_CASE) -> String:
	const N_S_E_W := LatitudeLongitudeType.N_S_E_W
	const LAT_LON := LatitudeLongitudeType.LAT_LON
	
	x = rad_to_deg(x)
	var is_short := text_format < 3
	var label: String
	if lat_lon_type == N_S_E_W:
		x = wrapf(x, -180.0, 180.0)
		if x > -0.0001 and x < 179.9999: # nearly 0 is E; nearly 180 is W
			label = _tr[&"TXT_EAST_SHORT"] if is_short else _tr[&"TXT_EAST"]
		else:
			label = _tr[&"TXT_WEST_SHORT"] if is_short else _tr[&"TXT_WEST"]
		x = absf(x)
	elif lat_lon_type == LAT_LON:
		x = wrapf(x, 0.0, 360.0)
		label = _tr[&"TXT_LONGITUDE_SHORT"] if is_short else _tr[&"TXT_LONGITUDE"]
	else: # PITCH_YAW
		x = wrapf(x, -180.0, 180.0)
		label = _tr[&"TXT_YAW"]
	
	match text_format:
		TextFormat.LONG_UPPER_CASE, TextFormat.SHORT_UPPER_CASE:
			label = label.to_upper()
		TextFormat.LONG_LOWER_CASE:
			label = label.to_lower()
		TextFormat.SHORT_LOWER_CASE:
			if lat_lon_type != N_S_E_W: # don't lower case E, W
				label = label.to_lower()
	
	return "%.*f° %s" % [decimal_pl, x, label]
