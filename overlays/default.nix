[
  (import ./cinnamon.nemo)
  # The gdal overlay pins an old upstream release; keep it opt-in until verified.
  # iamb is parked (see cells/programs/matrix.nix); its recursion_limit
  # build fix stays in ./iamb for when it comes back.
  # (import ./iamb)
]
