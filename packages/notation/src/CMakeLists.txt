# Builds Verovio (LGPL-3.0) as libverovio.so for the plugin. The source is fetched at build
# time from a pinned release and checked against its SHA-256; nothing is vendored.
cmake_minimum_required(VERSION 3.22)
project(notation_library LANGUAGES C CXX)

include(FetchContent)

# Only MusicXML in, SVG out: the other importers are left out to keep the
# library small. The app unzips .mxl itself, so Verovio's zip support is off too.
set(BUILD_AS_ANDROID_LIBRARY ON CACHE BOOL "" FORCE)
set(NO_HUMDRUM_SUPPORT ON CACHE BOOL "" FORCE)
set(NO_PAE_SUPPORT ON CACHE BOOL "" FORCE)
set(NO_ABC_SUPPORT ON CACHE BOOL "" FORCE)
set(NO_GABC_SUPPORT ON CACHE BOOL "" FORCE)
# NO_EDIT_SUPPORT stays OFF: Verovio 6.3.0 does not compile without its editor code.
set(NO_MXL_SUPPORT ON CACHE BOOL "" FORCE)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -ffunction-sections -fdata-sections")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--gc-sections")

FetchContent_Declare(verovio
  URL https://github.com/rism-digital/verovio/archive/refs/tags/version-6.3.0.tar.gz
  URL_HASH SHA256=095a561e9bd26c97787ad49e01009576d1ca234feae3995948c5aede97a40598
  SOURCE_SUBDIR cmake
)
FetchContent_MakeAvailable(verovio)
