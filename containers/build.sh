#!/usr/bin/env bash

for os in $(ls -1 -d */); do
  for release in $(ls -1 -d ${os}/*/); do
    for architecture in $(ls -1 -d ${os}/${release}/*/); do
      podman -build -t repo.rcmd.space/debrewery-${release}:${architecture} ${os}/${release}/${architecture}/
    done
  done
done
