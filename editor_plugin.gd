# editor_plugin.gd
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
@tool
extends EditorPlugin

# Adds autoload singletons as specified by cofig files
# res://addons/ivoyager_units/ivoyager_units.cfg and res://ivoyager_override.cfg.



const plugin_utils := preload("units_plugin_utils.gd")

var _config: ConfigFile # base config with overrides
var _autoloads: Dictionary[String, String] = {}



func _enter_tree() -> void:
	plugin_utils.print_plugin_name_and_version("ivoyager_units", " - https://ivoyager.dev")
	_config = plugin_utils.get_ivoyager_config("res://addons/ivoyager_units/ivoyager_units.cfg")
	if !_config:
		return
	_add_autoloads()


func _exit_tree() -> void:
	print("Removing I, Voyager - Units (plugin)")
	_config = null
	_remove_autoloads()


func _add_autoloads() -> void:
	for autoload_name in _config.get_section_keys("units_autoload"):
		var value: Variant = _config.get_value("units_autoload", autoload_name)
		if value: # could be null or "" to negate
			assert(typeof(value) == TYPE_STRING,
					"'%s' must specify a path as String" % autoload_name)
			_autoloads[autoload_name] = value
	for autoload_name in _autoloads:
		var path := _autoloads[autoload_name]
		add_autoload_singleton(autoload_name, path)


func _remove_autoloads() -> void:
	for autoload_name: String in _autoloads:
		remove_autoload_singleton(autoload_name)
	_autoloads.clear()
