# >>> check if workspace is on path
fpath=/workspaces/${PROJECT_FOLDER}

case ":$PATH:" in
  *:$fpath:*) ;;
  *) export PATH=${fpath}${PATH:+:${PATH}};;
esac
# <<< 