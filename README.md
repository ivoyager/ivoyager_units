# I, Voyager - Units

The plugin provides unit conversion and quantity string formatting via singletons. It can handle all SI, some non-SI, and user-added units, and can parse compound units like "m^3/(kg s^2)". It also converts internal quantities to strings like "1.50 x 10^8 km" (with fixed or dynamic units) or "8.2 Billion Humans" for GUI display.

This plugin can be used with our [Tables plugin](https://github.com/ivoyager/ivoyager_tables) to read and convert text file tables that include float values with units.

(Note: This plugin resulted from splitting the now-depreciated "Table Importer" plugin into "Tables" and "Units".)

## Installation

Find more detailed instructions at our [Developers Page](https://www.ivoyager.dev/developers/).

The plugin directory "ivoyager_units" should be added _directly to your addons directory_. You can do this one of two ways:

1. Download and extract the plugin, then add it (in its entirety) to your addons directory, creating an "addons" directory in your project if needed.
2. (Recommended) Add as a git submodule. From your project directory, use git command:  
	`git submodule add https://github.com/ivoyager/ivoyager_units addons/ivoyager_units`  
	This method will allow you to version-control the plugin from within your project rather than moving directories manually. You'll be able to pull updates, checkout any commit, or submit pull requests back to us. This does require some learning to use git submodules. (We use [GitKraken](https://www.gitkraken.com/) to make this easier!)

Then enable "I, Voyager - Units" from Project / Project Settings / Plugins.

## Usage

We recommend using a consistant set of units internally and convert unit-quantities only "on the way in" (e.g., specifying quantities in file header variables or constants) and "on the way out" (i.e., for GUI display). 

The plungin has three singletons to facilitate this:

#### [IVUnits](https://github.com/ivoyager/ivoyager_units/blob/master/units.gd)

This singleton defines base and derived units in constants and in two dictionaries. The plugin provides an easy way to replace this singleton if different constants are needed. 

Unit constants are convenient for coding quantities in your project files. For example, you can directly code quantity constants like `const TIME_INTERVAL = 10.0 * IVUnits.DAY` or `const MARS_PERIHELION = 1.3814 * IVUnits.AU`. The default singleton file includes constants for the six base SI units (SECOND, METER, KG, AMPERE, KELVIN, CANDELA) and many derived units.

In some projects it may be necessary to change constants, e.g., for a distance scale different than METER = 1.0. To do so, you can direct the plugin to load a different singleton file by including a project level config file "res://ivoyager_override.cfg" with the following section content:

```
[units_autoload]

IVUnits="<path to replacement file>"
```

The singleton provides two dictionaries: "unit_multipliers" and "unit_lambdas". The first includes a large set of multiplier values keyed by unit symbols (some with alternatives) such as "s", "min", "h", "d", "y", "yr", "a", "Cy", "mm", "cm", "m", "km", "au", "AU", "ly", "pc", "Mpc", etc. The second includes conversion lambdas keyed by non-multiplier units including "C" and "F". The dictionaries are used by the unit conversion method in IVQConvert and can be referenced directly. User can add units to these dictionaries as needed.

#### [IVQConvert](https://github.com/ivoyager/ivoyager_units/blob/master/qconvert.gd)

This singleton provides a conversion method `convert_quantity(x: float, unit: StringName, to_internal := true, parse_compound_unit := true, assert_error := true) -> float` and a valid unit test method `is_valid_unit(unit: StringName, parse_compound_unit := true) -> bool`.

The methods use member dictionaries `unit_multipliers` and `unit_lambdas`, which are set to the two IVUnits dictionaries by default.  If parse_compound_unit == true, the methods will handle previously undefined compound units like "m^3/(kg s^2)". The parsed unit StringName will be memoized by adding to `unit_multipliers` for faster subsequent usage.

Compound unit parsing follows these rules:

1. The compound unit string must be composed only of valid multiplier units (i.e., keys in `unit_multipliers` dictionary), valid float numbers, allowed unit operators, and parentheses "(" and ")".
2. Allowed unit operatiors, in order of precidence, are "^", "/", and " " (exponentiation, division, and multiplication, repectively). Spaces are ONLY allowed as multiplication operators.
3. Each parenthesis opening "(" must have a closing ")".
4. The unit parser does *not* interpret SI unit prefixes. So units like "mm", "cm", "m" and "km" must exist as individual keys in `unit_multipliers`.

The following strings are valid for unit parsing:

* "m/s^2"
* "m^3/(kg s^2)"
* "1e24"
* "10^24"
* "10^24 kg"
* "1/d"
* "d^-1"
* "m^0.5"

#### [IVQFormat](https://github.com/ivoyager/ivoyager_units/blob/master/qformat.gd)

This singleton provides methods for quantity conversion to strings for GUI display. User can specify the display unit, number format (e.g., scientific or dynamic), significant digits and other details.

`prefixed_unit()` generates quantity-unit strings with dynamically prefixed base units, e.g., "1.0 kW", "1.0 MW", "1.0 GW", "1.0 TW", etc. The function selects the appropriate 3-order prefix all the way from "q" (10^-30) to "Q" (10^30).

`dynamic_unit()` allows dynamic selection of unit depending on the size of the value. E.g., in one mode of operation, it will use "m", "km", "au" or "parsec" (whichever is appropriate) to generage a length string.

`named_number()` allows dynamic creation of named numbers such as "999 Million" or "1.00 Billion" (up to "x Decillion").

See file [API](https://github.com/ivoyager/ivoyager_units/blob/master/qformat.gd) for all formatting options.
