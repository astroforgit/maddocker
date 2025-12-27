# ==========================================
# STAGE 1: Builder
# ==========================================
FROM debian:stable-slim AS builder
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y fpc git wget ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /build

# 1. Mad Assembler (MADS) - We still use Git for this, it's stable
RUN git clone https://github.com/tebe6502/Mad-Assembler.git && \
    cd Mad-Assembler && fpc -Mdelphi -v -O3 mads.pas && \
    mkdir -p /dist/bin && mv mads /dist/bin/

# 2. Mad Pascal (STABLE v1.7.5)
# Instead of 'git clone', we download the official source code zip
RUN wget https://github.com/tebe6502/Mad-Pascal/archive/refs/tags/v1.7.5.tar.gz -O mp.tar.gz && \
    tar -xzf mp.tar.gz && \
    mv Mad-Pascal-1.7.5 Mad-Pascal && \
    cd Mad-Pascal/src && \
    fpc -Mdelphi -v -O3 mp.pas && \
    mv mp /dist/bin/ && \
    mkdir -p /dist/opt/MadPascal && \
    cp -r ../base /dist/opt/MadPascal/ && \
    cp -r ../lib /dist/opt/MadPascal/

# 3. Blibs (Clone latest)
RUN git clone https://gitlab.com/bocianu/blibs.git && \
    mkdir -p /dist/opt/MadPascal/blibs && \
    # Robust copy command
    cp -r blibs/blibs/* /dist/opt/MadPascal/blibs/ 2>/dev/null || cp -r blibs/* /dist/opt/MadPascal/blibs/

# ==========================================
# STAGE 2: Runtime
# ==========================================
FROM debian:stable-slim

# Install tools
RUN apt-get update && apt-get install -y --no-install-recommends bash findutils coreutils && rm -rf /var/lib/apt/lists/*

COPY --from=builder /dist/bin/mp /usr/bin/mp
COPY --from=builder /dist/bin/mads /usr/bin/mads
COPY --from=builder /dist/opt/MadPascal /opt/MadPascal

ENV MP_DIR="/opt/MadPascal"
ENV PATH="$MP_DIR:$PATH"

# --- UNIVERSAL CASE FIX (SYMLINKS) ---
# Creates Uppercase and CamelCase aliases for all libraries
RUN find /opt/MadPascal -type f \( -name "*.pas" -o -name "*.a65" -o -name "*.asm" -o -name "*.inc" -o -name "*.mac" \) | while read f; do \
      dir=$(dirname "$f"); \
      base=$(basename "$f"); \
      ext="${base##*.}"; \
      filename="${base%.*}"; \
      \
      # 1. Lowercase (system.a65) \
      lower_base=$(echo "$base" | tr '[:upper:]' '[:lower:]'); \
      if [ "$base" != "$lower_base" ]; then \
          ln -s "$base" "$dir/$lower_base" 2>/dev/null || true; \
      fi; \
      \
      # 2. Uppercase (SYSTEM.A65) \
      upper_base=$(echo "$base" | tr '[:lower:]' '[:upper:]'); \
      if [ "$base" != "$upper_base" ]; then \
          ln -s "$base" "$dir/$upper_base" 2>/dev/null || true; \
      fi; \
      \
      # 3. Mixed (SYSTEM.a65) \
      upper_name=$(echo "$filename" | tr '[:lower:]' '[:upper:]'); \
      mixed_base="$upper_name.$ext"; \
      if [ "$base" != "$mixed_base" ]; then \
          ln -s "$base" "$dir/$mixed_base" 2>/dev/null || true; \
      fi; \
    done

COPY script.sh /script.sh
RUN chmod +x /script.sh

WORKDIR /code
ENTRYPOINT ["/script.sh"]
