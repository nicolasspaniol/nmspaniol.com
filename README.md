# SSL, Let's Encrypt

|What                                   |Command|
|---                                    |---|
|Install certbot (snap)                 |`sudo snap install --classic certbot`|
|Generate certificate (standalone)      |`certbot certonly --standalone -d nmspaniol.com`|

# Docker-related

|What                                   |Command|
|---                                    |---|
|-                                      |`docker compose up --build`|

# Git

no local:
```
git remote add vps ssh://deploy@vps/var/www/nmspaniol.com.git
```

no remoto:
```
WWW_PATH=/var/www/nmspaniol.com.git
mkdir -p "$WWW_PATH"
git init --bare --initial-branch=main "$WWW_PATH"

useradd --create-home --groups docker deploy
chown --recursive deploy:deploy "$WWW_PATH"

sudo mkdir -p /app
sudo chown deploy:deploy /app
```

em `/var/www/nmspaniol.com.git/hooks/post-receive`:
```
#!/bin/bash
WORK_TREE=/app
GIT_DIR=/var/www/nmspaniol.com.git
LOG_FILE=/home/deploy/deploy.log

echo "=== Deploy started: $(date) ==="
git --work-tree=$WORK_TREE --git-dir=$GIT_DIR checkout -f main
cd $WORK_TREE

if docker compose up -d --build; then
    echo "[OK] Deploy succeeded: $(date)"
else
    echo "[ERR] Build/deploy FAILED: $(date)"
exit 1
fi
```

isso coloca o programa em `/app`. para logs, rodar `cd /app; docker compose logs`

LEMBRAR de dar `chmod +x post-receive`
