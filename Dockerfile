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
    # Try copying from nested folder first, fall back to root
    cp -r blibs/blibs/* /dist/opt/MadPascal/blibs/ 2>/dev/null || cp -r blibs/* /dist/opt/MadPascal/blibs/

# ==========================================
# STAGE 2: Runtime
# ==========================================
FROM debian:stable-slim
# Install standard tools
RUN apt-get update && apt-get install -y --no-install-recommends bash findutils coreutils && rm -rf /var/lib/apt/lists/*

COPY --from=builder /dist/bin/mp /usr/bin/mp
COPY --from=builder /dist/bin/mads /usr/bin/mads
COPY --from=builder /dist/opt/MadPascal /opt/MadPascal

ENV MP_DIR="/opt/MadPascal"
ENV PATH="$MP_DIR:$PATH"

# --- THE FIX: CREATE UPPERCASE SYMLINKS ---
# This ensures 'uses ATARI' finds 'atari.pas'
RUN find /opt/MadPascal -name "*.pas" | while read f; do \
      dir=$(dirname "$f"); \
      base=$(basename "$f"); \
      # Create UPPERCASE.pas link (e.g. atari.pas -> ATARI.pas)
      upper_base=$(echo "$base" | sed 's/\.pas$//' | tr '[:lower:]' '[:upper:]'); \
      ln -s "$base" "$dir/$upper_base.pas" 2>/dev/null || true; \
    done

COPY script.sh /script.sh
RUN chmod +x /script.sh

WORKDIR /code
ENTRYPOINT ["/script.sh"]
