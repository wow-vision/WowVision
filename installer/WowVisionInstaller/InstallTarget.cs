using System;
using System.Collections.Generic;
using System.IO;

namespace WowVisionInstaller
{
    /// <summary>
    /// One WoW client the installer can install into, together with what we found
    /// there. The wizard builds one of these per SUPPORTED client — not per
    /// detected one — so a client that exists but wasn't auto-found is still
    /// offered on the selection page, with <see cref="AddOnsPath"/> null until the
    /// user browses to it. Selection is a checkbox per client and one run covers
    /// all of them.
    /// </summary>
    public class InstallTarget
    {
        /// <summary>True if the main WowVision folder exists under this AddOns folder.</summary>
        internal static bool AddonInstalled(string addonsFolder) =>
            !string.IsNullOrEmpty(addonsFolder) &&
            Directory.Exists(Path.Combine(addonsFolder, Config.PrimaryFolder));

        /// <summary>Flavor token, e.g. wow_anniversary / wow_classic_beta.</summary>
        public string Product;

        /// <summary>Friendly label for the checkbox, e.g. "Anniversary (TBC)".</summary>
        public string DisplayName;

        /// <summary>Short tag for progress rows, e.g. "TBC" / "Forever".</summary>
        public string ShortName => WowLocator.ShortLabel(Product);

        /// <summary>Resolved Interface\AddOns folder, or null if not located yet.</summary>
        public string AddOnsPath;

        /// <summary>True when <see cref="AddOnsPath"/> came from auto-detection.</summary>
        public bool AutoDetected;

        /// <summary>Installed WowVision version in this client ("V0.9.0", "beta"), or null.</summary>
        public string InstalledVersion;

        /// <summary>The beta build recorded for it (manifest), or null.</summary>
        public string InstalledBuild;
        public DateTime? InstalledBuildDate;

        /// <summary>What the installed WowVision means for the chosen channel.</summary>
        public AddonState State =>
            AddonInstaller.Decide(InstalledVersion, InstalledVersion, InstalledBuild,
                                  Config.CurrentChannel, Config.LatestTag, Config.LatestBuild);

        /// <summary>True when WowVision is already installed in this client.</summary>
        public bool HasAddon => !string.IsNullOrEmpty(AddOnsPath) && AddonInstalled(AddOnsPath);

        /// <summary>True when this client is present on the machine at all.</summary>
        public bool ClientFound => !string.IsNullOrEmpty(AddOnsPath);

        /// <summary>True when the installed build is a test build (see <see cref="AddonInstaller.IsTestBuild"/>).</summary>
        public bool HasTestBuild => HasAddon && AddonInstaller.IsTestBuild(InstalledVersion);

        /// <summary>
        /// True when an update is available for the WowVision install in this
        /// client — a newer build of the chosen channel, or a switch to it. A
        /// client without WowVision is a fresh install, not an update; a test
        /// build is never "updated" unasked. Same rule as the plan
        /// (<see cref="AddonInstaller.Decide"/>).
        /// </summary>
        public bool UpdateAvailable => HasAddon && !IsDevSymlink && State == AddonState.Update;

        /// <summary>True when WowVision here is a symlink/junction to a folder we don't manage.</summary>
        public bool IsDevSymlink =>
            !string.IsNullOrEmpty(AddOnsPath) &&
            AddonInstaller.IsSymlinked(AddOnsPath, Config.PrimaryFolder);

        /// <summary>
        /// Re-reads the installed WowVision version for the current
        /// <see cref="AddOnsPath"/>. Call after the path changes (Browse).
        ///
        /// The install manifest is NOT taken as gospel. It records what the
        /// INSTALLER last wrote, so it can only ever lag what is on disk — never
        /// lead it. If the TOC reports a newer version, something other than this
        /// installer updated the folder and the TOC is the truth. (The Sku
        /// installer once reported a version months old because nothing ever
        /// reconciled the two.)
        /// </summary>
        public void RefreshInstalledVersion()
        {
            InstalledVersion = null;
            InstalledBuild = null;
            InstalledBuildDate = null;
            if (!HasAddon) return;

            string tocVersion = WowLocator.ReadTocVersion(AddOnsPath, Config.PrimaryFolder, Product);
            var recorded = InstallManifest.Load(AddOnsPath);
            InstalledBuild = recorded.GetBuild(Config.PrimaryFolder);
            InstalledBuildDate = recorded.GetBuildDate(Config.PrimaryFolder);

            // The beta names itself in the TOC; its build is the manifest's.
            if (AddonInstaller.IsBeta(tocVersion))
            {
                InstalledVersion = tocVersion;
                return;
            }

            // A symlinked folder is managed outside the installer entirely, and a
            // test build names itself: read the TOC and stop.
            if (IsDevSymlink || AddonInstaller.IsTestBuild(tocVersion))
            {
                InstalledVersion = tocVersion;
                return;
            }

            string manifestVersion = recorded.GetTag(Config.PrimaryFolder);
            if (AddonInstaller.IsBeta(manifestVersion)) manifestVersion = null;   // TOC says otherwise

            if (manifestVersion == null) { InstalledVersion = tocVersion; return; }
            if (tocVersion == null) { InstalledVersion = manifestVersion; return; }

            InstalledVersion = AddonInstaller.CompareVersions(tocVersion, manifestVersion) > 0
                ? tocVersion : manifestVersion;
        }

        /// <summary>A version as the user hears it: "0.9.0", never "V0.9.0"; the beta with its date.</summary>
        public static string Spoken(string version) => Config.SpokenVersion(version, null);

        /// <summary>This client's installed version as heard, beta date included when known.</summary>
        public string SpokenInstalled => Config.SpokenVersion(InstalledVersion, InstalledBuildDate);

        /// <summary>
        /// A one-line status sentence for this client, e.g.
        /// "Update available — WowVision 0.8.0 is installed, 0.9.0 is available."
        /// Used both as the visible description and (folded into AccessibleName) as
        /// what the screen reader says when the checkbox takes focus — so focusing
        /// a client tells you its whole story instead of just its name.
        /// </summary>
        public string StatusLine()
        {
            if (!ClientFound)
                return Loc.Get("target.notFound");

            if (!HasAddon)
                return Loc.Format("target.freshInstall", Config.LatestVersion);

            string installed = string.IsNullOrEmpty(InstalledVersion) || InstalledVersion.Contains("@")
                ? Loc.Get("target.versionUnknown")
                : SpokenInstalled;

            // Say so plainly rather than offering an update that will be silently
            // skipped: a symlinked folder is somebody's working copy and the
            // installer deliberately never writes to it.
            if (IsDevSymlink)
                return Loc.Format("target.devSymlink", installed);

            if (HasTestBuild)
                return Loc.Format("target.testBuild", installed, Config.LatestVersion);

            if (State == AddonState.Unknown)
                return Loc.Format("target.betaUnchecked", installed);

            return UpdateAvailable
                ? Loc.Format("target.updateAvailable", installed, Config.LatestVersion)
                : Loc.Format("target.upToDate", installed);
        }

        /// <summary>
        /// Builds one target per supported client, auto-detection filled in where
        /// possible, in <see cref="WowLocator.Clients"/> order.
        ///
        /// A folder the user picked by hand on an earlier run (PathMemory) beats
        /// detection, because it is the one piece of evidence here that somebody
        /// actually confirmed. Detection is a guess over a handful of likely
        /// drives; a remembered folder is a decision.
        /// </summary>
        public static List<InstallTarget> BuildAll()
        {
            var detected = WowLocator.DetectFlavors();
            var targets = new List<InstallTarget>();

            foreach (string product in WowLocator.SupportedProducts)
            {
                var found = detected.Find(f => f.Product == product);
                var t = new InstallTarget
                {
                    Product = product,
                    DisplayName = WowLocator.ProductLabel(product),
                    AddOnsPath = found?.AddOnsPath,
                    AutoDetected = found != null,
                };

                // ResolveFor returns null for a memory that has gone stale (folder
                // deleted, or now belonging to a different client), so a moved or
                // uninstalled game falls back to detection instead of sending the
                // install somewhere dead.
                string remembered = PathMemory.ResolveFor(product);
                if (remembered != null &&
                    !string.Equals(remembered, t.AddOnsPath, StringComparison.OrdinalIgnoreCase))
                {
                    Logger.Info($"Using remembered folder for {product}: {remembered} " +
                                $"(detection said {t.AddOnsPath ?? "(nothing)"})");
                    t.AddOnsPath = remembered;
                    t.AutoDetected = false;
                }

                t.RefreshInstalledVersion();
                targets.Add(t);
            }

            return targets;
        }
    }
}
