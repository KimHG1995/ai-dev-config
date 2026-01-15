# ai-dev-config

OpenCode + oh-my-opencode + MCP 서버를 위한 개인 설정 SSOT 레포입니다.

## 구성

```
./
├── opencode/
│   ├── base.opencode.jsonc
│   ├── mcp.docker.opencode.jsonc
│   └── mcp.local.opencode.jsonc
├── oh-my-opencode/
│   └── oh-my-opencode.json
├── docker/
│   ├── docker-compose.yml
│   └── .env.example
├── scripts/
│   └── install.sh
└── AGENTS.md
```

## 사용 방법

### 1) 프로젝트에 설정 적용 (심볼릭 링크)

```
./scripts/install.sh /path/to/project docker
```

생성되는 링크:
- `opencode.jsonc` -> `opencode/base.opencode.jsonc`
- `opencode.mcp.jsonc` -> `opencode/mcp.docker.opencode.jsonc` 또는 `opencode/mcp.local.opencode.jsonc`
- `oh-my-opencode.json` -> `oh-my-opencode/oh-my-opencode.json`

로컬 MCP 런너를 쓰는 경우:

```
./scripts/install.sh /path/to/project local
```

### 2) MCP 서버 실행 (Docker)

```
cd docker
cp .env.example .env
# 필요한 경우에만 키를 채우세요.

docker compose up -d
```

포트:
- sequential-thinking: `3333`
- taskmaster: `3334`
- tavily: `3335` (기본 비활성화)
- context7: `3336` (기본 비활성화)

## 운영 원칙

- API 키는 설정 파일에 넣지 않습니다.
- 최신 정보가 필요할 때만 Tavily/Context7을 활성화합니다.
- 프로젝트별 차이는 오버레이 설정으로 흡수합니다.
- `docker/docker-compose.yml` 이미지 이름은 실제 MCP 이미지에 맞게 조정하세요.
