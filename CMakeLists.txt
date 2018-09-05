cmake_minimum_required(VERSION 3.5)
project(masterlink)

set(OUTDIR "${CMAKE_SOURCE_DIR}/build")
set(LIBDIR "${OUTDIR}/lib")
set(CFGDIR "${OUTDIR}/data")
set(SCRDIR "${OUTDIR}/scripts")

file(MAKE_DIRECTORY ${OUTDIR})

include(Lua-cURLv3.cmake)
add_subdirectory(lua-cjson)

set_target_properties(cjson lcurl
        PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${LIBDIR}"
        )

add_custom_target(copyMLM)
add_custom_command(TARGET copyMLM PRE_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${LIBDIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${CFGDIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${SCRDIR}"
        COMMAND ${CMAKE_COMMAND} -E make_directory "${LIBDIR}/lua"
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/src/mlapi.lua "${LIBDIR}/lua"
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/src/master.lua "${SCRDIR}"
        COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/src/master.json "${CFGDIR}"
        )
