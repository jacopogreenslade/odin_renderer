package main

import "core:encoding/json"
import "core:fmt"
import "core:io"
import glm "core:math/linalg/glsl"
import "core:os"
import "core:slice"
import "core:strings"
import game "game"


ENTITY_LIST_DEFAULT_PATH :: "./assets/entity_list.json"
YAK_EXT :: ".json"
OBJ_EXT :: ".obj"
ASSETS_FOLDER_PATH :: "./assets/"

ENTITY_LIST_FNAME :: "entity_list"
FILE_LIMIT :: 50

check_for_new_assets :: proc() -> (fnames: []string, dirty: bool) {
	
	ser := game.Serializer {}
	
	// Is there a OBJ file in the assets folder that doesn't have a corresponding .json file
	f, _ := os.open(ASSETS_FOLDER_PATH)
	// n seems to be a limit on how many files to return?
	file_info, _ := os.read_dir(f, FILE_LIMIT)
	ExtMatch :: struct {
		json: bool,
		obj:  bool,
	}
	// Get all files and add them to the map
	s_files := make([]string, len(file_info))
	idx := 0

	// Reverse sort so OBJ is first
	fname_compare :: proc(i: os.File_Info, j: os.File_Info) -> bool {
		return i.name > j.name
	}
  
  // NOTE: Says it returns bool but errors if you attempt to check it...
  slice.sort_by(file_info, fname_compare)

	for file in file_info {
		if strings.contains(file.name, ENTITY_LIST_FNAME) {
			continue
		}
		// Add all obj files in
		if (strings.contains(file.name, OBJ_EXT)) {
      s_files[idx] = file.name
			idx += 1
		} else if (strings.contains(file.name, YAK_EXT)) {
      s_files[idx] = ""
			idx -= 1
		}
    // fmt.println("Found file", file.name, idx)
	}

	if idx == 0 {
		return []string{}, false
	}
	s_files = s_files[:idx]
	return s_files, true
}

mesh_serialize_json :: proc(mesh: ^Mesh) -> bool {
	path := strings.concatenate([]string{ASSETS_FOLDER_PATH, strings.to_lower(mesh.name), YAK_EXT})

	// os.O_CREATE allows file to be created if it's not there.
	f, err := os.open(path, os.O_CREATE)
	if err == os.ERROR_FILE_NOT_FOUND {
		fmt.println("File not found. Code:", err)
		return false
	}
	defer os.close(f)

	opt := json.Marshal_Options {
		spec = json.Specification.JSON5,
	}
	// json_data, err := json.marshal(o, opt)
	err1 := json.marshal_to_writer(os.stream_from_handle(f), mesh^, &opt)
	if err1 != json.Marshal_Data_Error.None {
		fmt.println("Error serializing mesh. code=", err1)
		return false
	}

	return true
}

mesh_deserialize_json :: proc(fname: string) -> (Mesh, bool) {
	path := strings.concatenate([]string{ASSETS_FOLDER_PATH, fname, YAK_EXT})
	f, err := os.open(path)
	if err == os.ERROR_FILE_NOT_FOUND {
		fmt.println("File not found.", path, " Code:", err)
		return Mesh{}, false
	}
	defer os.close(f)

	m := Mesh{}
	data, success := os.read_entire_file_from_handle(f)
	if !success {
		fmt.println("Failed to read file!")
		return Mesh{}, false
	}
	jerr := json.unmarshal(data, &m, spec = json.Specification.JSON5)
	if jerr != nil && jerr != json.Error.None {
		fmt.println("Error loading data!", jerr)
		return m, false
	}

	return m, true
}


// NOTE: This makes less sense than having a EntityList deserializer that get's everything 
entity_list_deserialize :: proc(fpath: string = ENTITY_LIST_DEFAULT_PATH) -> EntityList {
	// Open a file handle
	f, err := os.open(fpath)
	if err == os.ERROR_FILE_NOT_FOUND {
		fmt.println("File not found.", fpath, " Code:", err)
		return EntityList{}
	}
	defer os.close(f)

	// Read the whole file in
	data, success := os.read_entire_file_from_handle(f)
	if !success {
		fmt.println("Failed to read file!")
		return EntityList{}
	}

	// Unmarshall the json directly to the EntityList
	el := EntityList{}
	jerr := json.unmarshal(data, &el, spec = json.Specification.JSON5)
	if jerr != nil && jerr != json.Error.None {
		fmt.println("Error loading data!", jerr)
		return EntityList{}
	}

	return el
}

entity_list_serialize_json :: proc(el: ^EntityList) -> bool {

	// os.O_CREATE allows file to be created if it's not there.
	e := os.remove(ENTITY_LIST_DEFAULT_PATH)
	fmt.println("Try to remove existing entity list", e);

	f, err := os.open(ENTITY_LIST_DEFAULT_PATH, os.O_CREATE)
	if err == os.ERROR_FILE_NOT_FOUND {
		fmt.println("File not found. Code:", err)
		return false
	}
	defer os.close(f)

	opt := json.Marshal_Options {
		spec = json.Specification.JSON5,
	}
	// json_data, err := json.marshal(o, opt)
	err1 := json.marshal_to_writer(os.stream_from_handle(f), el^, &opt)
	if err1 != json.Marshal_Data_Error.None {
		fmt.println("Error serializing el. code=", err1)
		return false
	}

	return true
}

entity_create :: proc(name: string, mesh_name: string = "") -> Entity {
	e := Entity {
		name = name,
	}

	if mesh_name != "" {
		// mesh, ok := mesh_deserialize_json(mesh_name)
		// e.mesh = &mesh
	}


	return e
}

