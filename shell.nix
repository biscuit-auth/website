{ pkgs ? import <nixpkgs> {}}: with pkgs;

mkShell {
  buildInputs = [ zola nodejs-16_x ];
}
