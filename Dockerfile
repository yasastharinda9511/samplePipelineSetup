FROM golang:1.23

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    docker.io \
    wget \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install golangci-lint to /usr/local/bin
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b /usr/local/bin v1.55.2

# Install gosec v2.18.2 (compatible with Go 1.23)
RUN wget -q https://github.com/securego/gosec/releases/download/v2.18.2/gosec_2.18.2_linux_amd64.tar.gz && \
    tar -xzf gosec_2.18.2_linux_amd64.tar.gz -C /usr/local/bin gosec && \
    rm gosec_2.18.2_linux_amd64.tar.gz && \
    chmod +x /usr/local/bin/gosec

# Verify installations
RUN echo "=== Verifying installations ===" && \
    git --version && \
    go version && \
    golangci-lint --version && \
    gosec --version && \
    echo "=== All tools installed successfully ==="

WORKDIR /workspace

CMD ["/bin/bash"]