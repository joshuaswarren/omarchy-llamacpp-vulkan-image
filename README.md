# llamacpp-vulkan

This image runs [llama.cpp](https://github.com/ggml-org/llama.cpp)'s server on the Vulkan driver of Apple Silicon Macs that run Linux.

A GitHub workflow builds it on an arm64 runner. It publishes it to `ghcr.io/joshuaswarren/llamacpp-vulkan`.
[omarchy-local-ai](https://github.com/omacom/omarchy-local-ai) pins it by digest.

## What is inside

- A static `llama-server` and `llama-bench` with the Vulkan backend. They build from the llama.cpp commit in the workflow, plus the patches in `patches/`. One patch lets the Vulkan flash-attention path split the key loop across workgroups on the Honeykrisp driver, which does not report a core count.
- The Vulkan loader and the Arch Linux ARM `vulkan-asahi` driver. That is the driver build Omarchy ships on Apple Silicon.
- Nothing else. No compiler, no package database.

## Run it

The container needs the host's render node. The driver in the image must match the kernel's GPU interface.

```sh
podman run --rm --device /dev/dri/renderD128 --group-add keep-groups -p 127.0.0.1:8080:8080 \
  -v "$HOME/models:/models:ro" ghcr.io/joshuaswarren/llamacpp-vulkan@sha256:<digest> \
  llama-server --host 0.0.0.0 --port 8080 -m /models/model.gguf -ngl 999
```

## Build locally

The Containerfile needs the Arch Linux ARM root filesystem tarball in the build context. Fetch it, then build for arm64:

```sh
curl -fsSLO http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
podman build --arch arm64 -f Containerfile \
  --build-arg LLAMA_CPP_COMMIT=cd959bae99ff4bed22bef2604f45241c09bbb8c8 \
  -t llamacpp-vulkan .
```

## Update

Change `LLAMA_CPP_COMMIT` in `.github/workflows/image.yml` and push to `main`. The run prints the new digest.
