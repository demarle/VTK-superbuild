# set extra cpack variables before calling paraview.bundle.common
#set (CPACK_GENERATOR DragNDrop) #disabled since don't want to encourage drag to /Applications
set (CPACK_GENERATOR TGZ)

# include some common stub.
include(vtk.bundle.common)
include(CPack)

# now fixup each of the applications.
# we only do vtkpython explicitly.
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
