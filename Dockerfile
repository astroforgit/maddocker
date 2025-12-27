# ==========================================
# STAGE 1: Builder
# ==========================================
FROM debian:stable-slim AS builder
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y fpc git wget ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /build

# 1. Mad Assembler (Clone Latest)
RUN git clone https://github.com/tebe6502/Mad-Assembler.git && \
    cd Mad-Assembler && fpc -Mdelphi -v -O3 mads.pas && \
    mkdir -p /dist/bin && mv mads /dist/bin/

# 2. Mad Pascal (STABLE v1.7.5 via Download)
# We extract simply. It creates directory: Mad-Pascal-1.7.5
RUN wget https://github.com/tebe6502/Mad-Pascal/archive/refs/tags/v1.7.5.tar.gz -O mp.tar.gz && \
    tar -xzf mp.tar.gz && \
    cd Mad-Pascal-1.7.5/src && \
    fpc -Mdelphi -v -O3 mp.pas && \
    mv mp /dist/bin/ && \
    mkdir -p /dist/opt/MadPascal && \
    cp -r ../base /dist/opt/MadPascal/ && \
    cp -r ../lib /dist/opt/MadPascal/

# 3. Blibs (Latest)
RUN git clone https://gitlab.com/bocianu/blibs.git && \
    mkdir -p /dist/opt/MadPascal/blibs && \
    # Robust copy
    (cp -r blibs/blibs/* /dist/opt/MadPascal/blibs/ 2>/dev/null || cp -r blibs/* /dist/opt/MadPascal/blibs/)

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

# --- THE FIX: SYMLINKS FOR CASE SENSITIVITY ---
# 1. Finds all files in libraries.
# 2. Creates a Lowercase link (system.a65) for MADS/Base includes.
# 3. Creates an Uppercase link (B_CRT.PAS) for Pascal 'Uses' clauses.
RUN find /opt/MadPascal -type f -name "*.*" | while read f; do \
      dir=$(dirname "$f"); \
      base=$(basename "$f"); \
      ext="${base##*.}"; \
      name="${base%.*}"; \
      \
      # Link Lowercase (system.a65) \
      lower=$(echo "$base" | tr '[:upper:]' '[:lower:]'); \
      if [ "$base" != "$lower" ]; then ln -fs "$base" "$dir/$lower"; fi; \
      \
      # Link Uppercase (B_CRT.PAS) \
      upper=$(echo "$base" | tr '[:lower:]' '[:upper:]'); \
      if [ "$base" != "$upper" ]; then ln -fs "$base" "$dir/$upper"; fi; \
      \
      # Link UpperName.ext (B_CRT.pas) \
      upper_name=$(echo "$name" | tr '[:lower:]' '[:upper:]'); \
      mixed="$upper_name.$ext"; \
      if [ "$base" != "$mixed" ]; then ln -fs "$base" "$dir/$mixed"; fi; \
    done

COPY script.sh /script.sh
RUN chmod +x /script.sh

WORKDIR /code
ENTRYPOINT ["/script.sh"]
