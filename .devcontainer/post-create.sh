#!/bin/bash

# Post-create script for workspace-specific setup
# Most setup is now done in the Dockerfile for better caching

set -e

echo "🚀 Post-create setup for Runway workspace..."

# Ensure we're in the workspace directory
cd /workspace

# Add just completions
just --completions bash >> /home/vscode/.bashrc

# Source the environment (should already be in PATH from Dockerfile)
source ~/.bashrc

#######################
# Workspace-specific setup
#######################

# Set up git safety for the workspace
echo "🔧 Configuring git for workspace..."
git config --global --add safe.directory /workspace

#######################
# Validation
#######################
echo ""
echo "🎉 Workspace setup complete!"
echo ""

#######################
# bash completion
#######################

# Set up helm completion
if command -v helm &> /dev/null; then
    echo "Setting up helm bash completion..."
    helm completion bash | sudo tee /etc/bash_completion.d/helm > /dev/null
    echo "source <(helm completion bash)" >> ~/.bashrc
    echo "✅ helm bash completion installed"
else
    echo "⚠️ helm not found, skipping completion setup"
fi

cat <<EOF >> ~/.bashrc

source /etc/bash_completion

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
source <(kubectl completion bash)
alias k=kubectl
complete -F __start_kubectl k

export LESS="-rXF"

EOF


#######################
# Setup local secrets if provided
#######################

if [ -n "$DOCKER_LOGIN_B64" ]; then
  echo "DOCKER_LOGIN_B64 is set, setting up local secrets"
  mkdir -p ~/.docker
  echo "$DOCKER_LOGIN_B64" | base64 -d > ~/.docker/config.json
else
  echo "DOCKER_LOGIN_B64 is not set, using empty config"
fi


if [ -n "$GIT_CREDENTIALS_B64" ]; then
  echo "GIT_CREDENTIALS_B64 is set, setting up local secrets"
  echo "$GIT_CREDENTIALS_B64" | base64 -d >~/.git-credentials
else
  echo "GIT_CREDENTIALS_B64 is not set, using empty credentials"
fi


# Display environment info
ARCH=$(uname -m)
echo "🏗️  Architecture: $ARCH"
echo "🦀 Rust version: $(rustc --version 2>/dev/null || echo 'Not available')"
echo ""

# Test Rust compilation if Cargo.toml exists
if [ -f "Cargo.toml" ]; then
    echo "🔨 Testing Rust compilation..."
    if cargo check --all-targets; then
        echo "✅ Rust project compiles successfully"
    else
        echo "❌ Rust compilation failed"
    fi
else
    echo "⚠️  No Cargo.toml found - Rust project not present"
fi

echo ""
echo "🎯 Ready for Rust development! 🦀"
echo "🔧 Run './validate-setup.sh' to perform a full environment check"
