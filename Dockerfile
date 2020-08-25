FROM ubuntu:latest
ENV TZ=Europe/Warsaw
RUN apt-get -y update && \
	apt-get -y upgrade && \
	apt-get -y install  fpc-3.0.4
RUN apt-get -y install  git
RUN cd /tmp && \
    git clone https://github.com/tebe6502/Mad-Pascal && \
    git clone https://gitlab.com/bocianu/blibs && \
    cd Mad-Pascal && \
    fpc -Mdelphi -v -O3 mp.pas && \
    cp mp /bin/ && \
    cp -r ../Mad-Pascal /madPascal && \
    cp -r ./lib /paslib && \
    ln -s ../blibs/*.pas /paslib

RUN cd /tmp && \
        git clone https://github.com/tebe6502/Mad-Assembler.git && \
        cd Mad-Assembler && \
        fpc -Mdelphi -v -O3 mads.pas && \
        cp mads /bin/
RUN cd /tmp && \
        git clone https://github.com/astroforgit/maddocker.git && \
        cd maddocker && \
        cp script.sh /script.sh

RUN chmod +x /script.sh

ENTRYPOINT ["/script.sh"]
