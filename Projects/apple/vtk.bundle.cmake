# set extra cpack variables before calling paraview.bundle.common
set (CPACK_GENERATOR DragNDrop)

# include some common stub.
include(vtk.bundle.common)
include(CPack)

# now fixup each of the applications.
# we only do vtkpython explicitly.
install(CODE
  "
  file(INSTALL DESTINATION \"\${CMAKE_INSTALL_PREFIX}/bin\" USE_SOURCE_PERMISSIONS TYPE DIRECTORY FILES
  \"${install_location}/bin/vtkpython\")
  file(MAKE_DIRECTORY \"\${CMAKE_INSTALL_PREFIX}/lib\")
  file(INSTALL DESTINATION \"\${CMAKE_INSTALL_PREFIX}/lib/\" USE_SOURCE_PERMISSIONS TYPE DIRECTORY FILES
  \"${install_location}/lib/Python\")
#  \"${install_location}/lib/Python\" PATTERN \"*.so\" EXCLUDE)

  execute_process(
      COMMAND ${CMAKE_CURRENT_LIST_DIR}/fixup_bundle.py
      \"\${CMAKE_INSTALL_PREFIX}/bin/vtkpython\"
      \"${install_location}/lib\")
  "
  COMPONENT superbuild)
