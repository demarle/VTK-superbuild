set(PV_EXTRA_CMAKE_ARGS ""
    CACHE STRING "Extra arguments to be passed to ParaView when configuring.")
mark_as_advanced(PV_EXTRA_CMAKE_ARGS)

set (extra_cmake_args)
if(PV_NIGHTLY_SUFFIX)
  list (APPEND extra_cmake_args
    -DPV_NIGHTLY_SUFFIX:STRING=${PV_NIGHTLY_SUFFIX})
endif()

add_external_project(paraview
  DEPENDS_OPTIONAL
    boost ffmpeg hdf5 numpy png python zlib
    ${PV_EXTERNAL_PROJECTS}

  CMAKE_ARGS
    -DBUILD_SHARED_LIBS:BOOL=ON
    -DBUILD_TESTING:BOOL=OFF
    -DVTK_WRAP_PYTHON:BOOL=${python_ENABLED}
    -DVTK_USE_SYSTEM_HDF5:BOOL=${hdf5_ENABLED}
    -DVTK_INSTALL_LIBRARY_DIR:STRING=<INSTALL_DIR>/lib
    -DVTK_INSTALL_PYTHON_MODULE_DIR:STRING=<INSTALL_DIR>/lib/Python

    # specify the apple app install prefix. No harm in specifying it for all
    # platforms.
    -DMACOSX_APP_INSTALL_PREFIX:PATH=<INSTALL_DIR>/Applications

  ${extra_cmake_args}

  ${PV_EXTRA_CMAKE_ARGS}
)
