file(MAKE_DIRECTORY ${XNU_OBJ}/makedefs)
configure_file(${XNU_SRC}/cmake/MakeInc.cmd.in ${XNU_OBJ}/makedefs/MakeInc.cmd @ONLY)
configure_file(${XNU_SRC}/cmake/MakeInc.def.in ${XNU_OBJ}/makedefs/MakeInc.def @ONLY)

if(NOT DEFINED AVAILABILITY_PL_PATH)
    message(FATAL_ERROR "AVAILABILITY_PL_PATH must be set when running preprocess_files.cmake")
endif()

file(MAKE_DIRECTORY ${XNU_OBJ}/bsd/sys)
configure_file(${XNU_SRC}/cmake/make_symbol_aliasing.sh.in ${XNU_OBJ}/bsd/sys/make_symbol_aliasing.sh @ONLY)
