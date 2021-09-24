# Take the official valhalla runner image,
# remove a few superfluous things and
# create a new runner image from ubuntu:20.04
# with the previous runner's artifacts

FROM valhalla/valhalla:run-3.1.3 as builder
#FROM rushowl/valhalla:run-3.1.3-enhanced as builder
MAINTAINER Nils Nolde <nils@gis-ops.com>

RUN rm -rf /usr/local/src/valhalla
# remove some stuff from the original image
RUN cd /usr/local/bin && \
#   preserve="valhalla_service valhalla_build_tiles valhalla_build_config valhalla_build_admins valhalla_build_timezones valhalla_build_elevation valhalla_ways_to_edges" && \
  preserve="valhalla_build_config valhalla_build_timezones valhalla_build_elevation valhalla_run_map_match valhalla_benchmark_loki valhalla_benchmark_skadi valhalla_run_isochrone valhalla_run_route valhalla_benchmark_adjacency_list valhalla_run_matrix valhalla_path_comparison valhalla_export_edges valhalla_expand_bounding_box valhalla_service valhalla_build_statistics valhalla_ways_to_edges valhalla_validate_transit valhalla_benchmark_admins valhalla_build_connectivity valhalla_build_tiles valhalla_build_admins valhalla_convert_transit valhalla_fetch_transit valhalla_query_transit valhalla_add_predicted_traffic valhalla_assign_speeds" && \
  mv $preserve .. && \
  for f in valhalla*; do rm $f; done && \
  cd .. && mv $preserve ./bin

FROM ubuntu:20.04 as runner
MAINTAINER Nils Nolde <nils@gis-ops.com>

RUN apt-get update > /dev/null && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y libboost-program-options1.71.0 libluajit-5.1-2 \
      libzmq5 libczmq4 spatialite-bin libprotobuf-lite17 \
      libsqlite3-0 libsqlite3-mod-spatialite libgeos-3.8.0 libcurl4 \
      python3.8-minimal curl unzip parallel jq spatialite-bin > /dev/null && \
    ln -s /usr/bin/python3.8 /usr/bin/python && \
    ln -s /usr/bin/python3.8 /usr/bin/python3

COPY --from=builder /usr/local /usr/local
COPY --from=builder /usr/bin/prime_* /usr/bin/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libprime* /usr/lib/x86_64-linux-gnu/

ENV LD_LIBRARY_PATH="/usr/local/lib:${LD_LIBRARY_PATH}"

COPY scripts/runtime/. /valhalla/scripts

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# Expose the necessary port
EXPOSE 8002
CMD /valhalla/scripts/run.sh
