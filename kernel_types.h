#ifndef KERNEL_TYPES_H
#define KERNEL_TYPES_H

// Custom type definitions for freestanding kernel environment
// Replaces stdint.h dependency

typedef unsigned char      uint8_t;
typedef unsigned short     uint16_t;
typedef unsigned int       uint32_t;
typedef unsigned long long uint64_t;

typedef signed char        int8_t;
typedef signed short       int16_t;
typedef signed int         int32_t;
typedef signed long long   int64_t;

// Size type
typedef unsigned int       size_t;

// Null pointer
#ifndef NULL
#define NULL ((void*)0)
#endif

#endif // KERNEL_TYPES_H
