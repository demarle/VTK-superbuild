# script to "bundle" vtkpython.

#------------------------------------------------------------------------------
# include common stuff.

include(vtk.bundle.common)

if (CMAKE_CL_64)
  message("64 BIT")
  set(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES64")
  set(CPACK_NSIS_PACKAGE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${vtk_version_patch} (Win64)" )
  set(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${vtk_version_patch} (Win64)")
  message("IR ${CPACK_NSIS_INSTALL_ROOT}")
  message("PN ${CPACK_NSIS_PACKAGE_NAME}")
  message("RK ${CPACK_PACKAGE_INSTALL_REGISTRY_KEY}")
else()
  message("32 BIT")
  set(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES")
  set(CPACK_NSIS_PACKAGE_NAME "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${vtk_version_patch}" )
  set(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "${CPACK_PACKAGE_NAME}-${CPACK_PACKAGE_VERSION_MAJOR}.${CPACK_PACKAGE_VERSION_MINOR}.${vtk_version_patch}")
  message("IR ${CPACK_NSIS_INSTALL_ROOT}")
  message("PN ${CPACK_NSIS_PACKAGE_NAME}")
  message("RK ${CPACK_PACKAGE_INSTALL_REGISTRY_KEY}")
endif()

# set NSIS install specific stuff.

# URL to website providing assistance in installing your application.
set (CPACK_NSIS_HELP_LINK "http://vtk.org/Wiki/VTK")
set (CPACK_NSIS_MENU_LINKS
  "bin/vtkpython.exe" "VTK"
  )

#FIXME: need a pretty icon.

if(GENERATE_JAVA_PACKAGE)
  install(CODE
    "
    file(INSTALL
      DESTINATION \"\${CMAKE_INSTALL_PREFIX}\"
      USE_SOURCE_PERMISSIONS
      TYPE DIRECTORY
      FILES
        \"${install_location}/pom.xml\"
        \"${install_location}/README.txt\"
        \"${install_location}/vtk-${vtk_version_major}.${vtk_version_minor}.jar\"
        \"${install_location}/vtk-${vtk_version_major}.${vtk_version_minor}-natives-${package_suffix}.jar\"
    )
    "
    COMPONENT superbuild)
else()
  #------------------------------------------------------------------------------

  file(INSTALL
    DESTINATION "doc"
    USE_SOURCE_PERMISSIONS
    FILES "${CMAKE_SOURCE_DIR}/Projects/readme.vtkpython.txt")

  # install vtk executables to bin.
  foreach(executable
    vtkpython)
    install(PROGRAMS "${install_location}/bin/${executable}.exe"
      DESTINATION "bin"
      COMPONENT VTK)
  endforeach()

  # install all dlls to bin. This will install all VTK/ParaView dlls plus any
  # other tool dlls that were placed in bin.
  install(DIRECTORY "${install_location}/bin/"
          DESTINATION "bin"
          USE_SOURCE_PERMISSIONS
          COMPONENT VTK
          FILES_MATCHING PATTERN "*.dll")


  # install python since (since python dlls are not in the install location)
  if (python_ENABLED AND NOT USE_SYSTEM_python)
    # install the Python's modules.
    install(DIRECTORY "${SuperBuild_BINARY_DIR}/python/src/python/Lib"
            DESTINATION "bin"
            USE_SOURCE_PERMISSIONS
            COMPONENT VTK)

    # install python dlls.
    get_filename_component(python_bin_dir "${pv_python_executable}" PATH)
    install(DIRECTORY "${python_bin_dir}/"
            DESTINATION "bin"
            USE_SOURCE_PERMISSIONS
            COMPONENT VTK
            FILES_MATCHING PATTERN "python*.dll")

    # install python pyd objects (python dlls).
    # For 64 bit builds, these are in an amd64/ subdir
    set(PYTHON_PCBUILD_SUBDIR "")
    if(CMAKE_CL_64)
      set(PYTHON_PCBUILD_SUBDIR "amd64/")
    endif()
    install(DIRECTORY "${SuperBuild_BINARY_DIR}/python/src/python/PCbuild/${PYTHON_PCBUILD_SUBDIR}"
            DESTINATION "bin/Lib"
            USE_SOURCE_PERMISSIONS
            COMPONENT VTK
            FILES_MATCHING PATTERN "*.pyd")

  endif()

  if (numpy_ENABLED)
    install(DIRECTORY "${install_location}/lib/site-packages/numpy"
            DESTINATION "bin/Lib/site-packages"
            USE_SOURCE_PERMISSIONS
            COMPONENT VTK)
  endif()

  # install vtk python modules and others.
  install(DIRECTORY "${install_location}/lib/site-packages/vtk"
          DESTINATION "bin/Lib/site-packages"
          USE_SOURCE_PERMISSIONS
          COMPONENT VTK)
          #PATTERN "*.lib" EXCLUDE)

  #-----------------------------------------------------------------------------

  # install system runtimes.
  set(CMAKE_INSTALL_SYSTEM_RUNTIME_DESTINATION "bin")
  include(InstallRequiredSystemLibraries)
endif()

#-----------------------------------------------------------------------------
# include CPack at end so that all COMPONENTs specified in install rules are
# correctly detected.
include(CPack)
