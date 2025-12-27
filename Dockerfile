# STAGE 1: Builder
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

# 3. Blibs (FIXED COPY COMMAND)
RUN git clone https://gitlab.com/bocianu/blibs.git && \
    # We copy the whole folder to ensure no files are missed
    cp -r blibs /dist/opt/MadPascal/

# STAGE 2: Runtime
FROM debian:stable-slim
RUN apt-get update && apt-get install -y --no-install-recommends bash && rm -rf /var/lib/apt/lists/*

COPY --from=builder /dist/bin/mp /usr/bin/mp
COPY --from=builder /dist/bin/mads /usr/bin/mads
COPY --from=builder /dist/opt/MadPascal /opt/MadPascal

ENV MP_DIR="/opt/MadPascal"
ENV PATH="$MP_DIR:$PATH"

COPY script.sh /script.sh
RUN chmod +x /script.sh

WORKDIR /code
ENTRYPOINT ["/script.sh"]
