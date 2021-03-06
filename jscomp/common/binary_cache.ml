
(* Copyright (C) 2015-2016 Bloomberg Finance L.P.
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * In addition to the permissions granted to you by the LGPL, you may combine
 * or link a "work that uses the Library" with a publicly distributed version
 * of this file to produce a combined library or application, then distribute
 * that combined work under the terms of your choosing, with no requirement
 * to comply with the obligations normally placed on you by section 4 of the
 * LGPL version 3 (or the corresponding section of a later version of the LGPL
 * should you choose to use a later version).
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA. *)


type ml_kind =
  | Ml of string 
  | Re of string 
  | Ml_empty
type mli_kind = 
  | Mli of string 
  | Rei of string
  | Mli_empty

type module_info = 
  {
    mli : mli_kind ; 
    ml : ml_kind ; 
    mll : string option ;
  }

type t = 
      module_info String_map.t 


let module_info_magic_number = "BSBUILD20161012"

let write_build_cache bsbuild (bs_files : module_info String_map.t)  = 
  let oc = open_out_bin bsbuild in 
  output_string oc module_info_magic_number ;
  output_value oc bs_files ;
  close_out oc 

let read_build_cache bsbuild : module_info String_map.t = 
  let ic = open_in_bin bsbuild in 
  let buffer = really_input_string ic (String.length module_info_magic_number) in
  assert(buffer = module_info_magic_number); 
  let data : module_info String_map.t = input_value ic in 
  close_in ic ;
  data 


let bsbuild_cache = ".bsbuild"


let empty_module_info = {mli = Mli_empty ; mll = None ; ml = Ml_empty}

let adjust_module_info x suffix name =
  match suffix with 
  | ".ml" -> {x with ml = Ml name}
  | ".re" -> {x with ml = Re name}
  | ".mli" ->  {x with mli = Mli name}
  | ".rei" -> { x with mli = Rei name}
  | ".mll" -> {x with mll = Some name}
  | _ -> failwith ("don't know what to do with " ^ name)

let map_update ?dir (map : t)  name : t  = 
  let prefix   = 
    match dir with
    | None -> fun x ->  x
    | Some v -> fun x ->  Ext_filename.combine v x in
  let module_name = Ext_filename.module_name_of_file_if_any name in 
  let suffix = Ext_filename.get_extension name in 
  String_map.adjust 
    module_name 
    (fun _ -> (adjust_module_info empty_module_info suffix (prefix name )))
    (fun v -> (adjust_module_info v suffix (prefix name )))
    map 
