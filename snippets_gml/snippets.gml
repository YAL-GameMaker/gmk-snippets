#define snippet_init_dll
/// snippet_init_dll()
var _path, _dir;

_dir = "";
_path = _dir + "snippets.dll";
global.f_snippet_event_get_type = external_define(_path, "snippet_event_get_type", dll_cdecl, ty_real, 1, ty_string);
global.f_snippet_event_get_number = external_define(_path, "snippet_event_get_number", dll_cdecl, ty_real, 1, ty_string);
global.f_snippet_event_get_number_object = external_define(_path, "snippet_event_get_number_object", dll_cdecl, ty_string, 0);
global.f_snippet_event_register = external_define(_path, "snippet_event_register", dll_cdecl, ty_real, 3, ty_string, ty_real, ty_real);
global.f_snippet_event_register_type = external_define(_path, "snippet_event_register_type", dll_cdecl, ty_real, 3, ty_string, ty_real, ty_real);
global.f_snippet_parse_event_file = external_define(_path, "snippet_parse_event_file", dll_cdecl, ty_real, 1, ty_string);
global.f_snippet_function_add = external_define(_path, "snippet_function_add", dll_cdecl, ty_real, 1, ty_string);
global.f_snippet_function_remove = external_define(_path, "snippet_function_remove", dll_cdecl, ty_real, 1, ty_string);
global.f_snippet_parse_api_entry = external_define(_path, "snippet_parse_api_entry", dll_cdecl, ty_real, 1, ty_string);
global.f_snippet_parse_api_file = external_define(_path, "snippet_parse_api_file", dll_cdecl, ty_real, 1, ty_string);
global.f_sniptools_file_get_contents = external_define(_path, "sniptools_file_get_contents", dll_cdecl, ty_string, 1, ty_string);
global.f_sniptools_string_trim = external_define(_path, "sniptools_string_trim", dll_cdecl, ty_string, 1, ty_string);
global.f_sniptools_string_trim_start = external_define(_path, "sniptools_string_trim_start", dll_cdecl, ty_string, 1, ty_string);
global.f_sniptools_string_trim_end = external_define(_path, "sniptools_string_trim_end", dll_cdecl, ty_string, 1, ty_string);
global.f_sniptools_string_is_ident = external_define(_path, "sniptools_string_is_ident", dll_cdecl, ty_real, 1, ty_string);
global.f_sniptools_string_split_start = external_define(_path, "sniptools_string_split_start", dll_cdecl, ty_real, 2, ty_string, ty_string);
global.f_sniptools_string_split_next = external_define(_path, "sniptools_string_split_next", dll_cdecl, ty_string, 0);
global.f_snippet_preproc_run = external_define(_path, "snippet_preproc_run", dll_cdecl, ty_real, 3, ty_string, ty_string, ty_string);
global.f_snippet_preproc_pop_name = external_define(_path, "snippet_preproc_pop_name", dll_cdecl, ty_string, 0);
global.f_snippet_preproc_pop_code = external_define(_path, "snippet_preproc_pop_code", dll_cdecl, ty_string, 0);
global.f_snippet_preproc_concat_names = external_define(_path, "snippet_preproc_concat_names", dll_cdecl, ty_string, 0);


#define snippet_init
/// ()
snippet_init_dll();
var i; i = 0;
global.__snippet__argument[0] = 0;
global.__snippet__argument_count = 0;
global.__snippet__result = 0;
global.__snippet__map = ds_map_create(); // name -> ID
global.__snippet__code_map = ds_map_create();
global.__snippet__next = 100;

// blank object is used to count objects and as a properties drop-in
global.__snippet__blank_object = object_add();

// populate object names<->ids
global.__snippet__object_names = ds_map_create();
global.__snippet__object_ids = ds_map_create();
for (i = 0; i < global.__snippet__blank_object; i += 1) if (object_exists(i)) {
    var _name; _name = object_get_name(i);
    ds_map_add(global.__snippet__object_ids, _name, i);
}

// contains things like "create\nstep" in case we need to delete events later
global.__snippet__object_events = ds_map_create();

snippet_parse_api_file("fnames");
snippet_parse_event_file("events.gml");

// collect scripts:
var _max_gap; _max_gap = 1024;
var _gap; _gap = _max_gap;
var _seen_snippet_init; _seen_snippet_init = false;
while (_gap < _max_gap || !_seen_snippet_init) {
    if (script_exists(i)) {
        _gap = 0;
        var _name; _name = script_get_name(i);
        if (!_seen_snippet_init && _name == "snippet_init") _seen_snippet_init = true;
        snippet_function_add(_name);
    }
    i += 1;
    _gap += 1;
}
//var _script_time = current_time - _time;

/*show_message(
    "Parse time: " + string(_fnames_time)
    + "#Script time: " + string(_script_time)
);*/

#define snippet_execute_string
/// (gml_code)
var n; n = external_call(global.f_snippet_preproc_run, "", argument0, "define");
var _result; _result = 0;
repeat (n) {
    var _name; _name = external_call(global.f_snippet_preproc_pop_name);
    var _code; _code = external_call(global.f_snippet_preproc_pop_code);
    _result = execute_string(_code);
}
return _result;

#define snippet_define
/// (name, gml_code)
var n; n = external_call(global.f_snippet_preproc_run, argument0, argument1, "define");
repeat (n) {
    var _name; _name = external_call(global.f_snippet_preproc_pop_name);
    var _code; _code = external_call(global.f_snippet_preproc_pop_code);
    snippet_define_raw(_name, _code);
}

#define snippet_define_raw
/// (name, raw_gml_code)
var _name; _name = argument0;
var _code; _code = argument1;
// show_message(_name + ":" + chr(10) + _gml);

// unregister name so that subsequent snippets call the snippet and not the built-in:
snippet_function_remove(_name);

// one event per snippet:
var _enumb;
if (ds_map_exists(global.__snippet__map, _name)) {
    _enumb = ds_map_find_value(global.__snippet__map, _name);
    object_event_clear(obj_snippets, ev_alarm, _enumb);
    ds_map_replace(global.__snippet__code_map, _name, _code);
} else {
    _enumb = global.__snippet__next;
    global.__snippet__next += 1;
    
    ds_map_add(global.__snippet__map, _name, _enumb);
    ds_map_add(global.__snippet__code_map, _name, _code);
}
object_event_add(obj_snippets, ev_alarm, _enumb, _code);

/* one object per snippet:
var _obj;
if (ds_map_exists(global.__snippet__map, _name)) {
    _obj = ds_map_find_value(global.__snippet__map, _name);
    object_event_clear(_obj, ev_other, 257);
} else {
    _obj = object_add();
    ds_map_add(global.__snippet__map, _name, _obj);
}
object_event_add(_obj, ev_other, 257, _code);*/

#define snippet_exists
/// (name)->
return ds_map_exists(global.__snippet__map, argument0);

#define snippet_get_code
/// (name)->
if (ds_map_exists(global.__snippet__code_map, argument0)) {
    return ds_map_find_value(global.__snippet__code_map, argument0);
} else return "";

#define snippet_call
/// (name, ...args)
var _name; _name = argument0;

// store old arguments:
var _old_argc; _old_argc = global.__snippet__argument_count;
var _old_args; _old_args = global.__snippet__argument;
var i; i = 1;
repeat (_old_argc - 1) {
    _old_args[i] = global.__snippet__argument[i];
    i += 1;
}

// copy new arguments:
var _argc; _argc = argument_count - 1;
global.__snippet__argument_count = _argc;
i = 0;
repeat (_argc) {
    global.__snippet__argument[i] = argument[i + 1];
    i += 1;
}

// clear "extra" arguments:
repeat (_old_argc - _argc) {
    global.__snippet__argument[i] = 0;
    i += 1;
}

if (ds_map_exists(global.__snippet__map, _name)) {
    // one snippet per event:
    var _enumb; _enumb = ds_map_find_value(global.__snippet__map, _name);
    event_perform_object(obj_snippets, ev_alarm, _enumb);
    //*/
    
    /* one snippet per object:
    var _obj; _obj = ds_map_find_value(global.__snippet__map, _name);
    event_perform_object(_obj, ev_other, 257);
    //*/
} else {
    show_error('Snippet "' + _name + '" does not exist!', true);
}

// restore previous arguments:
global.__snippet__argument_count = _old_argc;
i = 0;
repeat (_old_argc) {
    global.__snippet__argument[i] = _old_args[i];
    i += 1;
}

// clear the extra arguments (the other way around!):
repeat (_argc - _old_argc) {
    global.__snippet__argument[i] = 0;
    i += 1;
}

return global.__snippet__result;

#define snippet_prepare_object
/// (name)
var _name; _name = argument0;
if (ds_map_exists(global.__snippet__object_ids, _name)) {
    return ds_map_find_value(global.__snippet__object_ids, _name);
} else {
    var _obj; _obj = object_add();
    ds_map_add(global.__snippet__object_ids, _name, _obj);
    ds_map_add(global.__snippet__object_names, _obj, _name);
    if (sniptools_string_is_ident(_name)) {
        // register so that it's globally accessible in code
        execute_string('globalvar ' + _name + ';' + _name + ' = argument0', _obj);
    }
    return _obj;
}

#define snippet_define_object
/// (name, gml_code)
var _name; _name = argument0;
var n; n = external_call(global.f_snippet_preproc_run, "properties", argument1, "event");
var _obj; _obj = snippet_prepare_object(_name);

// clear old events:
var _events; _events = external_call(global.f_snippet_preproc_concat_names);
if (ds_map_exists(global.__snippet__object_events, _obj)) {
    var _old_events; _old_events = ds_map_find_value(global.__snippet__object_events, _obj);
    repeat (sniptools_string_split_start(_old_events, chr(10))) {
        var _ename; _ename = sniptools_string_split_next();
        var _type; _type = snippet_event_get_type(_ename);
        var _numb; _numb = snippet_event_get_number(_ename);
        if (_type == -1) {
            if (_numb != 0) continue;
            // revert properties!
            object_set_visible(_obj, true);
            object_set_depth(_obj, 0);
            object_set_persistent(_obj, false);
            object_set_parent(_obj, -1);
            object_set_sprite(_obj, -1);
            object_set_mask(_obj, -1);
            object_set_solid(_obj, false);
            continue;
        }
        if (_numb == -1) continue;
        if (_numb == -2) { // object
            _numb = snippet_object_get_index(snippet_event_get_number_object());
            if (_numb == -1) continue;
        }
        object_event_clear(_obj, _type, _numb);
    }
    ds_map_replace(global.__snippet__object_events, _obj, _events);
} else {
    ds_map_add(global.__snippet__object_events, _obj, _events);
}

repeat (n) {
    var _ename; _ename = external_call(global.f_snippet_preproc_pop_name);
    var _code; _code = external_call(global.f_snippet_preproc_pop_code);
    var _type; _type = snippet_event_get_type(_ename);
    var _numb; _numb = snippet_event_get_number(_ename);
    if (_type == -1) {
        if (_numb != 0) {
            show_error('"' + _ename + '" is not a known event type!', false);
            continue;
        }
        // properties!
        with (instance_create(0, 0, global.__snippet__blank_object)) {
            visible = object_get_visible(_obj);
            depth = object_get_depth(_obj);
            persistent = object_get_persistent(_obj);
            parent_index = object_get_parent(_obj);
            sprite_index = object_get_sprite(_obj);
            mask_index = object_get_mask(_obj);
            solid = object_get_solid(_obj);
            //
            execute_string(_code);
            //
            object_set_visible(_obj, visible);
            object_set_depth(_obj, depth);
            object_set_persistent(_obj, persistent);
            object_set_parent(_obj, parent_index);
            object_set_sprite(_obj, sprite_index);
            object_set_mask(_obj, mask_index);
            object_set_solid(_obj, solid);
            //
            instance_destroy();
        }
        continue;
    }
    if (_numb == -1) {
        show_error('"' + _ename + '" is not a known event (sub-)type!', false);
        continue;
    }
    if (_numb == -2) {
        var _cobj_name; _cobj_name = snippet_event_get_number_object();
        var _cobj; _cobj = snippet_object_get_index(_cobj_name);
        if (_cobj == -1) {
            show_error('"' + _cobj_name + '" in "' + _ename + '" is not a known object!', false);
            continue;
        }
        _numb = _cobj;
    }
    object_event_add(_obj, _type, _numb, _code);
    /*show_message(_name
        + chr(10) + _ename + " -> (" + string(_type) + ", " + string(_numb) + ")"
        + chr(10) + _code
    );*/
}
return _obj;

#define snippet_object_get_name
/// (object_index)->
if (ds_map_exists(global.__snippet__object_names, argument0)) {
    return ds_map_find_value(global.__snippet__object_names, argument0);
} else {
    return object_get_name(argument0);
}

#define snippet_object_get_index
/// (object_name)->
if (ds_map_exists(global.__snippet__object_ids, argument0)) {
    return ds_map_find_value(global.__snippet__object_ids, argument0);
} else {
    return -1;
}

#define snippet_load_list
/// (path_list, dir)
var _files; _files = argument0;
var _pre; _pre = argument1;
if (_pre != "") switch (string_char_at(_pre, string_length(_pre))) {
    case '/': case '\': break;
    default: _pre += '\';
}
var i;
var n; n = ds_list_size(_files);
var _grid; _grid = ds_grid_create(n, 4); // [kind, path, name, meta]

// figure out what to do with each thing:
for (i = 0; i < n; i += 1) {
    var _file; _file = ds_list_find_value(_files, i);
    if (string_char_at(_file, 1) == '>') {
        ds_grid_set(_grid, i, 0, "inline");
        ds_grid_set(_grid, i, 1, sniptools_string_trim_start(string_delete(_file, 1, 1)));
        continue;
    }
    
    var _meta; _meta = 0;
    var _sep; _sep = string_pos('>', _file);
    if (_sep != 0) {
        _meta = sniptools_string_trim_start(string_delete(_file, 1, _sep));
        _file = sniptools_string_trim_end(string_copy(_file, 1, _sep - 1));
    }
    
    var _kind; _kind = "";
    
    var _name; _name = filename_name(_file);
    repeat (2) {
        if (filename_ext(_name) == "") break;
        _name = filename_change_ext(_name, "");
    }
    
    var _ext; _ext = string_lower(filename_ext(_file));
    if (_ext == ".gml") {
        var _noext; _noext = filename_change_ext(_file, "");
        var _ext2; _ext2 = string_lower(filename_ext(_noext));
        switch (_ext2) {
            case "": _kind = "script"; break;
            case ".object": _kind = "object"; break;
            case ".global": _kind = "global"; break;
            default:
                show_error('"' + _noext + '" is not a recognized sub-extension (for "' + _file + '")', false);
        }
    } else {
        show_error('No idea how to load "' + _ext + '" files (for "' + _file + '")', false);
    }
    ds_grid_set(_grid, i, 0, _kind);
    ds_grid_set(_grid, i, 1, _file);
    ds_grid_set(_grid, i, 2, _name);
    ds_grid_set(_grid, i, 3, _meta);
}

// should we create objects beforehand? It's okay so long as children appear after parents
/*for (i = 0; i < n; i += 1) {
    if (ds_grid_get(_grid, i, 0) == "object") {
        snippet_prepare_object(ds_grid_get(_grid, i, 2));
    }
}*/

// load the code bits:
for (i = 0; i < n; i += 1) {
    var _kind; _kind = ds_grid_get(_grid, i, 0);
    var _file; _file = ds_grid_get(_grid, i, 1);
    var _name; _name = ds_grid_get(_grid, i, 2);
    var _meta; _meta = ds_grid_get(_grid, i, 3);
    switch (_kind) {
        case "script": case "object":
            var _gml; _gml = sniptools_file_get_contents(_pre + _file);
            //show_message(_name + ":" + chr(10) + _gml);
            if (_gml == "") {
                show_error('"' + _file + '" is missing or empty!', false);
            } else if (_kind == "object") {
                var _obj; _obj = snippet_define_object(_name, _gml);
                if (is_string(_meta)) {
                    if (_meta == "") {
                        execute_string('instance_create(0, 0, argument0)', _obj);
                    } else {
                        show_error('Unsupported meta "' + _meta + '" for "' + _file + '"', false);
                    }
                    _meta = 0;
                }
            } else {
                snippet_define(_name, _gml);
            }
            break;
        case "global":
            var _gml; _gml = sniptools_file_get_contents(_pre + _file);
            if (_gml == "") {
                show_error('"' + _file + '" is missing or empty!', false);
            } else {
                snippet_execute_string(_gml);
            }
            break;
        case "inline":
            snippet_execute_string(_file);
            break;
    }
    if (is_string(_meta)) {
        show_error('">' + _meta + '" was specified for "' + _file + '" but is not supported for the file type.', false)
    }
}
ds_grid_destroy(_grid);

#define snippet_load_listfile
/// (path)
var _path; _path = argument0;
var _tf; _tf = file_text_open_read(_path);
var _todo; _todo = ds_list_create();
var _pre; _pre = filename_path(_path);
while (!file_text_eof(_tf)) {
    var _line; _line = file_text_read_string(_tf);
    file_text_readln(_tf);
    
    if (sniptools_string_trim_end(_line) == "") continue;
    if (string_char_at(_line, 1) == "#") continue;
    
    ds_list_add(_todo, _line);
}
file_text_close(_tf);
snippet_load_list(_todo, _pre);
ds_list_destroy(_todo);
#define snippet_event_get_type
/// snippet_event_get_type(name)
return external_call(global.f_snippet_event_get_type, argument0);

#define snippet_event_get_number
/// snippet_event_get_number(name)
return external_call(global.f_snippet_event_get_number, argument0);

#define snippet_event_get_number_object
/// snippet_event_get_number_object()
return external_call(global.f_snippet_event_get_number_object);

#define snippet_event_register
/// snippet_event_register(name, type, number)
return external_call(global.f_snippet_event_register, argument0, argument1, argument2);

#define snippet_event_register_type
/// snippet_event_register_type(name, type, arg_type)
return external_call(global.f_snippet_event_register_type, argument0, argument1, argument2);

#define snippet_parse_event_file
/// snippet_parse_event_file(path)
return external_call(global.f_snippet_parse_event_file, argument0);

#define snippet_function_add
/// snippet_function_add(name)
return external_call(global.f_snippet_function_add, argument0);

#define snippet_function_remove
/// snippet_function_remove(name)
return external_call(global.f_snippet_function_remove, argument0);

#define snippet_parse_api_entry
/// snippet_parse_api_entry(line)
return external_call(global.f_snippet_parse_api_entry, argument0);

#define snippet_parse_api_file
/// snippet_parse_api_file(path)
return external_call(global.f_snippet_parse_api_file, argument0);

#define sniptools_file_get_contents
/// sniptools_file_get_contents(path)
return external_call(global.f_sniptools_file_get_contents, argument0);

#define sniptools_string_trim
/// sniptools_string_trim(str)
return external_call(global.f_sniptools_string_trim, argument0);

#define sniptools_string_trim_start
/// sniptools_string_trim_start(str)
return external_call(global.f_sniptools_string_trim_start, argument0);

#define sniptools_string_trim_end
/// sniptools_string_trim_end(str)
return external_call(global.f_sniptools_string_trim_end, argument0);

#define sniptools_string_is_ident
/// sniptools_string_is_ident(str)
return external_call(global.f_sniptools_string_is_ident, argument0);

#define sniptools_string_split_start
/// sniptools_string_split_start(str, sep)
return external_call(global.f_sniptools_string_split_start, argument0, argument1);

#define sniptools_string_split_next
/// sniptools_string_split_next()
return external_call(global.f_sniptools_string_split_next);
