# CMake overrides for the HTI build. This file is included by the v5.1.0 root
# CMakeLists.txt before project() is created.

# QGC_APP_NAME is also the CMake project/target name in v5.1.0, so it must be a
# single CMake-safe token. The user-facing branding description is kept here;
# changing QGC_APP_NAME to a phrase would split project() arguments.
set(QGC_APP_NAME "HTI" CACHE STRING "Application name" FORCE)
set(QGC_APP_DESCRIPTION "HTI Ground Control" CACHE STRING "Application description" FORCE)
set(QGC_ORG_NAME "HTI" CACHE STRING "Organization name" FORCE)
set(QGC_ORG_DOMAIN "hti.local" CACHE STRING "Organization domain" FORCE)
set(QGC_PACKAGE_NAME "com.hti.groundcontrol" CACHE STRING "Package identifier" FORCE)
