# HTI custom build overlay for QGroundControl v5.1.0.

message(STATUS "QGC: Adding HTI custom build")

# The root build appends this list to the executable's resource list. Keeping
# the resource file here makes the overlay self-contained and easy to carry to
# a newer upstream revision.
set(QGC_RESOURCES
    ${QGC_RESOURCES}
    "${CMAKE_CURRENT_SOURCE_DIR}/resources.qrc"
    CACHE STRING "Paths to .qrc Resources" FORCE
)

set(CUSTOM_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/CustomPlugin.cc"
    "${CMAKE_CURRENT_SOURCE_DIR}/CustomPlugin.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/CustomOptions.cc"
    "${CMAKE_CURRENT_SOURCE_DIR}/CustomOptions.h"
    CACHE INTERNAL "HTI custom plugin sources" FORCE
)

set(CUSTOM_INCLUDE_DIRECTORIES
    "${CMAKE_CURRENT_SOURCE_DIR}"
    CACHE INTERNAL "HTI custom plugin include directories" FORCE
)

set(CUSTOM_DEFINITIONS
    QGC_CUSTOM_BUILD
    CUSTOMHEADER="CustomPlugin.h"
    CUSTOMCLASS=CustomPlugin
    CACHE INTERNAL "HTI custom build definitions" FORCE
)
