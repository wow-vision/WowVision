using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace WowVisionInstaller
{
    /// <summary>Progress callback payload for the UI/screen reader.</summary>
    public class InstallProgress
    {
        public string Addon;       // which addon
        public string Phase;       // "download" | "extract" | "ready" | "install" | "skip" | "done"
        public int Percent;        // 0..100, or -1 if unknown
        public string Message;     // human/screen-reader line
    }

    /// <summary>What an installed WowVision means for the chosen channel (<see cref="AddonInstaller.Decide"/>).</summary>
    public enum AddonState
    {
        /// <summary>The current build of the chosen channel is installed.</summary>
        UpToDate,
        /// <summary>Install the current build: newer, or the other channel is installed.</summary>
        Update,
        /// <summary>A test build that is neither a release nor the beta; kept unless Reinstall.</summary>
        TestBuildKept,
        /// <summary>Beta installed, but the online beta could not be checked (offline).</summary>
        Unknown,
    }

    /// <summary>One addon folder of the release that gets installed into a client this run.</summary>
    public class PlanItem
    {
        public string FolderName;
        public bool FirstInstall;  // target folder doesn't exist yet
    }

    /// <summary>One extra (third-party) addon entry that needs installing/updating this run.</summary>
    public class ManagedPlanItem
    {
        public ManagedEntry Entry;
        public bool FirstInstall;  // some required folder doesn't exist yet
    }

    /// <summary>
    /// The decided work for one client: whether the release goes in, whether the
    /// game must be fully closed first, and the settings / TOC repairs.
    ///
    /// <see cref="Items"/> is filled in only once the release zip has been
    /// downloaded (<see cref="InstallRunner.PreparePackage"/>): which folders the
    /// zip holds is not known before. That ordering is deliberate — the long
    /// download runs while the game may still be open, and the user is asked to
    /// close it only for the short copy that follows.
    /// </summary>
    public class InstallPlan
    {
        /// <summary>The release must be installed into this client.</summary>
        public bool AddonNeedsWork;

        /// <summary>The main WowVision folder is not there yet.</summary>
        public bool FirstInstall;

        public List<PlanItem> Items = new List<PlanItem>();

        /// <summary>Extra addons (Questie, DBM, …) needing work in this client this run.</summary>
        public List<ManagedPlanItem> ManagedItems = new List<ManagedPlanItem>();

        public bool NeedsGameClosed;

        /// <summary>Required game-client CVars that are currently wrong and need writing.</summary>
        public bool SettingsNeedWriting;
        public List<string> SettingsIssues = new List<string>();

        /// <summary>
        /// Installed addon folders whose TOC "## Interface:" line no longer names
        /// the client build and needs rewriting so they keep loading.
        /// </summary>
        public bool TocInterfaceNeedsSync;
        /// <summary>The client's interface number from its .build.info, 0 if unknown.</summary>
        public int ClientInterface;
        public List<string> TocInterfaceIssues = new List<string>();

        /// <summary>True if there's anything to do at all (addon, settings, or TOC sync).</summary>
        public bool HasWork => AddonNeedsWork || ManagedItems.Count > 0 || SettingsNeedWriting || TocInterfaceNeedsSync;
    }

    /// <summary>
    /// Decides whether a client needs the release and copies the release's
    /// folders into its AddOns folder. The copy goes from an already-extracted
    /// <see cref="ReleasePackage"/>, so a failed or partial download never touches
    /// a working install.
    /// </summary>
    public class AddonInstaller
    {
        private readonly string _addonsFolder;
        private readonly string _product;
        private readonly InstallManifest _manifest;
        private readonly Action<InstallProgress> _report;

        /// <summary>One temp root for every download/extract artifact, so leftovers
        /// from a crashed run can be swept in one shot.</summary>
        public static string TempRoot => Path.Combine(Path.GetTempPath(), "WowVisionInstaller");

        public AddonInstaller(string addonsFolder, string product, InstallManifest manifest,
                              Action<InstallProgress> report)
        {
            _addonsFolder = addonsFolder;
            _product = product;
            _manifest = manifest;
            _report = report ?? (_ => { });
        }

        /// <summary>
        /// Best-effort wipe of the temp root (orphans from a prior run). Called
        /// once at the start of a run, never while a package is in use.
        /// </summary>
        public static void CleanupTempRoot()
        {
            try { if (Directory.Exists(TempRoot)) Directory.Delete(TempRoot, recursive: true); }
            catch (Exception ex) { Logger.Warning($"Could not clean temp root: {ex.Message}"); }
        }

        /// <summary>
        /// Decide whether the current release (<see cref="Config.LatestTag"/>, and
        /// for the beta <see cref="Config.LatestBuild"/>) must be installed into
        /// this client, reporting <paramref name="firstInstall"/>:
        ///   * main folder missing           -> Install (first install)
        ///   * main folder is a symlink      -> Skip, adopt (a developer's checkout)
        ///   * otherwise                     -> <see cref="Decide"/> on what is there
        ///   * up to date, but a folder recorded at this release has gone
        ///     missing                       -> Install (repair)
        /// May record an adopted tag into the manifest (caller persists it).
        /// </summary>
        public bool NeedsWork(string tag, out bool firstInstall)
        {
            string primary = Config.PrimaryFolder;
            string folder = Path.Combine(_addonsFolder, primary);
            firstInstall = !Directory.Exists(folder);
            if (firstInstall) return true;

            // Dev safety: never plan work for a symlinked/junctioned addon folder
            // (the WowVision dev setup junctions AddOns\WowVision to the git
            // checkout). Adopt its tag so it counts as current, and leave it alone.
            if (IsReparsePoint(folder))
            {
                _manifest.SetTag(primary, tag);
                Logger.Warning($"{primary}: folder is a symlink/junction — managed outside the installer, skipping.");
                return false;
            }

            string tocVersion = WowLocator.ReadTocVersion(_addonsFolder, primary, _product);
            var state = Decide(tocVersion, _manifest.GetTag(primary), _manifest.GetBuild(primary),
                               Config.CurrentChannel, tag, Config.LatestBuild);
            Logger.Info($"{primary}: TOC {tocVersion ?? "-"}, manifest {_manifest.GetTag(primary) ?? "-"} " +
                        $"{_manifest.GetBuild(primary) ?? ""}, {Config.CurrentChannel} {tag} {Config.LatestBuild ?? ""} -> {state}.");
            if (state == AddonState.Update) return true;
            if (state != AddonState.UpToDate) return false;

            // A pre-existing manual install of this very release: adopt its tag so
            // later runs are precise.
            if (_manifest.GetTag(primary) == null && IsReleaseVersion(tocVersion))
                _manifest.SetTag(primary, tag);

            // A folder the installer put there with this release and that is gone
            // now (deleted by hand, or by a cleanup tool) is a broken install. Only
            // WowVision's own folders count; the extra addons keep their own keys.
            foreach (var kv in _manifest.InstalledTags)
            {
                if (string.Equals(kv.Key, primary, StringComparison.OrdinalIgnoreCase)) continue;
                if (ManagedAddons.IsManagedKey(kv.Key)) continue;
                if (!SameRelease(kv.Value, tag)) continue;
                if (!Directory.Exists(Path.Combine(_addonsFolder, kv.Key)))
                {
                    Logger.Info($"{kv.Key}: recorded at {kv.Value} but missing; reinstalling the release.");
                    firstInstall = true;
                    return true;
                }
            }
            return false;
        }

        private static bool SameRelease(string a, string b) =>
            IsBeta(a) || IsBeta(b) ? IsBeta(a) && IsBeta(b) : CompareVersions(a, b) == 0;

        /// <summary>
        /// What an installed WowVision means for the chosen channel. One function,
        /// so the plan and the status line on screen can never disagree.
        ///
        ///   Stable channel: a release older than the newest -> Update; the beta ->
        ///     Update (switching to stable is the user's decision); otherwise current.
        ///   Beta channel: the beta whose recorded build is the one online ->
        ///     current; any other beta (an older upload, or one installed by hand
        ///     with no build on record) -> Update; a release -> Update (switch).
        ///     When the online build cannot be read (offline) an installed beta is
        ///     Unknown, which never triggers a download.
        ///   Either channel: a version that is neither a release number nor "beta"
        ///     (an unexpanded "@project-version@" from a copied git checkout, a
        ///     custom build) is a test build and left alone; Reinstall replaces it.
        ///
        /// The manifest records what the INSTALLER last wrote, so it can lag the
        /// folder (a release unzipped by hand since) but never lead it: of two
        /// release numbers, the newer is what is installed.
        /// </summary>
        public static AddonState Decide(string tocVersion, string manifestTag, string manifestBuild,
                                        Channel channel, string latestTag, string latestBuild)
        {
            if (IsTestBuild(tocVersion)) return AddonState.TestBuildKept;

            bool installedBeta = IsBeta(tocVersion) || (tocVersion == null && IsBeta(manifestTag));

            if (channel == Channel.Beta)
            {
                if (!installedBeta) return AddonState.Update;
                if (string.IsNullOrEmpty(latestBuild)) return AddonState.Unknown;
                return string.Equals(manifestBuild, latestBuild, StringComparison.OrdinalIgnoreCase)
                    ? AddonState.UpToDate : AddonState.Update;
            }

            if (installedBeta) return AddonState.Update;

            string have = IsBeta(manifestTag) ? null : manifestTag;
            if (IsReleaseVersion(tocVersion) && (have == null || CompareVersions(tocVersion, have) > 0))
                have = tocVersion;

            // Compare by version ORDER, not tag inequality, so we only ever move
            // forward: the effective "latest" can fall BACK to the build-time pin
            // when the live redirect can't be resolved, and an equality test would
            // then plan a DOWNGRADE for a user already on a newer release.
            return CompareVersions(have, latestTag) < 0 ? AddonState.Update : AddonState.UpToDate;
        }

        /// <summary>The upstream beta: the packager writes its tag, "beta", into the TOC.</summary>
        public static bool IsBeta(string version) =>
            string.Equals(version?.Trim(), Config.BetaTag, StringComparison.OrdinalIgnoreCase);

        /// <summary>
        /// A version that is neither a release number nor the beta: an unexpanded
        /// "@project-version@" (a raw git checkout copied by hand) or a custom
        /// build. Comparing it as a number would read as 0 and "update" it, so it
        /// is left alone unless the user asks for Reinstall.
        /// </summary>
        public static bool IsTestBuild(string version) =>
            !string.IsNullOrWhiteSpace(version) && !IsReleaseVersion(version) && !IsBeta(version);

        /// <summary>"V0.9.0", "0.9.0", "1.2" — digits and dots after an optional V.</summary>
        public static bool IsReleaseVersion(string version) =>
            !string.IsNullOrWhiteSpace(version) &&
            Regex.IsMatch(version.Trim(), @"^[vV]?\d+(\.\d+)*$");

        /// <summary>
        /// Compares dotted numeric versions ("V0.9.0" vs "0.10"). A leading v/V is
        /// ignored, missing components count as 0. Returns -1/0/1. A null/empty
        /// version is treated as oldest so we err toward offering the update.
        ///
        /// Each component is compared as an INTEGER: 0.10 > 0.9 > 0.8. That is
        /// the semantic-versioning rule upstream's V0.x.y tags follow.
        /// </summary>
        internal static int CompareVersions(string a, string b)
        {
            int[] pa = ParseParts(a), pb = ParseParts(b);
            int n = Math.Max(pa.Length, pb.Length);
            for (int i = 0; i < n; i++)
            {
                int x = i < pa.Length ? pa[i] : 0;
                int y = i < pb.Length ? pb[i] : 0;
                if (x != y) return x < y ? -1 : 1;
            }
            return 0;
        }

        private static int[] ParseParts(string v)
        {
            if (string.IsNullOrWhiteSpace(v)) return new[] { 0 };
            var nums = new List<int>();
            foreach (var part in v.Trim().TrimStart('v', 'V').Split('.', '-', '_'))
            {
                // A component we cannot read counts as 0 instead of vanishing.
                // Dropping it would SHIFT every later component one place left.
                int.TryParse(new string(part.TakeWhile(char.IsDigit).ToArray()), out int p);
                nums.Add(p);
            }
            if (nums.Count == 0) nums.Add(0);
            return nums.ToArray();
        }

        /// <summary>
        /// A plan item requires the game fully closed if it's a brand-new addon
        /// folder: a fresh folder isn't picked up by /reload — it needs a client
        /// restart. An update of an already-loaded addon can be done live.
        /// </summary>
        public static bool RequiresGameClosed(PlanItem item) => item.FirstInstall;

        /// <summary>
        /// Copies one folder of the package into the AddOns folder and records the
        /// release tag for it. Returns true if work was done, false if skipped (a
        /// symlinked folder).
        /// </summary>
        public bool InstallFolder(ReleasePackage package, string folderName)
        {
            string targetDir = Path.Combine(_addonsFolder, folderName);

            // Defense in depth: even if something asked us to install over a
            // symlinked/junctioned folder, refuse — we must not write through a
            // developer's symlink into their git checkout.
            if (IsReparsePoint(targetDir))
            {
                _report(new InstallProgress { Addon = folderName, Phase = "skip",
                    Percent = 100, Message = Loc.Format("ai.symlink", folderName) });
                Logger.Warning($"{folderName}: symlink/junction — left untouched (managed outside the installer).");
                return false;
            }

            string source = package.SourceOf(folderName);

            // Overwrite the addon files in place while the game runs: deleting the
            // folder could fail on a file the game holds open, and file-by-file
            // lets us skip the rare locked file (logged) while the rest update; a
            // /reload then picks them up. With the game closed the folder is
            // replaced wholesale so files removed in the new version don't linger.
            _report(new InstallProgress { Addon = folderName, Phase = "install",
                Percent = -1, Message = Loc.Format("ai.installing", folderName) });

            int locked;
            if (!WowLocator.IsGameRunning() && Directory.Exists(targetDir))
            {
                CleanReplace(source, targetDir);
                locked = 0;
                Logger.Info($"{folderName}: clean-replaced (game closed) — orphans removed.");
            }
            else
            {
                locked = OverwriteInPlace(source, targetDir);
            }

            if (locked > 0)
            {
                // Don't record the new tag if some files couldn't be written —
                // the install is incomplete, so the next run will retry it.
                _report(new InstallProgress { Addon = folderName, Phase = "done",
                    Percent = 100, Message = Loc.Format("ai.locked", folderName, locked) });
                Logger.Warning($"{folderName}: {locked} locked file(s); tag NOT recorded so it retries.");
            }
            else
            {
                _manifest.SetTag(folderName, package.Tag);
                _manifest.SetBuild(folderName, package.Build, package.BuildDate);
                _report(new InstallProgress { Addon = folderName, Phase = "done",
                    Percent = 100, Message = Loc.Format("ai.installed", folderName, Config.SpokenVersion(package.Tag, package.BuildDate)) });
                Logger.Info($"{folderName}: installed {package.Tag}.");
            }
            return true;
        }

        /// <summary>True if an addon folder is a symlink/junction (managed externally).</summary>
        public static bool IsSymlinked(string addonsFolder, string folderName) =>
            IsReparsePoint(Path.Combine(addonsFolder, folderName));

        /// <summary>True if the path is a symlink/junction (reparse point).</summary>
        private static bool IsReparsePoint(string path)
        {
            try
            {
                return Directory.Exists(path) &&
                       (File.GetAttributes(path) & FileAttributes.ReparsePoint) != 0;
            }
            catch { return false; }
        }

        private static void SafeDeleteDirectory(string dir)
        {
            try { if (Directory.Exists(dir)) Directory.Delete(dir, true); }
            catch (Exception ex) { Logger.Warning($"Could not delete {dir}: {ex.Message}"); }
        }

        /// <summary>
        /// Replaces the target folder wholesale with the freshly-extracted version
        /// so that files removed in the new version don't survive as orphans.
        /// Crash-safe: the old folder is renamed aside first and only deleted on
        /// success; on any failure the partial new folder is removed and the old
        /// one restored. Only call with the game closed (a running game can hold
        /// files open and break the rename).
        /// </summary>
        internal static void CleanReplace(string source, string target)
        {
            string backup = target + ".old-" + Guid.NewGuid().ToString("N");
            bool movedAside = false;
            try
            {
                Directory.Move(target, backup);   // fast: same volume
                movedAside = true;
                OverwriteInPlace(source, target);  // copy fresh into the now-absent path
                SafeDeleteDirectory(backup);       // success — drop the old copy
            }
            catch
            {
                if (movedAside)
                {
                    SafeDeleteDirectory(target);   // remove any partial new copy
                    try { Directory.Move(backup, target); } catch { /* last resort */ }
                }
                throw;
            }
        }

        /// <summary>
        /// Copies every file from <paramref name="src"/> into <paramref name="dst"/>,
        /// overwriting, creating folders as needed. A file that can't be written
        /// (locked by the running game) is skipped and counted rather than throwing,
        /// so one open file never aborts the whole addon. Returns the locked count.
        /// </summary>
        internal static int OverwriteInPlace(string src, string dst)
        {
            Directory.CreateDirectory(dst);

            foreach (var dir in Directory.GetDirectories(src, "*", SearchOption.AllDirectories))
                Directory.CreateDirectory(dst + dir.Substring(src.Length));

            int locked = 0;
            foreach (var file in Directory.GetFiles(src, "*", SearchOption.AllDirectories))
            {
                string target = dst + file.Substring(src.Length);
                try
                {
                    File.Copy(file, target, overwrite: true);
                }
                catch (IOException ex)            // sharing violation: file in use
                {
                    locked++;
                    Logger.Warning($"In use, skipped: {target} ({ex.Message})");
                }
                catch (UnauthorizedAccessException ex)
                {
                    locked++;
                    Logger.Warning($"Access denied, skipped: {target} ({ex.Message})");
                }
            }
            return locked;
        }
    }
}
