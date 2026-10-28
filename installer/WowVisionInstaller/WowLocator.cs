using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;

namespace WowVisionInstaller
{
    /// <summary>One installed WoW client flavor and its AddOns folder.</summary>
    public class WowFlavor
    {
        public string Product;      // e.g. wow_anniversary, wow_classic_beta
        public string AddOnsPath;   // <flavor>\Interface\AddOns
        public string DisplayName;  // friendly label
        public bool Beta;           // the WoW Forever beta folder (a live client wins over it)
    }

    /// <summary>
    /// One game client WowVision supports, and everything that differs between
    /// them. One table instead of a switch per question, so adding a client is
    /// one entry here.
    /// </summary>
    public class ClientInfo
    {
        /// <summary>Product token in .flavor.info / .build.info, e.g. "wow_classic_beta".</summary>
        public string Product;

        /// <summary>Conventional flavor folder under the WoW base, e.g. "_classic_beta_".</summary>
        public string Folder;

        /// <summary>Friendly name, e.g. "WoW Forever".</summary>
        public string Label;

        /// <summary>One short word prefixed onto progress rows, e.g. "Forever".</summary>
        public string Short;

        /// <summary>
        /// TOC suffixes this client loads, in the client's own order of preference
        /// (WowVision_TBC.toc on Anniversary, WowVision_Camelot.toc on WoW
        /// Forever, …). A folder without any of them falls back to its plain TOC.
        /// </summary>
        public string[] TocSuffixes;

        /// <summary>
        /// The interface numbers of this client's game family, inclusive. A TOC
        /// entry in this range was written for this client; when it lags the
        /// client build, TocSync replaces it (1.15.8 to 1.15.9 = 11508 to 11509).
        /// Entries outside it belong to other clients and are left alone.
        /// </summary>
        public int InterfaceMin, InterfaceMax;

        public bool OwnsInterface(int iface) => iface >= InterfaceMin && iface <= InterfaceMax;

        /// <summary>Whether and how the WoW Login Tool serves this client.</summary>
        public LoginToolMode LoginTool;
    }

    /// <summary>
    /// What the WoW Login Tool does for a client. Taken from the tool's own game
    /// type table (data\gametypes.ini, GametypeFromVersion in v2\includes\detect.ahk):
    /// Classic (1.x), BurningCrusade (2.x) and Forever have screen data; Mists
    /// (5.x) has none and the tool announces it as unsupported; Retail is left
    /// out by decision.
    /// </summary>
    public enum LoginToolMode
    {
        /// <summary>Not installed for this client.</summary>
        None,
        /// <summary>Tool plus its recognition textures and font override in the client folder.</summary>
        WithTextures,
        /// <summary>Tool only: the client narrates its own login screens (WoW Forever).</summary>
        ToolOnly,
    }

    /// <summary>
    /// Finds installed WoW client flavors and their AddOns folders, and reports
    /// whether the game is running.
    ///
    /// Modern Battle.net writes no usable registry key, so detection is
    /// file-driven: under each WoW base dir, each "_*_" folder is a flavor; its
    /// .flavor.info names the product (wow_anniversary, wow_classic_beta, …) and a
    /// WowClassic.exe / Wow.exe / WowB.exe confirms it's a real client. The same
    /// WowVision zip serves every client: it carries one TOC per client
    /// (WowVision_Vanilla, _TBC, _Mists, _Standard, _Camelot) and each client loads
    /// its own. What keeps it loading after a client patch is TocSync writing that
    /// client's EXACT interface build into the TOC the client reads (see
    /// <see cref="ClientInterface"/>): the classic clients gate on the exact build
    /// number, and "Load out of date AddOns" (checkAddonVersion 0) does NOT cover
    /// a mismatched interface. (Learned in the Sku installer on Classic Era 11509,
    /// where addons tagged 11508 silently failed to load.)
    /// </summary>
    public static class WowLocator
    {
        /// <summary>
        /// The clients WowVision supports, in the order the wizard offers them.
        ///
        /// This is deliberately the SUPPORTED list, not the detected list: the
        /// version-selection page shows every entry so a user whose client sits
        /// somewhere we don't probe can still tick it and browse to it. Detection
        /// then fills in the folder for the ones we did find.
        /// </summary>
        public static readonly ClientInfo[] Clients =
        {
            new ClientInfo { Product = Config.ForeverFlavor, Folder = "_forever_", Label = "WoW Forever",
                             Short = "Forever", TocSuffixes = new[] { "Camelot" }, LoginTool = LoginToolMode.ToolOnly,
                             InterfaceMin = 16000, InterfaceMax = 19999 },
            new ClientInfo { Product = Config.AnniversaryFlavor, Folder = "_anniversary_", Label = "Anniversary (TBC)",
                             Short = "TBC", TocSuffixes = new[] { "TBC", "BCC", "Classic" }, LoginTool = LoginToolMode.WithTextures,
                             InterfaceMin = 20000, InterfaceMax = 29999 },
            new ClientInfo { Product = Config.EraFlavor, Folder = "_classic_era_", Label = "Classic Era (Vanilla)",
                             Short = "Era", TocSuffixes = new[] { "Vanilla", "Classic" }, LoginTool = LoginToolMode.WithTextures,
                             InterfaceMin = 10000, InterfaceMax = 15999 },
            new ClientInfo { Product = Config.MistsFlavor, Folder = "_classic_", Label = "Mists of Pandaria Classic",
                             Short = "Mists", TocSuffixes = new[] { "Mists", "Classic" },
                             InterfaceMin = 50000, InterfaceMax = 59999 },
            new ClientInfo { Product = Config.RetailFlavor, Folder = "_retail_", Label = "Retail",
                             Short = "Retail", TocSuffixes = new[] { "Mainline", "Standard" },
                             InterfaceMin = 100000, InterfaceMax = 999999 },
        };

        /// <summary>The supported product tokens, in wizard order.</summary>
        public static string[] SupportedProducts => Clients.Select(c => c.Product).ToArray();

        /// <summary>The table entry for a product, or null for one we don't support.</summary>
        public static ClientInfo Client(string product) =>
            Clients.FirstOrDefault(c => string.Equals(c.Product, product, StringComparison.OrdinalIgnoreCase));

        /// <summary>True for a client WowVision installs into.</summary>
        public static bool IsSupportedProduct(string product) => Client(product) != null;

        /// <summary>The game exe names (without extension) a flavor folder may hold.</summary>
        private static bool HasClientExe(string flavorDir) =>
            Config.GameProcessNames.Any(n => File.Exists(Path.Combine(flavorDir, n + ".exe")));

        /// <summary>
        /// Very short tag for a client, used to prefix progress rows so a
        /// multi-client run can be told apart ("TBC:", "Forever:"). One whole
        /// word each: an abbreviation means nothing when it is read aloud.
        /// </summary>
        public static string ShortLabel(string product) => Client(product)?.Short ?? product;

        /// <summary>Friendly name for a flavor token, with no folder suffix.</summary>
        public static string ProductLabel(string product) => Client(product)?.Label ?? product;

        /// <summary>Candidate WoW base directories to probe (before asking the user).</summary>
        private static string[] CandidateBaseDirs()
        {
            var dirs = new List<string>();

            // FIRST: the base dirs implied by folders the user already installed
            // into (PathMemory). A game on a drive we would never guess is found
            // straight away on the second run, and — because the probe is by BASE
            // dir — pointing us at one client there also finds the others.
            dirs.AddRange(PathMemory.RememberedBaseDirs());

            foreach (var pf in new[]
            {
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFilesX86),
                Environment.GetFolderPath(Environment.SpecialFolder.ProgramFiles),
            })
            {
                if (!string.IsNullOrEmpty(pf))
                    dirs.Add(Path.Combine(pf, "World of Warcraft"));
            }

            // Common non-default drives. Cheap to probe; harmless if absent.
            foreach (var drive in new[] { "C", "D", "E" })
            {
                dirs.Add($@"{drive}:\World of Warcraft");
                dirs.Add($@"{drive}:\Games\World of Warcraft");
            }

            return dirs.Distinct(StringComparer.OrdinalIgnoreCase).ToArray();
        }

        /// <summary>
        /// Detects every installed, supported WoW client with a real client exe,
        /// in <see cref="Clients"/> order. AddOns folders that don't exist yet are
        /// still offered (created on install).
        /// </summary>
        public static List<WowFlavor> DetectFlavors()
        {
            var found = new List<WowFlavor>();
            var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            foreach (var baseDir in CandidateBaseDirs())
            {
                if (!Directory.Exists(baseDir)) continue;

                string[] flavorDirs;
                try { flavorDirs = Directory.GetDirectories(baseDir, "_*_"); }
                catch { continue; }

                foreach (var flavorDir in flavorDirs)
                {
                    if (!HasClientExe(flavorDir)) continue;

                    string product = ReadFlavorProduct(flavorDir) ?? ProductForFolderName(flavorDir);
                    if (!IsSupportedProduct(product)) continue;   // PTRs, betas we don't know, …

                    string addons = Path.Combine(flavorDir, "Interface", "AddOns");
                    if (!seen.Add(addons)) continue;

                    found.Add(new WowFlavor
                    {
                        Product = product,
                        AddOnsPath = addons,
                        DisplayName = $"{ProductLabel(product)}  —  {Path.GetFileName(flavorDir)}",
                        Beta = Path.GetFileName(flavorDir).Equals(Config.ForeverBetaFolder, StringComparison.OrdinalIgnoreCase),
                    });
                }
            }

            // A leftover Forever BETA folder goes behind the live client: the
            // first flavor of a product is the one installed into, and
            // "_classic_beta_" sorts before "_forever_".
            var order = SupportedProducts.ToList();
            return found.OrderBy(f => order.IndexOf(f.Product)).ThenBy(f => f.Beta ? 1 : 0).ToList();
        }

        /// <summary>
        /// Which client an Interface\AddOns folder belongs to, e.g.
        /// wow_classic_beta, or null if it can't be told. An AddOns path is
        /// &lt;base&gt;\&lt;flavor&gt;\Interface\AddOns, so the flavor folder is two
        /// levels up and its .flavor.info names the product.
        ///
        /// Used when the user browses to a folder by hand: it lets the wizard file
        /// their choice under the right client instead of guessing.
        /// </summary>
        public static string ProductForAddOnsFolder(string addonsFolder)
        {
            try
            {
                if (string.IsNullOrEmpty(addonsFolder)) return null;
                var iface = Directory.GetParent(addonsFolder.TrimEnd('\\'));
                var flavorDir = iface?.Parent;
                if (flavorDir == null) return null;
                return ReadFlavorProduct(flavorDir.FullName) ?? ProductForFolderName(flavorDir.FullName);
            }
            catch { return null; }
        }

        private static string ReadFlavorProduct(string flavorDir)
        {
            try
            {
                string info = Path.Combine(flavorDir, ".flavor.info");
                if (!File.Exists(info)) return null;
                // line 1 = header, line 2 = the product token (e.g. "wow_anniversary")
                var lines = File.ReadAllLines(info);
                return lines.Length >= 2 ? Config.NormalizeProduct(lines[1].Trim()) : null;
            }
            catch { return null; }
        }

        /// <summary>The product whose conventional folder name this is, or null.</summary>
        private static string ProductForFolderName(string flavorDir)
        {
            string name = Path.GetFileName(flavorDir.TrimEnd('\\'));
            return Clients.FirstOrDefault(c => string.Equals(c.Folder, name, StringComparison.OrdinalIgnoreCase))?.Product;
        }

        private static string AddOnsInFlavor(string flavorDir)
        {
            string addons = Path.Combine(flavorDir, "Interface", "AddOns");
            try { Directory.CreateDirectory(addons); } catch { /* may need elevation */ }
            return addons;
        }

        /// <summary>
        /// True if the folder is a supported client: it holds a client exe and
        /// names a supported product (in .flavor.info, or by its conventional
        /// folder name when .flavor.info is missing).
        /// </summary>
        private static bool IsSupportedFlavor(string flavorDir)
        {
            if (string.IsNullOrEmpty(flavorDir) || !Directory.Exists(flavorDir)) return false;
            if (!HasClientExe(flavorDir)) return false;
            return IsSupportedProduct(ReadFlavorProduct(flavorDir) ?? ProductForFolderName(flavorDir));
        }

        /// <summary>
        /// Validates a user-picked folder. Accepts the AddOns folder itself, a
        /// client folder (_anniversary_, _classic_beta_, …) or the WoW base
        /// folder. Returns the resolved AddOns path or null.
        ///
        /// A base folder holds several clients; it resolves to the first one in
        /// <see cref="Clients"/> order that is there. The pages that ask per client
        /// (FolderConfirmForm) name the client they want, and the opening screen
        /// then shows every client it can now see under that base.
        /// </summary>
        public static string ResolveUserPickedFolder(string picked) => ResolveUserPickedFolder(picked, null);

        /// <summary>
        /// As above, but a base folder resolves to <paramref name="preferredProduct"/>
        /// when that client is in it.
        /// </summary>
        public static string ResolveUserPickedFolder(string picked, string preferredProduct)
        {
            string resolved = ResolvePicked(picked, preferredProduct);

            // A folder that names its client, and names one WowVision does not
            // support (a PTR, a beta), is refused rather than filed under some
            // other client whose TOC and settings rules would then be applied to
            // it. A folder that cannot tell stays the user's call.
            string product = resolved == null ? null : ProductForAddOnsFolder(resolved);
            if (product != null && !IsSupportedProduct(product))
            {
                Logger.Warning($"Picked folder {resolved} belongs to unsupported client {product}.");
                return null;
            }
            return resolved;
        }

        private static string ResolvePicked(string picked, string preferredProduct)
        {
            if (string.IsNullOrEmpty(picked) || !Directory.Exists(picked))
                return null;

            // Picked the AddOns folder directly.
            if (picked.TrimEnd('\\').EndsWith("AddOns", StringComparison.OrdinalIgnoreCase))
                return picked;

            // Picked a client folder.
            if (IsSupportedFlavor(picked))
                return AddOnsInFlavor(picked);

            // Picked a base folder: the wanted client first, then any supported one.
            string[] flavorDirs;
            try { flavorDirs = Directory.GetDirectories(picked, "_*_"); }
            catch { flavorDirs = new string[0]; }
            var supported = flavorDirs.Where(IsSupportedFlavor).ToList();
            if (supported.Count > 0)
            {
                string want = supported.FirstOrDefault(d =>
                    string.Equals(ReadFlavorProduct(d) ?? ProductForFolderName(d), preferredProduct,
                                  StringComparison.OrdinalIgnoreCase));
                if (want == null)
                {
                    var order = SupportedProducts.ToList();
                    want = supported.OrderBy(d => order.IndexOf(ReadFlavorProduct(d) ?? ProductForFolderName(d))).First();
                }
                return AddOnsInFlavor(want);
            }

            // Last resort: Interface\AddOns directly under whatever was picked.
            string guess = Path.Combine(picked, "Interface", "AddOns");
            if (Directory.Exists(guess)) return guess;

            return null;
        }

        // --- Game process detection ---
        //
        // We never close or launch the game ourselves: the user launches WoW from
        // Battle.net (the only reliable way) and closes it manually when an update
        // needs it. We only DETECT whether it's running, to gate first installs and
        // settings writes, and to decide the end-of-run message. The classic
        // clients share one exe name, so this can't tell which client is running;
        // worst case it asks once too often to close the game. Harmless.

        public static bool IsGameRunning() =>
            Config.GameProcessNames.Any(n => Process.GetProcessesByName(n).Length > 0);

        // --- TOC files ---

        /// <summary>
        /// The TOC this client loads for an addon folder: the first of its suffix
        /// TOCs that exists (WowVision_TBC.toc on Anniversary, either "_" or "-"
        /// before the suffix), else the plain &lt;folder&gt;.toc. Null if the
        /// folder has neither. <paramref name="isSuffixToc"/> says which it was:
        /// a suffix TOC is written for this client by definition, a plain TOC may
        /// be meant for others (see <see cref="TocSync"/>).
        /// </summary>
        public static string TocFor(string addonsFolder, string folderName, string product, out bool isSuffixToc)
        {
            isSuffixToc = false;
            string dir = Path.Combine(addonsFolder, folderName);
            if (!Directory.Exists(dir)) return null;

            var client = Client(product);
            if (client != null)
            {
                foreach (string suffix in client.TocSuffixes)
                    foreach (string sep in new[] { "_", "-" })
                    {
                        string candidate = Path.Combine(dir, folderName + sep + suffix + ".toc");
                        if (File.Exists(candidate)) { isSuffixToc = true; return candidate; }
                    }
            }

            string plain = Path.Combine(dir, folderName + ".toc");
            return File.Exists(plain) ? plain : null;
        }

        /// <summary>
        /// Reads the "## Version:" line of the TOC this client loads, e.g.
        /// "V0.9.0". When that TOC is missing (an old build without this client's
        /// TOC), any TOC of the folder answers, since they all carry the same
        /// version. Null if there is none. A UTF-8 BOM is handled by ReadAllLines.
        /// </summary>
        public static string ReadTocVersion(string addonsFolder, string folderName, string product)
        {
            try
            {
                string toc = TocFor(addonsFolder, folderName, product, out _);
                if (toc == null)
                {
                    string dir = Path.Combine(addonsFolder, folderName);
                    if (!Directory.Exists(dir)) return null;
                    toc = Directory.GetFiles(dir, "*.toc").OrderBy(f => f, StringComparer.OrdinalIgnoreCase).FirstOrDefault();
                    if (toc == null) return null;
                }

                foreach (var raw in File.ReadAllLines(toc))
                {
                    string line = raw.Trim();
                    if (!line.StartsWith("##", StringComparison.Ordinal)) continue;
                    int colon = line.IndexOf(':');
                    if (colon <= 0) continue;
                    string key = line.Substring(2, colon - 2).Trim();
                    if (string.Equals(key, "Version", StringComparison.OrdinalIgnoreCase))
                        return line.Substring(colon + 1).Trim();
                }
            }
            catch (Exception ex)
            {
                Logger.Warning($"Could not read {folderName} TOC version: {ex.Message}");
            }
            return null;
        }

        // --- Client interface version (for TOC "## Interface:" sync) ---
        //
        // WoW records each installed product's build version in ".build.info" at the
        // WoW base dir (a "|"-delimited table with a header row). The TOC interface
        // number is that build's first three dotted parts folded as
        // major*10000 + minor*100 + patch  (2.5.6 -> 20506, 12.0.7 -> 120007).

        /// <summary>
        /// The interface number of the client <paramref name="addonsFolder"/>
        /// belongs to, read from the .build.info of its WoW base, or 0 if it can't
        /// be read. If that base has none (a custom or throwaway path), the
        /// machine's known bases are scanned for the same product.
        /// </summary>
        public static int ClientInterface(string addonsFolder, string product)
            => ClientInterfaceCore(addonsFolder, product);

        /// <summary>
        /// True when an addon folder under <paramref name="parentDir"/> (an
        /// AddOns folder, or an extracted zip) is written for this client: it has
        /// a TOC with this client's suffix, or a plain TOC that lists an interface
        /// number of this client's family. Used to install only what a client can
        /// load: the TBC map data ("20506, 16001") goes to Anniversary and WoW
        /// Forever only, and an extra addon without a Mists TOC is not put into
        /// Mists.
        /// </summary>
        public static bool FolderServesClient(string parentDir, string folderName, string product)
        {
            var client = Client(product);
            if (client == null) return false;
            string toc = TocFor(parentDir, folderName, product, out bool isSuffixToc);
            if (toc == null) return false;
            if (isSuffixToc) return true;
            try
            {
                foreach (var raw in File.ReadAllLines(toc))
                {
                    string line = raw.Trim();
                    if (!line.StartsWith("##")) continue;
                    int colon = line.IndexOf(':');
                    if (colon < 0 || !string.Equals(line.Substring(2, colon - 2).Trim(), "Interface",
                                                    StringComparison.OrdinalIgnoreCase)) continue;
                    foreach (string part in line.Substring(colon + 1).Split(','))
                        if (int.TryParse(part.Trim(), out int n) && client.OwnsInterface(n)) return true;
                    return false;
                }
            }
            catch (Exception ex) { Logger.Warning($"Could not read {toc}: {ex.Message}"); }
            return false;
        }

        private static int ClientInterfaceCore(string addonsFolder, string product)
        {
            if (string.IsNullOrEmpty(product)) product = ProductForAddOnsFolder(addonsFolder);
            if (string.IsNullOrEmpty(product)) return 0;

            int found = ReadInterfaceFromBuildInfo(BaseDirOf(addonsFolder), product);
            if (found > 0) return found;

            foreach (var bd in CandidateBaseDirs())
            {
                found = ReadInterfaceFromBuildInfo(bd, product);
                if (found > 0) return found;
            }
            return 0;
        }

        /// <summary>WoW base dir that owns an AddOns tree (…\&lt;base&gt;\_flavor_\Interface\AddOns).</summary>
        private static string BaseDirOf(string addonsFolder)
        {
            try
            {
                var interfaceDir = Directory.GetParent(addonsFolder.TrimEnd('\\')); // Interface
                var flavor = interfaceDir?.Parent;                                 // _flavor_
                var baseDir = flavor?.Parent;                                      // WoW base
                return baseDir?.FullName;
            }
            catch { return null; }
        }

        /// <summary>The interface number of one product in &lt;baseDir&gt;\.build.info, or 0.</summary>
        private static int ReadInterfaceFromBuildInfo(string baseDir, string product)
        {
            if (string.IsNullOrEmpty(baseDir)) return 0;
            string buildInfo = Path.Combine(baseDir, ".build.info");
            if (!File.Exists(buildInfo)) return 0;

            try
            {
                var lines = File.ReadAllLines(buildInfo);
                if (lines.Length < 2) return 0;

                // Header names carry a "!TYPE:len" suffix — strip it to find columns.
                var headers = lines[0].Split('|');
                int verCol = -1, prodCol = -1;
                for (int i = 0; i < headers.Length; i++)
                {
                    string name = headers[i].Split('!')[0].Trim();
                    if (name.Equals("Version", StringComparison.OrdinalIgnoreCase)) verCol = i;
                    else if (name.Equals("Product", StringComparison.OrdinalIgnoreCase)) prodCol = i;
                }
                if (verCol < 0 || prodCol < 0) return 0;

                for (int r = 1; r < lines.Length; r++)
                {
                    if (string.IsNullOrWhiteSpace(lines[r])) continue;
                    var cols = lines[r].Split('|');
                    if (verCol >= cols.Length || prodCol >= cols.Length) continue;
                    if (!string.Equals(Config.NormalizeProduct(cols[prodCol].Trim()), product, StringComparison.OrdinalIgnoreCase)) continue;

                    int iface = InterfaceFromBuildVersion(cols[verCol].Trim());
                    if (iface > 0) return iface;
                }
            }
            catch (Exception ex)
            {
                Logger.Warning($"Could not read .build.info in {baseDir}: {ex.Message}");
            }
            return 0;
        }

        /// <summary>"2.5.6.68502" -> 20506 (major*10000 + minor*100 + patch). 0 if unparseable.</summary>
        internal static int InterfaceFromBuildVersion(string build)
        {
            if (string.IsNullOrWhiteSpace(build)) return 0;
            var parts = build.Split('.');
            if (parts.Length < 3) return 0;
            if (int.TryParse(parts[0], out int maj) &&
                int.TryParse(parts[1], out int min) &&
                int.TryParse(parts[2], out int pat))
                return maj * 10000 + min * 100 + pat;
            return 0;
        }
    }
}
