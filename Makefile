# PashuSetu task runner. Run `make <target>` from the repo root.
#
# On Windows, recipes run in Git Bash so the same Makefile works for the whole
# team (Windows, Linux, macOS). PROGRA~1 is the space-free short name for
# "Program Files"; override GIT_BASH if Git is installed elsewhere.
ifeq ($(OS),Windows_NT)
GIT_BASH ?= C:/PROGRA~1/Git/bin/bash.exe
SHELL := $(GIT_BASH)
else
SHELL := bash
endif
.SHELLFLAGS := -eu -o pipefail -c

SCENARIO ?= lsd_outbreak
SPEED ?= 20

.PHONY: help env up down api migrate seed reset-demo simulate sync-shared test test-backend test-mobile apk

help:
	@echo "Targets: up down api migrate seed reset-demo simulate sync-shared test apk"

# Create .env from the example the first time, never overwrite an edited one.
env:
	@test -f .env || { cp .env.example .env; echo "Created .env from .env.example"; }

# Start PostGIS and wait until its healthcheck passes.
up: env
	docker compose up -d --wait

down:
	docker compose down

api: env
	cd backend && uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

migrate: env
	cd backend && uv run alembic upgrade head

seed:
	@echo "seed is available from Phase 2 (backend/scripts/seed.py)." && exit 1

reset-demo:
	@echo "reset-demo is available from Phase 7 (simulator --reset + seed)." && exit 1

simulate:
	@echo "simulate is available from Phase 7 (SCENARIO=$(SCENARIO) SPEED=$(SPEED))." && exit 1

# shared/ is the single source of truth; the app gets a fresh copy, never edits.
sync-shared:
	rm -rf mobile/assets/shared
	mkdir -p mobile/assets/shared
	cp -r shared/. mobile/assets/shared/
	@echo "Copied shared/ -> mobile/assets/shared/"

test: test-backend test-mobile

test-backend: env
	cd backend && uv run pytest

test-mobile: sync-shared
	cd mobile && flutter test

apk: sync-shared
	cd mobile && flutter build apk --release
