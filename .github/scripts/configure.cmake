#!/usr/local/bin/cmake -P

if ("$ENV{RUNNER_OS}" STREQUAL "Windows" AND NOT "x$ENV{ENVIRONMENT_SCRIPT}" STREQUAL "x")
	execute_process(
		COMMAND "$ENV{ENVIRONMENT_SCRIPT}" && set
		OUTPUT_FILE environment_script_output.txt
	)
	file(STRINGS environment_script_output.txt output_lines)
	foreach(line IN LISTS output_lines)
		if (line MATCHES "^([a-zA-Z0-9_-]+)=(.*)$")
			set(ENV{${CMAKE_MATCH_1}} "${CMAKE_MATCH_2}")
		endif()
	endforeach()
endif()

set(path_separator ":")
if ("$ENV{RUNNER_OS}" STREQUAL "Windows")
	set(path_separator ";")
endif()
set(ENV{PATH} "$ENV{GITHUB_WORKSPACE}${path_separator}$ENV{PATH}")

# CMakeLists.txt only include()s cmake/CodeCoverage.cmake (which defines the
# CMAKE_*_FLAGS_COVERAGE variables, including --coverage) when CMAKE_BUILD_TYPE
# is literally "Coverage" -- never "Debug". Substitute it in for exactly the
# leg that actually uploads coverage (ci.yml's Codecov/gcovr-action steps only
# run when runner.os == Linux && matrix.build_type == Debug); every other leg
# keeps getting the real Debug/Release value, untouched.
set(actual_build_type "$ENV{BUILD_TYPE}")
if ("$ENV{RUNNER_OS}" STREQUAL "Linux" AND "$ENV{CC}" STREQUAL "gcc" AND "$ENV{BUILD_TYPE}" STREQUAL "Debug")
	set(actual_build_type "Coverage")
endif()

if ("$ENV{RUNNER_OS}" STREQUAL "Windows")
	file(TO_CMAKE_PATH "$ENV{GITHUB_WORKSPACE}/vcpkg/scripts/buildsystems/vcpkg.cmake" toolchain_file)
	execute_process(
		COMMAND cmake
			-S .
			-B build
			-D CMAKE_BUILD_TYPE=${actual_build_type}
			-G "Ninja"
			-D CMAKE_MAKE_PROGRAM=ninja
			-D CMAKE_C_COMPILER_LAUNCHER=ccache
			-D CMAKE_CXX_COMPILER_LAUNCHER=ccache
			-D CMAKE_TOOLCHAIN_FILE=${toolchain_file} -DVCPKG_TARGET_TRIPLET=$ENV{VCPKG_TRIPLET} -DVCPKG_HOST_TRIPLET=$ENV{VCPKG_TRIPLET} #-DVCPKG_MANIFEST_MODE=OFF
			--fresh # Necessary if changing between build types
		RESULT_VARIABLE result
	)
else()
	execute_process(
		COMMAND cmake
			-S .
			-B build
			-D CMAKE_BUILD_TYPE=${actual_build_type}
			-G "Ninja"
			-D CMAKE_MAKE_PROGRAM=ninja
			-D CMAKE_C_COMPILER_LAUNCHER=ccache
			-D CMAKE_CXX_COMPILER_LAUNCHER=ccache
			--fresh # Necessary if changing between build types
		RESULT_VARIABLE result
	)
endif()

if (NOT result EQUAL 0)
	message(FATAL_ERROR "Bad exit status")
endif()
