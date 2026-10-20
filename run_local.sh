#!/usr/bin/env bash
#
# run_local.sh — build or serve the site locally with the same Jekyll as GitHub Pages
#
# Usage:
#   ./run_local.sh           serve on http://localhost:4000
#   ./run_local.sh build     build once into _site/
#
# Modes:
#   serve (default)  jekyll serve, rebuilds when a file changes
#   build            jekyll build, then exit
#
# Everything runs in a ruby container: Docker is the only host requirement.
# Gems are cached in ~/.cache/coworking-bourg-gems between runs.

set -euo pipefail

RUBY_IMAGE="ruby:3.3"
REPO_NWO="chocobn69/coworking-bourg"
GEM_CACHE="${HOME}/.cache/coworking-bourg-gems"
PORT="4000"
BUNDLE_INSTALL="bundle install --quiet"
SITE_DIR="$(cd "$(dirname "$0")" && pwd)"

docker_options=(
    --rm
    # Run as the host user so _site/ and Gemfile.lock are not owned by root
    --user "$(id -u):$(id -g)"
    # The host uid has no home directory in the image; bundler needs a writable one
    --env HOME=/tmp
    # Install gems into the cache volume instead of the root-owned /usr/local/bundle
    --env BUNDLE_PATH=/gems
    # github-pages needs the repository name to fill site.github outside of GitHub
    --env PAGES_REPO_NWO="${REPO_NWO}"
    --volume "${GEM_CACHE}:/gems"
    --volume "${SITE_DIR}:/srv"
    --workdir /srv
)

prepare_gem_cache() {
    mkdir -p "${GEM_CACHE}"
}

build_site() {
    docker run "${docker_options[@]}" \
        "${RUBY_IMAGE}" \
        sh -c "${BUNDLE_INSTALL} && bundle exec jekyll build"
}

serve_site() {
    local serve_options=(
        # A TTY lets Ctrl+C stop the server
        --interactive
        --tty
        --publish "${PORT}:${PORT}"
    )

    docker run "${docker_options[@]}" "${serve_options[@]}" \
        "${RUBY_IMAGE}" \
        sh -c "${BUNDLE_INSTALL} && bundle exec jekyll serve --host 0.0.0.0 --port ${PORT}"
}

main() {
    local mode="${1:-serve}"

    prepare_gem_cache

    case "${mode}" in
        build)
            build_site
            ;;
        serve)
            serve_site
            ;;
        *)
            echo "Usage: $0 [serve|build]" >&2
            exit 1
            ;;
    esac
}

main "$@"
