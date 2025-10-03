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

## Singleton [IVQConvert] provides API for conversion of unit quantities to and
## from a consistent internal unit standard.
##
## Dictionaries [member unit_multipliers] and [member unit_lambdas] must be
## specified if different than [IVUnits] dictionaries.[br][br]
##
## Methods can parse compound units such as "m^3/(kg s^2)" assuming relevant
## simple units ("m", "kg" and "s") are present in [member unit_multipliers].
## See [method get_parsed_unit_multiplier] for parsing details. By default,
## methods will memoize parsed compound units for faster subsequent usage. 


## See [member IVUnits.unit_multipliers].
var unit_multipliers: Dictionary[StringName, float] = IVUnits.unit_multipliers
## See [member IVUnits.unit_lambdas].
var unit_lambdas: Dictionary[StringName, Callable] = IVUnits.unit_lambdas


## Tests whether [param unit] is valid for [method to_internal] or
## [method from_internal].[br][br]
##
## If a compound unit string is successfully parsed, then the compound unit name
## and resulting multiplier will be memoized by adding to [member unit_multipliers]
## as a key-value pair for subsequent lookup. (To disable, set
## [param memoize_parsed_unit] to false.)[br][br]
##
## See parsing comments in [method get_parsed_unit_multiplier].
func is_valid_unit(unit: StringName, parse_compound_unit := true, memoize_parsed_unit := true
		) -> bool:
	if !unit or unit_multipliers.has(unit) or unit_lambdas.has(unit):
		return true
	if !parse_compound_unit:
		return false
	var multiplier := get_parsed_unit_multiplier(unit, false)
	if is_nan(multiplier):
		return false
	if memoize_parsed_unit:
		unit_multipliers[unit] = multiplier
	return true


## Parses and adds a compound unit to [member unit_multipliers] if it isn't
## already present. This is only needed if accessing [member unit_multipliers]
## directly without [method to_internal] or [method from_internal], as these
## methods will parse and memoize compound units by default.[br][br]
##
## See parsing comments in [method get_parsed_unit_multiplier].
func include_compound_unit(unit: StringName, allow_assert := true) -> void:
	if !unit or unit_multipliers.has(unit):
		return
	var multiplier := get_parsed_unit_multiplier(unit, allow_assert)
	if !is_nan(multiplier):
		unit_multipliers[unit] = multiplier


## Converts quantity [param x] in specified [param unit] to internal units as specified
## by [member unit_multipliers] and [member unit_lambdas]. Will attempt to parse
## a compound unit unless [param parse_compound_unit] is false.[br][br]
##
## Throws an error if [param unit] is not present in conversion dictionaries or
## can't be parsed. Or returns NAN if [param allow_assert] is false.[br][br]
##
## If a compound unit string is successfully parsed, then the compound unit string
## and derived multiplier will be memoized by adding to [member unit_multipliers]
## as a key-value pair for subsequent lookup. (To disable, set
## [param memoize_parsed_unit] to false.)[br][br]
##
## See parsing comments in [method get_parsed_unit_multiplier].
func to_internal(x: float, unit: StringName, parse_compound_unit := true,
		memoize_parsed_unit := true, allow_assert := true) -> float:
	if !unit:
		return x
	var multiplier: float = unit_multipliers.get(unit, 0.0)
	if multiplier:
		return x * multiplier
	if unit_lambdas.has(unit):
		var lambda := unit_lambdas[unit]
		return lambda.call(x, true)
	if !parse_compound_unit:
		assert(!allow_assert, "'%s' is not in unit_multipliers or unit_lambdas" % unit)
		return NAN
	multiplier = get_parsed_unit_multiplier(unit, allow_assert)
	if memoize_parsed_unit and !is_nan(multiplier):
		unit_multipliers[unit] = multiplier
	return x * multiplier


## Inverse of [method to_internal]. Converts an internal quantity [param x]
## to an external quantity in specified [param unit] (e.g., for GUI display).
## Additional args are as in [method to_internal].
func from_internal(x: float, unit: StringName, parse_compound_unit := true,
		memoize_parsed_unit := true, allow_assert := true) -> float:
	if !unit:
		return x
	var multiplier: float = unit_multipliers.get(unit, 0.0)
	if multiplier:
		return x / multiplier
	if unit_lambdas.has(unit):
		var lambda := unit_lambdas[unit]
		return lambda.call(x, false)
	if !parse_compound_unit:
		assert(!allow_assert, "'%s' is not in unit_multipliers or unit_lambdas" % unit)
		return NAN
	multiplier = get_parsed_unit_multiplier(unit, allow_assert)
	if memoize_parsed_unit and !is_nan(multiplier):
		unit_multipliers[unit] = multiplier
	return x / multiplier


## Parses compound unit strings and returns a compound unit multiplier. Valid
## [param unit_str] examples include "m/s^2", "m^3/(kg s^2)",
## "1e24", "10^24", "10^24 kg", "1/d", "d^-1" and "m^0.5" (assuming that
## "m", "kg", "s", and "d" are present in [member unit_multipliers]).[br][br]
##
## Does NOT attempt to parse unit prefixes such as "k" in "km".[br][br]
##
## Throws an error if [param unit_str] can't be parsed. Or returns NAN if
## [param allow_assert] is false.[br][br]
##
## Parser rules:[br][br]
##
##   1. The compound unit string must be composed only of multiplier
##      units (i.e., keys in [member unit_multipliers]), float numbers,
##      unit operators, and opening and closing parentheses: "(", ")".[br]
##   2. Allowed unit operatiors are "^", "/", and " ", corresponding to
##      exponentiation, division and multiplication, in that order of precedence.[br]
##   3. Spaces are ONLY allowed as multiplication operators![br]
##   4. Operators must have a valid non-operator substring on each side without
##      adjacent spaces.[br]
##   5. Each parenthesis opening "(" must have a closing ")".
func get_parsed_unit_multiplier(unit_str: String, allow_assert := true) -> float:
	
	# debug print unit strings & substrings at each recursion...
	# print(unit_str)
	
	if !unit_str:
		assert(!allow_assert, "Empty unit string or substring. This could be caused by a"
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
								unit_str.trim_prefix("(").trim_suffix(")"), allow_assert)
					break # opening '(' matched before the end
				if enclosure_level < 0:
					assert(!allow_assert,
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
				return (get_parsed_unit_multiplier(unit_str.left(position), allow_assert)
						* get_parsed_unit_multiplier(unit_str.substr(position + 1), allow_assert))
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
				return (get_parsed_unit_multiplier(unit_str.left(position), allow_assert)
						/ get_parsed_unit_multiplier(unit_str.substr(position + 1), allow_assert))
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
				return pow(get_parsed_unit_multiplier(unit_str.left(position), allow_assert),
						 get_parsed_unit_multiplier(unit_str.substr(position + 1), allow_assert))
			position += 1
	
	assert(!allow_assert, "Could not parse unit string or substring '%s'" % unit_str)
	return NAN
