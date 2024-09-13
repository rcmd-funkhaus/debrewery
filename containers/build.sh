#!/usr/bin/env bash

for os in "debian"; do
  for release in "bookworm"; do
    for arch in "amd64" "armhf" "arm64"; do
      podman build -t repo.rcmd.space/debrewery-${release}:${arch} . -f ${os}/${release}/${arch}/Dockerfile
      podman push -t repo.rcmd.space/debrewery-${release}:${arch}
    done
  done
done
