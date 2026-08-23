# HTI custom build overlay for QGroundControl v5.1.0.

message(STATUS "QGC: Adding HTI custom build")

# The root build appends this list to the executable's resource list. Keeping
# the resource file here makes the overlay self-contained and easy to carry to
# a newer upstream revision.
file(GLOB HTI_VOICE_WAV_FILES CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/Voice/wav_output/*.wav")
set(HTI_VOICE_WAV_QRC "${CMAKE_CURRENT_BINARY_DIR}/hti_voice_wav.qrc")
file(WRITE "${HTI_VOICE_WAV_QRC}" "<RCC>\n    <qresource prefix=\"/HTI/Voice/wav\">\n")
foreach(HTI_VOICE_WAV_FILE IN LISTS HTI_VOICE_WAV_FILES)
    get_filename_component(HTI_VOICE_WAV_NAME "${HTI_VOICE_WAV_FILE}" NAME)
    file(TO_CMAKE_PATH "${HTI_VOICE_WAV_FILE}" HTI_VOICE_WAV_RESOURCE_PATH)
    file(APPEND "${HTI_VOICE_WAV_QRC}" "        <file alias=\"${HTI_VOICE_WAV_NAME}\">${HTI_VOICE_WAV_RESOURCE_PATH}</file>\n")
endforeach()
file(APPEND "${HTI_VOICE_WAV_QRC}" "    </qresource>\n</RCC>\n")

set(QGC_RESOURCES
    ${QGC_RESOURCES}
    "${CMAKE_CURRENT_SOURCE_DIR}/resources.qrc"
    "${HTI_VOICE_WAV_QRC}"
    CACHE STRING "Paths to .qrc Resources" FORCE
)

set(CUSTOM_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/CustomPlugin.cc"
    "${CMAKE_CURRENT_SOURCE_DIR}/CustomPlugin.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/CustomOptions.cc"
    "${CMAKE_CURRENT_SOURCE_DIR}/CustomOptions.h"
    "${CMAKE_CURRENT_SOURCE_DIR}/Voice/HTIVoiceManager.cc"
    "${CMAKE_CURRENT_SOURCE_DIR}/Voice/HTIVoiceManager.h"
    CACHE INTERNAL "HTI custom plugin sources" FORCE
)

set(CUSTOM_INCLUDE_DIRECTORIES
    "${CMAKE_CURRENT_SOURCE_DIR}"
    CACHE INTERNAL "HTI custom plugin include directories" FORCE
)

set(CUSTOM_LIBRARIES
    Qt6::Multimedia
    CACHE INTERNAL "HTI custom libraries" FORCE
)

set(CUSTOM_DEFINITIONS
    QGC_CUSTOM_BUILD
    CUSTOMHEADER="CustomPlugin.h"
    CUSTOMCLASS=CustomPlugin
    CACHE INTERNAL "HTI custom build definitions" FORCE
)
