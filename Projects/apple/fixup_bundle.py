#!/usr/bin/env python


#App="$1" # argument is the application to fixup
#LibrariesPrefix="Contents/Libraries"
#echo ""
#echo "Fixing up $App"
#echo "All required frameworks/libraries will be placed under $App/$LibrariesPrefix"
#echo ""
#echo "----------------------------"
#echo "Locating all executables and dylibs already in the package ... "
#
## the sed-call removes the : Mach-O.. suffix that "file" generates
#executables=`find $App | xargs file | grep -i "Mach-O.*executable" | sed "s/:.*//" | sort`
#
#echo "----------------------------"
#echo "Found following executables:"
#for i in $executables; do
#  echo $i
#done
#
## for each executable, find any external library.
#
#
#libraries=`find $App | xargs file | grep -i "Mach-O.*shared library" | sed "s/:.*//" | sort`
#
## command to find all external libraries referrenced in package:
## find paraview.app | xargs file | grep "Mach-O" | sed "s/:.*//" | xargs otool -l | grep " name" | sort | uniq | sed "s/name\ //" | grep -v "@executable"
#
## find non-system libs
## find paraview.app | xargs file | grep "Mach-O" | sed "s/:.*//" | xargs otool -l | grep " name" | sort | uniq | sed "s/name\ //" | grep -v "@executable" | grep -v "/System/" | grep -v "/usr/lib/"

import commands
import sys
import os.path
import re
import shutil

class Library(object):
  def __init__(self):
    # This is the actual path to a physical file
    self.RealPath = None

    # This is the id for shared library.
    self.Id = None

    # These are names for symbolic links to this file.
    self.SymLinks = []

    self.__depencies = None
    pass

  def __hash__(self):
    return self.RealPath.__hash__()

  def __eq__(self, other):
    return self.RealPath == other.RealPath

  def __repr__(self):
    return "Library(%s : %s)" % (self.Id, self.RealPath)

  def dependencies(self, exepath):
    if self.__depencies:
      return self.__depencies
    collection = set()
    for dep in _getdependencies(self.RealPath):
      collection.add(Library.createFromReference(dep, exepath))
    self.__depencies = collection
    return self.__depencies

  def copyToApp(self, app, fakeCopy=False):
    appdir = os.path.dirname(app)
    if _isframework(self.RealPath):
      print "is framework"
      m = re.match(r'(.*)/(\w+\.framework)/(.*)', self.RealPath)
      # FIXME: this could be optimized to only copy the particular version.
      if not fakeCopy:
        print "Copying %s/%s ==> %s" % (m.group(1), m.group(2), ".../Contents/Frameworks/")
        dirdest = os.path.join(os.path.join(appdir, "Contents/Frameworks/"), m.group(2))
        filedest = os.path.join(dirdest, m.group(3))
        shutil.copytree(os.path.join(m.group(1), m.group(2)), dirdest, symlinks=True)
      self.Id = "@executable_path/../Frameworks/%s" % (os.path.join(m.group(2), m.group(3)))
      #print self.Id, dirdest, filedest
      if not fakeCopy:
        commands.getoutput('install_name_tool -id "%s" %s' % (self.Id, filedest))
    else:
      print "is library"
      if not fakeCopy:
        print "Copying %s ==> %s" % (self.RealPath, os.path.join(appdir, "..", "/lib/"))
        shutil.copy(self.RealPath, os.path.join(appdir, "..", "lib"))
      self.Id = "@executable_path/../lib/%s" % os.path.basename(self.RealPath)
      if not fakeCopy:
        commands.getoutput('install_name_tool -id "%s" %s' % (self.Id,
                            os.path.join(appdir, "../lib/%s" % os.path.basename(self.RealPath))))
      """
      # Create symlinks for this copied file in the install location
      # as were present in the source dir.
      destdir = os.path.join(appdir, "../lib")
      # sourcefile is the file we copied already into the app bundle. We need to create symlink
      # to it itself in the app bundle.
      sourcefile = os.path.basename(self.RealPath)
      for symlink in self.SymLinks:
        print "Creating Symlink %s ==> .../../lib/%s" % (symlink, os.path.basename(self.RealPath))
        if not fakeCopy:
          commands.getoutput("ln -s %s %s" % (sourcefile, os.path.join(destdir, symlink)))
      """

  @classmethod
  def createFromReference(cls, ref, exepath):
    path = ref.replace("@executable_path", exepath)
    print "looking for ", path
    if not os.path.exists(path):
      print "not found"
      path = _find(ref)
      print "result:", path
    return cls.createFromPath(path)

  @classmethod
  def createFromPath(cls, path):
    if not os.path.exists(path):
      raise RuntimeError, "%s is not a filename" % path
    lib = Library()
    lib.RealPath = os.path.realpath(path)
    lib.Id = _getid(path)
    # locate all symlinks to this file in the containing directory. These are used when copying.
    # We ensure that we copy all symlinks too.
    dirname = os.path.dirname(lib.RealPath)
    symlinks = commands.getoutput("find -L %s -samefile %s" % (dirname, lib.RealPath))
    symlinks = symlinks.split()
    try:
      symlinks.remove(lib.RealPath)
    except ValueError:
      pass
    linknames = []
    for link in symlinks:
      linkname = os.path.basename(link)
      linknames.append(linkname)
    lib.SymLinks = linknames
    return lib


def _getid(lib):
  """Returns the id for the library"""
  val = commands.getoutput("otool -D %s" % lib)
  m = re.match(r"[^:]+:\s*([^\s]+)", val)
  if m:
    return m.group(1)
  raise RuntimeError, "Could not determine id for %s" % lib

def _getdependencies(path):
  val = commands.getoutput('otool -l %s| grep " name" | sort | uniq | sed "s/name\ //" | sed "s/(offset.*)//"' % path)
  return val.split()

def isexcluded(id):
  # we don't consider the libgfortran or libquadmath a system library since
  # it will rarely be on the installed machine
  if re.match(r".*libgfortran.*", id) or re.match(r".*libquadmath.*", id):
    return False
  if re.match(r"^/System/Library", id):
    return True
  if re.match(r"^/usr/lib", id):
    return True
  if re.match(r"^/usr/local", id):
    return True
  if re.match(r"^libz.1.dylib", id):
    return True
  return False

def _isframework(path):
  if re.match(".*\.framework.*", path):
    return True

def _find(ref):
  name = os.path.basename(ref)
  for loc in SearchLocations:
    output = commands.getoutput('find "%s" -name "%s"' % (loc, name)).strip()
    if output:
      print "find command found:", output
      return output
  return ref

SearchLocations = []
if __name__ == "__main__":
  App = sys.argv[1]
  SearchLocations = [sys.argv[2]]
  print "App:",App
  print "SearchLocations:",SearchLocations

  appdir = os.path.dirname(App)
  print "appdir:",appdir
  #os.mkdir(os.path.join(appdir,"..","lib"))

  # Find libraries inside the package already.
  libraries = commands.getoutput('find %s -type f | xargs file | grep -i "Mach-O.*shared library" | sed "s/:.*//" | sort' % SearchLocations[0])
  libraries = libraries.split()
  print libraries
  print "Found %d libraries within the package." % len(libraries)

  # Find external libraries. Any libraries referred to with @.* relative paths are treated as already in the package.
  # ITS NOT THIS SCRIPT'S JOB TO FIX BROKEN INSTALL RULES.

  external_libraries = commands.getoutput(
    'find %s | xargs file | grep "Mach-O" | sed "s/:.*//" | xargs otool -l | grep " name" | sort | uniq | sed "s/name\ //" | grep -v "@" | sed "s/ (offset.*)//"' % appdir)
  elibraries = external_libraries.split()
  print elibraries
  print "Found %d external libraries refered to by the executable." % len(elibraries)

  mLibraries = set()
  all_libs = libraries + external_libraries.split()
  for lib in all_libs:
    if not isexcluded(lib):
      print "Processing ", lib
      mLibraries.add(Library.createFromReference(lib, "%s/../lib" % appdir))

  print "Found %d direct external dependencies." % len(mLibraries)

  def recursive_dependency_scan(base, to_scan):
    dependencies = set()
    for lib in to_scan:
      dependencies.update(lib.dependencies("%s/../lib" % appdir))
    dependencies -= base
    # Now we have the list of non-packaged dependencies.
    dependencies_to_package = set()
    for dep in dependencies:
      if not isexcluded(dep.RealPath):
        dependencies_to_package.add(dep)
    if len(dependencies_to_package) > 0:
      new_base = base | dependencies_to_package
      dependencies_to_package |= recursive_dependency_scan(new_base, dependencies_to_package)
      return dependencies_to_package
    return dependencies_to_package

  indirect_mLibraries = recursive_dependency_scan(mLibraries, mLibraries)
  print "Found %d indirect external dependencies." % (len(indirect_mLibraries))
  print ""
  mLibraries.update(indirect_mLibraries)

  print "------------------------------------------------------------"
  install_name_tool_command = []
  for dep in mLibraries:
    old_id = dep.Id
    print "copy ", dep
    dep.copyToApp(App)
    new_id = dep.Id
    install_name_tool_command += ["-change", '"%s"' % old_id, '"%s"' % new_id]
  print ""

  install_name_tool_command = " ".join(install_name_tool_command)
  print "command:", install_name_tool_command

  print "------------------------------------------------------------"
  print "Running 'install_name_tool' to fix paths to copied files."
  print ""
  # Run the command for all libraries and executables.
  # The --separator for file allows helps use locate the file name accurately.
  binaries_to_fix = commands.getoutput('find %s -type f | xargs file --separator ":--:" | grep -i ":--:.*Mach-O" | sed "s/:.*//" | sort | uniq ' % appdir).split()
  binaries_to_fix2 = commands.getoutput('find %s/../lib -type f | xargs file --separator ":--:" | grep -i ":--:.*Mach-O" | sed "s/:.*//" | sort | uniq ' % appdir).split()
  binaries_to_fix = binaries_to_fix + binaries_to_fix2
  print "TO FIX:", binaries_to_fix
  result = ""
  for dep in binaries_to_fix:
    commands.getoutput('chmod u+w "%s"' % dep)
  #  print "Fixing '%s'" % dep
    commands.getoutput('install_name_tool %s "%s"' % (install_name_tool_command, dep))
    commands.getoutput('chmod a-w "%s"' % dep)
