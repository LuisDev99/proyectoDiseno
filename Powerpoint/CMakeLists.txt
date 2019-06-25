cmake_minimum_required (VERSION 3.0)
project (VGATest)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/")

find_package(VERILATOR REQUIRED)
find_package(SDL2 REQUIRED)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CPP_SRCDIR "${CMAKE_SOURCE_DIR}/cpp")
set(VERILOG_SRCDIR "${CMAKE_SOURCE_DIR}/verilog")
set(VERILOG_SOURCES "${VERILOG_SRCDIR}/VGA800x600.v")
set(VTOPMODULE "VGA800x600")
set(VERILOG_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/verilog-build")
set(VERILOG_LIB "${VERILOG_BINARY_DIR}/V${VTOPMODULE}__ALL.a")
separate_arguments(VERILOG_SOURCES)

include_directories(${SDL2_INCLUDE_DIR})
include_directories(${CMAKE_CURRENT_BINARY_DIR})
include_directories(${VERILOG_BINARY_DIR})
include_directories(${VERILATOR_INCLUDE_DIR})
include_directories(${VERILATOR_DPI_INCLUDE_DIR})
include_directories(${CPP_SRCDIR})

# Run verilator to compile the Verilog Module
add_custom_command (
    OUTPUT ${VERILOG_LIB}
    COMMAND ${VERILATOR} -Wall -Wno-fatal -I${VERILOG_SRCDIR} --cc ${VERILOG_SOURCES}
            --top-module ${VTOPMODULE} -Mdir ${VERILOG_BINARY_DIR} -CFLAGS \"\$\(CXX_DEFINES\) \$\(CXX_INCLUDES\) \$\(CXX_FLAGS\)\"
    COMMAND make -C ${VERILOG_BINARY_DIR} -f V${VTOPMODULE}.mk
    MAIN_DEPENDENCY ${VERILOG_SRCDIR}/${VTOPMODULE}.v
    DEPENDS ${VERILOG_SOURCES}
  )

set_source_files_properties(
    ${CPP_SRCDIR}/VGATestMain.cpp
    PROPERTIES OBJECT_DEPENDS ${VERILOG_LIB}
)

set_directory_properties(
    PROPERTIES
    ADDITIONAL_MAKE_CLEAN_FILES "${VERILOG_BINARY_DIR}"
)
 
add_executable(${PROJECT_NAME}  ${VERILATOR_INCLUDE_DIR}/verilated.cpp
                                ${CPP_SRCDIR}/VGADisplay.cpp
                                ${CPP_SRCDIR}/VGATestMain.cpp)

target_link_libraries(${PROJECT_NAME} ${VERILOG_LIB})
target_link_libraries(${PROJECT_NAME} ${SDL2_LIBRARIES})
