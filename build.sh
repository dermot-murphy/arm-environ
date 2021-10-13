rm -f -R build
mkdir build
cmake -B build
cmake --build build
#docker images
#docker run -it --mount type=bind,source="$(pwd)",target=/mnt sensoteq-kappa-sensor