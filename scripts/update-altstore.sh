#!/usr/bin/env bash
# Regenerate altstore/apps.json from a GitLab release and, inside CI, commit
# it back to main with ci.skip so the push does not start another pipeline.
# Runs at the end of the github-release-sync job; RELEASE_TAG comes from the
# pipeline trigger.
set -euo pipefail

PROJECT_DIR="${CI_PROJECT_DIR:-$PWD}"
cd "$PROJECT_DIR"

APPS_JSON="altstore/apps.json"
IPA_ASSET="glam-ios-arm64-unsigned.ipa"
RAW_BASE="https://gitlab.com/HttpAnimations/Glam/-/raw/main"
PROJECT="${CI_PROJECT_ID:-HttpAnimations%2FGlam}"
MIN_OS="14.0"

RELEASE_TAG="${RELEASE_TAG:-}"
if [ -z "$RELEASE_TAG" ]; then
  RELEASE_TAG=$(glab api "projects/$PROJECT/releases?per_page=1" | jq -r '.[0].tag_name')
fi
echo "Updating AltStore source for $RELEASE_TAG"

RELEASE=$(glab api "projects/$PROJECT/releases/$RELEASE_TAG")
IPA_URL=$(jq -r --arg n "$IPA_ASSET" \
  '[.assets.links[] | select(.name == $n) | .direct_asset_url // .url][0] // empty' \
  <<<"$RELEASE")
if [ -z "$IPA_URL" ]; then
  echo "Release $RELEASE_TAG has no $IPA_ASSET asset, skipping"
  exit 0
fi

DATE=$(jq -r '.released_at | .[:10]' <<<"$RELEASE")
VERSION="${RELEASE_TAG#v}"
RELEASE_URL="https://gitlab.com/HttpAnimations/Glam/-/releases/$RELEASE_TAG"

# The ipa was already downloaded into release-assets/ by sync-from-github.sh;
# fall back to the asset's content-length when running locally.
if [ -f "release-assets/$IPA_ASSET" ]; then
  SIZE=$(stat -c %s "release-assets/$IPA_ASSET")
else
  SIZE=$(curl -sIL "$IPA_URL" | awk 'tolower($1) == "content-length:" {n=$2} END {gsub(/\r/, "", n); print n+0}')
fi
if [ -z "$SIZE" ] || [ "$SIZE" = "0" ]; then
  echo "Could not determine size of $IPA_ASSET" >&2
  exit 1
fi

# In CI, base the commit on the current tip of main so the push is a fast
# forward even when the pipeline ran on an older commit.
PUSH_TO_MAIN=""
if [ -n "${GITLAB_TOKEN:-}" ] && [ -n "${CI_PROJECT_PATH:-}" ]; then
  PUSH_TO_MAIN="1"
  git config user.name "GitLab CI"
  git config user.email "ci@gitlab.com"
  git remote add altstore-push \
    "https://oauth2:${GITLAB_TOKEN}@${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git" 2>/dev/null || true
  git fetch altstore-push main
  git checkout -B ci-altstore-update FETCH_HEAD
fi

ENTRY=$(jq -n --arg v "$VERSION" --arg d "$DATE" --arg u "$IPA_URL" \
  --argjson s "$SIZE" --arg os "$MIN_OS" \
  '{version: $v, date: $d, downloadURL: $u, size: $s, minOSVersion: $os}')
NEWS=$(jq -n --arg id "release-$RELEASE_TAG" --arg t "Glam $RELEASE_TAG" \
  --arg c "Glam $VERSION for iOS is now available." \
  --arg d "$DATE" --arg u "$RELEASE_URL" \
  '{identifier: $id, title: $t, caption: $c, date: $d, url: $u, tintColor: "FC6D26"}')
APP_SKELETON=$(jq -n --arg icon "$RAW_BASE/altstore/icon.png" --arg shots "$RAW_BASE" '
  {
    name: "Glam",
    bundleIdentifier: "dev.glam.glam",
    developerName: "HttpAnimations",
    subtitle: "A GitLab client for iPhone and iPad.",
    localizedDescription: "Glam is a GitLab client that works against gitlab.com or any self-hosted instance. Browse projects, issues, merge requests, pipelines and more over the REST v4 API. Sign in with a personal access token; it stays in the device keychain.",
    iconURL: $icon,
    tintColor: "FC6D26",
    category: "developer",
    screenshotURLs: [
      ($shots + "/test/goldens/goldens/dashboard.png"),
      ($shots + "/test/goldens/goldens/projects.png"),
      ($shots + "/test/goldens/goldens/issue.png"),
      ($shots + "/test/goldens/goldens/pipelines.png")
    ],
    versions: [],
    appPermissions: {}
  }')

BASE=$(cat "$APPS_JSON" 2>/dev/null || echo '{}')
jq --indent 2 \
  --argjson entry "$ENTRY" \
  --argjson news "$NEWS" \
  --argjson app "$APP_SKELETON" \
  --arg icon "$RAW_BASE/altstore/icon.png" '
  .name //= "Glam" |
  .identifier //= "dev.glam.source" |
  .apps //= [] |
  (if (.apps | length) == 0 then .apps = [$app] else . end) |
  .apps[0].iconURL //= $icon |
  .apps[0].versions = ([$entry] + [.apps[0].versions[]? | select(.version != $entry.version)]) |
  .news = (([$news] + [.news[]? | select(.identifier != $news.identifier)])[0:20])
' <<<"$BASE" > "$APPS_JSON.tmp"
mv "$APPS_JSON.tmp" "$APPS_JSON"

if [ -z "$PUSH_TO_MAIN" ]; then
  echo "GITLAB_TOKEN or CI_PROJECT_PATH not set, wrote $APPS_JSON without committing"
  exit 0
fi

git add "$APPS_JSON"
if git diff --cached --quiet; then
  echo "AltStore source already up to date"
  exit 0
fi

git commit -m "chore: 更新 AltStore 源"
push_update() {
  git push -o ci.skip altstore-push HEAD:main
}
if ! push_update; then
  git fetch altstore-push main
  git rebase FETCH_HEAD
  push_update
fi
