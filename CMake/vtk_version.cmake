# We hardcode the version numbers since we cannot determine versions during
# configure stage.
set (vtk_version_major 6)
set (vtk_version_minor 2)
set (vtk_version_patch 0)
#set (vtk_version_suffix "RC2")
set (vtk_version "${vtk_version_major}.${vtk_version_minor}")
if (vtk_version_suffix)
  set (vtk_version_long "${vtk_version}.${vtk_version_patch}-${vtk_version_suffix}")
else()
  set (vtk_version_long "${vtk_version}.${vtk_version_patch}")
endif()
