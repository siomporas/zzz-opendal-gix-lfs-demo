# Use Ubuntu 24.04 as base
FROM ubuntu:24.04

# Build arguments for multi-arch support
ARG RUST_VERSION=1.88.0
ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
  BIND_ADDRESS=0.0.0.0:8000 \
  RUST_VERSION=${RUST_VERSION} \
  TARGETPLATFORM=${TARGETPLATFORM} \
  TARGETARCH=${TARGETARCH}

# Rename ubuntu user to vscode
RUN usermod --login vscode --move-home --home /home/vscode ubuntu && \
  groupmod --new-name vscode ubuntu

# Install system dependencies and add deadsnakes PPA
RUN apt-get update && apt-get install -y \
  software-properties-common \
  && add-apt-repository ppa:deadsnakes/ppa \
  && apt-get update && apt-get install -y \
  git \
  git-lfs \
  curl \
  build-essential \
  pkg-config \
  libssl-dev \
  bash-completion \
  fzf \
  ripgrep \
  bat \
  sudo \
  pandoc \
  just \
  gettext-base \
  && rm -rf /var/lib/apt/lists/* 

# Add vscode user to sudo group with passwordless sudo
RUN usermod -aG sudo vscode && \
  echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/vscode && \
  chmod 0440 /etc/sudoers.d/vscode

# Install Rust with architecture detection
RUN set -eux; \
  # Detect architecture and map to Rust targets \
  case "${TARGETARCH:-$(uname -m)}" in \
  amd64|x86_64) RUST_TARGET="x86_64-unknown-linux-gnu" ;; \
  arm64|aarch64) RUST_TARGET="aarch64-unknown-linux-gnu" ;; \
  *) echo "Unsupported architecture: ${TARGETARCH:-$(uname -m)}" && exit 1 ;; \
  esac; \
  echo "Installing Rust ${RUST_VERSION} for target ${RUST_TARGET}"; \
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- \
  -y \
  --default-toolchain ${RUST_VERSION} \
  --target ${RUST_TARGET} \
  --no-modify-path; \
  echo 'source /root/.cargo/env' >> /root/.bashrc

# Detect architecture and install fastfetch
RUN ARCH=$(uname -m) && \
  case $ARCH in \
  x86_64) FF_ARCH="amd64" ;; \
  aarch64) FF_ARCH="aarch64" ;; \
  *) echo "Unknown architecture: $ARCH" && exit 1 ;; \
  esac && \
  echo "Installing fastfetch for ${FF_ARCH}..." && \
  curl -fsSL -o /tmp/fastfetch.deb "https://github.com/fastfetch-cli/fastfetch/releases/download/2.54.0/fastfetch-linux-${FF_ARCH}.deb" && \
  dpkg -i /tmp/fastfetch.deb && \
  rm /tmp/fastfetch.deb && \
  echo "fastfetch" >> /home/vscode/.bashrc

# Install kubectl and helm
RUN ARCH=$(uname -m) && \
  case $ARCH in \
  x86_64) KUBECTL_ARCH="amd64" HELM_ARCH="amd64" ;; \
  aarch64) KUBECTL_ARCH="arm64" HELM_ARCH="arm64" ;; \
  *) echo "Unknown architecture: $ARCH, defaulting to amd64" && KUBECTL_ARCH="amd64" HELM_ARCH="amd64" ;; \
  esac && \
  echo "Installing kubectl for ${KUBECTL_ARCH}..." && \
  KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) && \
  curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl" && \
  chmod +x kubectl && \
  mv kubectl /usr/local/bin/kubectl && \
  echo "Installing helm for ${HELM_ARCH}..." && \
  HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') && \
  curl -LO "https://get.helm.sh/helm-${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz" && \
  tar -zxvf "helm-${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz" && \
  mv linux-${HELM_ARCH}/helm /usr/local/bin/helm && \
  rm -rf "helm-${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz" linux-${HELM_ARCH} && \
  kubectl version --client && \
  helm version

# Initialize git-lfs
RUN git lfs install

# Create and set up the objects directory
RUN mkdir -p /models /metadata /datasets /cache \
  && chown -R vscode:vscode /models /metadata /datasets /cache \
  && chmod 755 /models /metadata /datasets /cache

# Set up Rust environment
WORKDIR /workspace
# Copy Rust installation to vscode user and set permissions
RUN cp -r /root/.cargo /home/vscode/.cargo \
  && cp -r /root/.rustup /home/vscode/.rustup \
  && chown -R vscode:vscode /home/vscode/.cargo /home/vscode/.rustup

# Switch to vscode user for package installation
USER vscode
ENV PATH="/home/vscode/.local/bin:/home/vscode/.venv/bin:/home/vscode/.cargo/bin:$PATH" \
  CARGO_HOME="/home/vscode/.cargo" \
  RUSTUP_HOME="/home/vscode/.rustup"

# # Install additional Rust components
RUN rustup toolchain install nightly -c rustfmt -c clippy \
  && cargo install cargo-watch \
  && rustup default stable

# Set up bash completion and environment
RUN echo '' >> /home/vscode/.bashrc \
  && echo '# Rust environment' >> /home/vscode/.bashrc \
  && echo 'export CARGO_HOME="$HOME/.cargo"' >> /home/vscode/.bashrc \
  && echo 'export RUSTUP_HOME="$HOME/.rustup"' >> /home/vscode/.bashrc \
  && echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /home/vscode/.bashrc \
  && echo '' >> /home/vscode/.bashrc \
  && echo '# Development aliases' >> /home/vscode/.bashrc \
  && echo 'alias ll="ls -la"' >> /home/vscode/.bashrc \
  && echo 'alias grep="grep --color=auto"' >> /home/vscode/.bashrc \
  && echo 'alias cargo-check="cargo check --all-targets"' >> /home/vscode/.bashrc \
  && echo 'alias cargo-test="cargo test --all"' >> /home/vscode/.bashrc \
  && echo 'alias cargo-fmt="cargo +nightly fmt --all"' >> /home/vscode/.bashrc \
  && echo 'alias cf="cargo +nightly fmt --all"' >> /home/vscode/.bashrc \
  && echo 'alias cr="cargo run"' >> /home/vscode/.bashrc \
  && echo 'alias cb="cargo build"' >> /home/vscode/.bashrc \
  && ln -s /usr/bin/batcat /home/vscode/.cargo/bin/bat

# Set working directory
WORKDIR /workspace

# Expose port
EXPOSE 8000

# Default command for devcontainer (keeps container running)
CMD ["/bin/bash"]
