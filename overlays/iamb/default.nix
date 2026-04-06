_final: prev: {
  iamb = prev.iamb.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/main.rs \
        --replace-fail '#![allow(clippy::bool_assert_comparison)]' $'#![allow(clippy::bool_assert_comparison)]\n#![recursion_limit = "512"]'
    '';
  });
}
