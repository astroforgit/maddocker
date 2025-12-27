# ==========================================
# STAGE 1: Builder
# ==========================================
FROM debian:stable-slim AS builder
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y fpc git ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /build

# 1. Mad Assembler
RUN git clone https://github.com/tebe6502/Mad-Assembler.git && \
    cd Mad-Assembler && fpc -Mdelphi -v -O3 mads.pas && \
    mkdir -p /dist/bin && mv mads /dist/bin/

# 2. Mad Pascal
RUN git clone https://github.com/tebe6502/Mad-Pascal.git && \
    cd Mad-Pascal/src && fpc -Mdelphi -v -O3 mp.pas && \
    mv mp /dist/bin/ && \
    mkdir -p /dist/opt/MadPascal && \
    cp -r ../base /dist/opt/MadPascal/ && \
    cp -r ../lib /dist/opt/MadPascal/

# 3. Blibs (Robust Copy)
RUN git clone https://gitlab.com/bocianu/blibs.git && \
    mkdir -p /dist/opt/MadPascal/blibs && \
    # Copy from nested folder if it exists, otherwise root
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

# --- UNIVERSAL CASE FIX ---
# Create Lowercase AND Uppercase symlinks for every .pas, .a65, .asm, .inc, .mac file
# This fixes "File not found" errors on Linux due to case mismatch
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
      # 3. Upper Name + Lower Ext (SYSTEM.a65) \
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
