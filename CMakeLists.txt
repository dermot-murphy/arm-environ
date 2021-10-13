# Project: Kappa
#
# Build the Docker image useed in development of the KAPPA Sensor firmware

cmake_minimum_required(VERSION 3.16)

project(KAPPA-docker)

find_program(DOCKER_CMD docker REQUIRED)

# Setup a custom command to build the image.
# The command sets up a temporary working directory,
# then executes the docker build command.
# When the image is build a hash file is stored.
# 
# We communicate to CMake that the image needs to
# be rebuilt via the DEPENDS argument.
#
# The output of the docker build command is an image in docker
# not a file artifact that CMake can then track.
#
# The hash of the image becomes the output which 
# is tracked.  If the Dockerfile is newer than the hash
# the Docker image is rebuild.

# Name of the Docker image
set(IMAGE_NAME "sensoteq-kappa-sensor")

# Name of the dockerfile to use
set(DOCKERFILE ${CMAKE_CURRENT_LIST_DIR}/Dockerfile)

# Name of the hash file to create
set(_IMAGE_HASH ${CMAKE_CURRENT_BINARY_DIR}/${IMAGE_NAME}.hash)

# Directory to build the image in
set(_BUILD_CONTEXT context)

# Custom command to build a docker image from a dockerfile

add_custom_command(

    OUTPUT ${_IMAGE_HASH}
    COMMENT "Building docker image \"${IMAGE_NAME}\""

    # Create a fresh context with the executable.
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${_BUILD_CONTEXT}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${_BUILD_CONTEXT}

    # Launch the docker build command using the build context.
    COMMAND ${DOCKER_CMD} build 
        --tag ${IMAGE_NAME}
        --file ${DOCKERFILE}
        ${_BUILD_CONTEXT}

    # Cleanup the build context. Not strictly required, but it
    # cuts down on some of the clutter in the binary directory.
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${_BUILD_CONTEXT}

    # Capture the image's hash and store it as a tracked output.
    COMMAND ${DOCKER_CMD} images --no-trunc ${IMAGE_NAME} > ${_IMAGE_HASH}

    # The docker image depends on the dockerfile
    DEPENDS
        ${DOCKERFILE}
)

# Define a target that depends on the image hash.
# Running "make" will trigger the custom
# command if it's out-of-date (e.g. the underlying
# executable has changed or the dockerfile was updated).
add_custom_target(docker_image ALL DEPENDS ${_IMAGE_HASH})
