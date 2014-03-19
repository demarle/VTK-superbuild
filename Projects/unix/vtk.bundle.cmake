# script to "bundle" vtk.

include(vtk.bundle.common)
include(CPack)

# install all VTK's shared libraries.
install(DIRECTORY "@install_location@/lib/"
  DESTINATION "lib"
  USE_SOURCE_PERMISSIONS
  COMPONENT superbuild)

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
  # install python
  if (python_ENABLED AND NOT USE_SYSTEM_python)
    install(DIRECTORY "@install_location@/lib/python2.7"
      DESTINATION "lib"
      USE_SOURCE_PERMISSIONS
      COMPONENT superbuild)
    # install pyconfig.h
    install (DIRECTORY "@install_location@/include/python2.7"
      DESTINATION "include"
      USE_SOURCE_PERMISSIONS
      COMPONENT superbuild
      PATTERN "pyconfig.h")
  endif()

  # install library dependencies for various executables.
  # the dependencies are searched only under the <install_location> and hence
  # system libraries are not packaged.
  set (reference_executable vtkpython)

  install(CODE
    "execute_process(COMMAND
      ${CMAKE_COMMAND}
        -Dexecutable:PATH=${install_location}/bin/${reference_executable}
        -Ddependencies_root:PATH=${install_location}
        -Dtarget_root:PATH=\${CMAKE_INSTALL_PREFIX}/lib
        -P ${CMAKE_CURRENT_LIST_DIR}/install_dependencies.cmake)"
    COMPONENT superbuild)

  # install executables
  set (executables vtkpython)

  foreach(executable ${executables})
    install(PROGRAMS "@install_location@/bin/${executable}"
      DESTINATION "bin"
      COMPONENT superbuild)
  endforeach()
endif()

add_test(NAME GenerateVTKPackage
         COMMAND ${CMAKE_CPACK_COMMAND} -G TGZ -V
         WORKING_DIRECTORY ${SuperBuild_BINARY_DIR})
set_tests_properties(GenerateVTKPackage PROPERTIES
                     # needed so that tests are run on typical paraview
                     # dashboards
                     LABELS "VTK"
                     TIMEOUT 1200) # increase timeout to 20 mins.
