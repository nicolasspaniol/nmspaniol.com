FROM node:22-slim AS assets
ENV CI=true
RUN npm install -g pnpm
WORKDIR /app
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .
RUN pnpm install
COPY . .
RUN pnpm run build:css

FROM ghcr.io/astral-sh/uv:python3.14-trixie-slim
WORKDIR /app
RUN ls
COPY pyproject.toml .
RUN ls
COPY . .
RUN uv sync
COPY --from=assets /app/src/nmspaniol_com ./src/nmspaniol_com

CMD ["sh", "-c", "uv run gunicorn --bind 0.0.0.0:8000 nmspaniol_com.app:app"]
