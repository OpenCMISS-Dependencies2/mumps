# Borrowed heavily from https://github.com/amd/mumps-build
#
# With the license permissions:
#
# MIT License
#  
# Copyright (c) 2021-2022 Advanced Micro Devices, Inc. All rights reserved
#  
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#  
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#  
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

cmake_minimum_required(VERSION 3.26 FATAL_ERROR)

set(MUMPS_MAJOR_VERSION 5)
set(MUMPS_MINOR_VERSION 7)
set(MUMPS_PATCH_VERSION 3)

set(MUMPS_VERSION "${MUMPS_MAJOR_VERSION}.${MUMPS_MINOR_VERSION}.${MUMPS_PATCH_VERSION}")

project(MUMPS
  LANGUAGES C Fortran
  VERSION ${MUMPS_VERSION}
  HOMEPAGE_URL "http://mumps-solver.org/"
)

option(BUILD_SHARED_LIBS "Enable building of shared libraries." ON)
option(PARALLEL "Enable parallel MUMPS." ON)
option(OPENMP "Enable OpenMP." ON)
option(LARGE_INTEGERS "Enable large integer support." OFF)
option(SCOTCH_ORDERING "Enable Scotch/PT-Scotch orderings." ON)
option(METIS_ORDERING "Enable METIS orderings." ON)
option(PARMETIS_ORDERING "Enable ParMETIS orderings." ON)
option(BUILD_SINGLE "Enable single precision MUMPS." ON)
option(BUILD_DOUBLE "Enable double precision MUMPS." ON)
option(BUILD_COMPLEX "Enable single precision complex MUMPS." ON)
option(BUILD_COMPLEX16 "Enable double precision complex MUMPS." ON)

if(BUILD_SHARED_LIBS)
  set(MUMPS_LIBRARY_TYPE "SHARED")
else()
  set(MUMPS_LIBRARY_TYPE "STATIC")
endif()

set(MUMPS_ARITH_LIST )
if(BUILD_SINGLE)
  list(APPEND MUMPS_ARITH_LIST "s") 
endif()
if(BUILD_DOUBLE)
  list(APPEND MUMPS_ARITH_LIST "d") 
endif()
if(BUILD_COMPLEX)
  list(APPEND MUMPS_ARITH_LIST "c") 
endif()
if(BUILD_COMPLEX16)
  list(APPEND MUMPS_ARITH_LIST "z") 
endif()

include(OCCMakeMiscellaneous)

OCCMakeDebug("BUILD_SHARED_LIBS = '${BUILD_SHARED_LIBS}'" 1)
OCCMakeDebug("PARALLEL = '${PARALLEL}'" 1)
OCCMakeDebug("OPENMP = '${OPENMP}'" 1)
OCCMakeDebug("LARGE_INTEGERS = '${LARGE_INTEGERS}'" 1)
OCCMakeDebug("SCOTCH_ORDERING = '${SCOTCH_ORDERING}'" 1)
OCCMakeDebug("METIS_ORDERING = '${METIS_ORDERING}'" 1)
OCCMakeDebug("PARMETIS_ORDERING = '${PARMETIS_ORDERING}'" 1)
OCCMakeDebug("BUILD_SINGLE = '${BUILD_SINGLE}'" 1)
OCCMakeDebug("BUILD_DOUBLE = '${BUILD_DOUBLE}'" 1)
OCCMakeDebug("BUILD_COMPLEX = '${BUILD_COMPLEX}'" 1)
OCCMakeDebug("BUILD_COMPLEX16 = '${BUILD_COMPLEX16}'" 1)

include(GNUInstallDirs)

# Set compiler flags

# Add_
add_compile_definitions("$<$<COMPILE_LANGUAGE:C>:Add_>")
# Large indicies
add_compile_definitions("$<$<BOOL:${LARGE_INTEGERS}>:INTSIZE64;PORD_INTSIZE64>")

if(CMAKE_C_COMPILER_ID STREQUAL "IntelLLVM")
  add_compile_options( "$<$<COMPILE_LANGUAGE:C>:-Werror-implicit-function-declaration>" )
  add_compile_options( "$<$<COMPILE_LANGUAGE:C>:-xHost>" )
  # OpenMP
  add_compile_options( "$<$<AND:$<COMPILE_LANGUAGE:C>,$<BOOL:${OPENMP}>>:-fiopenmp>" )
elseif(CMAKE_C_COMPILER_ID STREQUAL "GNU")
  add_compile_options( "$<$<COMPILE_LANGUAGE:C>:-Werror-implicit-function-declaration>" )
  # OpenMP
  add_compile_options( "$<$<AND:$<COMPILE_LANGUAGE:C>,$<BOOL:${OPENMP}>>:-fopenmp>" )
elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
  add_compile_options( "$<$<COMPILE_LANGUAGE:C>:-Werror-implicit-function-declaration>" )
elseif(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  add_compile_definitions( "$<COMPILE_LANGUAGE:C>:_CRT_SECURE_NO_WARNINGS>" )
endif()

if(CMAKE_Fortran_COMPILER_ID MATCHES "^Intel")
  add_compile_options( "$<$<COMPILE_LANGUAGE:Fortran>:-xHost>" )
  # OpenMP
  add_compile_options( "$<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<BOOL:${OPENMP}>>:-fiopenmp>" )
  # Large indices
  add_compile_options( "$<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<BOOL:${LARGE_INTEGERS}>>:-i8>" )
  add_compile_definitions( "$<$<AND:$<COMPILE_LANGUAGE:Fortran>,$<BOOL:${LARGE_INTEGERS}>>:WORKAROUNDINTELILP64MPI2INTEGER>" )
elseif(CMAKE_Fortran_COMPILER_ID STREQUAL "GNU")
  add_compile_options( "$<$<COMPILE_LANGUAGE:Fortran>:-fimplicit-none;-fallow-argument-mismatch;-fallow-invalid-boz>" )
  add_compile_options( "-mtune=native" )
  # OpenMP
  add_compile_options( "$<$<AND:$<COMPILE_LANGUAGE:C>,$<BOOL:${OPENMP}>>:-fopenmp>" )
endif()

# Dependencies

# Threading
find_package(Threads REQUIRED)
set(MUMPS_NUMERICAL_LIBRARIES Threads::Threads)

# Lapack
find_package(LAPACK REQUIRED)
set(MUMPS_NUMERICAL_LIBRARIES LAPACK::LAPACK)

if(PARALLEL)
  # MPI
  find_package(MPI COMPONENTS C Fortran REQUIRED)
  list(APPEND MUMPS_NUMERICAL_LIBRARIES MPI::MPI_Fortran MPI::MPI_C)
  
  # ScaLAPCK
  find_package(ScaLAPACK REQUIRED)
  list(PREPEND MUMPS_NUMERICAL_LIBRARIES ScaLAPACK::ScaLAPACK)
    
  # OpenMP
  if(OPENMP)
    find_package(OpenMP COMPONENTS C Fortran REQUIRED)
    list(APPEND MUMPS_NUMERICAL_LIBRARIES OpenMP::OpenMP_Fortran OpenMP::OpenMP_C)
  endif()
endif()

# Orderings

set(MUMPS_ORDERING_DEFINITIONS pord)
set(MUMPS_ORDERING_LIBRARIES )
if(PARALLEL)
  if(SCOTCH_ORDERING)
    find_package(SCOTCH)
    if(SCOTCH_PTESMUMPS_FOUND)
      list(APPEND MUMPS_ORDERING_DEFINITIONS scotch)
      list(APPEND MUMPS_ORDERING_LIBRARIES SCOTCH::ptesmumps)
    endif()
  endif()
  if(PARMETIS_ORDERING)
    find_package(ParMETIS REQUIRED)
    list(APPEND MUMPS_ORDERING_DEFINITIONS parmetis metis)
    list(APPEND MUMPS_ORDERING_LIBRARIES ParMETIS::ParMETIS)
  endif()
else()
  if(SCOTCH_ORDERING)
    find_package(SCOTCH)
    if(SCOTCH_ESMUMPS_FOUND)
      list(APPEND MUMPS_ORDERING_DEFINITIONS scotch)
      list(APPEND MUMPS_ORDERING_LIBRARIES SCOTCH::esmumps)
    endif()
  endif()
  if(METIS_ORDERING)
    find_package(METIS REQUIRED)
    list(APPEND MUMPS_ORDERING_DEFINITIONS metis)
    list(APPEND MUMPS_ORDERING_LIBRARIES METIS::METIS)
  endif()
endif()

# Directories

set(MUMPS_CURRENT_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
set(MUMPS_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}")
set(MUMPS_VERSION_DIR "${MUMPS_CURRENT_DIR}/MUMPS_${MUMPS_VERSION}")
set(MUMPS_SOURCE_DIR "${MUMPS_VERSION_DIR}/src")
set(MUMPS_GEN_SOURCE_DIR "${MUMPS_BINARY_DIR}/src")
set(MUMPS_INCLUDE_DIR "${MUMPS_VERSION_DIR}/include")
set(MUMPS_GEN_INCLUDE_DIR "${MUMPS_BINARY_DIR}/include")
set(MUMPS_Fortran_MODULE_DIR "${MUMPS_GEN_INCLUDE_DIR}")
set(MUMPS_PORD_DIR "${MUMPS_VERSION_DIR}/PORD")
set(MUMPS_PORD_SOURCE_DIR "${MUMPS_PORD_DIR}/lib")
set(MUMPS_PORD_INCLUDE_DIR "${MUMPS_PORD_DIR}/include")

OCCMakeDebug("MUMPS_CURRENT_DIR = '${MUMPS_CURRENT_DIR}'" 1)
OCCMakeDebug("MUMPS_BINARY_DIR = '${MUMPS_BINARY_DIR}'" 1)
OCCMakeDebug("MUMPS_VERSION_DIR = '${MUMPS_VERSION_DIR}'" 1)
OCCMakeDebug("MUMPS_SOURCE_DIR = '${MUMPS_SOURCE_DIR}'" 1)
OCCMakeDebug("MUMPS_GEN_SOURCE_DIR = '${MUMPS_GEN_SOURCE_DIR}'" 1)
OCCMakeDebug("MUMPS_INCLUDE_DIR = '${MUMPS_INCLUDE_DIR}'" 1)
OCCMakeDebug("MUMPS_GEN_INCLUDE_DIR = '${MUMPS_GEN_INCLUDE_DIR}'" 1)
OCCMakeDebug("MUMPS_Fortran_MODULE_DIR = '${MUMPS_Fortran_MODULE_DIR}'" 1)
OCCMakeDebug("MUMPS_PORD_DIR = '${MUMPS_PORD_DIR}'" 1)
OCCMakeDebug("MUMPS_PORD_SOURCE_DIR = '${MUMPS_PORD_SOURCE_DIR}'" 1)
OCCMakeDebug("MUMPS_PORD_INCLUDE_DIR = '${MUMPS_PORD_INCLUDE_DIR}'" 1)

# Sources

set(MUMPS_PORD_SOURCES
  graph.c
  gbipart.c
  gbisect.c
  ddcreate.c
  ddbisect.c
  nestdiss.c
  multisector.c
  gelim.c
  bucket.c
  tree.c
  symbfac.c
  interface.c
  sort.c
  minpriority.c
)

set(MUMPS_FULL_PORD_SOURCES )
foreach(_source ${MUMPS_PORD_SOURCES})
  list(APPEND MUMPS_FULL_PORD_SOURCES "${MUMPS_PORD_SOURCE_DIR}/${_source}")
endforeach()

if(LARGE_INDICES)
  configure_file("${MUMPS_SOURCE_DIR}/mumps_int_def64_h.in"
    "${MUMPS_GEN_INCLUDE_DIR}/mumps_int_def.h"
  )
else()
  configure_file("${MUMPS_SOURCE_DIR}/mumps_int_def32_h.in"
    "${MUMPS_GEN_INCLUDE_DIR}/mumps_int_def.h"
  )
endif()

set(MUMPS_COMMON_SOURCES
  mumps_pivnul_mod.F
  ana_omp_m.F
  ana_blk_m.F
  ana_orderings_wrappers_m.F
  double_linked_list.F
  fac_asm_build_sort_index_ELT_m.F
  fac_asm_build_sort_index_m.F
  fac_descband_data_m.F
  fac_future_niv2_mod.F
  fac_ibct_data_m.F
  fac_maprow_data_m.F
  front_data_mgt_m.F
  lr_common.F
  mumps_comm_ibcast.F
  mumps_l0_omp_m.F
  mumps_memory_mod.F
  mumps_mpitoomp_m.F
  mumps_ooc_common.F
  sol_ds_common_m.F
  mumps_static_mapping.F
  omp_tps_common_m.F
)

set(MUMPS_COMMON_OTHER_Fortran_SOURCES
  ana_blk.F
  ana_orderings.F
  ana_set_ordering.F
  ana_AMDMF.F
  bcast_errors.F
  estim_flops.F
  mumps_type2_blocking.F
  mumps_version.F
  mumps_print_defined.F
  tools_common.F
  sol_common.F
)

set(MUMPS_COMMON_OTHER_C_SOURCES
  mumps_addr.c
  mumps_common.c
  mumps_pord.c
  mumps_metis.c
  mumps_metis64.c
  mumps_metis_int.c
  mumps_scotch.c
  mumps_scotch64.c
  mumps_scotch_int.c
  mumps_io.c
  mumps_io_basic.c
  mumps_io_thread.c
  mumps_io_err.c
  mumps_numa.c
  mumps_thread.c
  mumps_save_restore_C.c 
  mumps_config_file_C.c
  mumps_thread_affinity.c
  mumps_register_thread.c
)

set(MUMPS_FULL_ARITHMUMPS_C_SOURCE
  ${MUMPS_SOURCE_DIR}/mumps_c.c
)

set(MUMPS_FULL_COMMON_SOURCES )
foreach(_source ${MUMPS_COMMON_SOURCES})
  list(APPEND MUMPS_FULL_COMMON_SOURCES "${MUMPS_SOURCE_DIR}/${_source}")
endforeach()
set(MUMPS_FULL_COMMON_OTHER_Fortran_SOURCES )
foreach(_source ${MUMPS_COMMON_OTHER_Fortran_SOURCES})
  list(APPEND MUMPS_FULL_COMMON_OTHER_Fortran_SOURCES "${MUMPS_SOURCE_DIR}/${_source}")
endforeach()
set(MUMPS_FULL_COMMON_OTHER_C_SOURCES )
foreach(_source ${MUMPS_COMMON_OTHER_C_SOURCES})
  list(APPEND MUMPS_FULL_COMMON_OTHER_C_SOURCES "${MUMPS_SOURCE_DIR}/${_source}")
endforeach()

# Targets

set(MUMPS_INSTALL_TARGETS )

# PORD

add_library(PORD ${MUMPS_LIBRARY_TYPE}
  ${MUMPS_FULL_PORD_SOURCES}
)
target_include_directories(PORD
  PUBLIC
  $<BUILD_INTERFACE:${MUMPS_PORD_INCLUDE_DIR}>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)
set_target_properties(PORD
  PROPERTIES
  EXPORT_NAME PORD
  LIBRARY_OUTPUT_DIRECTORY "${MUMPS_BINARY_DIR}"
  ARCHIVE_OUTPUT_DIRECTORY "${MUMPS_BINARY_DIR}"
  RUNTIME_OUTPUT_DIRECTORY "${MUMPS_BINARY_DIR}"
)

set(MUMPS_INSTALL_TARGETS PORD)

# MUMPS common

add_library(mumps_common ${MUMPS_LIBRARY_TYPE}
  ${MUMPS_FULL_COMMON_SOURCES}
  ${MUMPS_FULL_COMMON_OTHER_SOURCES}
)
target_link_libraries(mumps_common
  PUBLIC
  ${MUMPS_ORDERING_LIBRARIES}
  ${MUMPS_NUMERIC_LIBRARIES}
)
target_include_directories(mumps_common
  PUBLIC
  $<BUILD_INTERFACE:${MUMPS_SOURCE_DIR}>
  $<BUILD_INTERFACE:${MUMPS_INCLUDE_DIR}>
  $<BUILD_INTERFACE:${MUMPS_GEN_INCLUDE_DIR}>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)
target_compile_definitions(mumps_common
  PRIVATE
  ${MUMPS_ORDERING_DEFINITIONS}
)
set_target_properties(mumps_common
  PROPERTIES
  Fortran_MODULE_DIRECTORY ${MUMPS_Fortran_MODULE_DIR}
  LIBRARY_OUTPUT_DIRECTORY ${MUMPS_BINARY_DIR}
  ARCHIVE_OUTPUT_DIRECTORY ${MUMPS_BINARY_DIR}
  RUNTIME_OUTPUT_DIRECTORY ${MUMPS_BINARY_DIR}
  EXPORT_NAME COMMON
  VERSION ${MUMPS_VERSION}
)

install(TARGETS mumps_common
  EXPORT ${PROJECT_NAME}Targets
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# MUMPS arith

# Add MUMPS full target library
add_library(MUMPS INTERFACE)

foreach(ARITH IN LISTS MUMPS_ARITH_LIST)
  
  string(TOUPPER ${ARITH} UPPER_ARITH)
  
  set(MUMPS_${ARITH}_MOD_SOURCES
    ${ARITH}ana_aux.F
    ${ARITH}ana_aux_par.F
    ${ARITH}ana_lr.F
    ${ARITH}fac_asm_master_ELT_m.F
    ${ARITH}fac_asm_master_m.F
    ${ARITH}fac_front_aux.F
    ${ARITH}fac_front_LU_type1.F
    ${ARITH}fac_front_LU_type2.F
    ${ARITH}fac_front_LDLT_type1.F
    ${ARITH}fac_front_LDLT_type2.F
    ${ARITH}fac_front_type2_aux.F
    ${ARITH}fac_sispointers_m.F
    ${ARITH}fac_lr.F
    ${ARITH}fac_mem_dynamic.F
    ${ARITH}fac_omp_m.F
    ${ARITH}fac_par_m.F
    ${ARITH}fac_sol_l0omp_m.F
    ${ARITH}lr_core.F
    ${ARITH}lr_stats.F
    ${ARITH}lr_type.F
    ${ARITH}mumps_comm_buffer.F
    ${ARITH}mumps_config_file.F
    ${ARITH}mumps_load.F
    ${ARITH}mumps_lr_data_m.F
    ${ARITH}mumps_ooc_buffer.F
    ${ARITH}mumps_ooc.F
    ${ARITH}mumps_sol_es.F
    ${ARITH}mumps_save_restore.F
    ${ARITH}mumps_save_restore_files.F
    ${ARITH}mumps_struc_def.F
    ${ARITH}omp_tps_m.F
    ${ARITH}sol_lr.F
    ${ARITH}sol_omp_m.F
    ${ARITH}static_ptr_m.F
    ${ARITH}mumps_mpi3_mod.F
  )
  
  set(MUMPS_${ARITH}_OTHER_Fortran_SOURCES
    ${ARITH}ini_driver.F
    ${ARITH}ana_driver.F
    ${ARITH}fac_driver.F
    ${ARITH}sol_driver.F
    ${ARITH}sol_distrhs.F
    ${ARITH}sol_distsol.F
    ${ARITH}end_driver.F
    ${ARITH}ana_aux_ELT.F
    ${ARITH}ana_dist_m.F
    ${ARITH}ana_LDLT_preprocess.F
    ${ARITH}ana_reordertree.F
    ${ARITH}arrowheads.F
    ${ARITH}bcast_int.F
    ${ARITH}fac_asm_ELT.F
    ${ARITH}fac_asm.F
    ${ARITH}fac_b.F
    ${ARITH}fac_diag.F
    ${ARITH}fac_distrib_distentry.F
    ${ARITH}fac_dist_arrowheads_omp.F
    ${ARITH}fac_distrib_ELT.F
    ${ARITH}fac_lastrtnelind.F
    ${ARITH}fac_mem_alloc_cb.F
    ${ARITH}fac_mem_compress_cb.F
    ${ARITH}fac_mem_free_block_cb.F
    ${ARITH}fac_mem_stack_aux.F
    ${ARITH}fac_mem_stack.F
    ${ARITH}fac_process_band.F
    ${ARITH}fac_process_blfac_slave.F
    ${ARITH}fac_process_blocfacto_LDLT.F
    ${ARITH}fac_process_blocfacto.F
    ${ARITH}fac_process_bf.F
    ${ARITH}fac_process_end_facto_slave.F
    ${ARITH}fac_process_contrib_type1.F
    ${ARITH}fac_process_contrib_type2.F
    ${ARITH}fac_process_contrib_type3.F
    ${ARITH}fac_process_maprow.F
    ${ARITH}fac_process_master2.F
    ${ARITH}fac_process_message.F
    ${ARITH}fac_process_root2slave.F
    ${ARITH}fac_process_root2son.F
    ${ARITH}fac_process_rtnelind.F
    ${ARITH}fac_root_parallel.F
    ${ARITH}fac_scalings.F
    ${ARITH}fac_determinant.F
    ${ARITH}fac_scalings_simScaleAbs.F
    ${ARITH}fac_scalings_simScale_util.F
    ${ARITH}fac_sol_pool.F
    ${ARITH}fac_type3_symmetrize.F
    ${ARITH}ini_defaults.F
    ${ARITH}mumps_driver.F
    ${ARITH}mumps_f77.F
    ${ARITH}mumps_iXamax.F
    ${ARITH}ana_mtrans.F
    ${ARITH}ooc_panel_piv.F
    ${ARITH}rank_revealing.F
    ${ARITH}sol_aux.F
    ${ARITH}sol_bwd_aux.F
    ${ARITH}sol_bwd.F
    ${ARITH}sol_c.F
    ${ARITH}sol_fwd_aux.F
    ${ARITH}sol_fwd.F
    ${ARITH}sol_matvec.F
    ${ARITH}sol_root_parallel.F
    ${ARITH}tools.F
    ${ARITH}type3_root.F
  )

  set(MUMPS_${ARITH}_OTHER_C_SOURCES
    ${ARITH}mumps_gpu.c
  )
  
  set(MUMPS_FULL_${ARITH}_MOD_SOURCES )
  foreach(_source ${MUMPS_${ARITH}_MOD_SOURCES})
    set(ARITH_SOURCE "${_source}")
    list(APPEND MUMPS_FULL_${ARITH}_MOD_SOURCES "${MUMPS_SOURCE_DIR}/${ARITH_SOURCE}")
  endforeach()
  set(MUMPS_FULL_${ARITH}_OTHER_Fortran_SOURCES )
  foreach(_source ${MUMPS_${ARITH}_OTHER_Fortran_SOURCES})
    set(ARITH_SOURCE "${_source}")
    list(APPEND MUMPS_FULL_${ARITH}_OTHER_Fortran_SOURCES "${MUMPS_SOURCE_DIR}/${ARITH_SOURCE}")
  endforeach()
  set(MUMPS_FULL_${ARITH}_OTHER_C_SOURCES )
  foreach(_source ${MUMPS_${ARITH}_OTHER_C_SOURCES})
    set(ARITH_SOURCE "${_source}")
    list(APPEND MUMPS_FULL_${ARITH}_OTHER_C_SOURCES "${MUMPS_SOURCE_DIR}/${ARITH_SOURCE}")
  endforeach()
      
  add_library(${ARITH}mumps ${MUMPS_LIBRARY_TYPE}
    ${MUMPS_FULL_ARITHMUMPS_C_SOURCE}
    ${MUMPS_FULL_${ARITH}_MOD_SOURCES}
    ${MUMPS_FULL_${ARITH}_OTHER_Fortran_SOURCES}
    ${MUMPS_FULL_${ARITH}_OTHER_C_SOURCES}
  )
  target_compile_definitions(${ARITH}mumps
    PRIVATE
    MUMPS_ARITH=MUMPS_ARITH_${ARITH}
    ${MUMPS_ORDERING_DEFINITIONS}
  )
  target_include_directories(${ARITH}mumps
    PUBLIC
    "$<BUILD_INTERFACE:${MUMPS_INCLUDE_DIR}>"
    "$<BUILD_INTERFACE:${MUMPS_GEN_INCLUDE_DIR}>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
  )
  target_link_libraries(${ARITH}mumps
    PUBLIC
    mumps_common
    ${MUMPS_ORDERING_LIBRARIES}
    ${MUMPS_NUMERIC_LIBRARIES}
  )
  set_target_properties(${ARITH}mumps PROPERTIES
    Fortran_MODULE_DIRECTORY "${MUMPS_Fortran_MODULE_DIR}"
    LIBRARY_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}"
    ARCHIVE_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}"
    RUNTIME_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}"
    EXPORT_NAME "${UPPER_ARITH}MUMPS"
    VERSION "${MUMPS_VERSION}"
  )  
  target_link_libraries(MUMPS INTERFACE ${ARITH}mumps)  
  install(TARGETS ${ARITH}mumps
    EXPORT "${PROJECT_NAME}Targets"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
    INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
  )  
  install(FILES
    "${MUMPS_INCLUDE_DIR}/${ARITH}mumps_c.h"
    "${MUMPS_INCLUDE_DIR}/${ARITH}mumps_root.h"
    "${MUMPS_INCLUDE_DIR}/${ARITH}mumps_struc.h"
    "${MUMPS_GEN_INCLUDE_DIR}/mumps_int_def.h"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
  )
  
  list(APPEND MUMPS_INSTALL_TARGETS ${ARITH}mumps)
  
endforeach()

list(APPEND MUMPS_INSTALL_TARGETS MUMPS)

install(FILES
  "${MUMPS_INCLUDE_DIR}/mumps_c_types.h"
  "${MUMPS_INCLUDE_DIR}/mumps_compat.h"
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)

# Config files

set(MUMPS_CMAKE_SUBDIR "${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}-${PROJECT_VERSION}")

include(CMakePackageConfigHelpers)
configure_package_config_file("${MUMPS_CURRENT_DIR}/${PROJECT_NAME}Config.cmake.in"
  "${MUMPS_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
  INSTALL_DESTINATION "${MUMPS_CMAKE_SUBDIR}"
)

write_basic_package_version_file(
  "${MUMPS_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
  COMPATIBILITY SameMajorVersion
)

# Install

install(TARGETS MUMPS
  EXPORT "${PROJECT_NAME}Targets"
  LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
  RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
  INCLUDES DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
)

install(FILES
  "${MUMPS_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
  "${MUMPS_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
  DESTINATION "${MUMPS_CMAKE_SUBDIR}"
)

install(EXPORT "${PROJECT_NAME}Targets"
  NAMESPACE "${PROJECT_NAME}::"
  DESTINATION "${MUMPS_CMAKE_SUBDIR}"
)

