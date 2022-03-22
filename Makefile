build_all:
	cd 57 && docker buildx build --platform linux/amd64 -t timglabisch/percona57:latest_amd64 .
	cd 57 && docker buildx build --platform linux/arm64 -t timglabisch/percona57:linux_arm64 .