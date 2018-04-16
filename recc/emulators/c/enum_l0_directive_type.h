#ifndef OP_CPU_enum_l0_directive_type_H_
#define OP_CPU_enum_l0_directive_type_H_
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

enum l0_directive_type {
	L0_MACHINE_INSTRUCTION,      /* 0 */
	L0_DW_DIRECTIVE,             /* 1 */
	L0_SW_DIRECTIVE,             /* 2 */
	L0_OFFSET_ADDRESS_DIRECTIVE, /* 3 */
	L0_STRING_DIRECTIVE,         /* 4 */
	L0_LINKAGE_DIRECTIVE,        /* 5 */
	L0_UNRESOLVED_DIRECTIVE,     /* 6 */
	L0_FUNCTION_DIRECTIVE,       /* 7 */
	L0_VARIABLE_DIRECTIVE,       /* 8 */
	L0_CONSTANT_DIRECTIVE,       /* 9 */
	L0_START_DIRECTIVE,          /* A */
	L0_END_DIRECTIVE,            /* B */
	L0_IMPLEMENTED_DIRECTIVE,    /* C */
	L0_REQUIRED_DIRECTIVE,       /* D */
	L0_REGION_DIRECTIVE,         /* E */
	L0_PERMISSION_DIRECTIVE,     /* F */
	L0_IMAGE_SIZE,               /* 10 */
	L0_NUM_L0_ITEMS              /* 11 */
};

#endif
