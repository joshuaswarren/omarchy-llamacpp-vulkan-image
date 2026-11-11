# llama.cpp's server on the Vulkan driver of Apple Silicon Macs running Linux.
# The runtime layer holds only the packages the server needs (the Vulkan loader and the Arch Linux ARM
# `vulkan-asahi` driver, the same build the host runs), plus a static llama-server and llama-bench.
# The host supplies /dev/dri/renderD*; the kernel's GPU interface and the driver version must match.
FROM scratch AS alarm
ADD ArchLinuxARM-aarch64-latest.tar.gz /
RUN sed -i 's/^CheckSpace/#CheckSpace/; s/^\[options\]/[options]\nDisableSandbox/' /etc/pacman.conf \
 && pacman-key --init && pacman-key --populate archlinuxarm

FROM alarm AS build
ARG LLAMA_CPP_COMMIT
RUN pacman -Syu --noconfirm --needed base-devel cmake git vulkan-headers vulkan-icd-loader shaderc spirv-headers \
 && mkdir /src && cd /src && git init -q && git remote add origin https://github.com/ggml-org/llama.cpp \
 && git fetch -q --depth 1 origin "$LLAMA_CPP_COMMIT" && git checkout -q FETCH_HEAD \
 && cmake -B build -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF -DGGML_VULKAN=ON -DGGML_NATIVE=OFF \
      -DGGML_CPU_ARM_ARCH=armv8.4-a+dotprod -DLLAMA_BUILD_TESTS=OFF -DLLAMA_BUILD_EXAMPLES=OFF \
 && cmake --build build --target llama-server llama-bench -j "$(nproc)"
RUN mkdir -p /rootfs/var/lib/pacman /rootfs/etc/pacman.d \
 && pacman -r /rootfs --gpgdir /etc/pacman.d/gnupg --config /etc/pacman.conf -Sy --noconfirm --needed \
      filesystem glibc gcc-libs bash coreutils curl ca-certificates vulkan-asahi vulkan-icd-loader \
 && rm -rf /rootfs/var/cache /rootfs/var/lib/pacman/sync /rootfs/usr/share/man /rootfs/usr/share/doc /rootfs/usr/share/info \
 && install -m 0755 /src/build/bin/llama-server /src/build/bin/llama-bench /rootfs/usr/local/bin/

FROM scratch
COPY --from=build /rootfs /
ENV VK_DRIVER_FILES=/usr/share/vulkan/icd.d/asahi_icd.json
EXPOSE 8080
CMD ["llama-server", "--host", "0.0.0.0", "--port", "8080"]
