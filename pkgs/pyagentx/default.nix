{
  python3Packages,
  fetchFromGitHub,
  ...
}:
python3Packages.buildPythonPackage {
  pname = "pyagentx";
  version = "8fcc2f05";

  src = fetchFromGitHub {
    owner = "ondrejmular";
    repo = "pyagentx";
    rev = "8fcc2f056b54b92c67a264671198fd197d5a1799";
    hash = "sha256-uXFRtQskF2HhHi3KhJwajPvt8c8unrBBOqxGimV74Rc=";
  };
}
