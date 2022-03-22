build_all:
	cd 57 && docker buildx build --platform linux/amd64 -t easybill/percona_xtradb_cluster:57_latest_amd64 .
	cd 57 && docker buildx build --platform linux/arm64 -t easybill/percona_xtradb_cluster:57_latest_arm64 .

build_and_push: build_all
	docker push easybill/percona_xtradb_cluster:57_latest_arm64
	docker push easybill/percona_xtradb_cluster:57_latest_amd64
	docker manifest rm easybill/percona_xtradb_cluster:57_latest || true
	docker manifest create easybill/percona_xtradb_cluster:57_latest easybill/percona_xtradb_cluster:57_latest_amd64 easybill/percona_xtradb_cluster:57_latest_arm64
	docker manifest push easybill/percona_xtradb_cluster:57_latest
