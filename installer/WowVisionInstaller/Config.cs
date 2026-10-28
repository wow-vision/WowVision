namespace WowVisionInstaller
{
    /// <summary>Which WowVision the installer installs: the stable release or the beta.</summary>
    public enum Channel { Stable, Beta }

    /// <summary>
    /// The channel chosen on the components page, kept across runs in
    /// %LOCALAPPDATA%\WowVisionUpdater\WowVisionChannel.txt ("channel=beta"), so
    /// "Update now" keeps following it without a wizard visit. One choice for
    /// every game version. Never throws: an unreadable store is the default.
    /// </summary>
    public static class ChannelPrefs
    {
        /// <summary>Test hook: when set, the store lives in this folder.</summary>
        internal static string DirOverride = null;

        private static string StorePath => System.IO.Path.Combine(
            DirOverride ?? Shortcut.PersistentDir, "WowVisionChannel.txt");

        public static Channel Load()
        {
            try
            {
                if (System.IO.File.Exists(StorePath))
                    foreach (var raw in System.IO.File.ReadAllLines(StorePath))
                    {
                        string line = raw.Trim();
                        if (!line.StartsWith("channel=", System.StringComparison.OrdinalIgnoreCase)) continue;
                        string v = line.Substring("channel=".Length).Trim();
                        if (string.Equals(v, "stable", System.StringComparison.OrdinalIgnoreCase)) return Channel.Stable;
                        if (string.Equals(v, "beta", System.StringComparison.OrdinalIgnoreCase)) return Channel.Beta;
                    }
            }
            catch (System.Exception ex) { Logger.Warning($"Channel choice unreadable, using the default: {ex.Message}"); }
            return Config.DefaultChannel;
        }

        public static void Save(Channel channel)
        {
            try
            {
                System.IO.Directory.CreateDirectory(System.IO.Path.GetDirectoryName(StorePath));
                System.IO.File.WriteAllText(StorePath,
                    "# WowVision installer: which WowVision to install, stable or beta.\n" +
                    "channel=" + (channel == Channel.Beta ? "beta" : "stable") + "\n");
            }
            catch (System.Exception ex) { Logger.Warning($"Could not save the channel choice: {ex.Message}"); }
        }
    }

    /// <summary>
    /// Build-time constants. Update here when the release topology changes.
    /// See README.md "Where things come from".
    ///
    /// WowVision ships as ONE zip on the newest GitHub release of the addon repo
    /// (packaged by the BigWigs packager from a V* tag). There are no companion
    /// downloads: everything the addon needs is inside that zip. The zip may hold
    /// more than one addon folder — upstream's .pkgmeta moves the TBC map data
    /// out into its own WowVision_MapData_TBC folder — and every top-level folder
    /// of the zip is installed side by side (<see cref="ReleasePackage"/>).
    /// </summary>
    public static class Config
    {
        public const string DisplayName = "WowVision";

        // ── where the addon AND the installer come from ─────────────────────
        // The maintainers' repository. Its releases are made by GitHub Actions:
        //   stable: a V* tag, e.g. tag "V0.9.0", asset "WowVision-V0.9.0.zip";
        //   beta:   one moving pre-release under the tag "beta", rebuilt on every
        //           push to main, asset "WowVision-beta.zip".
        // The packager writes a release.json beside each zip (which names it).
        // The installer ships as an asset on the same releases
        // (.github/workflows/installer.yml attaches InstallerExeName and
        // installer-version.txt to every stable release and to the beta).
        public const string AddonRepo = "wow-vision/WowVision";
        public const string InstallerRepo = AddonRepo;
        public const string InstallerExeName = "WowVisionInstaller.exe";

        public const string SiteUrl = "https://github.com/" + AddonRepo;

        // ── which WowVision: stable release or beta ─────────────────────────
        // One decision for every game version, made on the components page and
        // remembered (ChannelPrefs). Beta is preselected while the addon changes
        // this fast; switch DefaultChannel to Stable once the releases catch up.
        public const Channel DefaultChannel = Channel.Beta;

        /// <summary>The channel this run works with (set from ChannelPrefs at startup).</summary>
        public static Channel CurrentChannel { get; private set; } = DefaultChannel;

        /// <summary>The moving pre-release tag of the beta channel.</summary>
        public const string BetaTag = "beta";

        // STABLE: at startup the installer resolves the newest release tag from
        // the github.com/.../releases/latest redirect (the website URL, not the
        // rate-limited api.github.com), so an OLD installer exe still finds
        // releases published after it was built. FallbackTag is what it uses when
        // the redirect can't be resolved (offline, GitHub outage). A live tag is
        // only adopted when it is NEWER than the pin, so a fresh exe never
        // downgrades anyone. The "beta" pre-release never carries the Latest
        // badge, so the redirect always names a stable release.
        //
        // BETA: the tag is always "beta" and the TOC says "## Version: beta", so
        // neither can tell one beta from the next. What can: the download
        // redirect of the zip names the uploaded file by an id that changes
        // exactly when the packager uploads a new zip
        // (GitHubClient.ResolveBetaBuildAsync). That id is LatestBuild; the
        // manifest records the id of the zip each folder came from.
        public const string FallbackTag = "V0.9.0";

        /// <summary>The release tag the installer works with, e.g. "V0.9.0" or "beta".</summary>
        public static string LatestTag { get; private set; } = DefaultChannel == Channel.Beta ? BetaTag : FallbackTag;

        /// <summary>
        /// Beta only: the id of the zip now on the beta release, or null when it
        /// could not be read (offline). Null means "unknown", never "changed".
        /// </summary>
        public static string LatestBuild { get; private set; }

        /// <summary>Beta only: when that zip was uploaded, for the user's ears.</summary>
        public static System.DateTime? LatestBuildDate { get; private set; }

        /// <summary>
        /// What the user is told: "0.9.0" for a release, "beta of 2026-10-16" for
        /// the beta (see <see cref="SpokenVersion"/>).
        /// </summary>
        public static string LatestVersion => SpokenVersion(LatestTag, LatestBuildDate);

        /// <summary>A version as heard: no V on release numbers, the beta with its date when known.</summary>
        public static string SpokenVersion(string tagOrVersion, System.DateTime? betaDate)
        {
            if (string.IsNullOrEmpty(tagOrVersion)) return tagOrVersion;
            string v = tagOrVersion.Trim();
            if (string.Equals(v, BetaTag, System.StringComparison.OrdinalIgnoreCase))
                return betaDate.HasValue ? Loc.Format("version.betaDated", betaDate.Value.ToString("yyyy-MM-dd"))
                                         : Loc.Get("version.beta");
            return v.TrimStart('v', 'V');
        }

        /// <summary>
        /// The zip on that release. The packager's naming is "WowVision-&lt;tag&gt;.zip";
        /// the release's own release.json, when it can be read, overrides it
        /// (<see cref="GitHubClient.ResolveAndAdoptLatestRelease"/>).
        /// </summary>
        public static string AssetName { get; private set; } = ConventionalAssetName(LatestTag);

        public static string ConventionalAssetName(string tag) => "WowVision-" + tag + ".zip";

        /// <summary>Adopt a live-resolved release (tag plus, when known, its zip name and beta build).</summary>
        public static void OverrideLatest(string tag, string assetName = null,
                                          string build = null, System.DateTime? buildDate = null)
        {
            LatestTag = tag;
            AssetName = string.IsNullOrEmpty(assetName) ? ConventionalAssetName(tag) : assetName;
            LatestBuild = build;
            LatestBuildDate = buildDate;
        }

        /// <summary>
        /// Switch the channel for this run. Resets the release to the channel's
        /// starting point; GitHubClient.ResolveAndAdoptLatestRelease fills in the
        /// live values.
        /// </summary>
        public static void SetChannel(Channel channel)
        {
            CurrentChannel = channel;
            OverrideLatest(channel == Channel.Beta ? BetaTag : FallbackTag);
        }

        /// <summary>
        /// The addon folder that carries the version and decides "is there an
        /// update". The other folders of the zip follow it.
        /// </summary>
        public const string PrimaryFolder = "WowVision";

        /// <summary>Manifest filename written into the AddOns folder.</summary>
        public const string ManifestFileName = "WowVisionInstall.json";

        // ── the WoW Login Tool ──────────────────────────────────────────────
        // A standalone tool (originally by Yennister/Duugu, reworked with an
        // AutoHotkey v2 + OCR driver) that gives the login, server and character
        // screens an audio menu. It is NOT a WoW addon: it installs as its own
        // program folder next to the game, plus login-screen recognition textures
        // in the client's Interface folder and a readable-font override. Which
        // clients get it, and how, is WowLocator.Clients' LoginTool column.
        //
        // It ships from the Sku repository on a PERMANENT rolling tag: each new
        // build re-uploads WoW-Login-Tool.zip to the same 'login-tool' tag, so the
        // URL never changes. LoginToolVersion is the freshness signal instead:
        // keep it in step with the Sku installer's Config.LoginToolVersion, and
        // LoginToolInstaller upgrades every install whose marker predates it.
        public const string LoginToolRepo = "Sku75/Sku-WoW-Addon-TBC";
        public const string LoginToolTag = "login-tool";
        public const string LoginToolVersion = "4.1";
        public const string LoginToolAsset = "WoW-Login-Tool.zip";
        public const string LoginToolFolderName = "WoW Login Tool";

        // ── the game clients (see WowLocator.Clients for the full table) ────
        public const string EraFlavor = "wow_classic_era";
        public const string AnniversaryFlavor = "wow_anniversary";
        public const string MistsFlavor = "wow_classic";
        public const string RetailFlavor = "wow";
        /// <summary>
        /// The installer's ONE token for WoW Forever. The beta client
        /// (_classic_beta_\WowB.exe) writes it into .flavor.info / .build.info;
        /// the live client (_forever_\Wow.exe, since 2026-10) writes
        /// <see cref="ForeverLiveFlavor"/>, which <see cref="NormalizeProduct"/>
        /// maps onto it wherever a token is read from disk.
        /// </summary>
        public const string ForeverFlavor = "wow_classic_beta";

        /// <summary>The live WoW Forever client's token (build 1.60.1.70634).</summary>
        public const string ForeverLiveFlavor = "wowf";

        /// <summary>Flavor folder of the WoW Forever beta (ended 2026-10-21).</summary>
        public const string ForeverBetaFolder = "_classic_beta_";

        /// <summary>A product token as read from disk, as the installer uses it.</summary>
        public static string NormalizeProduct(string token) =>
            string.Equals(token, ForeverLiveFlavor, System.StringComparison.OrdinalIgnoreCase) ? ForeverFlavor : token;

        /// <summary>
        /// Every game process this installer cares about: the classic clients run
        /// WowClassic.exe, retail and the live WoW Forever Wow.exe, the Forever
        /// beta WowB.exe.
        /// </summary>
        public static readonly string[] GameProcessNames = { "WowClassic", "Wow", "WowB" };
    }
}
