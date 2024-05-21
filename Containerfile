FROM debian:12.5

RUN apt-get -o APT::Retries=3 update -y && \
    apt-get -o APT::Retries=3 install -y --no-install-recommends \
        vim \
        make \
        build-essential \
        libglib2.0-dev \
        valgrind

RUN mkdir -p /root/cstyle
WORKDIR /root/cstyle

CMD ["/bin/bash"]
