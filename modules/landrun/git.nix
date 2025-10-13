{
  features.tty = true;
  cli.ro = [
    "$HOME/.gitconfig"
  ];
  cli.rw = [
    # Git needs to write to the repository
    "$PWD/.git"
  ];
}
