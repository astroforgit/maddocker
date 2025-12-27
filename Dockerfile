# ==========================================
# STAGE 1: Builder
# ==========================================
FROM debian:stable-slim AS builder
ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Dependencies
RUN apt-get update && \
    apt-get install -y fpc git wget ca-certificates && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

# 2. Build Mad Assembler (MADS)
RUN git clone https://github.com/tebe6502/Mad-Assembler.git && \
    cd Mad-Assembler && \
    fpc -Mdelphi -v -O3 mads.pas && \
    mkdir -p /dist/bin && \
    mv mads /dist/bin/

# 3. Build Mad Pascal (v1.7.5 from Tarball)
RUN wget https://github.com/tebe6502/Mad-Pascal/archive/refs/tags/v1.7.5.tar.gz -O mp.tar.gz && \
    tar -xzf mp.tar.gz && \
    # The user confirmed 'mp.pas' is in 'origin' folder, NOT 'src'
    cd Mad-Pascal-1.7.5/origin && \
    fpc -Mdelphi -v -O3 mp.pas && \
    mv mp /dist/bin/ && \
    mkdir -p /dist/opt/MadPascal && \
    # Copy standard libraries from the tarball
    cp -r ../base /dist/opt/MadPascal/ && \
    cp -r ../lib /dist/opt/MadPascal/ && \
    # Copy 'blibs' which is ALSO inside the tarball (no need to git clone)
    cp -r ../blibs /dist/opt/MadPascal/

# ==========================================
# STAGE 2: Runtime
# ==========================================
FROM debian:stable-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends bash findutils coreutils && \
    rm -rf /var/lib/apt/lists/*

# Copy binaries and libraries
COPY --from=builder /dist/bin/mp /usr/bin/mp
COPY --from=builder /dist/bin/mads /usr/bin/mads
COPY --from=builder /dist/opt/MadPascal /opt/MadPascal

ENV MP_DIR="/opt/MadPascal"
ENV PATH="$MP_DIR:$PATH"

# --- CASE SENSITIVITY FIX (Symlinks) ---
# Creates aliases so Linux can find files even if the casing doesn't match
# e.g. 'Uses B_CRT' -> finds 'b_crt.pas'
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
