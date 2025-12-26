# ==========================================
# STAGE 1: Builder (Compiles tools from source)
# ==========================================
FROM alpine:latest AS builder

# Install build dependencies (Free Pascal and Git)
RUN apk add --no-cache fpc git

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
    # Organize libraries for the final image
    mkdir -p /dist/opt/MadPascal && \
    cp -r ../base /dist/opt/MadPascal/ && \
    cp -r ../lib /dist/opt/MadPascal/

# 3. Add Blibs (Libraries)
RUN git clone https://gitlab.com/bocianu/blibs.git && \
    cp -r blibs/*.pas /dist/opt/MadPascal/lib/

# ==========================================
# STAGE 2: Final Runtime Image (Small Size)
# ==========================================
FROM alpine:latest

# Install Bash (required for script.sh)
RUN apk add --no-cache bash

# Copy executables (mp, mads) to system bin
COPY --from=builder /dist/bin/mp /usr/bin/mp
COPY --from=builder /dist/bin/mads /usr/bin/mads

# Copy libraries
COPY --from=builder /dist/opt/MadPascal /opt/MadPascal

# Set Environment Variables
ENV MP_DIR="/opt/MadPascal"
ENV PATH="$MP_DIR:$PATH"

# Setup the runner script
COPY script.sh /script.sh
RUN chmod +x /script.sh

# Set working directory to match the -v mount
WORKDIR /code

ENTRYPOINT ["/script.sh"]
