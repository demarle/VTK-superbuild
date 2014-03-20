set(VTK_EXTRA_CMAKE_ARGS ""
    CACHE STRING "Extra arguments to be passed to VTK when configuring.")
mark_as_advanced(VTK_EXTRA_CMAKE_ARGS)

set (extra_cmake_args)
if(VTK_NIGHTLY_SUFFIX)
  list (APPEND extra_cmake_args
    -DVTK_NIGHTLY_SUFFIX:STRING=${VTK_NIGHTLY_SUFFIX})
endif()

set(osdefaultflags)
if (platform STREQUAL "linux")
  list(APPEND osdefaultflags "-DVTK_INSTALL_LIBRARY_DIR:STRING=lib")
  list(APPEND osdefaultflags "-DVTK_INSTALL_PYTHON_MODULE_DIR:STRING=lib/python2.7/site-packages")
elseif (platform STREQUAL "linux")
  list(APPEND osdefaultflags "-DVTK_INSTALL_LIBRARY_DIR:STRING=<INSTALL_DIR>/lib")
  list(APPEND osdefaultflags "-DVTK_INSTALL_PYTHON_MODULE_DIR:STRING=<INSTALL_DIR>/bin")
endif()

# --------------------------
# Build type
# --------------------------

set(package_conf)
if(GENERATE_JAVA_PACKAGE)

  # --------------------------
  # Cmd line that should be run to pre-download Java libraries dependancies:
  # - mvn org.apache.maven.plugins:maven-dependency-plugin:2.1:get -DrepoUrl=http://repo1.maven.org/maven2 -Dartifact=org.jogamp.gluegen:gluegen-rt:2.0.2
  # - mvn org.apache.maven.plugins:maven-dependency-plugin:2.1:get -DrepoUrl=http://repo1.maven.org/maven2 -Dartifact=org.jogamp.jogl:jogl-all:2.0.2
  # --------------------------
  message("Generate Java package for ${package_suffix}")

  list(APPEND package_conf "-DVTK_WRAP_PYTHON:BOOL=OFF")
  list(APPEND package_conf "-DVTK_WRAP_JAVA:BOOL=ON")
  list(APPEND package_conf "-DVTK_JAVA_INSTALL:BOOL=ON")
  list(APPEND package_conf "-DVTK_JAVA_JOGL_COMPONENT:BOOL=ON")
  list(APPEND package_conf "-DMAVEN_LOCAL_NATIVE_NAME:STRING=${package_suffix}")
  list(APPEND package_conf "-DMAVEN_NATIVE_ARTIFACTS:STRING=Linux-64bit:Linux-32bit:Win-32bit:Win-64bit:Darwin-64bit")
  list(APPEND package_conf "-DMAVEN_VTK_GROUP_ID:STRING=kitware.community")
else()
  list(APPEND package_conf "-DVTK_WRAP_PYTHON:BOOL=ON")
  list(APPEND package_conf "-DVTK_WRAP_JAVA:BOOL=OFF")
endif()

ExternalProject_Add(vtk
  DEPENDS_OPTIONAL
    boost ffmpeg hdf5 numpy png python zlib
    ${VTK_EXTERNAL_PROJECTS}

  LIST_SEPARATOR |

  CMAKE_ARGS
    -DBUILD_SHARED_LIBS:BOOL=ON
    -DBUILD_TESTING:BOOL=OFF

    -DVTK_USE_SYSTEM_HDF5:BOOL=${hdf5_ENABLED}
    ${osdefaultflags}

    # specify the apple app install prefix. No harm in specifying it for all
    # platforms.
    -DMACOSX_APP_INSTALL_PREFIX:PATH=<INSTALL_DIR>/Applications

    -DJAVA_AWT_INCLUDE_PATH:PATH=${JAVA_AWT_INCLUDE_PATH}
    -DJAVA_INCLUDE_PATH:PATH=${JAVA_INCLUDE_PATH}
    -DJAVA_INCLUDE_PATH2:PATH=${JAVA_INCLUDE_PATH2}

    -DJAVA_JVM_LIBRARY:PATH=${JAVA_JVM_LIBRARY}
    -DJAVA_AWT_LIBRARY:PATH=${JAVA_AWT_LIBRARY}

    -DJava_JAR_EXECUTABLE:FILEPATH=${Java_JAR_EXECUTABLE}
    -DJava_JAVAC_EXECUTABLE:FILEPATH=${Java_JAVAC_EXECUTABLE}
    -DJava_JAVADOC_EXECUTABLE:FILEPATH=${Java_JAVADOC_EXECUTABLE}
    -DJava_JAVAH_EXECUTABLE:FILEPATH=${Java_JAVAH_EXECUTABLE}
    -DJava_JAVA_EXECUTABLE:FILEPATH=${Java_JAVA_EXECUTABLE}

  ${extra_cmake_args}

  ${VTK_EXTRA_CMAKE_ARGS}

  ${package_conf}
)
