#!/bin/bash
# 重建后端镜像：使源码层缓存失效，依赖下载层保持缓存
cd "$(dirname "$0")"
CACHEBUST=$(date +%s) docker-compose build backend && docker-compose up -d backend
