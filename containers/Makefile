all:
	for os in $(shell ls -1 .); do \
		for release in $(shell ls -1 ${os}/); do \
			for arch in $(shell ls -1 ${os}/${release}/); do \
				podman build -t repo.rcmd.space/debrewery-${release}:${arch} ${os}/${release}/${arch} \
			done
		done
	done
