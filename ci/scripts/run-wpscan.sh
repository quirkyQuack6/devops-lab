#!/bin/bash

docker run --rm \
		--network host \
		wpscanteam/wpscan \
		--url http://localhost:8008 \
		--enumerate vp,vt,u
