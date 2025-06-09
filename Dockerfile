FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
    libc6 \
    libgcc-s1 \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

COPY external/bwa-mem2/bwa-mem2* /usr/local/bin/ 
COPY tests/ /app/tests/ 
COPY data /app/data/
RUN chmod +x /usr/local/bin/bwa-mem2* /app/tests/

WORKDIR  /app

ENTRYPOINT ["bwa-mem2"]