# set extra cpack variables before calling paraview.bundle.common
#set (CPACK_GENERATOR DragNDrop) #disabled since don't want to encourage drag to /Applications
set (CPACK_GENERATOR TGZ)

# include some common stub.
include(vtk.bundle.common)
include(CPack)

# now fixup each of the applications.
# we only do vtkpython explicitly.
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
  install(CODE
    "
    file(INSTALL
         DESTINATION \"\${CMAKE_INSTALL_PREFIX}\"
         USE_SOURCE_PERMISSIONS
         TYPE DIRECTORY
         FILES \"${CMAKE_SOURCE_DIR}/Projects/readme.vtkpython.txt\")
    file(INSTALL
         DESTINATION \"\${CMAKE_INSTALL_PREFIX}/vtkpython/bin\"
         USE_SOURCE_PERMISSIONS
         TYPE DIRECTORY
         FILES \"${install_location}/bin/vtkpython\")
    file(INSTALL
         DESTINATION \"\${CMAKE_INSTALL_PREFIX}/vtkpython/bin/\"
         USE_SOURCE_PERMISSIONS
         TYPE DIRECTORY
         FILES \"${install_location}/lib/Python/vtk\")
    file(MAKE_DIRECTORY \"\${CMAKE_INSTALL_PREFIX}/vtkpython/lib\")
    execute_process(
        COMMAND ${CMAKE_CURRENT_LIST_DIR}/fixup_bundle.py
        \"\${CMAKE_INSTALL_PREFIX}/vtkpython/bin/vtkpython\"
        \"${install_location}/lib\")
    "
    COMPONENT superbuild)
endif()


add_test(NAME GenerateVTKPackage
         COMMAND ${CMAKE_CPACK_COMMAND} -G TGZ -V
         WORKING_DIRECTORY ${SuperBuild_BINARY_DIR})
set_tests_properties(GenerateVTKPackage PROPERTIES
                     # needed so that tests are run on typical paraview
                     # dashboards
                     LABELS "VTK"
                     TIMEOUT 1200) # increase timeout to 20 mins.
