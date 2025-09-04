# Changelog

This file documents changes to [ivoyager_units](https://github.com/ivoyager/ivoyager_units).

File format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [v0.0.5] - UNRELEASED

Developed using Godot 4.5.beta7

### Changed
* IVQFormat functions return "" when x is NAN.

## [v0.0.4] - 2025-06-12

Developed using Godot 4.4.1.

### Changed
* Display approximate value with prepend "~" when precision == 0. E.g., "~1 km".

### Fixed
* Scientific notation exponent no longer shows ".0". This was causeded by Godot str(float) change.

## [v0.0.3] - 2025-03-31

Developed using Godot 4.4.

### Changed
* File comments/class docs.

## [v0.0.2] - 2025-03-20

Developed using Godot 4.4.

### Changed
* [API breaking] Typed all dictionaries.

## v0.0.1 - 2025-01-07

Developed using Godot 4.3.

This plugin resulted from splitting the now-depreciated [Table Importer](https://github.com/ivoyager/ivoyager_table_importer) (v0.0.9) into two plugins: [Tables](https://github.com/ivoyager/ivoyager_tables) (v0.0.1) and [Units](https://github.com/ivoyager/ivoyager_units) (v0.0.1).

[v0.0.5]: https://github.com/ivoyager/ivoyager_units/compare/v0.0.4...HEAD
[v0.0.4]: https://github.com/ivoyager/ivoyager_units/compare/v0.0.3...v0.0.4
[v0.0.3]: https://github.com/ivoyager/ivoyager_units/compare/v0.0.2...v0.0.3
[v0.0.2]: https://github.com/ivoyager/ivoyager_units/compare/v0.0.1...v0.0.2
