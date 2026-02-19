#!/usr/bin/env bash

# Shared config keys for runtime/init/upgrade.
RALPH_CONFIG_KEYS=(
  SPECIFICATION
  EXECUTION_PLAN
  LOG_DIR
  ERROR_LOG
  OUTPUT_LOG
  CONTAINER_NAME
  CONTAINER_WORKDIR
  CONTAINER_RUNTIME
  USE_CODEX
  CALLBACK
)

ralph_var_is_set() {
  local var_name="$1"
  [[ "${!var_name+x}" == "x" ]]
}

ralph_normalize_path() {
  local input="$1"
  local is_absolute=0
  local -a parts=()
  local -a stack=()
  local part=""
  local joined=""

  if [[ "$input" == /* ]]; then
    is_absolute=1
  fi

  IFS='/' read -r -a parts <<< "$input"
  for part in "${parts[@]}"; do
    case "$part" in
      ""|".")
        continue
        ;;
      "..")
        if [[ ${#stack[@]} -gt 0 ]]; then
          unset "stack[$(( ${#stack[@]} - 1 ))]"
        fi
        ;;
      *)
        stack+=("$part")
        ;;
    esac
  done

  if [[ ${#stack[@]} -gt 0 ]]; then
    local IFS='/'
    joined="${stack[*]}"
  fi

  if [[ $is_absolute -eq 1 ]]; then
    if [[ -n "$joined" ]]; then
      printf '/%s\n' "$joined"
    else
      printf '/\n'
    fi
  else
    if [[ -n "$joined" ]]; then
      printf '%s\n' "$joined"
    else
      printf '.\n'
    fi
  fi
}

ralph_resolve_project_root() {
  local path="${1:-$(pwd)}"

  if [[ "$path" == /* ]]; then
    ralph_normalize_path "$path"
  else
    ralph_normalize_path "$(pwd)/$path"
  fi
}

ralph_resolve_against_root() {
  local root="$1"
  local path="$2"

  if [[ "$path" == /* || "$path" == "~"* ]]; then
    ralph_normalize_path "$path"
  else
    ralph_normalize_path "$root/$path"
  fi
}

ralph_path_key_needs_project_resolution() {
  local key="$1"
  local value="$2"

  case "$key" in
    SPECIFICATION|EXECUTION_PLAN|LOG_DIR|ERROR_LOG|OUTPUT_LOG)
      ;;
    *)
      return 1
      ;;
  esac

  if [[ -z "$value" ]]; then
    return 1
  fi

  if [[ "$value" == /* || "$value" == "~"* ]]; then
    return 1
  fi

  return 0
}

ralph_capture_shell_env_snapshot() {
  local key=""

  for key in "${RALPH_CONFIG_KEYS[@]}"; do
    if ralph_var_is_set "$key"; then
      printf -v "RALPH_SHELL_HAS_${key}" '%s' "1"
      printf -v "RALPH_SHELL_VAL_${key}" '%s' "${!key}"
    else
      printf -v "RALPH_SHELL_HAS_${key}" '%s' "0"
      printf -v "RALPH_SHELL_VAL_${key}" '%s' ""
    fi
  done
}

ralph_clear_config_vars() {
  local key=""

  for key in "${RALPH_CONFIG_KEYS[@]}"; do
    printf -v "$key" '%s' ""
  done
}

ralph_apply_env_file() {
  local env_file="$1"
  local project_root="${2:-}"
  local key=""
  local value=""

  if [[ ! -f "$env_file" ]]; then
    return 0
  fi

  while IFS=$'\t' read -r key value; do
    if [[ -n "$project_root" ]] && ralph_path_key_needs_project_resolution "$key" "$value"; then
      value="$(ralph_resolve_against_root "$project_root" "$value")"
    fi
    printf -v "$key" '%s' "$value"
  done < <(
    (
      set +u
      for key in "${RALPH_CONFIG_KEYS[@]}"; do
        unset "$key"
      done
      # shellcheck disable=SC1090
      source "$env_file"
      for key in "${RALPH_CONFIG_KEYS[@]}"; do
        if [[ "${!key+x}" == "x" ]]; then
          printf '%s\t%s\n' "$key" "${!key}"
        fi
      done
    )
  )
}

ralph_apply_shell_env_snapshot() {
  local key=""
  local has_var_name=""
  local value_var_name=""

  for key in "${RALPH_CONFIG_KEYS[@]}"; do
    has_var_name="RALPH_SHELL_HAS_${key}"
    value_var_name="RALPH_SHELL_VAL_${key}"
    if [[ "${!has_var_name:-0}" == "1" ]]; then
      printf -v "$key" '%s' "${!value_var_name-}"
    fi
  done
}

ralph_apply_default_config_values() {
  if [[ -z "${SPECIFICATION:-}" ]]; then
    SPECIFICATION=".ralph/plans/SPECIFICATION.md"
  fi
  if [[ -z "${EXECUTION_PLAN:-}" ]]; then
    EXECUTION_PLAN=".ralph/plans/EXECUTION_PLAN.md"
  fi
  if [[ -z "${LOG_DIR:-}" ]]; then
    LOG_DIR=".ralph/logs"
  fi
  if [[ -z "${CONTAINER_NAME:-}" ]]; then
    CONTAINER_NAME=""
  fi
  if [[ -z "${CONTAINER_WORKDIR:-}" ]]; then
    CONTAINER_WORKDIR=""
  fi
  if [[ -z "${CONTAINER_RUNTIME:-}" ]]; then
    CONTAINER_RUNTIME="docker"
  fi
  if [[ -z "${USE_CODEX:-}" ]]; then
    USE_CODEX="0"
  fi
  if [[ -z "${CALLBACK:-}" ]]; then
    CALLBACK=""
  fi
  if [[ -z "${ERROR_LOG:-}" ]]; then
    ERROR_LOG="${LOG_DIR}/ERROR_LOG.md"
  fi
  if [[ -z "${OUTPUT_LOG:-}" ]]; then
    OUTPUT_LOG="${LOG_DIR}/OUTPUT_LOG.md"
  fi
}

ralph_load_config() {
  local project_root="${1:-}"
  local user_env_file=""

  if [[ -n "$project_root" ]]; then
    project_root="$(ralph_resolve_project_root "$project_root")"
  fi

  ralph_capture_shell_env_snapshot
  ralph_clear_config_vars

  if [[ -n "${HOME:-}" ]]; then
    user_env_file="${HOME}/.ralph/.env"
    ralph_apply_env_file "$user_env_file"
  fi

  if [[ -n "$project_root" ]]; then
    ralph_apply_env_file "$project_root/.ralph/.env" "$project_root"
  fi

  ralph_apply_shell_env_snapshot
  ralph_apply_default_config_values
}
