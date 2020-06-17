/**
 * This folder aims to help users setup _profiles_ which include a long
 * all the recommended development tools. Each item returned here is a
 * list of packages that can be installed in (one of) your profile(s).
 */
rec {

   /* ---------- Partial profiles; building-blocks ---------- */

   /**
    * Common CLI utilities shared by all other profiles
    */
   base = import ./base/default.nix;

   /**
    * bknix-specific management utilities
    */
   mgmt = import ./mgmt/default.nix;

   /* ---------- Full profiles ---------- */

   /**
    * The minimum system requirements.
    */
   min = import ./min/default.nix;

   /**
    * The maximum tested system requirements.
    */
   max = import ./max/default.nix;

   /**
    * An old minimum from a past release.
    */
   old = import ./old/default.nix;

   /**
    * A new maximum for a future release.
    */
   edge = import ./edge/default.nix;

   /**
    * A nice, in-between list of requirements
    */
   dfl = import ./dfl/default.nix;
}
