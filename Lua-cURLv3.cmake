set(LCURL_PATH_SRC "${CMAKE_SOURCE_DIR}/Lua-cURLv3/src")

FILE(GLOB SOURCE_FILES ${LCURL_PATH_SRC}/*.c)

find_package(Lua51 REQUIRED)
find_package(CURL REQUIRED)

add_library(lcurl SHARED ${SOURCE_FILES})
target_link_libraries(lcurl ${LUA_LIBRARY} ${CURL_LIBRARIES})
target_include_directories(lcurl SYSTEM PRIVATE ${LUA_INCLUDE_DIR} ${CURL_INCLUDE_DIRS})
set_target_properties(lcurl PROPERTIES PREFIX "")

add_custom_command(TARGET lcurl PRE_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${LCURL_PATH_SRC}/lua $<TARGET_FILE_DIR:lcurl>)
