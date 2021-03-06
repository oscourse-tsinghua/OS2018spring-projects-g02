

/*
    Copyright 2016 Robert Elder Software Inc.
    
    Licensed under the Apache License, Version 2.0 (the "License"); you may not 
    use this file except in compliance with the License.  You may obtain a copy 
    of the License at
    
        http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software 
    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT 
    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the 
    License for the specific language governing permissions and limitations 
    under the License.
*/

/*GETS_REPLACED_WITH_INCLUDES*/

struct identifier_declaration_namespace{
	/*  An ordered list of type ids of things that are declared in this namespace */
	struct struct_general_type_id_list ordered_type_ids;
	/*  Allows us to map an identifier to the type id it is associated with */
	struct struct_identifier_id_to_struct_general_type_id_map identifier_ids_to_type_ids;
	/*  Allows us to map an identifier to the index it has in its scope */
	struct struct_identifier_id_to_unsigned_int_map identifier_id_to_ordered_index;
};
