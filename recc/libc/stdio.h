#ifndef STDIO_H_DEFINED_
#define STDIO_H_DEFINED_
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

#ifndef COMMON_H_DEFINED_
#include "common.h"
#endif
#ifndef STDARG_H_DEFINED_
#include <stdarg.h>
#endif
#ifndef PUTCHAR_H_DEFINED_
#include <putchar.h>
#endif
#ifndef SIZE_T_H_DEFINED_
#include "size_t.h"
#endif

#define EOF 255   /*  TODO: should be -1*/

int vsnprintf(char *, size_t, const char *, va_list);
int snprintf(char *, size_t, const char *, ...);
int vsprintf (char *, const char *, va_list);
int printf(const char *, ...);
int vprintf(const char *, va_list);

#endif
