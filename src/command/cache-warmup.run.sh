## Cache-maintenance: Periodically prune+repack the git repos
if [[ $(( RANDOM % 100 )) -lt 25 ]]; then
  GIT_CACHE_OPTIMIZE=1
fi

[ $GIT_CACHE_OPTIMIZE -eq 1 ] && echo "[cache-warmup] Enable git optimization ($GIT_CACHE_OPTIMIZE)" || echo "[cache-warmup] Skip git optimization ($GIT_CACHE_OPTIMIZE)"

default_cache_setup
legacy_cache_warmup
