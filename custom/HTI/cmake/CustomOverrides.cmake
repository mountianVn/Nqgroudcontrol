# CMake overrides for the HTI build. This file is included by the v5.1.0 root
# CMakeLists.txt before project() is created.

# QGC_APP_NAME is also the CMake project/target name in v5.1.0, so it must be a
# single CMake-safe token. The user-facing branding description is kept here;
# changing QGC_APP_NAME to a phrase would split project() arguments.
set(QGC_APP_NAME "NGroundControl" CACHE STRING "Application name" FORCE)
set(QGC_APP_COPYRIGHT "Copyright (c) ${_copyright_year} NGroundControl. All rights reserved." CACHE STRING "Copyright notice" FORCE)
set(QGC_APP_DESCRIPTION "NGroundControl Ground Control" CACHE STRING "Application description" FORCE)
set(QGC_ORG_NAME "NGroundControl" CACHE STRING "Organization name" FORCE)
set(QGC_ORG_DOMAIN "ngroundcontrol.local" CACHE STRING "Organization domain" FORCE)
set(QGC_PACKAGE_NAME "com.ngroundcontrol.groundcontrol" CACHE STRING "Package identifier" FORCE)
