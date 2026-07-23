#!/usr/bin/env bash

set -e

default_container='php'

fn_run() {
  "${runner[@]}" "${command_args[@]}" "${additional_args[@]}"
  if [[ "${should_exit}" == 'true' ]]; then
    exit
  fi
}

fn_purge() {
  fn_delete
  mapfile -t additional_args < <(docker images -q)

  if ((${#additional_args[@]} > 0)); then
    echo ' Removing all images:'
    command_args=(rmi --force)
    fn_run
  else
    echo '   No images to remove.'
  fi
}

fn_delete() {
  fn_kill
  mapfile -t additional_args < <(docker ps -aq)

  if ((${#additional_args[@]} > 0)); then
    echo ' Removing all containers:'
    command_args=(rm)
    fn_run
  else
    echo '   No containers to remove.'
  fi
}

fn_kill() {
  fn_stop
  runner=(docker)
  should_exit='false'
  mapfile -t additional_args < <(docker ps -q)

  if ((${#additional_args[@]} > 0)); then
    echo ' Killing all running containers:'
    command_args=(kill)
    fn_run
  else
    echo '   No containers to kill.'
  fi
}

fn_stop() {
  echo ' Stopping NDE'
  command_args=(down)
  additional_args=()
  should_exit='false'
  runner=(docker compose -f "${config}")
  fn_run
}

fn_stop_containers() {
  local -a running_containers

  mapfile -t running_containers < <(docker ps -q)
  if ((${#running_containers[@]} > 0)); then
    docker stop "${running_containers[@]}"
  fi

  mapfile -t running_containers < <(docker ps -q)
  if ((${#running_containers[@]} > 0)); then
    docker kill "${running_containers[@]}"
  fi
}

fn_help() {
  cat "${path}/topath/d.help.md"
}

path=$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")
config="${path}/docker-compose.yml"

export USER_NAME="$(id -un)"
export GROUP_NAME="$(id -gn)"
export USER_ID="$(id -u)"
export GROUP_ID="$(id -g)"
export DOCKER_GID="$(getent group docker | cut -d: -f3)"

runner=(docker compose -f "${config}")
command_args=("$@")
input_params=("$@")
additional_args=()
should_exit='true'

command_text="${command_args[*]}"

case "${command_text}" in
  df|--df)
    docker system df
    exit
    ;;
  h|-h|--help)
    fn_help
    exit
    ;;
  i|-i|-init|init|--init)
    "${path}/init.sh" script
    exit
    ;;
  p|-p|-purge|purge|--purge)
    fn_purge
    exit
    ;;
  x|-x|-delete|-del|delete|del|--delete)
    fn_delete
    exit
    ;;
  k|-k|-kill|kill|--kill)
    fn_kill
    exit
    ;;
  d|-d|down|--down)
    docker compose -f "${config}" down
    exit
    ;;
  r|-r|-reload|reload|--reload)
    docker compose -f "${config}" down
    "${path}/build-php.sh"
    docker compose -f "${config}" up -d --build
    exit
    ;;
esac

if [[ "${1:-}" =~ ^[^-]+$ ]]; then
  default_container="${1}"
fi

container_name=$(docker ps --format '{{.Names}}' \
  -f label=com.docker.compose.project=nde 2>/dev/null \
  | grep -F "${default_container}" | sort | head -n 1)

if [[ -n "${container_name}" ]]; then
  runner=(docker exec -it)
  command_args=("${container_name}")
  additional_args=(bash)
  if [[ -n "${2:-}" ]]; then
    additional_args=("${2}")
  fi
elif [[ -z "${container_name}" && -z "${1:-}" ]]; then
  command_args=(up)
  additional_args=(-d)
else
  command_args=("$@")
fi

if [[ "${input_params[0]:-}" == '-c' ]]; then
  command_args+=(bash -c)
  additional_args=("${input_params[*]:1}")
fi

if [[ "${input_params[1]:-}" == '-c' ]]; then
  command_args+=(bash -c)
  additional_args=("${input_params[*]:2}")
fi

has_option() {
  local option="${1}"
  local param

  for param in "${command_args[@]}"; do
    if [[ "${param}" == "${option}" ]]; then
      return 0
    fi
  done

  return 1
}

if [[ "${command_args[0]:-}" == 'up' ]] && has_option '-a'; then
  filtered_args=()
  for arg in "${command_args[@]}"; do
    if [[ "${arg}" != '-a' ]]; then
      filtered_args+=("${arg}")
    fi
  done
  command_args=("${filtered_args[@]}")
elif [[ "${command_args[0]:-}" == 'up' ]] && ! has_option '-d'; then
  additional_args=(-d)
fi

if [[ "${command_args[0]:-}" == 'up' || "${command_args[0]:-}" == 'build' ]]; then
  "${path}/build-php.sh"
fi

if [[ "${command_args[0]:-}" == 'up' ]]; then
  command_args+=(--build)
fi

if [[ "${command_args[0]:-}" == 'up' ]] && has_option '-o'; then
  filtered_args=()
  for arg in "${command_args[@]}"; do
    if [[ "${arg}" != '-o' ]]; then
      filtered_args+=("${arg}")
    fi
  done
  command_args=("${filtered_args[@]}")

  fn_stop_containers
fi

fn_run
