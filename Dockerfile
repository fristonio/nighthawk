FROM envoyproxy/envoy-build-ubuntu:f4a881a1205e8e6db1a57162faf3df7aed88eae8@sha256:b10346fe2eee41733dbab0e02322c47a538bf3938d093a5daebad9699860b814 as builder

WORKDIR /source
ADD . /source/

# No auth for remote build cache.
#
# ENV BAZEL_BUILD_EXTRA_OPTIONS "--config=remote-ci-download --config=remote-envoy-engflow"
# RUN echo "build:remote-envoy-engflow --config=bes-envoy-engflow" > repo.bazelrc

RUN ./ci/do_ci.sh opt_build

# Nighthawk Docker image.
FROM ubuntu:24.04@sha256:1e622c5f073b4f6bfad6632f2616c7f59ef256e96fe78bf6a595d1dc4376ac02

RUN apt -y update && apt -y install libatomic1 curl

COPY --from=builder /source/bazel-bin/nighthawk_client /usr/local/bin/nighthawk_client
COPY --from=builder /source/bazel-bin/nighthawk_test_server /usr/local/bin/nighthawk_test_server
COPY --from=builder /source/bazel-bin/nighthawk_output_transform /usr/local/bin/nighthawk_output_transform
COPY --from=builder /source/bazel-bin/nighthawk_service /usr/local/bin/nighthawk_service
COPY --from=builder /source/bazel-bin/nighthawk_adaptive_load_client /usr/local/bin/nighthawk_adaptive_load_client

ADD ci/docker/default-config.yaml /etc/nighthawk/nighthawk.yaml

# Ports for nighthawk_test_server, see default-config.yaml
EXPOSE 10001 10080
# The default port for nighthawk_service
EXPOSE 8443

ENTRYPOINT ["/usr/local/bin/nighthawk_test_server"]
CMD ["-c", "/etc/nighthawk/nighthawk.yaml"]