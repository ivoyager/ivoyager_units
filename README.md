# I, Voyager - Units

This plugin helps maintain a consistent internal unit standard when many different units are needed for game data or display. It can handle all SI, some non-SI, and project-added units, and can parse compound units like `m^3/(kg s^2)`. It facilitates definition of quantity constants in class files such as `const TIME_INTERVAL = 10.0 * IVUnits.DAY`. It also converts internal quantities to GUI display strings like "1.50 x 10^8 km" with fixed or dynamic unit selection (including automated SI prefixing) or "8.2 Billion Humans" (using dynamically selected number names) with full specification of significant digits (not just decimal places).

This plugin can be used (optionally) with our [Tables plugin](https://github.com/ivoyager/ivoyager_tables) to read text file tables with unit quantities. When used together, whole column fields and/or individual table cells can have unit specification.

This plugin was developed for our solar system explorer app [Planetarium](https://www.ivoyager.dev/planetarium/) and related projects.


## Installation

Find more detailed instructions at our [Developers Page](https://www.ivoyager.dev/developers/).

The plugin directory "ivoyager_units" should be added _directly to your addons directory_. You can do this one of two ways:

1. Download and extract the plugin, then add it (in its entirety) to your addons directory, creating an "addons" directory in your project if needed.
2. (Recommended) Add as a git submodule. From your project directory, use git command:  
	`git submodule add https://github.com/ivoyager/ivoyager_units addons/ivoyager_units`  
	This method will allow you to version-control the plugin from within your project rather than moving directories manually. You'll be able to pull updates, checkout any commit, or submit pull requests back to us. This does require some learning to use git submodules. (We use [GitKraken](https://www.gitkraken.com/) to make this easier!)

Then enable "I, Voyager - Units" from Project / Project Settings / Plugins.

## Usage

We recommend using a consistant set of units internally. Unit conversion should happen only _on the way in_ (e.g., reading game data from text files or from class file constants) and _on the way out_ (GUI display). 

The plungin has three singletons to facilitate this:

#### [IVUnits](https://github.com/ivoyager/ivoyager_units/blob/master/units.gd)

This singleton defines base and derived units in constants and in two dictionaries. The plugin provides an easy way to replace this singleton if different constants are needed.

Unit constants are convenient for coding quantities in your project files. For example, you can directly code quantity constants like `const TIME_INTERVAL = 10.0 * IVUnits.DAY` or `const MARS_PERIHELION = 1.3814 * IVUnits.AU`. The default singleton file includes constants for the six base SI units (`SECOND`, `METER`, `KG`, `AMPERE`, `KELVIN`, `CANDELA`) and many derived units.

In some projects, it may be necessary or convenient to change constants, e.g., for a distance scale different than `METER = 1.0`. To do so, you can direct the plugin to load a different file as the "IVUnits" singleton (using the plugin file as template). To do so, include a project level config file `res://ivoyager_override.cfg` with the following section content:

```
[units_autoload]

IVUnits="<path to replacement file>"
```

The singleton provides two dictionaries: `unit_multipliers` and `unit_lambdas`. The first includes a large set of multiplier values keyed by unit symbols (some alternatives for the same unit) such as `s`, `min`, `h`, `d`, `y`, `yr`, `a`, `Cy`, `mm`, `cm`, `m`, `km`, `au`, `AU`, `ly`, `pc`, `Mpc`, etc. The second includes conversion lambdas keyed by non-multiplier units including `degC` and `degF` (IVQFormat displays these as "°C" and "°F"). The dictionaries are used by the unit conversion methods in IVQConvert and can be referenced directly. User can add units to these dictionaries as needed.

#### [IVQConvert](https://github.com/ivoyager/ivoyager_units/blob/master/qconvert.gd)

This singleton provides two conversion methods `to_internal()` and `from_internal()` with required args `x: float` and `unit: StringName`. Optional args specify whether to parse compound units (true by default) or throw an error (default) or return NAN when `unit` isn't defined or can't be parsed. Method `is_valid_unit()` tests whether a unit string is valid for conversion methods.

The methods use member dictionaries `unit_multipliers` and `unit_lambdas`, which are set to the two IVUnits dictionaries by default.  If `parse_compound_unit` is set, the methods will handle previously undefined compound units like `m^3/(kg s^2)`. The parsed unit StringName will be memoized by adding to `unit_multipliers` for faster subsequent usage.

Compound unit parsing follows these rules:

1. The compound unit string must be composed only of multiplier units (i.e., keys in `unit_multipliers`), float numbers, unit operators, and opening and closing parentheses: "(", ")".
2. Allowed unit operatiors are "^", "/", and " ", corresponding to exponentiation, division and multiplication, in that order of precedence.
3. Spaces are ONLY allowed as multiplication operators!
4. Operators must have a valid non-operator substring on each side without adjacent spaces.
5. Each parenthesis opening "(" must have a closing ")".

The following strings are valid for unit parsing:

* `m/s^2`
* `m^3/(kg s^2)`
* `1e24`
* `10^24`
* `10^24 kg`
* `1/d`
* `d^-1`
* `m^0.5`

#### [IVQFormat](https://github.com/ivoyager/ivoyager_units/blob/master/qformat.gd)

This singleton provides methods for quantity conversion to strings for GUI display. User can specify the display unit, number format (e.g., scientific or dynamic), significant digits, and other details.

`prefixed_unit()` generates quantity-unit strings with dynamically prefixed base units, e.g., "1.0 kW", "1.0 MW", "1.0 GW", "1.0 TW", etc. The function selects the appropriate 3-order prefix all the way from `q` (10^-30) to `Q` (10^30).

`dynamic_unit()` allows dynamic selection of unit depending on the size of the value. E.g., in one mode of operation, it will generate a quantity string in "m", "km", "au" or SI-prefixed-"parsec" (whichever is appropriate).

`named_number()` allows dynamic creation of named numbers such as "999 Million" or "1.00 Billion".

See file [API](https://github.com/ivoyager/ivoyager_units/blob/master/qformat.gd) for all formatting options.
