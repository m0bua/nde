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

fn_update_cert() {
  local cert_file="${path}/cfg/nginx/cert/nginx-selfsigned.crt"
  local cert_hash_before=''
  local cert_hash_after=''

  if [[ -x "${cert_script}" ]]; then
    if [[ -f "${cert_file}" ]]; then
      cert_hash_before="$(sha256sum "${cert_file}" | awk '{print $1}')"
    fi
    "${cert_script}" --auto

    if [[ -f "${cert_file}" ]]; then
      cert_hash_after="$(sha256sum "${cert_file}" | awk '{print $1}')"
    fi
    if [[ -n "${cert_hash_before}" && "${cert_hash_before}" != "${cert_hash_after}" ]] &&
      docker compose -f "${config}" ps --status running --services 2>/dev/null |
      grep -Fxq nginx; then
      echo 'Restarting nginx to load the new certificate.'
      docker compose -f "${config}" restart nginx
    fi
  fi
}

fn_help() {
  cat "${path}/d.help.md"
}

fn_host_block() {
  local project handler
  local -a projects project_dirs handlers

  local -a static_projects=(main adminer mail)
  mapfile -t project_dirs < <(
    find "${HOME}/prj" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null |
      grep -E '^[a-zA-Z0-9-]+$' |
      grep -Ev '^(main|adminer|mail|html)$' |
      sort || true
  )
  projects=("${static_projects[@]}" "${project_dirs[@]}")
  mapfile -t handlers < <(
    docker compose -f "${config}" config --services |
      grep -E '^[a-zA-Z0-9-]+$' |
      grep -Ev '^(nginx|db|redis|mail)$' | sort -u
  )

  if ((${#projects[@]} <= 3)); then
    echo 'No project directories found under ~/prj.' >&2
    return 1
  fi
  if ((${#handlers[@]} == 0)); then
    echo 'No handlers found in docker-compose.yml.' >&2
    return 1
  fi

  printf '%s\n' '# NDE managed hosts start'
  for project in "${projects[@]}"; do
    printf '127.0.0.1 %s.local\n' "$project"
    for handler in "${handlers[@]}"; do
      printf '127.0.0.1 %s.%s.local\n' "$project" "$handler"
    done
  done
  printf '%s\n' '# NDE managed hosts end'
}

fn_hosts_write() {
  local hosts_file="$1"
  local block_file="$2"
  local temp_file

  temp_file=$(mktemp)
  if ! awk '
    function flush_blanks() {
      for (i = 0; i < blank_count; i++) print ""
      blank_count = 0
    }
    $0 == "# NDE managed hosts start" {
      if (inside || seen_start) exit 2
      inside = 1
      seen_start = 1
      next
    }
    $0 == "# NDE managed hosts end" {
      if (!inside || seen_end) exit 2
      inside = 0
      seen_end = 1
      next
    }
    !inside {
      if ($0 ~ /^[[:space:]]*$/) {
        blank_count++
        next
      }
      flush_blanks()
      print
    }
    END {
      if (inside || (seen_start != seen_end)) exit 2
    }
  ' "$hosts_file" > "$temp_file"; then
    rm -f "$temp_file"
    echo 'NDE hosts markers are incomplete or duplicated; hosts was left unchanged.' >&2
    return 1
  fi

  printf '\n' >> "$temp_file"
  cat "$block_file" >> "$temp_file"
  if [[ -w "$hosts_file" ]]; then
    cat "$temp_file" > "$hosts_file"
  else
    sudo tee "$hosts_file" < "$temp_file" >/dev/null
  fi
  rm -f "$temp_file"
}

fn_hosts_sync() {
  local block_file
  block_file=$(mktemp)
  fn_host_block > "$block_file"
  fn_hosts_write /etc/hosts "$block_file"
  rm -f "$block_file"
  echo 'Updated /etc/hosts with NDE domains.'
}

fn_hosts_clean() {
  local hosts_file='/etc/hosts'
  local temp_file

  if ! grep -Fxq '# NDE managed hosts start' "$hosts_file" &&
    ! grep -Fxq '# NDE managed hosts end' "$hosts_file"; then
    echo 'No NDE hosts block found.'
    return 0
  fi

  temp_file=$(mktemp)
  if ! awk '
    function flush_blanks() {
      for (i = 0; i < blank_count; i++) print ""
      blank_count = 0
    }
    $0 == "# NDE managed hosts start" {
      if (inside || seen_start) exit 2
      inside = 1
      seen_start = 1
      next
    }
    $0 == "# NDE managed hosts end" {
      if (!inside || seen_end) exit 2
      inside = 0
      seen_end = 1
      next
    }
    !inside {
      if ($0 ~ /^[[:space:]]*$/) {
        blank_count++
        next
      }
      flush_blanks()
      print
    }
    END {
      if (inside || seen_start != 1 || seen_end != 1) exit 2
    }
  ' "$hosts_file" > "$temp_file"; then
    rm -f "$temp_file"
    echo 'NDE hosts markers are incomplete or duplicated; hosts was left unchanged.' >&2
    return 1
  fi

  if [[ -w "$hosts_file" ]]; then
    cat "$temp_file" > "$hosts_file"
  else
    sudo tee "$hosts_file" < "$temp_file" >/dev/null
  fi
  rm -f "$temp_file"
  echo 'Removed the NDE hosts block from /etc/hosts.'
}

path=$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")
config="${path}/docker-compose.yml"
cert_script="${path}/scripts/cert.sh"
build_script="${path}/scripts/build-php.sh"

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
  v|-v|--view)
    fn_host_block
    exit
    ;;
  s|-s|--sync)
    fn_hosts_sync
    exit
    ;;
  c|-c|--clean)
    fn_hosts_clean
    exit
    ;;
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
    "${build_script}"
    fn_update_cert
    docker compose -f "${config}" up -d
    exit
    ;;
  refresh|-refresh|--refresh)
    docker compose -f "${config}" down
    "${build_script}"
    fn_update_cert
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
  "${build_script}"
  fn_update_cert
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
