# This file contains common MOOSE application settings
# Note: MOOSE applications are assumed to reside in peer directories relative to MOOSE and its modules.
#       This can be overridden by using the MOOSE_DIR environment variable

# list of application-wide excluded source files
excluded_srcfiles :=

#
# Save off parameters for possible app.mk recursion
#
STACK ?= stack
STACK := $(STACK).X
$APPLICATION_DIR$(STACK) := $(APPLICATION_DIR)
$APPLICATION_NAME$(STACK) := $(APPLICATION_NAME)
$DEPEND_MODULES$(STACK) := $(DEPEND_MODULES)
$BUILD_EXEC$(STACK) := $(BUILD_EXEC)
$DEP_APPS$(STACK) := $(DEP_APPS)

-include $(APPLICATION_DIR)/$(APPLICATION_NAME).mk

#
# Restore parameters
#
APPLICATION_DIR := $($APPLICATION_DIR$(STACK))
APPLICATION_NAME := $($APPLICATION_NAME$(STACK))
DEPEND_MODULES := $($DEPEND_MODULES$(STACK))
BUILD_EXEC := $($BUILD_EXEC$(STACK))
DEP_APPS := $($DEP_APPS$(STACK))
STACK := $(basename $(STACK))

ifneq ($(SUFFIX),)
  app_LIB_SUFFIX := $(app_LIB_SUFFIX)_$(SUFFIX)
endif

##############################################################################
######################### Application Variables ##############################
##############################################################################
#
# source files
TEST_SRC_DIRS    := $(APPLICATION_DIR)/test/src
SRC_DIRS    := $(APPLICATION_DIR)/src
PLUGIN_DIR  := $(APPLICATION_DIR)/plugins

excluded_srcfiles += main.C
find_excludes     := $(foreach i, $(excluded_srcfiles), -not -name $(i))
srcfiles    := $(shell find $(SRC_DIRS) -name "*.C" $(find_excludes))


### Unity Build ###
ifeq ($(MOOSE_UNITY),true)

unity_src_dir = $(APPLICATION_DIR)/build/unity_src

# Build unity buiild directory
$(eval $(call unity_dir_rule, $(unity_src_dir)))

# Exclude .libs... but also: exclude unity building src.
# The idea here is that if all they have is src then it's a big jumble of stuff
# that won't benefit from unity building
non_unity_dirs := %.libs %/src

# Find all of the individual subdirectories
# We will create a Unity file for each individual subdirectory
# The idea is that files grouped withing a subdirectory are closely related
# and will benefit from a Unity build
srcsubdirs := $(shell find $(APPLICATION_DIR)/src -type d -not -path '*/.libs*')

# Filter out the paths we don't want to Unity build
unity_srcsubdirs := $(filter-out $(non_unity_dirs), $(srcsubdirs))
non_unity_srcsubdirs := $(filter $(non_unity_dirs), $(srcsubdirs))

# This is a biggie
# Loop over the subdirectories, creating a rule to create the Unity source file
# for each subdirectory.  To do that we need to create a unique name using the
# full hierarchy of the path underneath src
$(foreach srcsubdir,$(unity_srcsubdirs),$(eval $(call unity_file_rule,$(call unity_unique_name,$(unity_src_dir),$(APPLICATION_DIR),$(srcsubdir)),$(shell find $(srcsubdir) -maxdepth 1 -type f -name "*.C"),$(srcsubdir),$(unity_src_dir))))

# This creates the whole list of Unity source files so we can use it as a dependency
app_unity_srcfiles = $(foreach srcsubdir,$(unity_srcsubdirs),$(call unity_unique_name,$(unity_src_dir),$(APPLICATION_DIR),$(srcsubdir)))

# Add to the global list of unity source files
unity_srcfiles += $(app_unity_srcfiles)

# Pick up all of the additional files in the src directory since we're not unity building those
files_in_src := $(filter-out %main.C, $(shell find $(APPLICATION_DIR)/src -maxdepth 1 -name "*.C" -type f))

# Override srcfiles
srcfiles    := $(app_unity_srcfiles) $(if $(non_unity_src_subdirs), $(shell find $(non_unity_srcsubdirs) -name "*.C"),) $(files_in_src)
endif



csrcfiles   := $(shell find $(SRC_DIRS) -name "*.c")
fsrcfiles   := $(shell find $(SRC_DIRS) -name "*.f")
f90srcfiles := $(shell find $(SRC_DIRS) -name "*.f90")

# object files
ifeq ($(LIBRARY_SUFFIX),yes)
objects	    := $(patsubst %.C, %_with$(app_LIB_SUFFIX).$(obj-suffix), $(srcfiles))
else
objects	    := $(patsubst %.C, %.$(obj-suffix), $(srcfiles))
endif
cobjects    := $(patsubst %.c, %.$(obj-suffix), $(csrcfiles))
fobjects    := $(patsubst %.f, %.$(obj-suffix), $(fsrcfiles))
f90objects  := $(patsubst %.f90, %.$(obj-suffix), $(f90srcfiles))

app_objects := $(objects) $(cobjects) $(fobjects) $(f90objects) $(ADDITIONAL_APP_OBJECTS)

test_srcfiles    := $(shell find $(TEST_SRC_DIRS) -name "*.C" $(find_excludes) 2>/dev/null)
test_csrcfiles   := $(shell find $(TEST_SRC_DIRS) -name "*.c" 2>/dev/null)
test_fsrcfiles   := $(shell find $(TEST_SRC_DIRS) -name "*.f" 2>/dev/null)
test_f90srcfiles := $(shell find $(TEST_SRC_DIRS) -name "*.f90" 2>/dev/null)
ifeq ($(LIBRARY_SUFFIX),yes)
  test_objects:= $(patsubst %.C, %_with$(app_LIB_SUFFIX).$(obj-suffix), $(test_srcfiles))
else
  test_objects:= $(patsubst %.C, %.$(obj-suffix), $(test_srcfiles))
endif

test_cobjects:= $(patsubst %.c, %.$(obj-suffix), $(test_csrcfiles))
test_fobjects:= $(patsubst %.f, %.$(obj-suffix), $(test_fsrcfiles))
test_f90objects:= $(patsubst %.f90, %.$(obj-suffix), $(test_f90srcfiles))
app_test_objects := $(test_objects) $(test_cobjects) $(test_fobjects) $(test_f90objects)

# plugin files
plugfiles   := $(shell find $(PLUGIN_DIR) -name "*.C" 2>/dev/null)
cplugfiles  := $(shell find $(PLUGIN_DIR) -name "*.c" 2>/dev/null)
fplugfiles  := $(shell find $(PLUGIN_DIR) -name "*.f" 2>/dev/null)
f90plugfiles:= $(shell find $(PLUGIN_DIR) -name "*.f90" 2>/dev/null)

# plugins
plugins	    := $(patsubst %.C, %-$(METHOD).plugin, $(plugfiles))
plugins	    += $(patsubst %.c, %-$(METHOD).plugin, $(cplugfiles))
plugins	    += $(patsubst %.f, %-$(METHOD).plugin, $(fplugfiles))
plugins	    += $(patsubst %.f90, %-$(METHOD).plugin, $(f90plugfiles))

# main
MAIN_DIR    ?= $(APPLICATION_DIR)/src
main_src    := $(MAIN_DIR)/main.C
main_object := $(patsubst %.C, %.$(obj-suffix), $(main_src))

# dependency files
app_deps     := $(patsubst %.$(obj-suffix), %.$(obj-suffix).d, $(objects)) \
                $(patsubst %.c, %.$(obj-suffix).d, $(csrcfiles)) \
                $(patsubst %.C, %.$(obj-suffix).d, $(main_src)) \
                $(ADDITIONAL_APP_DEPS)

app_test_deps     := $(patsubst %.$(obj-suffix), %.$(obj-suffix).d, $(test_objects)) \
                $(patsubst %.c, %.$(obj-suffix).d, $(test_csrcfiles))
depend_dirs := $(foreach i, $(DEPEND_MODULES), $(MOOSE_DIR)/modules/$(i)/include)
depend_dirs += $(APPLICATION_DIR)/include
ifneq ($(wildcard $(APPLICATION_DIR)/test/include/*),)
  depend_dirs += $(APPLICATION_DIR)/test/include
endif

# header files
include_dirs	:= $(shell find $(depend_dirs) -type d | grep -v "\.svn")
include_files	:= $(shell find $(depend_dirs) -name "*.[hf]" | grep -v "\.svn")

# clang static analyzer files
app_analyzer := $(patsubst %.C, %.plist.$(obj-suffix), $(srcfiles))

# library
ifeq ($(LIBRARY_SUFFIX),yes)
  app_LIB     := $(APPLICATION_DIR)/lib/lib$(APPLICATION_NAME)_with$(app_LIB_SUFFIX)-$(METHOD).la
else
  app_LIB     := $(APPLICATION_DIR)/lib/lib$(APPLICATION_NAME)-$(METHOD).la
endif

ifeq ($(LIBRARY_SUFFIX),yes)
  app_test_LIB     := $(APPLICATION_DIR)/test/lib/lib$(APPLICATION_NAME)_with$(app_LIB_SUFFIX)_test-$(METHOD).la
else
  app_test_LIB     := $(APPLICATION_DIR)/test/lib/lib$(APPLICATION_NAME)_test-$(METHOD).la
endif

# all_header_directory
all_header_dir := $(APPLICATION_DIR)/build/header_symlinks

# header file links

link_names := $(foreach i, $(include_files), $(all_header_dir)/$(notdir $(i)))

$(eval $(call all_header_dir_rule, $(all_header_dir)))
$(call symlink_rules, $(all_header_dir), $(include_files))

header_symlinks:: $(all_header_dir) $(link_names)

# application
app_EXEC    := $(APPLICATION_DIR)/$(APPLICATION_NAME)-$(METHOD)

# revision header
CAMEL_CASE_NAME := $(shell echo $(APPLICATION_NAME) | perl -pe 's/(?:^|_)([a-z])/\u$$1/g')
app_BASE_DIR    ?= base/
app_HEADER      ?= $(APPLICATION_DIR)/include/$(app_BASE_DIR)$(CAMEL_CASE_NAME)Revision.h
# depend modules
depend_libs  := $(foreach i, $(DEPEND_MODULES), $(MOOSE_DIR)/modules/$(i)/lib/lib$(i)-$(METHOD).la)

ifeq ($(USE_TEST_LIBS),yes)
  depend_test_libs := $(depend_test_libs) $(app_test_LIB)
  depend_test_libs_flags := $(foreach i, $(depend_test_libs), -L$(dir $(i)) -l$(shell echo $(notdir $(i)) | perl -pe 's/^lib(.*?)\.la/$$1/'))
endif


##################################################################################################
# If we are NOT building a module, then make sure the dependency libs are updated to reflect
# all real dependencies
##################################################################################################
ifeq (,$(findstring $(APPLICATION_NAME), $(MODULE_NAMES)))
  depend_libs := $(depend_libs) $(app_LIBS)
endif
# Here we'll filter out MOOSE libs since we'll assume our application already has MOOSE compiled in
depend_libs := $(filter-out $(moose_LIBS),$(depend_libs))
# Create -L/-l versions of the depend libs
depend_libs_flags := $(foreach i, $(depend_libs), -L$(dir $(i)) -l$(shell echo $(notdir $(i)) | perl -pe 's/^lib(.*?)\.la/$$1/'))

# If building shared libs, make the plugins a dependency, otherwise don't.
ifeq ($(libmesh_shared),yes)
  app_plugin_deps := $(plugins)
else
  app_plugin_deps :=
endif

app_LIBS       := $(app_LIB) $(app_LIBS)
app_LIBS_other := $(filter-out $(app_LIB),$(app_LIBS))
app_HEADERS    := $(app_HEADER) $(app_HEADERS)
app_INCLUDES   += -I$(all_header_dir) $(ADDITIONAL_INCLUDES)
app_DIRS       += $(APPLICATION_DIR)

# WARNING: the += operator does NOT work here!
ADDITIONAL_CPPFLAGS := $(ADDITIONAL_CPPFLAGS) -D$(shell echo $(APPLICATION_NAME) | perl -pe 'y/a-z/A-Z/' | perl -pe 's/-//g')_ENABLED

# dependencies
-include $(app_deps)
-include $(app_test_deps)

# Rest the certain variables in case this file is sourced again
DEPEND_MODULES :=
SUFFIX :=
LIBRARY_SUFFIX :=


###############################################################################
# Build Rules:
#
###############################################################################

# Instantiate a new suffix rule for the module loader
$(eval $(call CXX_RULE_TEMPLATE,_with$(app_LIB_SUFFIX)))

ifeq ($(BUILD_EXEC),yes)
  all:: $(app_EXEC)
endif

BUILD_EXEC :=

app_GIT_DIR := $(shell cd "$(APPLICATION_DIR)" && which git &> /dev/null && git rev-parse --show-toplevel)
# Use wildcard in case the files don't exist
app_HEADER_deps := $(wildcard $(app_GIT_DIR)/.git/HEAD $(app_GIT_DIR)/.git/index)
# Target-specific Variable Values (See GNU-make manual)
$(app_HEADER): curr_dir    := $(APPLICATION_DIR)
$(app_HEADER): curr_app    := $(APPLICATION_NAME)
$(app_HEADER): all_header_dir := $(all_header_dir)
$(app_HEADER): $(app_HEADER_deps)
	@echo "MOOSE Checking if header needs updating: "$@"..."
	$(shell $(FRAMEWORK_DIR)/scripts/get_repo_revision.py $(curr_dir) $@ $(curr_app))
	@ln -sf $@ $(all_header_dir)

# Target-specific Variable Values (See GNU-make manual)
$(app_LIB): curr_objs := $(app_objects)
$(app_LIB): curr_dir  := $(APPLICATION_DIR)
$(app_LIB): curr_deps := $(depend_libs)
$(app_LIB): curr_libs := $(depend_libs_flags)
$(app_LIB): $(app_HEADER) $(app_plugin_deps) $(depend_libs) $(app_objects)
	@echo "Linking Library "$@"..."
	@$(libmesh_LIBTOOL) --tag=CXX $(LIBTOOLFLAGS) --mode=link --quiet \
	  $(libmesh_CXX) $(libmesh_CXXFLAGS) -o $@ $(curr_objs) $(libmesh_LDFLAGS) $(EXTERNAL_FLAGS) -rpath $(curr_dir)/lib $(curr_libs)
	@$(libmesh_LIBTOOL) --mode=install --quiet install -c $@ $(curr_dir)/lib

ifeq ($(BUILD_TEST_OBJECTS_LIB),no)
  app_test_LIB :=
  depend_test_libs :=
  depend_test_libs_flags :=
else
# Target-specific Variable Values (See GNU-make manual)
$(app_test_LIB): curr_objs := $(app_test_objects)
$(app_test_LIB): curr_dir  := $(APPLICATION_DIR)/test
$(app_test_LIB): curr_deps := $(depend_libs)
$(app_test_LIB): curr_libs := $(depend_libs_flags)
$(app_test_LIB): $(app_HEADER) $(app_plugin_deps) $(depend_libs) $(app_test_objects)
	@echo "Linking Library "$@"..."
	@$(libmesh_LIBTOOL) --tag=CXX $(LIBTOOLFLAGS) --mode=link --quiet \
	  $(libmesh_CXX) $(libmesh_CXXFLAGS) -o $@ $(curr_objs) $(libmesh_LDFLAGS) $(EXTERNAL_FLAGS) -rpath $(curr_dir)/lib $(curr_libs)
	@$(libmesh_LIBTOOL) --mode=install --quiet install -c $@ $(curr_dir)/lib
endif

$(app_EXEC): $(app_LIBS) $(mesh_library) $(main_object) $(app_test_LIB) $(depend_test_libs) $(ADDITIONAL_DEPEND_LIBS)
	@echo "Linking Executable "$@"..."
	@$(libmesh_LIBTOOL) --tag=CXX $(LIBTOOLFLAGS) --mode=link --quiet \
	  $(libmesh_CXX) $(libmesh_CXXFLAGS) -o $@ $(main_object) $(app_test_LIB) $(app_LIBS) $(depend_test_libs) $(libmesh_LIBS) $(libmesh_LDFLAGS) $(depend_test_libs_flags) $(EXTERNAL_FLAGS) $(ADDITIONAL_LIBS)

# Clang static analyzer
sa:: $(app_analyzer)

compile_commands_all_srcfiles += $(srcfiles)
