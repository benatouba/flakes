[
  (import ./cinnamon.nemo)
  (import ./iamb)
  (final: prev: {
    sonic-pi =
      (prev.sonic-pi.override {
        # Ruby 3.4 moved mutex_m out of the default gems set, and vendored
        # minitest now requires it explicitly during sonic-pi's test phase.
        ruby = prev.ruby // {
          withPackages = f: prev.ruby.withPackages (ps: prev.lib.unique ((f ps) ++ [ ps.mutex_m ]));
        };
      }).overrideAttrs
        (old: {
          postPatch = (old.postPatch or "") + ''
            # Boost 1.89+ dropped the dummy compiled boost_system library.
            # Remove references so CMake keeps using the header-only components.
            sed -i 's/COMPONENTS filesystem system thread/COMPONENTS filesystem thread/g' app/api/CMakeLists.txt
          '';

          meta = old.meta // {
            broken = false;
          };
        });
  })
]
