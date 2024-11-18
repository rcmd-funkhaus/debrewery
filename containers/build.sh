#!/usr/bin/env bash

for os in "debian"; do
  for release in "bookworm" "bullseye" "buster"; do
    for arch in "amd64" "armhf" "arm64"; do
      podman build -t repo.rcmd.space/debrewery-${release}:${arch} . -f ${os}/${release}/${arch}/Dockerfile
      podman push repo.rcmd.space/debrewery-${release}:${arch}
    done
  done
done
