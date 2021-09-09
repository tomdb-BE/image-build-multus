ARG ARCH="amd64"
ARG TAG="v3.7.2"
ARG UBI_IMAGE
ARG GO_IMAGE

# Build the multus project
FROM ${GO_IMAGE} as builder
RUN set -x \
 && apk --no-cache add \
    patch
ARG ARCH
ARG TAG
ENV GOARCH ${ARCH}
ENV GOOS "linux"
RUN git clone --depth=1 https://github.com/k8snetworkplumbingwg/multus-cni \
    && cd multus-cni \
    && git fetch --all --tags --prune \
    && git checkout tags/${TAG} -b ${TAG} \
    && ./hack/build-go.sh

# Create the multus image
FROM ${UBI_IMAGE}
RUN yum update -y && \
    yum install -y python && \
    rm -rf /var/cache/yum
COPY --from=builder /go/multus-cni /usr/src/multus-cni
WORKDIR /
RUN cp /usr/src/multus-cni/images/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
