#!/usr/bin/env bash
set -ex

# Install lcov if not present on the system
if ! command -v lcov &> /dev/null; then
    apt-get update && apt-get install -y lcov
    fi

    echo "Capturing coverage data..."
    lcov --capture --directory build --output-file coverage.info

    echo "Filtering coverage data (removing system headers and tests)..."
    lcov --remove coverage.info \
         '/usr/*' \
              '*/tests/*' \
                   '*/test/*' \
                        '*/external/*' \
                             '*/build/*' \
                                  --output-file coverage_filtered.info

                                  echo "Generating HTML report..."
                                  genhtml coverage_filtered.info --output-directory coverage

                                  echo "Coverage summary for GitLab regex:"
                                  lcov --list coverage_filtered.info