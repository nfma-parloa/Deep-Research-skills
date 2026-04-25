#!/usr/bin/env bash
# Pull upstream Weizhena/Deep-Research-skills, transform to plugin-shaped layout,
# and append a single commit on master if the resulting tree differs from HEAD.
#
# Linear history; no force-push. Run by .github/workflows/sync-from-upstream.yml.
set -euo pipefail

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
UPSTREAM_URL="${UPSTREAM_URL:-https://github.com/Weizhena/Deep-Research-skills.git}"
UPSTREAM_BRANCH="${UPSTREAM_BRANCH:-master}"

# Files this fork owns — preserved through every sync.
FORK_OWNED=(
  ".claude-plugin/plugin.json"
  "FORK.md"
  "scripts/sync-from-upstream.sh"
  ".github/workflows/sync-from-upstream.yml"
)

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

if ! git remote get-url "$UPSTREAM_REMOTE" >/dev/null 2>&1; then
  git remote add "$UPSTREAM_REMOTE" "$UPSTREAM_URL"
fi
git fetch "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH" --tags --quiet

upstream_sha=$(git rev-parse "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH")
short_sha="${upstream_sha:0:7}"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# 1. Lay down upstream tree as-is.
git archive "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH" | tar -x -C "$work"

# 2. Apply structural transforms.
if [[ -d "$work/skills/research-en" ]]; then
  mkdir -p "$work/skills"
  for dir in "$work/skills/research-en"/*/; do
    [[ -d "$dir" ]] || continue
    name=$(basename "$dir")
    rm -rf "$work/skills/$name"
    mv "$dir" "$work/skills/$name"
  done
  rmdir "$work/skills/research-en" 2>/dev/null || true
fi

rm -rf \
  "$work/skills/research-zh" \
  "$work/skills/research-codex-en" \
  "$work/skills/research-codex-zh" \
  "$work/agents-codex" \
  "$work/agents/web-search-opencode.md" \
  "$work/README.zh.md"

# 3. Restore fork-owned files from current HEAD.
for path in "${FORK_OWNED[@]}"; do
  if git cat-file -e "HEAD:$path" 2>/dev/null; then
    mkdir -p "$work/$(dirname "$path")"
    git show "HEAD:$path" > "$work/$path"
    if [[ "$path" == *.sh ]]; then
      chmod +x "$work/$path"
    fi
  fi
done

# 4. Build a tree object from $work using a temp index.
tmp_index=$(mktemp -u)
trap 'rm -rf "$work" "$tmp_index"' EXIT

GIT_INDEX_FILE="$tmp_index" GIT_WORK_TREE="$work" git add -A
new_tree=$(GIT_INDEX_FILE="$tmp_index" git write-tree)
head_tree=$(git rev-parse HEAD^{tree})

if [[ "$new_tree" == "$head_tree" ]]; then
  echo "✓ tree unchanged — already in sync with upstream@$short_sha"
  exit 0
fi

# 5. Commit and push.
parent=$(git rev-parse HEAD)
commit_msg="sync: upstream@$short_sha

Mirrors https://github.com/Weizhena/Deep-Research-skills/commit/$upstream_sha
with plugin-shape transforms applied (see FORK.md)."

new_commit=$(git commit-tree "$new_tree" -p "$parent" -m "$commit_msg")

git update-ref refs/heads/master "$new_commit"
echo "✓ committed $new_commit (upstream@$short_sha)"

if [[ "${SYNC_PUSH:-true}" == "true" ]]; then
  git push origin master
  echo "✓ pushed to origin/master"
else
  echo "→ skip push (SYNC_PUSH=false)"
fi
