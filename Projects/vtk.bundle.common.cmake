# Consolidates platform independent stub for vtk.bundle.cmake files.

include (vtk_version)

# Enable CPack packaging.
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_BINARY_DIR}/vtk/src/vtk/Copyright.txt")
set(CPACK_RESOURCE_FILE_README "${CMAKE_BINARY_DIR}/vtk/src/vtk/README.html")
set(CPACK_RESOURCE_FILE_WELCOME "${CMAKE_SOURCE_DIR}/Projects/readme.vtkpython.txt")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY
  "VTK is a library for scientific visualization.")
set(CPACK_PACKAGE_NAME "VTK")
set(CPACK_PACKAGE_VENDOR "Kitware, Inc.")
set(CPACK_PACKAGE_VERSION_MAJOR ${vtk_version_major})
set(CPACK_PACKAGE_VERSION_MINOR ${vtk_version_minor})
if (vtk_version_suffix)
  set(CPACK_PACKAGE_VERSION_PATCH ${vtk_version_patch}-${vtk_version_suffix})
else()
  set(CPACK_PACKAGE_VERSION_PATCH ${vtk_version_patch})
endif()

set(CPACK_PACKAGE_FILE_NAME
    "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${CPACK_PACKAGE_VERSION_PATCH}-${package_suffix}")

# Don't import CPack yet, let the platform specific code get another chance at
# changing the variables.
# include(CPack)
