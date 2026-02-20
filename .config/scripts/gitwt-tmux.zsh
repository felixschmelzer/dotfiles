#!/usr/bin/env zsh

function _gitwt_fzf() {
  local fzf_bin

  fzf_bin="$(command -v fzf 2>/dev/null)"
  if [[ -z "$fzf_bin" ]]; then
    if [[ -x "/opt/homebrew/bin/fzf" ]]; then
      fzf_bin="/opt/homebrew/bin/fzf"
    elif [[ -x "/usr/local/bin/fzf" ]]; then
      fzf_bin="/usr/local/bin/fzf"
    fi
  fi

  if [[ -z "$fzf_bin" ]]; then
    print -u2 "gitwt: fzf not found (install fzf or set branch arg)"
    return 1
  fi

  "$fzf_bin" "$@"
}

function _gitwt_git() {
  local git_bin

  git_bin="$(command -v git 2>/dev/null)"
  if [[ -z "$git_bin" ]]; then
    if [[ -x "/opt/homebrew/bin/git" ]]; then
      git_bin="/opt/homebrew/bin/git"
    elif [[ -x "/usr/local/bin/git" ]]; then
      git_bin="/usr/local/bin/git"
    elif [[ -x "/usr/bin/git" ]]; then
      git_bin="/usr/bin/git"
    fi
  fi

  if [[ -z "$git_bin" ]]; then
    print -u2 "gitwt: git not found"
    return 1
  fi

  "$git_bin" "$@"
}

function _gitwt_tmux_open() {
  local worktree_path="$1"
  local window_name="$2"
  local apps_csv="${GITWT_TMUX_APPS:-terminal}"
  local -a apps
  local window_id pane_id idx

  apps=(${(s:,:)apps_csv})
  if (( ${#apps[@]} == 0 )); then
    apps=(terminal)
  fi

  window_id="$(tmux new-window -P -F '#{window_id}' -c "$worktree_path" -n "$window_name")" || return 1
  tmux select-window -t "$window_id" >/dev/null

  pane_id="$(tmux display-message -p "#{pane_id}")"
  if [[ "${apps[1]}" != "terminal" ]]; then
    tmux send-keys -t "$pane_id" "${apps[1]}" C-m
  fi

  idx=2
  while (( idx <= ${#apps[@]} )); do
    if (( idx % 2 == 0 )); then
      tmux split-window -t "$window_id" -c "$worktree_path" -h >/dev/null
    else
      tmux split-window -t "$window_id" -c "$worktree_path" -v >/dev/null
    fi

    pane_id="$(tmux display-message -p "#{pane_id}")"
    if [[ "${apps[idx]}" != "terminal" ]]; then
      tmux send-keys -t "$pane_id" "${apps[idx]}" C-m
    fi

    (( idx++ ))
  done

  tmux select-layout -t "$window_id" tiled >/dev/null
}

function _gitwt_select_branch() {
  local output query selection
  local -a lines

  output="$(_gitwt_git branch -a --format='%(refname:short)' \
    | sed 's|^remotes/||' \
    | sort -u \
    | _gitwt_fzf --prompt='branch> ' --height=40% --border \
      --header='type to create branch' --print-query)"

  lines=(${(f)output})
  query="${lines[1]}"
  selection="${lines[2]}"

  if [[ -n "$selection" ]]; then
    print -r -- "$selection"
  else
    print -r -- "$query"
  fi
}

function gitwt_ls() {
  local worktree_root="$HOME/.worktrees"
  local -a entries
  local -a selection
  local key choice path label
  local wt repo_name branch

  if [[ ! -d "$worktree_root" ]]; then
    print -u2 "gitwt: worktree base not found: $worktree_root"
    return 1
  fi

  for wt in "$worktree_root"/*/*(/N); do
    if [[ -f "$wt/.git" || -d "$wt/.git" ]]; then
      repo_name="${wt:h:t}"
      branch="$(_gitwt_git -C "$wt" symbolic-ref --quiet --short HEAD 2>/dev/null)"
      if [[ -z "$branch" ]]; then
        branch="detached"
      fi
      entries+=("$wt | ${repo_name}/${branch}")
    fi
  done

  if (( ${#entries[@]} == 0 )); then
    print -u2 "gitwt: no worktrees found"
    return 1
  fi

  selection=("${(@f)$(print -rl -- "${entries[@]}" \
    | _gitwt_fzf --prompt='worktree> ' --height=40% --border \
      --header='enter: cd  ctrl-d: delete  ctrl-t: tmux window' --expect=enter,ctrl-d,ctrl-t)}")

  key="${selection[1]}"
  choice="${selection[2]}"

  if [[ -z "$choice" ]]; then
    return 0
  fi

  path="${choice%% | *}"
  label="${choice##* | }"

  case "$key" in
    ctrl-d)
      if [[ "$path" != "$HOME/.worktrees/"* ]]; then
        print -u2 "gitwt: refusing to remove outside ~/.worktrees"
        return 1
      fi
      _gitwt_git worktree remove "$path" || return 1
      ;;
    ctrl-t)
      if [[ -z "$TMUX" ]]; then
        print -u2 "gitwt: not running inside tmux"
        return 1
      fi
      _gitwt_tmux_open "$path" "$label" || return 1
      ;;
    *)
      builtin cd -- "$path"
      ;;
  esac
}

function gitwt() {
  if [[ "$1" == "-ls" ]]; then
    shift
    gitwt_ls "$@"
    return $?
  fi

  local branch="$1"
  local repo_root repo_name worktree_base worktree_path

  repo_root="$(_gitwt_git rev-parse --show-toplevel 2>/dev/null)" || {
    print -u2 "gitwt: not inside a git repository"
    return 1
  }

  repo_name="${repo_root:t}"
  worktree_base="$HOME/.worktrees/${repo_name}"

  if [[ -z "$branch" ]]; then
    branch="$(_gitwt_select_branch)"
  fi

  if [[ -z "$branch" ]]; then
    print -u2 "gitwt: no branch selected"
    return 1
  fi

  if _gitwt_git show-ref --verify --quiet "refs/heads/$branch"; then
    :
  elif _gitwt_git show-ref --verify --quiet "refs/remotes/$branch"; then
    _gitwt_git branch --track "$branch" "refs/remotes/$branch" || return 1
  else
    _gitwt_git branch "$branch" || return 1
  fi

  worktree_path="$worktree_base/$branch"
  mkdir -p "$worktree_base" || return 1

  if [[ -d "$worktree_path" ]]; then
    print -u2 "gitwt: worktree already exists: $worktree_path"
    return 1
  fi

  _gitwt_git worktree add "$worktree_path" "$branch" || return 1

  if [[ -n "$TMUX" ]]; then
    _gitwt_tmux_open "$worktree_path" "$branch" || return 1
  else
    builtin cd -- "$worktree_path"
  fi
}
