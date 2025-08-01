build:
	docker build -t pure-ftpd .

run:
	docker run \
	  --privileged \
	  -p 21:21 \
	  -p 30000-30009:30000-30009 \
	  -e FTP_PASSIVE_IP=localhost \
	  -e FTP_USER=test \
	  -e FTP_PASSWORD=test \
	  pure-ftpd

run-bash:
	docker run \
	  -it --entrypoint bash \
	  --privileged \
	  -p 21:21 \
	  -p 30000-30009:30000-30009 \
	  -e FTP_PASSIVE_IP=localhost \
	  -e FTP_USER=test \
	  -e FTP_PASSWORD=test \
	  pure-ftpd
