# units.gd
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

## Template file for IVUnits singleton
##
## This node is added as singleton "IVUnits". You can replace this singleton by
## creating an override config file in your project directory
## [code]res://ivoyager_override.cfg[/code] (if it doesn't already exist) with
## these lines:
##
## [codeblock]
##
## [units_autoload]
##
## IVUnits="your_replacement_path"
##
## [/codeblock][br]
##
## You can add to or modify dictionaries [member unit_multipliers] and
## [member unit_lambdas] here. However, if you need different base units or
## unit constants, we suggest you replace this singleton as outlined above.[br][br]
##
## See [IVQConvert] for unit quantity conversion API. In short, unit strings are
## first tested in [member unit_multipliers] and then in [member unit_lambdas].
## If not found in either, the unit string may be parsed as a compound unit.
## Parsed compound units may be memoized for faster subsequent usage by adding
## to [member unit_multipliers].[br][br]
##
## See [IVQFormat] for quantity GUI display API. Display symbol is often but
## not always the same as the unit dictionary key.


# SI base units
const SECOND := 1.0
const METER := 1.0
const KG := 1.0
const AMPERE := 1.0
const KELVIN := 1.0
const CANDELA := 1.0

# derived units & constants
const DEG := PI / 180.0 # radians
const MINUTE := 60.0 * SECOND
const HOUR := 3600.0 * SECOND
const DAY := 86400.0 * SECOND # exact Julian day
const YEAR := 365.25 * DAY # exact Julian year
const CENTURY := 36525.0 * DAY
const MM := 1e-3 * METER
const CM := 1e-2 * METER
const KM := 1e3 * METER
const AU := 149597870700.0 * METER
const PARSEC := 648000.0 * AU / PI
const SPEED_OF_LIGHT := 299792458.0 * METER / SECOND
const LIGHT_YEAR := SPEED_OF_LIGHT * YEAR
const STANDARD_GRAVITY := 9.80665 * METER / SECOND ** 2
const GRAM := 1e-3 * KG
const TONNE := 1e3 * KG
const HECTARE := 1e4 * METER ** 2
const LITER := 1e-3 * METER ** 3
const NEWTON := KG * METER / SECOND ** 2
const PASCAL := NEWTON / METER ** 2
const BAR := 1e5 * PASCAL
const ATM := 101325.0 * PASCAL
const JOULE := NEWTON * METER
const ELECTRONVOLT := 1.602176634e-19 * JOULE
const WATT := NEWTON / SECOND
const VOLT := WATT / AMPERE
const COULOMB := SECOND * AMPERE
const WEBER := VOLT * SECOND
const TESLA := WEBER / METER ** 2
const GRAVITATIONAL_CONSTANT := 6.67430e-11 * METER ** 3 / (KG * SECOND ** 2)



## Conversion multipliers for units that are linear with zero-intersect.
## Internal unit symbols must be unique. However, redundant symbol usage can
## be specified for display in [IVQFormat] (e.g., &"g" for gram and &"g0" for
## g-force both display as "g"). 
## Default units are mostly (but not all) SI units that follow:
## [url]https://en.wikipedia.org/wiki/International_System_of_Units[/url].
var unit_multipliers: Dictionary[StringName, float] = {
	# time
	&"s" : SECOND,
	&"min" : MINUTE,
	&"h" : HOUR,
	&"d" : DAY,
	&"a" : YEAR, # Julian year symbol
	&"y" : YEAR,
	&"yr" : YEAR,
	&"Cy" : CENTURY,
	# length
	&"mm" : MM,
	&"cm" : CM,
	&"m" : METER,
	&"km" : KM,
	&"au" : AU,
	&"AU" : AU,
	&"ly" : LIGHT_YEAR,
	&"pc" : PARSEC,
	&"Mpc" : 1e6 * PARSEC,
	# mass
	&"g" : GRAM,
	&"kg" : KG,
	&"t" : TONNE,
	# angle
	&"rad" : 1.0,
	&"deg" : DEG, # IVQFormat displays as °
	# temperature
	&"K" : KELVIN,
	# frequency
	&"Hz" : 1.0 / SECOND,
	&"1/Cy" : 1.0 / CENTURY,
	# area
	&"m^2" : METER ** 2,
	&"km^2" : KM ** 2,
	&"ha" : HECTARE,
	# volume
	&"l" : LITER,
	&"L" : LITER,
	&"m^3" : METER ** 3,
	# velocity
	&"m/s" : METER / SECOND,
	&"km/s" : KM / SECOND,
	&"au/Cy" : AU / CENTURY,
	&"c" : SPEED_OF_LIGHT,
	# acceleration/gravity
	&"m/s^2" : METER / SECOND ** 2,
	&"g0" : STANDARD_GRAVITY, # IVQFormat displays as g
	# angular velocity
	&"rad/s" : 1.0 / SECOND, 
	&"deg/d" : DEG / DAY,
	&"deg/Cy" : DEG / CENTURY,
	# particle density
	&"m^-3" : 1.0 / METER ** 3,
	# density
	&"g/cm^3" : GRAM / CM ** 3,
	# force
	&"N" : NEWTON,
	# pressure
	&"Pa" : PASCAL,
	&"bar" : BAR,
	&"atm" : ATM,
	# energy
	&"J" : JOULE,
	&"kJ" : 1e3 * JOULE,
	&"MJ" : 1e6 * JOULE,
	&"GJ" : 1e9 * JOULE,
	&"Wh" : WATT * HOUR,
	&"kWh" : 1e3 * WATT * HOUR,
	&"MWh" : 1e6 * WATT * HOUR,
	&"GWh" : 1e9 * WATT * HOUR,
	&"eV" : ELECTRONVOLT,
	# power
	&"W" : WATT,
	&"kW" : 1e3 * WATT,
	&"MW" : 1e6 * WATT,
	&"GW" : 1e9 * WATT,
	# luminous intensity / luminous flux
	&"cd" : CANDELA,
	&"lm" : CANDELA, # 1 lm = 1 cd·sr, but sr is dimensionless
	# luminance
	&"cd/m^2" : CANDELA / METER ** 2,
	# electric potential
	&"V" : VOLT,
	# electric charge
	&"C" :  COULOMB,
	# magnetic flux
	&"Wb" : WEBER,
	# magnetic flux density
	&"T" : TESLA,
	# information
	&"bit" : 1.0,
	&"B" : 8.0,
	# information (base 10)
	&"kbit" : 1e3,
	&"Mbit" : 1e6,
	&"Gbit" : 1e9,
	&"Tbit" : 1e12,
	&"kB" : 8e3,
	&"MB" : 8e6,
	&"GB" : 8e9,
	&"TB" : 8e12,
	# information (base 2)
	&"Kibit" : 1024.0,
	&"Mibit" : 1024.0 ** 2,
	&"Gibit" : 1024.0 ** 3,
	&"Tibit" : 1024.0 ** 4,
	&"KiB" : 8.0 * 1024.0,
	&"MiB" : 8.0 * 1024.0 ** 2,
	&"GiB" : 8.0 * 1024.0 ** 3,
	&"TiB" : 8.0 * 1024.0 ** 4,
	# misc
	&"percent" : 100.0, # e.g., display x = 0.55 as "55%" (see IVQFormat)
	&"ppm" : 1e6,
	&"ppb" : 1e9,
}

## Conversion lambdas for units that are nonlinear or have non-zero intersect
## (e.g., celsius and fahrenheit). All lambdas must have method signature
## [code](x: float, to_internal: bool)[/code] where [param x] is the quantity
## and [param to_internal] specifies conversion to internal (true) or from
## internal (false).
var unit_lambdas: Dictionary[StringName, Callable] = {
	&"degC" : func convert_celsius(x: float, to_internal: bool) -> float:
		# Assumes Kelvin is the internal unit.
		return x + 273.15 if to_internal else x - 273.15,
	&"degF" : func convert_fahrenheit(x: float, to_internal: bool) -> float:
		# Assumes Kelvin is the internal unit.
		return  (x + 459.67) / 1.8 if to_internal else x * 1.8 - 459.67,
}
