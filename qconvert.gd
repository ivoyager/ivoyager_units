# qconvert.gd
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

## Singleton "IVQConvert" provides API for conversion of quantities to or from
## internal units.
##
## Dictionaries [member unit_multipliers] and [member unit_lambdas] must be
## specified if different than [IVUnits] dictionaries.[br][br]
##
## Methods can parse compound units such as "m/s^2" assuming relevant simple
## units (e.g., "m" and "s") are present in [member unit_multipliers]. See
## [method get_parsed_unit_multiplier] for parsing details. When calling 
## [method internalize_quantity] or [method externalize_quantity], parsed
## compound units are memoized for fast subsequent usage. 


var unit_multipliers: Dictionary[StringName, float] = IVUnits.unit_multipliers
var unit_lambdas: Dictionary[StringName, Callable] = IVUnits.unit_lambdas


## Tests whether [param unit] is valid for [method internalize_quantity] or
## [method externalize_quantity].
func is_valid_unit(unit: StringName, parse_compound_unit := false) -> bool:
	return !is_nan(internalize_quantity(1.0, unit, parse_compound_unit, false))


## Converts quantity [param x] in specified [param unit] to internal units as specified
## by [member unit_multipliers] and [member unit_lambdas]. Will attempt to parse
## a compound [param unit] if [param parse_compound_unit] == true. Throws an error if
## [param unit] is not present in conversion dictionaries or can't be parsed,
## or returns NAN if [param assert_error] == false.[br][br]
##
## If [param unit] is in [member unit_multipliers] or [member unit_lambdas],
## then no parsing is attempted. Dictionary [member unit_multipliers] may have
## compound units like "m/s^2" pre-added for quick lookup without parsing.[br][br]
##
## If a compound unit string is successfully parsed, then the compound unit name
## and resulting multiplier will be memoized by added to [member unit_multipliers]
## as a key-value pair for subsequent lookup.[br][br]
##
## See parsing comments in [method get_parsed_unit_multiplier].
func internalize_quantity(x: float, unit: StringName, parse_compound_unit := true,
		assert_error := true) -> float:
	if !unit:
		return x
	var multiplier: float = unit_multipliers.get(unit, 0.0)
	if multiplier:
		return x * multiplier
	if unit_lambdas.has(unit):
		var lambda := unit_lambdas[unit]
		return lambda.call(x, true)
	if !parse_compound_unit:
		assert(!assert_error, "'%s' is not in unit_multipliers or unit_lambdas" % unit)
		return NAN
	multiplier = get_parsed_unit_multiplier(unit, assert_error)
	unit_multipliers[unit] = multiplier # memoize!
	return x * multiplier


## Inverse of [method internalize_quantity]. Converts an internal quantity [param x]
## to an external quantity (e.g., for GUI display) in specified [param unit].
## Additional args are as in [method internalize_quantity].
func externalize_quantity(x: float, unit: StringName, parse_compound_unit := true,
		assert_error := true) -> float:
	if !unit:
		return x
	var multiplier: float = unit_multipliers.get(unit, 0.0)
	if multiplier:
		return x / multiplier
	if unit_lambdas.has(unit):
		var lambda := unit_lambdas[unit]
		return lambda.call(x, false)
	if !parse_compound_unit:
		assert(!assert_error, "'%s' is not in unit_multipliers or unit_lambdas" % unit)
		return NAN
	multiplier = get_parsed_unit_multiplier(unit, assert_error)
	unit_multipliers[unit] = multiplier # memoize!
	return x / multiplier



## @depricate
func convert_quantity(x: float, unit: StringName, to_internal := true,
		parse_compound_unit := true, assert_error := true) -> float:
	if !unit:
		return x
	
	var multiplier: float = unit_multipliers.get(unit, 0.0)
	if multiplier:
		return x * multiplier if to_internal else x / multiplier
	
	if unit_lambdas.has(unit):
		var lambda := unit_lambdas[unit]
		return lambda.call(x, to_internal)
	
	if !parse_compound_unit:
		assert(!assert_error,
				"'%s' is not in unit_multipliers or unit_lambdas dictionaries" % unit)
		return NAN
	
	multiplier = get_parsed_unit_multiplier(unit, assert_error)
	
	unit_multipliers[unit] = multiplier # for direct access in subsequent usage!
	
	return x * multiplier if to_internal else x / multiplier


## Parses compound unit strings. Valid examples include "m/s^2", "m^3/(kg s^2)",
## "1e24", "10^24", "10^24 kg", "1/d", "d^-1" and "m^0.5" (assuming that
## "m", "kg", "s", and "d" are present in [member unit_multipliers]).[br][br]
##
## Does NOT attempt to parse unit prefixes such as "k" in "km" ("km"
## would have to be present in [member unit_multipliers] to use).[br][br]
##
## Throws an error if [param unit_str] can't be parsed (or returns NAN if
## [param assert_error] == false).[br][br]
##
## Parser rules:[br][br]
##
##   1. The compound unit string must be composed only of valid multiplier
##      units (i.e., keys in [member unit_multipliers]), valid float numbers,
##      unit operators, and opening and closing parentheses: "(", ")".[br]
##   2. Allowed unit operatiors are "^", "/", and " ", corresponding to
##      exponentiation, division and multiplication, in that order of precedence.[br]
##   3. Spaces are ONLY allowed as multiplication operators![br]
##   4. Operators must have a valid non-operator substring on each side without
##      adjacent spaces.[br]
##   5. Each parenthesis opening "(" must have a closing ")".
func get_parsed_unit_multiplier(unit_str: String, assert_error := true) -> float:
	
	# debug print unit strings & substrings at each recursion
	# print(unit_str)
	
	if !unit_str:
		assert(!assert_error, "Empty unit string or substring. This could be caused by a"
				+ " disallowed space that is not a multiplication operator.")
		return NAN
	
	var multiplier: float = unit_multipliers.get(unit_str, 0.0)
	if multiplier:
		return multiplier
	
	if unit_str.is_valid_float():
		return unit_str.to_float()
	
	var length := unit_str.length()
	var position := 0
	var enclosure_level := 0
	
	# check for matching enclosure parentheses
	if unit_str[0] == "(":
		position = 1
		enclosure_level = 1
		while position < length:
			var chr := unit_str[position]
			if chr == "(":
				enclosure_level += 1
			elif chr == ")":
				enclosure_level -= 1
				if enclosure_level == 0:
					if position == length - 1:
						return get_parsed_unit_multiplier(
								unit_str.trim_prefix("(").trim_suffix(")"), assert_error)
					break # opening '(' matched before the end
				if enclosure_level < 0:
					assert(!assert_error,
							"Unmatched ')' in unit string or substring '%s'" % unit_str)
					return NAN
			position += 1
	
	# multiply two parts on non-enclosed " "
	if unit_str.find(" ") != -1:
		position = 0
		enclosure_level = 0
		while position < length:
			var chr := unit_str[position]
			if chr == "(":
				enclosure_level += 1
			elif chr == ")":
				enclosure_level -= 1
			elif chr == " " and enclosure_level == 0:
				return (get_parsed_unit_multiplier(unit_str.left(position), assert_error)
						* get_parsed_unit_multiplier(unit_str.substr(position + 1), assert_error))
			position += 1
	
	# divide two parts on non-enclosed "/"
	if unit_str.find("/") != -1:
		position = 0
		enclosure_level = 0
		while position < length:
			var chr := unit_str[position]
			if chr == "(":
				enclosure_level += 1
			elif chr == ")":
				enclosure_level -= 1
			elif chr == "/" and enclosure_level == 0:
				return (get_parsed_unit_multiplier(unit_str.left(position), assert_error)
						/ get_parsed_unit_multiplier(unit_str.substr(position + 1), assert_error))
			position += 1
	
	# exponentiate two parts on non-enclosed "^"
	if unit_str.find("^") != -1:
		position = 0
		enclosure_level = 0
		while position < length:
			var chr := unit_str[position]
			if chr == "(":
				enclosure_level += 1
			elif chr == ")":
				enclosure_level -= 1
			elif chr == "^" and enclosure_level == 0:
				return pow(get_parsed_unit_multiplier(unit_str.left(position), assert_error),
						 get_parsed_unit_multiplier(unit_str.substr(position + 1), assert_error))
			position += 1
	
	assert(!assert_error, "Could not parse unit string or substring '%s'" % unit_str)
	return NAN
