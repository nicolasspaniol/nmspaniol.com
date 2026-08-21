# SSL, Let's Encrypt

|What                                   |Command|
|---                                    |---|
|Install certbot (snap)                 |`sudo snap install --classic certbot`|
|Generate certificate (standalone)      |`certbot certonly --standalone -d nmspaniol.com`|

# Docker-related

|What                                   |Command|
|---                                    |---|
|-                                      |`docker compose up`|

# Git

`git remote add vps ssh://root@vps/var/nmspaniol.com.git`

`git init --bare`
