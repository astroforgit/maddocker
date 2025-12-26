# ==========================================
# STAGE 1: Builder (Compiles tools)
# ==========================================
FROM debian:stable-slim AS builder

# Prevent interactive errors
ENV DEBIAN_FRONTEND=noninteractive

# Install FPC and Git
RUN apt-get update && \
    apt-get install -y fpc git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

# 1. Build Mad Assembler (MADS)
RUN git clone https://github.com/tebe6502/Mad-Assembler.git && \
    cd Mad-Assembler && \
    fpc -Mdelphi -v -O3 mads.pas && \
    mkdir -p /dist/bin && \
    mv mads /dist/bin/

# 2. Build Mad Pascal (MP)
RUN git clone https://github.com/tebe6502/Mad-Pascal.git && \
    cd Mad-Pascal/src && \
    fpc -Mdelphi -v -O3 mp.pas && \
    mv mp /dist/bin/ && \
    # Organize libraries
    mkdir -p /dist/opt/MadPascal && \
    cp -r ../base /dist/opt/MadPascal/ && \
    cp -r ../lib /dist/opt/MadPascal/

# 3. Add Blibs (Libraries)
RUN git clone https://gitlab.com/bocianu/blibs.git && \
    cp -r blibs/*.pas /dist/opt/MadPascal/lib/

# ==========================================
# STAGE 2: Final Runtime Image
# ==========================================
FROM debian:stable-slim

# Install minimal dependencies (if any needed for the script)
RUN apt-get update && \
    apt-get install -y --no-install-recommends bash && \
    rm -rf /var/lib/apt/lists/*

# Copy binaries
COPY --from=builder /dist/bin/mp /usr/bin/mp
COPY --from=builder /dist/bin/mads /usr/bin/mads

# Copy libraries
COPY --from=builder /dist/opt/MadPascal /opt/MadPascal

# Environment setup
ENV MP_DIR="/opt/MadPascal"
ENV PATH="$MP_DIR:$PATH"

# Setup script
COPY script.sh /script.sh
RUN chmod +x /script.sh

WORKDIR /code

ENTRYPOINT ["/script.sh"]
