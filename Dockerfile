# Helper image to run podman 4 daemon in rootless mode for testing
FROM almalinux:9 as builder
ARG PODMAN_VERSION=4.0.0 \
    GOLANG_VERSION=1.19.2

WORKDIR /src
ENV PATH="${PATH}:/usr/local/go/bin" \
    DESTDIR=/build

RUN curl -L https://dl.google.com/go/go${GOLANG_VERSION}.linux-amd64.tar.gz -o /tmp/go.tar.gz \
    && tar -C /usr/local -xzf /tmp/go.tar.gz

RUN dnf -y install dnf-plugins-core \
    && dnf config-manager --set-enabled crb \
    && dnf -y install git make pkg-config gcc gpgme-devel libseccomp-devel glibc-devel

RUN git clone --depth 1 --branch v${PODMAN_VERSION} https://github.com/containers/podman.git \
    && make -C podman all install

FROM almalinux:9
COPY --from=builder /build /

RUN dnf install -y containers-common crun conmon netavark aardvark-dns fuse-overlayfs \
    && dnf clean all \
    && useradd -m podman \
    && usermod --add-subuids 10000-64535 --add-subgids 10000-64535 podman

USER podman
ENTRYPOINT [ "/usr/bin/podman" ]
CMD [ "system", "service", "--time=0", "tcp://:10888" ]