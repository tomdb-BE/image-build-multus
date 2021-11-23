ARG ARCH="amd64"
ARG TAG="v3.8"
ARG UBI_IMAGE=registry.access.redhat.com/ubi8/ubi-minimal:latest
ARG GO_IMAGE=rancher/hardened-build-base:v1.16.10b7

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
RUN microdnf update -y && microdnf install python
COPY --from=builder /go/multus-cni /usr/src/multus-cni
WORKDIR /
RUN cp /usr/src/multus-cni/images/entrypoint.sh /entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
