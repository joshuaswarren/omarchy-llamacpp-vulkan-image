# llamacpp-vulkan

This image runs [llama.cpp](https://github.com/ggml-org/llama.cpp)'s server on the Vulkan driver of Apple Silicon Macs that run Linux.

A GitHub workflow builds it on an arm64 runner. It publishes it to `ghcr.io/joshuaswarren/llamacpp-vulkan`.
[omarchy-local-ai](https://github.com/omacom/omarchy-local-ai) pins it by digest.

## What is inside

- A static `llama-server` and `llama-bench` with the Vulkan backend. They build from the llama.cpp commit in the workflow.
- The Vulkan loader and the Arch Linux ARM `vulkan-asahi` driver. That is the driver build Omarchy ships on Apple Silicon.
- Nothing else. No compiler, no package database.

## Run it

The container needs the host's render node. The driver in the image must match the kernel's GPU interface.

```sh
podman run --rm --device /dev/dri/renderD128 --group-add keep-groups -p 127.0.0.1:8080:8080 \
  -v "$HOME/models:/models:ro" ghcr.io/joshuaswarren/llamacpp-vulkan@sha256:<digest> \
  llama-server --host 0.0.0.0 --port 8080 -m /models/model.gguf -ngl 999
```

## Update

Change `LLAMA_CPP_COMMIT` in `.github/workflows/image.yml` and push to `main`. The run prints the new digest.
