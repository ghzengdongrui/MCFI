# Get sources
file(GLOB LIBCXX_SOURCES ../src/*.cpp)
if(WIN32)
  file(GLOB LIBCXX_WIN32_SOURCES ../src/support/win32/*.cpp)
  list(APPEND LIBCXX_SOURCES ${LIBCXX_WIN32_SOURCES})
endif()

# Add all the headers to the project for IDEs.
if (MSVC_IDE OR XCODE)
  file(GLOB_RECURSE LIBCXX_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/../include/*)
  if(WIN32)
    file( GLOB LIBCXX_WIN32_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/../include/support/win32/*.h)
    list(APPEND LIBCXX_HEADERS ${LIBCXX_WIN32_HEADERS})
  endif()
  # Force them all into the headers dir on MSVC, otherwise they end up at
  # project scope because they don't have extensions.
  if (MSVC_IDE)
    source_group("Header Files" FILES ${LIBCXX_HEADERS})
  endif()
endif()

if (LIBCXX_ENABLE_SHARED)
  add_library(cxx SHARED
    ${LIBCXX_SOURCES}
    ${LIBCXX_HEADERS}
    )
else()
  add_library(cxx STATIC
    ${LIBCXX_SOURCES}
    ${LIBCXX_HEADERS}
    )
endif()

if (DEFINED LIBCXX_CXX_ABI_DEPS)
  add_dependencies(cxx LIBCXX_CXX_ABI_DEPS)
endif()

# Generate library list.
set(libraries ${LIBCXX_CXX_ABI_LIBRARIES})
append_if(libraries LIBCXX_HAS_PTHREAD_LIB pthread)
append_if(libraries LIBCXX_HAS_C_LIB c)
append_if(libraries LIBCXX_HAS_M_LIB m)
append_if(libraries LIBCXX_HAS_RT_LIB rt)
append_if(libraries LIBCXX_HAS_GCC_S_LIB gcc_s)

target_link_libraries(cxx ${libraries})

# Setup flags.
append_if(compile_flags LIBCXX_HAS_FPIC_FLAG -fPIC)
append_if(link_flags LIBCXX_HAS_NODEFAULTLIBS_FLAG -nodefaultlibs)

if ( APPLE )
  if ( CMAKE_OSX_DEPLOYMENT_TARGET STREQUAL "10.6" )
    list(APPEND compile_flags "-U__STRICT_ANSI__")
    list(APPEND link_flags
      "-compatibility_version 1"
      "-current_version ${LIBCXX_VERSION}"
      "-install_name /usr/lib/libc++.1.dylib"
      "-Wl,-reexport_library,/usr/lib/libc++abi.dylib"
      "-Wl,-unexported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/libc++unexp.exp"
      "/usr/lib/libSystem.B.dylib")
  else()
    if ( ${CMAKE_OSX_SYSROOT} )
      list(FIND ${CMAKE_OSX_ARCHITECTURES} "armv7" OSX_HAS_ARMV7)
      if (OSX_HAS_ARMV7)
        set(OSX_RE_EXPORT_LINE
          "${CMAKE_OSX_SYSROOT}/usr/lib/libc++abi.dylib"
          "-Wl,-reexported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/libc++sjlj-abi.exp")
      else()
        set(OSX_RE_EXPORT_LINE
          "-Wl,-reexport_library,${CMAKE_OSX_SYSROOT}/usr/lib/libc++abi.dylib")
      endif()
    else()
      set (OSX_RE_EXPORT_LINE "/usr/lib/libc++abi.dylib -Wl,-reexported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/libc++abi${LIBCXX_LIBCPPABI_VERSION}.exp")
    endif()

    list(APPEND link_flags
      "-compatibility_version 1"
      "-install_name /usr/lib/libc++.1.dylib"
      "-Wl,-unexported_symbols_list,${CMAKE_CURRENT_SOURCE_DIR}/libc++unexp.exp"
      "${OSX_RE_EXPORT_LINE}"
      "-Wl,-force_symbols_not_weak_list,${CMAKE_CURRENT_SOURCE_DIR}/notweak.exp"
      "-Wl,-force_symbols_weak_list,${CMAKE_CURRENT_SOURCE_DIR}/weak.exp")
  endif()
endif()

string(REPLACE ";" " " link_flags "${link_flags}")

set_target_properties(cxx
  PROPERTIES
    COMPILE_FLAGS "${compile_flags}"
    LINK_FLAGS    "${link_flags}"
    OUTPUT_NAME   "c++"
    VERSION       "1.0"
    SOVERSION     "1"
  )

install(TARGETS cxx
  LIBRARY DESTINATION lib
  ARCHIVE DESTINATION lib
  )
