# ./lib/home/desktop/terminaltexteffects.nix
{ pkgs
, inputs
, ...
}:
let
  tte-latest = pkgs.python3Packages.buildPythonApplication {
    pname = "terminaltexteffects";
    version = "0.15.0"; # Keep this in sync with the actual version
    format = "pyproject";

    src = inputs.terminaltexteffects;

    nativeBuildInputs = with pkgs.python3Packages; [
      hatchling
    ];

    propagatedBuildInputs = with pkgs.python3Packages; [
      pydantic
    ];

    doCheck = false;
  };
in
{
  home.packages = [
    tte-latest
  ];
}

