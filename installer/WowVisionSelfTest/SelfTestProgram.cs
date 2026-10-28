using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;

namespace WowVisionInstaller
{
    /// <summary>
    /// Headless checks for the installer engine. Every command prints PASS/FAIL
    /// lines and sets the exit code, so it is readable by ear and usable from a
    /// script. Nothing here touches the real game folders, the real remembered
    /// folders, the voice registry or the desktop: the client tests build a
    /// throwaway World of Warcraft folder under %TEMP%.
    ///
    /// Usage: WowVisionSelfTest.exe &lt;command&gt;   (no command lists them)
    /// </summary>
    internal static class SelfTestProgram
    {
        private static int _fails;

        private static void Main(string[] args)
        {
            try { Run(args); }
            catch (Exception ex)
            {
                Console.WriteLine("FATAL: " + ex);
                Environment.ExitCode = 1;
            }
        }

        private static void Run(string[] args)
        {
            Console.OutputEncoding = new UTF8Encoding(false);
            Loc.Init();
            string cmd = args.Length > 0 ? args[0].ToLowerInvariant() : "";
            string arg1 = args.Length > 1 ? args[1] : null;

            switch (cmd)
            {
                case "flavors":         RunFlavors(); return;
                case "clienttest":      RunClientTest(); break;
                case "toctest":         RunTocTest(); break;
                case "versiontest":     RunVersionTest(); break;
                case "pathmemory":      RunPathMemoryTest(); break;
                case "loc":             RunLocTest(); break;
                case "logtest":         RunLogTest(); break;
                case "resolve":         RunResolve(); break;
                case "fullinstall":     RunFullInstall(); break;
                case "availability":    RunAvailabilityTest(); break;
                case "texturesweep":    RunTextureSweepTest(); break;
                case "managedinstall":  RunManagedInstallTest(arg1 ?? Config.MistsFlavor); break;
                case "logintool":       RunLoginToolTest(arg1 ?? Config.AnniversaryFlavor); break;
                case "selfupdate":      RunSelfUpdateTest(arg1 ?? "0.1"); break;
                case "selfupdateproof": RunSelfUpdateProof(); break;
                case "versionfile":     RunVersionFileTest(arg1); break;
                case "swaptest":        RunSwapTest(arg1 == "child"); return;
                case "offline":
                    // Everything that needs no network, in one go.
                    RunClientTest(); RunTocTest(); RunVersionTest(); RunPathMemoryTest();
                    RunLocTest(); RunLogTest(); RunAvailabilityTest(); RunTextureSweepTest();
                    break;
                default:
                    Console.WriteLine("WowVisionSelfTest commands:");
                    Console.WriteLine("  offline          every network-free test below in one run");
                    Console.WriteLine("  clienttest       five clients in a throwaway WoW folder: detection, TOCs, settings, status lines");
                    Console.WriteLine("  toctest          interface math and the TOC rewrite rule, BOM round-trip");
                    Console.WriteLine("  versiontest      version order, test builds, what needs an update");
                    Console.WriteLine("  pathmemory       remembered folders (throwaway store)");
                    Console.WriteLine("  loc              the three text tables have the same keys and placeholders");
                    Console.WriteLine("  logtest          the log bundle from a throwaway WoW folder");
                    Console.WriteLine("  availability     which client gets the map data, the login tool and each extra addon");
                    Console.WriteLine("  texturesweep     the login tool's stale-texture cleanup (throwaway folders)");
                    Console.WriteLine("  managedinstall [product]  REAL downloads of every extra addon for one client (default wow_classic)");
                    Console.WriteLine("  logintool [product]       REAL login tool download into a throwaway client (default wow_anniversary)");
                    Console.WriteLine("  resolve          the newest WowVision release online (no download)");
                    Console.WriteLine("  fullinstall      REAL download, installed into a throwaway WoW folder, twice");
                    Console.WriteLine("  selfupdate [v]   the published installer: version file, download, hash (poses as v, default 0.1)");
                    Console.WriteLine("  selfupdateproof  the hash check accepts the right exe and refuses wrong ones");
                    Console.WriteLine("  versionfile [p]  parse dist\\installer-version.txt as the installer would");
                    Console.WriteLine("  swaptest         a running exe can be renamed aside and replaced");
                    Console.WriteLine("  flavors          list the WoW clients on this machine (read only)");
                    return;
            }

            Console.WriteLine();
            Console.WriteLine(_fails == 0 ? "RESULT: ALL PASS" : $"RESULT: {_fails} FAILURE(S)");
            if (_fails > 0) Environment.ExitCode = 1;
        }

        private static void Check(string label, bool ok)
        {
            Console.WriteLine($"    [{(ok ? "PASS" : "FAIL")}] {label}");
            if (!ok) _fails++;
        }

        // ── a throwaway World of Warcraft folder ─────────────────────────────

        /// <summary>
        /// A fake WoW base under %TEMP% with all five supported clients (exe,
        /// .flavor.info, WTF account, AddOns) plus an unsupported PTR, and a
        /// .build.info laid out like the real one. PathMemory is pointed at a
        /// throwaway store holding one of its clients, which is how detection gets
        /// to see this base at all. Dispose removes everything.
        /// </summary>
        private sealed class FakeWow : IDisposable
        {
            public readonly string Root, Base, Store;
            public readonly Dictionary<string, string> AddOns = new Dictionary<string, string>();
            public readonly Dictionary<string, string> FlavorDir = new Dictionary<string, string>();

            // the live Forever client writes "wowf" (Config.ForeverLiveFlavor) into
            // .flavor.info and .build.info; the installer reads it as ForeverFlavor
            public static readonly (string product, string folder, string exe, string build)[] Layout =
            {
                (Config.ForeverFlavor,     "_forever_",      "Wow.exe",        "1.60.1.70634"),
                (Config.AnniversaryFlavor, "_anniversary_",  "WowClassic.exe", "2.5.6.70006"),
                (Config.EraFlavor,         "_classic_era_",  "WowClassic.exe", "1.15.9.70003"),
                (Config.MistsFlavor,       "_classic_",      "WowClassic.exe", "5.5.4.70449"),
                (Config.RetailFlavor,      "_retail_",       "Wow.exe",        "12.0.7.70500"),
                ("wow_classic_ptr",        "_classic_ptr_",  "WowClassicT.exe","5.5.5.70500"),
            };

            public FakeWow(string name)
            {
                Root = Path.Combine(Path.GetTempPath(), name);
                if (Directory.Exists(Root)) Directory.Delete(Root, true);
                Base = Path.Combine(Root, "Games", "World of Warcraft");
                Store = Path.Combine(Root, "store");
                Directory.CreateDirectory(Store);

                var buildInfo = new StringBuilder(
                    "Branch!STRING:0|Active!DEC:1|Build Key!HEX:16|Version!STRING:0|KeyRing!HEX:16|Product!STRING:0\r\n");
                foreach (var c in Layout)
                {
                    string dir = Path.Combine(Base, c.folder);
                    Directory.CreateDirectory(Path.Combine(dir, "Interface", "AddOns"));
                    Directory.CreateDirectory(Path.Combine(dir, "WTF", "Account", "TESTACCOUNT", "Realm", "Char", "SavedVariables"));
                    Directory.CreateDirectory(Path.Combine(dir, "WTF", "Account", "TESTACCOUNT", "SavedVariables"));
                    string token = c.product == Config.ForeverFlavor ? Config.ForeverLiveFlavor : c.product;
                    File.WriteAllText(Path.Combine(dir, ".flavor.info"), "Product Flavor!STRING:0\r\n" + token + "\r\n");
                    File.WriteAllText(Path.Combine(dir, c.exe), "x");
                    AddOns[c.product] = Path.Combine(dir, "Interface", "AddOns");
                    FlavorDir[c.product] = dir;
                    buildInfo.Append($"eu|1|aa|{c.build}||{token}\r\n");
                }
                File.WriteAllText(Path.Combine(Base, ".build.info"), buildInfo.ToString());

                PathMemory.DirOverride = Store;
                PathMemory.Remember(Config.ForeverFlavor, AddOns[Config.ForeverFlavor]);
            }

            /// <summary>A WowVision folder with the five TOCs exactly as the V0.9.0 zip ships them.</summary>
            public void PutWowVision(string product, string version)
            {
                string dir = Path.Combine(AddOns[product], Config.PrimaryFolder);
                Directory.CreateDirectory(dir);
                var tocs = new Dictionary<string, string>
                {
                    ["Vanilla"] = "11508", ["TBC"] = "20505,20506", ["Mists"] = "50503, 50504",
                    ["Standard"] = "120005, 120007", ["Camelot"] = "16001",
                };
                foreach (var kv in tocs)
                {
                    byte[] bom = { 0xEF, 0xBB, 0xBF };
                    byte[] body = Encoding.UTF8.GetBytes(
                        $"## Title: WowVision\n## Version: {version}\n## Interface: {kv.Value}\n\nlibs.xml\n");
                    using (var fs = new FileStream(Path.Combine(dir, $"WowVision_{kv.Key}.toc"), FileMode.Create))
                    {
                        fs.Write(bom, 0, bom.Length);
                        fs.Write(body, 0, body.Length);
                    }
                }
            }

            public void Dispose()
            {
                PathMemory.DirOverride = null;
                try { Directory.Delete(Root, true); } catch { }
            }
        }

        // ── commands ─────────────────────────────────────────────────────────

        private static void RunFlavors()
        {
            Console.WriteLine("=== WoW clients on this machine ===");
            foreach (var f in WowLocator.DetectFlavors())
            {
                int iface = WowLocator.ClientInterface(f.AddOnsPath, f.Product);
                Console.WriteLine($"    {f.DisplayName}");
                Console.WriteLine($"        AddOns: {f.AddOnsPath}");
                Console.WriteLine($"        interface: {iface}, TOC it reads: " +
                    (Path.GetFileName(WowLocator.TocFor(f.AddOnsPath, Config.PrimaryFolder, f.Product, out _)) ?? "(no WowVision)"));
            }
        }

        private static void RunClientTest()
        {
            Console.WriteLine("=== clienttest: five clients in a throwaway WoW folder ===");
            using (var wow = new FakeWow("WowVisionClientTest"))
            {
                var flavors = WowLocator.DetectFlavors().FindAll(f => f.AddOnsPath.StartsWith(wow.Base, StringComparison.OrdinalIgnoreCase));
                foreach (var f in flavors) Console.WriteLine($"    found {f.DisplayName}");
                Check("all five supported clients detected", flavors.Count == 5);
                Check("the PTR is skipped", !flavors.Exists(f => f.Product == "wow_classic_ptr"));
                Check("detection follows the wizard order",
                      flavors.Select(f => f.Product).SequenceEqual(WowLocator.SupportedProducts));
                Check("labels", WowLocator.ProductLabel(Config.ForeverFlavor) == "WoW Forever" &&
                                WowLocator.ShortLabel(Config.MistsFlavor) == "Mists");

                Console.WriteLine("=== client interface from .build.info ===");
                var expected = new Dictionary<string, int>
                {
                    [Config.ForeverFlavor] = 16001, [Config.AnniversaryFlavor] = 20506, [Config.EraFlavor] = 11509,
                    [Config.MistsFlavor] = 50504, [Config.RetailFlavor] = 120007,
                };
                foreach (var kv in expected)
                    Check($"{WowLocator.ShortLabel(kv.Key)} -> {kv.Value}",
                          WowLocator.ClientInterface(wow.AddOns[kv.Key], kv.Key) == kv.Value);

                Console.WriteLine("=== which TOC each client reads ===");
                var wantToc = new Dictionary<string, string>
                {
                    [Config.ForeverFlavor] = "WowVision_Camelot.toc", [Config.AnniversaryFlavor] = "WowVision_TBC.toc",
                    [Config.EraFlavor] = "WowVision_Vanilla.toc", [Config.MistsFlavor] = "WowVision_Mists.toc",
                    [Config.RetailFlavor] = "WowVision_Standard.toc",
                };
                foreach (var kv in wantToc)
                {
                    wow.PutWowVision(kv.Key, "V0.9.0");
                    string toc = WowLocator.TocFor(wow.AddOns[kv.Key], Config.PrimaryFolder, kv.Key, out bool suffix);
                    Check($"{WowLocator.ShortLabel(kv.Key)} reads {kv.Value}", Path.GetFileName(toc) == kv.Value && suffix);
                    Check($"{WowLocator.ShortLabel(kv.Key)} version V0.9.0",
                          WowLocator.ReadTocVersion(wow.AddOns[kv.Key], Config.PrimaryFolder, kv.Key) == "V0.9.0");
                }

                Console.WriteLine("=== TOC drift as shipped in V0.9.0 ===");
                foreach (var kv in expected)
                {
                    string want = TocSync.Desired(wow.AddOns[kv.Key], Config.PrimaryFolder, kv.Key, kv.Value, out string cur);
                    Console.WriteLine($"    {WowLocator.ShortLabel(kv.Key),-8} {cur,-16} -> {want ?? "(in step)"}");
                }
                Check("only Classic Era drifts (11508 shipped, client 11509)",
                      TocSync.Desired(wow.AddOns[Config.EraFlavor], Config.PrimaryFolder, Config.EraFlavor, 11509, out _) == "11509" &&
                      expected.Where(kv => kv.Key != Config.EraFlavor)
                              .All(kv => TocSync.Desired(wow.AddOns[kv.Key], Config.PrimaryFolder, kv.Key, kv.Value, out _) == null));

                string era = wow.AddOns[Config.EraFlavor];
                string camelotBefore = File.ReadAllText(Path.Combine(era, "WowVision", "WowVision_Camelot.toc"));
                Check("sync rewrites the Era TOC",
                      TocSync.SyncInterface(era, Config.PrimaryFolder, Config.EraFlavor, 11509, m => Console.WriteLine("    " + m)));
                byte[] after = File.ReadAllBytes(Path.Combine(era, "WowVision", "WowVision_Vanilla.toc"));
                Check("BOM kept", after.Length > 3 && after[0] == 0xEF && after[1] == 0xBB && after[2] == 0xBF);
                Check("Era TOC now 11509", TocSync.ReadInterface(era, Config.PrimaryFolder, Config.EraFlavor) == "11509");
                Check("the other clients' TOCs in that folder untouched",
                      File.ReadAllText(Path.Combine(era, "WowVision", "WowVision_Camelot.toc")) == camelotBefore);
                Check("second sync is a no-op",
                      !TocSync.SyncInterface(era, Config.PrimaryFolder, Config.EraFlavor, 11509, null));

                Console.WriteLine("=== picking folders by hand ===");
                Check("base folder + Mists wanted -> Mists AddOns",
                      WowLocator.ResolveUserPickedFolder(wow.Base, Config.MistsFlavor) == wow.AddOns[Config.MistsFlavor]);
                Check("base folder, nothing wanted -> first client in order (Forever)",
                      WowLocator.ResolveUserPickedFolder(wow.Base) == wow.AddOns[Config.ForeverFlavor]);
                Check("client folder -> its AddOns",
                      WowLocator.ResolveUserPickedFolder(wow.FlavorDir[Config.RetailFlavor]) == wow.AddOns[Config.RetailFlavor]);
                Check("AddOns folder accepted as is",
                      WowLocator.ResolveUserPickedFolder(wow.AddOns[Config.EraFlavor]) == wow.AddOns[Config.EraFlavor]);
                Check("the PTR folder is not accepted as a client",
                      WowLocator.ResolveUserPickedFolder(wow.FlavorDir["wow_classic_ptr"]) == null);
                foreach (var kv in expected)
                    Check($"{WowLocator.ShortLabel(kv.Key)} AddOns folder names its client",
                          WowLocator.ProductForAddOnsFolder(wow.AddOns[kv.Key]) == kv.Key);

                Console.WriteLine("=== game settings ===");
                string fwd = wow.AddOns[Config.ForeverFlavor];
                Check("both blockers reported on a fresh WTF", GameSettings.CheckNeeded(fwd).Count == GameSettings.Required.Length);
                GameSettings.Apply(fwd, m => Console.WriteLine("    " + m));
                Check("written into that client's own WTF",
                      File.ReadAllText(Path.Combine(wow.FlavorDir[Config.ForeverFlavor], "WTF", "Config.wtf")).Contains("SET checkAddonVersion \"0\"") &&
                      File.ReadAllText(Path.Combine(wow.FlavorDir[Config.ForeverFlavor], "WTF", "Account", "TESTACCOUNT", "config-cache.wtf"))
                          .Contains("SET AllowDangerousScripts \"1\""));
                Check("nothing left to fix afterwards", GameSettings.CheckNeeded(fwd).Count == 0);
                Check("other clients untouched", !File.Exists(Path.Combine(wow.FlavorDir[Config.MistsFlavor], "WTF", "Config.wtf")));

                Console.WriteLine("=== status lines ===");
                Config.SetChannel(Channel.Stable);
                Config.OverrideLatest("V0.9.0");
                wow.PutWowVision(Config.AnniversaryFlavor, "V0.8.0");
                wow.PutWowVision(Config.MistsFlavor, "@project-version@");
                Directory.Delete(Path.Combine(wow.AddOns[Config.RetailFlavor], Config.PrimaryFolder), true);
                var targets = InstallTarget.BuildAll();
                foreach (var t in targets) Console.WriteLine($"    {t.DisplayName}: {t.StatusLine()}");
                InstallTarget T(string p) => targets.Find(t => t.Product == p);
                Check("Anniversary 0.8.0 -> update available", T(Config.AnniversaryFlavor).UpdateAvailable);
                Check("Forever 0.9.0 -> up to date", T(Config.ForeverFlavor).HasAddon && !T(Config.ForeverFlavor).UpdateAvailable);
                Check("Mists copied git checkout -> test build, no update offered",
                      T(Config.MistsFlavor).HasTestBuild && !T(Config.MistsFlavor).UpdateAvailable);
                Check("Retail without WowVision -> fresh install", T(Config.RetailFlavor).ClientFound && !T(Config.RetailFlavor).HasAddon);

                Console.WriteLine("=== developer junction ===");
                string devCheckout = Path.Combine(wow.Root, "checkout", "WowVision");
                Directory.CreateDirectory(devCheckout);
                File.WriteAllText(Path.Combine(devCheckout, "WowVision_Vanilla.toc"), "## Version: @project-version@\n## Interface: 11508\n");
                string eraWv = Path.Combine(era, Config.PrimaryFolder);
                Directory.Delete(eraWv, true);
                if (MakeJunction(eraWv, devCheckout))
                {
                    var eraTarget = InstallTarget.BuildAll().Find(t => t.Product == Config.EraFlavor);
                    Console.WriteLine($"    Era: {eraTarget.StatusLine()}");
                    Check("junction recognised", eraTarget.IsDevSymlink && !eraTarget.UpdateAvailable);
                    var installer = new AddonInstaller(era, Config.EraFlavor, new InstallManifest(), null);
                    Check("no work planned through a junction", !installer.NeedsWork("V0.9.0", out _));
                    Check("TOC sync refuses to write through it",
                          !TocSync.SyncInterface(era, Config.PrimaryFolder, Config.EraFlavor, 11509, null) &&
                          File.ReadAllText(Path.Combine(devCheckout, "WowVision_Vanilla.toc")).Contains("11508"));
                    Directory.Delete(eraWv);   // the junction only, never its target
                    Check("checkout survives removing the junction", File.Exists(Path.Combine(devCheckout, "WowVision_Vanilla.toc")));
                }
                else
                {
                    Check("could create a test junction (mklink /J)", false);
                }
            }
        }

        private static bool MakeJunction(string link, string target)
        {
            var psi = new ProcessStartInfo("cmd.exe", $"/c mklink /J \"{link}\" \"{target}\"")
            { UseShellExecute = false, CreateNoWindow = true, RedirectStandardOutput = true, RedirectStandardError = true };
            using (var p = Process.Start(psi)) { p.WaitForExit(10000); }
            return AddonInstaller.IsSymlinked(Path.GetDirectoryName(link), Path.GetFileName(link));
        }

        private static void RunTocTest()
        {
            Console.WriteLine("=== toctest: build version -> interface number ===");
            Check("2.5.6.68502 -> 20506", WowLocator.InterfaceFromBuildVersion("2.5.6.68502") == 20506);
            Check("1.15.9.70003 -> 11509", WowLocator.InterfaceFromBuildVersion("1.15.9.70003") == 11509);
            Check("1.60.1.70450 -> 16001", WowLocator.InterfaceFromBuildVersion("1.60.1.70450") == 16001);
            Check("12.0.7.70500 -> 120007", WowLocator.InterfaceFromBuildVersion("12.0.7.70500") == 120007);
            Check("garbage -> 0", WowLocator.InterfaceFromBuildVersion("nope") == 0);

            Console.WriteLine("=== the rewrite rule ===");
            var ann = WowLocator.Client(Config.AnniversaryFlavor);
            var fwd = WowLocator.Client(Config.ForeverFlavor);
            var era = WowLocator.Client(Config.EraFlavor);
            var mists = WowLocator.Client(Config.MistsFlavor);
            void Rule(string label, string current, ClientInfo c, int iface, bool suffix, string want)
            {
                string got = TocSync.DesiredValue(current, c, iface, suffix);
                Check($"{label}: '{current}' on {c.Short} {iface} -> {got ?? "(no change)"}", got == want);
            }
            Rule("in step",                  "20505,20506",   ann,   20506, true,  null);
            Rule("family replaced",          "20505,20506",   ann,   20507, true,  "20507");
            Rule("shared plain TOC, TBC",    "20506, 16001",  ann,   20507, false, "20507, 16001");
            Rule("shared plain TOC, Forever","20506, 16001",  fwd,   16002, false, "20506, 16002");
            Rule("plain TOC not for Era",    "20506, 16001",  era,   11509, false, null);
            Rule("plain TOC not for Mists",  "20506, 16001",  mists, 50504, false, null);
            Rule("Forever is not Era",       "16001",         era,   11509, false, null);
            Rule("suffix TOC with no entry", "",              era,   11509, true,  "11509");
            Rule("V0.9.0 Vanilla TOC",       "11508",         era,   11509, true,  "11509");

            Console.WriteLine("=== CRLF and BOM round-trip ===");
            string root = Path.Combine(Path.GetTempPath(), "WowVisionTocTest", "_classic_era_", "Interface", "AddOns");
            try
            {
                string dir = Path.Combine(root, "Fake");
                Directory.CreateDirectory(dir);
                string toc = Path.Combine(dir, "Fake_Vanilla.toc");
                byte[] bom = { 0xEF, 0xBB, 0xBF };
                byte[] text = Encoding.UTF8.GetBytes("## Interface: 11508\r\n## Title: Fake\r\n## Version: 1.0\r\n");
                using (var fs = new FileStream(toc, FileMode.Create)) { fs.Write(bom, 0, 3); fs.Write(text, 0, text.Length); }

                Check("rewritten", TocSync.SyncInterface(root, "Fake", Config.EraFlavor, 11509, null));
                byte[] after = File.ReadAllBytes(toc);
                string body = Encoding.UTF8.GetString(after, 3, after.Length - 3);
                Check("BOM kept", after[0] == 0xEF && after[1] == 0xBB && after[2] == 0xBF);
                Check("CRLF kept and other lines intact", body == "## Interface: 11509\r\n## Title: Fake\r\n## Version: 1.0\r\n");
            }
            finally { try { Directory.Delete(Path.Combine(Path.GetTempPath(), "WowVisionTocTest"), true); } catch { } }
        }

        private static void RunVersionTest()
        {
            Console.WriteLine("=== versiontest: order ===");
            Check("V0.10.0 > V0.9.0", AddonInstaller.CompareVersions("V0.10.0", "V0.9.0") > 0);
            Check("0.9 == V0.9.0", AddonInstaller.CompareVersions("0.9", "V0.9.0") == 0);
            Check("v1.0 > V0.99.9", AddonInstaller.CompareVersions("v1.0", "V0.99.9") > 0);
            Check("nothing installed < anything", AddonInstaller.CompareVersions(null, "V0.0.1") < 0);

            Console.WriteLine("=== release numbers and test builds ===");
            Check("V0.9.0 is a release", AddonInstaller.IsReleaseVersion("V0.9.0"));
            Check("0.9.0 is a release", AddonInstaller.IsReleaseVersion("0.9.0"));
            Check("beta is the beta, not a test build", AddonInstaller.IsBeta("beta") && !AddonInstaller.IsTestBuild("beta"));
            Check("@project-version@ is a test build", AddonInstaller.IsTestBuild("@project-version@"));
            Check("V0.9.0-beta1 is a test build", AddonInstaller.IsTestBuild("V0.9.0-beta1"));
            Check("no version is not a test build", !AddonInstaller.IsTestBuild(null));

            Console.WriteLine("=== the decision per channel ===");
            void D(string label, string toc, string tag, string build, Channel ch, string latest, string latestBuild, AddonState want)
            {
                var got = AddonInstaller.Decide(toc, tag, build, ch, latest, latestBuild);
                Check($"{label} -> {got}", got == want);
            }
            D("stable: older release",          "V0.8.0", "V0.8.0", null, Channel.Stable, "V0.9.0", null, AddonState.Update);
            D("stable: current release",        "V0.9.0", "V0.9.0", null, Channel.Stable, "V0.9.0", null, AddonState.UpToDate);
            D("stable: newer than online (pin)", "V0.10.0", null,   null, Channel.Stable, "V0.9.0", null, AddonState.UpToDate);
            D("stable: beta installed -> switch", "beta",  "beta",  "b1", Channel.Stable, "V0.9.0", null, AddonState.Update);
            D("beta: same build",               "beta",   "beta",  "b1", Channel.Beta,   "beta",   "b1", AddonState.UpToDate);
            D("beta: older build",              "beta",   "beta",  "b0", Channel.Beta,   "beta",   "b1", AddonState.Update);
            D("beta: by hand, no build on record", "beta", null,   null, Channel.Beta,   "beta",   "b1", AddonState.Update);
            D("beta: offline, cannot check",    "beta",   "beta",  "b1", Channel.Beta,   "beta",   null, AddonState.Unknown);
            D("beta: release installed -> switch", "V0.9.0", "V0.9.0", null, Channel.Beta, "beta", "b1", AddonState.Update);
            D("either: git checkout copied",    "@project-version@", null, null, Channel.Beta, "beta", "b1", AddonState.TestBuildKept);

            Console.WriteLine("=== channel choice is remembered ===");
            string store = Path.Combine(Path.GetTempPath(), "WowVisionChannelTest");
            ChannelPrefs.DirOverride = store;
            try
            {
                if (Directory.Exists(store)) Directory.Delete(store, true);
                Check("nothing stored -> the default (" + Config.DefaultChannel + ")", ChannelPrefs.Load() == Config.DefaultChannel);
                ChannelPrefs.Save(Channel.Stable);
                Check("stable survives a reload", ChannelPrefs.Load() == Channel.Stable);
                ChannelPrefs.Save(Channel.Beta);
                Check("beta survives a reload", ChannelPrefs.Load() == Channel.Beta);
            }
            finally { ChannelPrefs.DirOverride = null; try { Directory.Delete(store, true); } catch { } }
            Check("beta is preselected", Config.DefaultChannel == Channel.Beta);

            Console.WriteLine("=== beta build id from the download redirect ===");
            Check("asset id read from the storage URL",
                  GitHubClient.BuildIdFromUri(new Uri("https://release-assets.githubusercontent.com/github-production-release-asset/1109589856/b107f80f-951a-488f-b57b-7e410cd0b074?sp=r")) ==
                  "b107f80f-951a-488f-b57b-7e410cd0b074");
            Check("no id from an unrelated URL", GitHubClient.BuildIdFromUri(new Uri("https://github.com/x")) == null);

            Console.WriteLine("=== manifest round-trip ===");
            string mdir = Path.Combine(Path.GetTempPath(), "WowVisionManifestTest");
            try
            {
                Directory.CreateDirectory(mdir);
                var mf = new InstallManifest();
                mf.SetTag("WowVision", "beta");
                mf.SetBuild("WowVision", "b107f80f", new DateTime(2026, 10, 16, 0, 0, 0, DateTimeKind.Utc));
                mf.SetTag("CurseQuestie", "bundle/v12.1.0+v1.0.6");
                mf.Save(mdir);
                var back = InstallManifest.Load(mdir);
                Check("tags and builds survive", back.GetTag("WowVision") == "beta" && back.GetBuild("WowVision") == "b107f80f" &&
                      back.GetBuildDate("WowVision")?.ToString("yyyy-MM-dd") == "2026-10-16" &&
                      back.GetTag("CurseQuestie") == "bundle/v12.1.0+v1.0.6");
                Check("extra-addon keys are told apart", ManagedAddons.IsManagedKey("CurseQuestie") && !ManagedAddons.IsManagedKey("WowVision_MapData_TBC"));
            }
            finally { try { Directory.Delete(mdir, true); } catch { } }

            Console.WriteLine("=== what needs the release (stable) ===");
            Config.SetChannel(Channel.Stable);
            using (var wow = new FakeWow("WowVisionVersionTest"))
            {
                string addons = wow.AddOns[Config.AnniversaryFlavor];
                string product = Config.AnniversaryFlavor;
                bool Needs(InstallManifest m, out bool first) =>
                    new AddonInstaller(addons, product, m, null).NeedsWork("V0.9.0", out first);

                Check("missing folder -> install, first install", Needs(new InstallManifest(), out bool f1) && f1);

                wow.PutWowVision(product, "V0.8.0");
                Check("older TOC, no manifest -> update", Needs(new InstallManifest(), out bool f2) && !f2);

                wow.PutWowVision(product, "V0.9.0");
                var adopt = new InstallManifest();
                Check("same version, no manifest -> nothing, tag adopted",
                      !Needs(adopt, out _) && adopt.GetTag(Config.PrimaryFolder) == "V0.9.0");

                var lagging = new InstallManifest();
                lagging.SetTag(Config.PrimaryFolder, "V0.8.0");
                Check("manifest older than a hand-unzipped TOC -> nothing", !Needs(lagging, out _));

                wow.PutWowVision(product, "V0.10.0");
                Check("newer installed than the release -> nothing (no downgrade)", !Needs(new InstallManifest(), out _));

                wow.PutWowVision(product, "@project-version@");
                Check("test build -> left alone", !Needs(new InstallManifest(), out _));

                wow.PutWowVision(product, "V0.9.0");
                var broken = new InstallManifest();
                broken.SetTag(Config.PrimaryFolder, "V0.9.0");
                broken.SetTag("WowVision_MapData_TBC", "V0.9.0");
                Check("a folder recorded at this release went missing -> reinstall",
                      Needs(broken, out bool f3) && f3);
            }
        }

        private static void RunPathMemoryTest()
        {
            Console.WriteLine("=== pathmemory: what this machine has on record (read only) ===");
            Console.WriteLine($"    per-user : {PathMemory.LocalFile} {(File.Exists(PathMemory.LocalFile) ? "" : "(absent)")}");
            Console.WriteLine($"    machine  : {PathMemory.MachineFile} {(File.Exists(PathMemory.MachineFile) ? "" : "(absent)")}");
            foreach (var kv in PathMemory.Load())
                Console.WriteLine($"    {kv.Key,-18} -> {kv.Value}");

            Console.WriteLine("=== pathmemory: round-trip against a throwaway store ===");
            using (var wow = new FakeWow("WowVisionPathMemoryTest"))
            {
                PathMemory.Remember(Config.MistsFlavor, wow.AddOns[Config.MistsFlavor]);
                var loaded = PathMemory.Load();
                Check("both clients survive a reload",
                      loaded.Count == 2 && loaded[Config.MistsFlavor] == wow.AddOns[Config.MistsFlavor]);
                Check("a path with spaces comes back verbatim",
                      PathMemory.ResolveFor(Config.ForeverFlavor) == wow.AddOns[Config.ForeverFlavor]);
                Check("the base dir is derived for detection",
                      PathMemory.RememberedBaseDirs().Exists(d => string.Equals(d, wow.Base, StringComparison.OrdinalIgnoreCase)));

                Directory.Delete(wow.FlavorDir[Config.MistsFlavor], true);
                Check("a vanished folder resolves to null", PathMemory.ResolveFor(Config.MistsFlavor) == null);

                File.WriteAllText(Path.Combine(wow.FlavorDir[Config.ForeverFlavor], ".flavor.info"),
                                  "Product!STRING:0\nwow_classic_era\n");
                Check("a folder that now reports another client is ignored",
                      PathMemory.ResolveFor(Config.ForeverFlavor) == null);
                Check("an unremembered client resolves to null", PathMemory.ResolveFor(Config.RetailFlavor) == null);
            }
        }

        private static void RunLocTest()
        {
            Console.WriteLine("=== loc: three tables, one key set ===");
            var en = Loc.Table(Lang.En);
            foreach (var lang in new[] { Lang.De, Lang.Fr })
            {
                var t = Loc.Table(lang);
                var missing = en.Keys.Except(t.Keys).ToList();
                var extra = t.Keys.Except(en.Keys).ToList();
                if (missing.Count > 0) Console.WriteLine($"    {lang} lacks: {string.Join(", ", missing)}");
                if (extra.Count > 0) Console.WriteLine($"    {lang} has extra: {string.Join(", ", extra)}");
                Check($"{lang} has exactly the English keys", missing.Count == 0 && extra.Count == 0);

                var badPlaceholders = en.Keys.Where(k => t.ContainsKey(k) && Placeholders(en[k]) != Placeholders(t[k])).ToList();
                if (badPlaceholders.Count > 0) Console.WriteLine($"    {lang} placeholder mismatch: {string.Join(", ", badPlaceholders)}");
                Check($"{lang} uses the same placeholders", badPlaceholders.Count == 0);
            }

            var args = Enumerable.Range(0, 10).Select(i => (object)("x" + i)).ToArray();
            var broken = new List<string>();
            foreach (var lang in new[] { Lang.En, Lang.De, Lang.Fr })
                foreach (var kv in Loc.Table(lang))
                    try { string.Format(kv.Value, args); }
                    catch { broken.Add($"{lang}:{kv.Key}"); }
            if (broken.Count > 0) Console.WriteLine("    unformattable: " + string.Join(", ", broken));
            Check("every text formats", broken.Count == 0);

            // Every key the code asks for exists (scanned from the sources when
            // the harness runs inside the repo).
            string src = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\..\..\WowVisionInstaller"));
            if (Directory.Exists(src))
            {
                var used = new HashSet<string>();
                foreach (string file in Directory.GetFiles(src, "*.cs"))
                    foreach (Match m in Regex.Matches(File.ReadAllText(file), "Loc\\.(?:Get|Format)\\(\"([^\"]+)\""))
                        if (!m.Groups[1].Value.EndsWith(".")) used.Add(m.Groups[1].Value);   // "opt." + key is added below
                foreach (string opt in new[] { "shortcut", "sapi2sr", "windowsVoices", "force" })
                { used.Add("opt." + opt + ".label"); used.Add("opt." + opt + ".desc"); }
                var undefined = used.Where(k => !en.ContainsKey(k)).ToList();
                if (undefined.Count > 0) Console.WriteLine("    used but undefined: " + string.Join(", ", undefined));
                Check($"all {used.Count} keys the code uses are defined", undefined.Count == 0);
            }
        }

        private static string Placeholders(string s) =>
            string.Join(",", Regex.Matches(s, @"\{(\d+)\}").Cast<Match>().Select(m => m.Groups[1].Value).Distinct().OrderBy(x => x));

        private static void RunLogTest()
        {
            Console.WriteLine("=== logtest: the log bundle ===");
            using (var wow = new FakeWow("WowVisionLogTest"))
            {
                wow.PutWowVision(Config.ForeverFlavor, "V0.9.0");
                string fwd = wow.FlavorDir[Config.ForeverFlavor];
                File.WriteAllText(Path.Combine(fwd, "WTF", "Account", "TESTACCOUNT", "SavedVariables", "WowVision.lua"), "WowVisionGlobalDB = {}\n");
                File.WriteAllText(Path.Combine(fwd, "WTF", "Account", "TESTACCOUNT", "Realm", "Char", "SavedVariables", "WowVision.lua"), "WowVisionDB = {}\n");
                File.WriteAllText(Path.Combine(fwd, "WTF", "Account", "TESTACCOUNT", "SavedVariables", "Unrelated.lua"), "x = 1\n");
                Directory.CreateDirectory(Path.Combine(fwd, "Logs"));
                File.WriteAllText(Path.Combine(fwd, "Logs", "General.log"), "an error\n");

                string downloads = Path.Combine(wow.Root, "Downloads");
                Directory.CreateDirectory(downloads);
                LogCollector.DownloadsOverride = downloads;
                try
                {
                    var result = LogCollector.Collect(InstallTarget.BuildAll().FindAll(t => t.ClientFound &&
                        t.AddOnsPath.StartsWith(wow.Base, StringComparison.OrdinalIgnoreCase)));
                    Check("bundle written", result.Success && File.Exists(result.ArchivePath));
                    if (!result.Success) { Console.WriteLine("    " + result.Error); return; }
                    Console.WriteLine($"    {Path.GetFileName(result.ArchivePath)}: {result.FileCount} files from {result.ClientCount} clients");
                    using (var zip = ZipFile.OpenRead(result.ArchivePath))
                    {
                        var names = zip.Entries.Select(e => e.FullName.Replace('\\', '/')).ToList();
                        Check("account and character WowVision.lua", names.Count(n => n.EndsWith("/WowVision.lua")) == 2);
                        Check("unrelated SavedVariables left out", !names.Any(n => n.EndsWith("Unrelated.lua")));
                        Check("the game's General.log", names.Any(n => n.EndsWith("Forever/Logs/General.log")));
                        Check("WowVision's TOCs", names.Count(n => n.Contains("Forever/tocs/")) == 5);
                        Check("system-info.txt and voices.txt", names.Contains("system-info.txt") && names.Contains("voices.txt"));
                        string info = new StreamReader(zip.GetEntry("system-info.txt").Open()).ReadToEnd();
                        Check("system-info names the TOC Forever reads", info.Contains("WowVision_Camelot.toc"));
                        Check("all five clients covered", result.ClientCount == 5);
                    }
                }
                finally { LogCollector.DownloadsOverride = null; }
            }
        }

        /// <summary>
        /// Who gets what, network-free: the map data's plain TOC, the login tool
        /// table, and the extra addons' per-client package lists (which mirror
        /// the probe of the real zips from 2026-10-19).
        /// </summary>
        private static void RunAvailabilityTest()
        {
            Console.WriteLine("=== availability: map data ===");
            string root = Path.Combine(Path.GetTempPath(), "WowVisionAvailability");
            try
            {
                string dir = Path.Combine(root, "WowVision_MapData_TBC");
                Directory.CreateDirectory(dir);
                File.WriteAllText(Path.Combine(dir, "WowVision_MapData_TBC.toc"),
                                  "## Interface: 20506, 16001\n## Title: TBC Map Data\n## Dependencies: WowVision\n");
                foreach (var c in WowLocator.Clients)
                {
                    bool want = c.Product == Config.AnniversaryFlavor || c.Product == Config.ForeverFlavor;
                    Check($"map data {(want ? "goes to" : "stays out of")} {c.Label}",
                          WowLocator.FolderServesClient(root, "WowVision_MapData_TBC", c.Product) == want);
                }
                string wv = Path.Combine(root, "WowVision");
                Directory.CreateDirectory(wv);
                File.WriteAllText(Path.Combine(wv, "WowVision_Mists.toc"), "## Interface: 50503, 50504\n");
                Check("a suffix TOC serves its client", WowLocator.FolderServesClient(root, "WowVision", Config.MistsFlavor));
                Check("a folder without a TOC for the client does not",
                      !WowLocator.FolderServesClient(root, "WowVision", Config.RetailFlavor));
            }
            finally { try { Directory.Delete(root, true); } catch { } }

            Console.WriteLine("=== availability: login tool ===");
            Check("Forever: tool only, no textures",
                  LoginToolInstaller.ClientSupported(Config.ForeverFlavor) && !LoginToolInstaller.ClientNeedsTextures(Config.ForeverFlavor));
            Check("Anniversary and Era: tool with textures",
                  LoginToolInstaller.ClientNeedsTextures(Config.AnniversaryFlavor) && LoginToolInstaller.ClientNeedsTextures(Config.EraFlavor));
            Check("Mists: no tool (it has no Mists screen data)", !LoginToolInstaller.ClientSupported(Config.MistsFlavor));
            Check("Retail: no tool", !LoginToolInstaller.ClientSupported(Config.RetailFlavor));

            Console.WriteLine("=== availability: extra addons ===");
            string Keys(string product) => string.Join(", ",
                ManagedAddons.Entries.SelectMany(e => ManagedAddons.PackagesFor(e, product)).Select(p => p.Key));
            foreach (var c in WowLocator.Clients)
                Console.WriteLine($"    {c.Short,-8} {Keys(c.Product)}");
            Check("Forever (Sku's list)", Keys(Config.ForeverFlavor) ==
                  "CurseQuestie, CurseAtlasLootContinued, CurseDetails, CursePawnForever, DBMCore, DBMRaidsVanilla, DBMDungeons, CurseGTFO, BugSack, CurseBugGrabber");
            Check("Anniversary (Sku's list)", Keys(Config.AnniversaryFlavor) ==
                  "CurseQuestie, CurseAtlasLootContinued, CurseDetails, CursePawnTBC, DBMCore, DBMRaidsBC, DBMDungeons, CurseGTFO, BugSack, CurseBugGrabber");
            Check("Era (Sku's list)", Keys(Config.EraFlavor) ==
                  "CurseQuestie, CurseAtlasLootContinued, CurseDetails, CursePawnVanilla, DBMCore, DBMRaidsVanilla, DBMDungeons, CurseGTFO, BugSack, CurseBugGrabber");
            Check("Mists: no AtlasLoot, Pandaria Pawn, DBM MoP raids", Keys(Config.MistsFlavor) ==
                  "CurseQuestie, CurseDetails, CursePawnMists, DBMCore, DBMRaidsMoP, DBMDungeons, CurseGTFO, BugSack, CurseBugGrabber");
            Check("Retail: no Questie, no AtlasLoot, retail Pawn", Keys(Config.RetailFlavor) ==
                  "CurseDetails, CursePawnRetail, DBMCore, DBMDungeons, CurseGTFO, BugSack, CurseBugGrabber");
            var atlas = ManagedAddons.Entries.Find(e => e.PrefKey == "ManageAtlasLoot");
            Check("an entry with nothing for a client is not available there",
                  !ManagedAddons.AvailableFor(atlas, Config.RetailFlavor) && ManagedAddons.AvailableFor(atlas, Config.EraFlavor));
        }

        /// <summary>
        /// Every extra addon of one client with the REAL downloads (needs network,
        /// a few hundred MB): live release resolution, download, hash/shape
        /// validation, the per-client TOC check, install into a throwaway AddOns
        /// folder of that client, then a second pass that must find nothing to do.
        /// </summary>
        private static void RunManagedInstallTest(string product)
        {
            Console.WriteLine($"=== managedinstall: every extra addon for {WowLocator.ProductLabel(product)} (real downloads) ===");
            using (var wow = new FakeWow("WowVisionManagedInstall"))
            using (var github = new GitHubClient())
            {
                string addons = wow.AddOns[product];

                // Old AtlasLoot sets that must go, and look-alikes that must stay.
                string[] obsolete = { "AtlasLootClassic", "AtlasLoot_Favourites" };
                string[] keep = { "AtlasLootClassic_TBC_Phase_1_Karazhan" };
                foreach (var name in obsolete.Concat(keep))
                {
                    Directory.CreateDirectory(Path.Combine(addons, name));
                    File.WriteAllText(Path.Combine(addons, name, name + ".toc"), "## Interface: 20506\n");
                }

                ManagedAddons.ResolveAll(github, TimeSpan.FromSeconds(30));
                var manifest = InstallManifest.Load(addons);
                foreach (var entry in ManagedAddons.Entries)
                {
                    if (!ManagedAddons.AvailableFor(entry, product))
                    {
                        Console.WriteLine($"    {entry.DisplayName}: not available for this client (by the list)");
                        continue;
                    }
                    foreach (var p in ManagedAddons.PackagesFor(entry, product))
                    {
                        var r = ManagedAddons.Resolved(p);
                        Console.WriteLine($"    {p.Key,-26} {r.Version,-24} {(r.Sha256 == null ? "live" : "pin")}");
                    }
                    bool ok = ManagedAddonInstaller.InstallEntryAsync(addons, product, entry, github, manifest,
                            pr => { if (pr.Phase != "download") Console.WriteLine("      " + pr.Message); }, force: false)
                        .GetAwaiter().GetResult();
                    bool unavailable = ManagedAddons.PackagesFor(entry, product).Any(p => ManagedAddons.KnownUnavailable(manifest, p));
                    Check(entry.DisplayName + (unavailable ? " found unusable and skipped" : " installed"),
                          ok && (unavailable || ManagedAddons.EntryInstalled(addons, product, entry)));
                    foreach (var p in ManagedAddons.PackagesFor(entry, product))
                        if (!ManagedAddons.KnownUnavailable(manifest, p))
                            Check($"{p.Key} carries a TOC this client loads",
                                  p.RequiredRoots.Any(rt => WowLocator.FolderServesClient(addons, rt, product)));
                }
                manifest.Save(addons);

                var atlas = ManagedAddons.Entries.Find(e => e.PrefKey == "ManageAtlasLoot");
                if (ManagedAddons.AvailableFor(atlas, product))
                    Check("old AtlasLoot folders removed, look-alikes kept",
                          obsolete.All(n => !Directory.Exists(Path.Combine(addons, n))) &&
                          keep.All(n => Directory.Exists(Path.Combine(addons, n))));

                Console.WriteLine("=== second pass ===");
                var again = InstallManifest.Load(addons);
                foreach (var entry in ManagedAddons.Entries)
                    Check(entry.DisplayName + " nothing to do", !ManagedAddons.EntryNeedsWork(addons, product, again, entry));
            }
        }

        /// <summary>
        /// The login tool, REAL download, into a throwaway client: program folder
        /// at the WoW base, recognition textures in Interface and the font
        /// override only where the client needs them, nothing at all for a client
        /// the tool does not serve. No launcher lands on the desktop.
        /// </summary>
        private static void RunLoginToolTest(string product)
        {
            Console.WriteLine($"=== logintool: {WowLocator.ProductLabel(product)} (real download) ===");
            using (var wow = new FakeWow("WowVisionLoginToolTest"))
            using (var github = new GitHubClient())
            {
                LoginToolInstaller.SkipShortcut = true;
                try
                {
                    string addons = wow.AddOns[product];
                    if (!LoginToolInstaller.ClientSupported(product))
                    {
                        Check("this client gets no login tool", !LoginToolInstaller.ClientSupported(product));
                        return;
                    }
                    LoginToolInstaller.Install(addons, github, m => Console.WriteLine("    " + m), force: false, product: product);
                    string toolDir = LoginToolInstaller.ResolveToolDir(addons);
                    Console.WriteLine($"    tool folder: {toolDir}");
                    Check("tool folder at the WoW base", toolDir == Path.Combine(wow.Base, Config.LoginToolFolderName));
                    Check("v2\\START.ahk present", LoginToolInstaller.IsInstalled(addons));
                    Check("version marker written",
                          File.ReadAllText(Path.Combine(toolDir, "installed-release.txt")).Trim() == Config.LoginToolVersion);
                    string marker = Path.Combine(wow.FlavorDir[product], "Interface", LoginToolInstaller.FiducialMarkerRelPath);
                    if (LoginToolInstaller.ClientNeedsTextures(product))
                        Check("recognition textures in this client's Interface", File.Exists(marker));
                    else
                        Check("no textures in this client (it narrates its own login screens)", !File.Exists(marker));
                    Check("no textures in any other client",
                          wow.FlavorDir.Where(kv => kv.Key != product).All(kv =>
                              !File.Exists(Path.Combine(kv.Value, "Interface", LoginToolInstaller.FiducialMarkerRelPath))));
                }
                finally { LoginToolInstaller.SkipShortcut = false; }
            }
        }

        /// <summary>
        /// LoginToolInstaller.RemoveStaleFiducialTextures against a throwaway
        /// payload + Interface tree (from the Sku harness): current files and
        /// non-.blp files survive, stale .blp files go with their emptied folders,
        /// and nothing outside the payload's folders — AddOns above all — is touched.
        /// </summary>
        private static void RunTextureSweepTest()
        {
            Console.WriteLine("=== texturesweep ===");
            string root = Path.Combine(Path.GetTempPath(), "WowVisionTextureSweepTest");
            if (Directory.Exists(root)) Directory.Delete(root, true);
            string payload = Path.Combine(root, "payload");
            string iface = Path.Combine(root, "Interface");
            void Put(string baseDir, string rel)
            {
                string p = Path.Combine(baseDir, rel);
                Directory.CreateDirectory(Path.GetDirectoryName(p));
                File.WriteAllText(p, "x");
            }
            try
            {
                Put(payload, @"BUTTONS\128RedButton.BLP");
                Put(payload, @"GLUES\COMMON\Current.blp");
                Put(iface, @"BUTTONS\128RedButton.BLP");
                Put(iface, @"BUTTONS\LegacyButton.BLP");
                Put(iface, @"Glues\Common\Current.blp");
                Put(iface, @"GLUES\OLDGEN\dead.blp");
                Put(iface, @"GLUES\readme.txt");
                Put(iface, @"FrameGeneral\gone.blp");
                Put(iface, @"AddOns\SomeAddon\art.blp");
                Put(iface, @"CustomFolder\user.blp");

                LoginToolInstaller.RemoveStaleFiducialTextures(payload, iface);

                Check("current marker survives", File.Exists(Path.Combine(iface, @"BUTTONS\128RedButton.BLP")));
                Check("current file survives casing differences", File.Exists(Path.Combine(iface, @"GLUES\COMMON\Current.blp")));
                Check("stale .BLP removed", !File.Exists(Path.Combine(iface, @"BUTTONS\LegacyButton.BLP")));
                Check("stale subfolder and its folder removed", !Directory.Exists(Path.Combine(iface, @"GLUES\OLDGEN")));
                Check("non-.blp file untouched", File.Exists(Path.Combine(iface, @"GLUES\readme.txt")));
                Check("dropped payload folder swept", !Directory.Exists(Path.Combine(iface, "FrameGeneral")));
                Check("Interface\\AddOns untouched", File.Exists(Path.Combine(iface, @"AddOns\SomeAddon\art.blp")));
                Check("unrelated user folder untouched", File.Exists(Path.Combine(iface, @"CustomFolder\user.blp")));
            }
            finally { try { Directory.Delete(root, true); } catch { } }
        }

        private static void RunResolve()
        {
            Console.WriteLine("=== resolve: the beta online ===");
            Config.SetChannel(Channel.Beta);
            GitHubClient.ResolveAndAdoptLatestRelease();
            Console.WriteLine($"    asset {Config.AssetName}, build {Config.LatestBuild ?? "(none)"}, heard as \"{Config.LatestVersion}\"");
            Check("beta build id read", !string.IsNullOrEmpty(Config.LatestBuild));
            Check("beta upload date read", Config.LatestBuildDate.HasValue);
            Check("the installer's self-update looks at the beta release",
                  GitHubClient.BuildInstallerDownloadUrl("x").Contains("/releases/download/beta/"));

            Console.WriteLine("=== resolve: the newest stable release online ===");
            Config.SetChannel(Channel.Stable);
            Console.WriteLine($"    built-in pin : {Config.FallbackTag}");
            GitHubClient.ResolveAndAdoptLatestRelease();
            Check("the installer's self-update looks at the latest release",
                  GitHubClient.BuildInstallerDownloadUrl("x").Contains("/releases/latest/download/"));
            Console.WriteLine($"    effective    : {Config.LatestTag}, asset {Config.AssetName}");
            Console.WriteLine($"    download     : {GitHubClient.BuildAddonDownloadUrl(Config.LatestTag, Config.AssetName)}");
            Console.WriteLine($"    log          : {Logger.LastLine}");
            Check("tag looks like a release", Regex.IsMatch(Config.LatestTag, @"^[vV]\d+(\.\d+)*$"));
            Check("asset is a zip", Config.AssetName.EndsWith(".zip", StringComparison.OrdinalIgnoreCase));
            Check("never older than the pin", AddonInstaller.CompareVersions(Config.LatestTag, Config.FallbackTag) >= 0);
        }

        private static void RunFullInstall()
        {
            Console.WriteLine("=== fullinstall: real downloads into a throwaway WoW folder ===");
            using (var wow = new FakeWow("WowVisionFullInstall"))
            using (var github = new GitHubClient())
            {
                var targets = InstallTarget.BuildAll().FindAll(t =>
                    t.ClientFound && t.AddOnsPath.StartsWith(wow.Base, StringComparison.OrdinalIgnoreCase));
                Check("five targets", targets.Count == 5);
                // WowVision only: the extra addons and the login tool have their
                // own commands (managedinstall, logintool).
                var options = new InstallOptions
                {
                    SkipMachineWide = true,
                    InstallLoginTool = false,
                    ManagedEnabled = ManagedAddons.Entries.ToDictionary(e => e.PrefKey, e => false),
                };

                // 1. Stable into five empty clients.
                Config.SetChannel(Channel.Stable);
                GitHubClient.ResolveAndAdoptLatestRelease();
                Console.WriteLine($"=== stable: {Config.LatestTag} ({Config.AssetName}) ===");
                var first = Run(targets, options, github);
                Check("every client planned a first install", first.All(r => r.Plan != null && r.Plan.FirstInstall));
                Check("first install needs the game closed", InstallRunner.NeedsGameClosed(first));
                Check("no client failed", !InstallRunner.AnyFailed(first));
                Check("the downloaded release was removed from %TEMP%",
                      !Directory.Exists(AddonInstaller.TempRoot) || !Directory.GetDirectories(AddonInstaller.TempRoot).Any());
                CheckInstalled(targets, Config.LatestTag);
                Check("no beta build recorded for a release",
                      targets.All(t => InstallManifest.Load(t.AddOnsPath).GetBuild(Config.PrimaryFolder) == null));
                SecondPass(targets, options, github);

                // 2. Switch to the beta: every client is offered the beta.
                Config.SetChannel(Channel.Beta);
                GitHubClient.ResolveAndAdoptLatestRelease();
                Console.WriteLine($"=== beta: {Config.AssetName}, build {Config.LatestBuild}, {Config.LatestVersion} ===");
                Check("the beta build id was read", !string.IsNullOrEmpty(Config.LatestBuild));
                foreach (var t in targets) t.RefreshInstalledVersion();
                Check("every client offers the switch to beta", targets.All(t => t.UpdateAvailable));
                var beta = Run(targets, options, github);
                Check("no client failed", !InstallRunner.AnyFailed(beta));
                CheckInstalled(targets, Config.BetaTag);
                Check("beta build recorded in every client",
                      targets.All(t => InstallManifest.Load(t.AddOnsPath).GetBuild(Config.PrimaryFolder) == Config.LatestBuild));

                // The beta zip carries the TBC map data as its own folder.
                foreach (var t in targets)
                {
                    bool want = t.Product == Config.AnniversaryFlavor || t.Product == Config.ForeverFlavor;
                    bool has = Directory.Exists(Path.Combine(t.AddOnsPath, "WowVision_MapData_TBC"));
                    Check($"{t.ShortName}: map data {(want ? "installed" : "left out")}", has == want);
                }
                SecondPass(targets, options, github);

                // 3. A recorded build that is not the one online -> update offered.
                var m = InstallManifest.Load(targets[0].AddOnsPath);
                m.SetBuild(Config.PrimaryFolder, "an-older-upload", null);
                m.Save(targets[0].AddOnsPath);
                targets[0].RefreshInstalledVersion();
                Check("an older beta build is offered the newer one", targets[0].UpdateAvailable);
            }
        }

        private static List<TargetResult> Run(List<InstallTarget> targets, InstallOptions options, GitHubClient github)
        {
            using (var runner = new InstallRunner(targets, options, github, Print))
            {
                var results = runner.BuildPlans();
                runner.PreparePackage(results);
                runner.Execute(results);
                Console.WriteLine();
                Console.WriteLine(runner.ComposeSummary(results));
                Console.WriteLine();
                return results;
            }
        }

        private static void CheckInstalled(List<InstallTarget> targets, string tag)
        {
            foreach (var t in targets)
            {
                string v = WowLocator.ReadTocVersion(t.AddOnsPath, Config.PrimaryFolder, t.Product);
                int iface = WowLocator.ClientInterface(t.AddOnsPath, t.Product);
                string line = TocSync.ReadInterface(t.AddOnsPath, Config.PrimaryFolder, t.Product) ?? "";
                Console.WriteLine($"    {t.ShortName,-8} version {v}, interface {line}");
                Check($"{t.ShortName}: {tag} installed", string.Equals(v, tag, StringComparison.OrdinalIgnoreCase));
                Check($"{t.ShortName}: TOC names the client ({iface})",
                      line.Split(',').Select(s => s.Trim()).Contains(iface.ToString()));
                Check($"{t.ShortName}: manifest records {tag}",
                      InstallManifest.Load(t.AddOnsPath).GetTag(Config.PrimaryFolder) == tag);
                Check($"{t.ShortName}: game settings written", GameSettings.CheckNeeded(t.AddOnsPath).Count == 0);
            }
        }

        private static void SecondPass(List<InstallTarget> targets, InstallOptions options, GitHubClient github)
        {
            Console.WriteLine("=== second pass ===");
            foreach (var t in targets) t.RefreshInstalledVersion();
            Check("no client offers an update", targets.All(t => !t.UpdateAvailable));
            using (var runner = new InstallRunner(targets, options, github, Print))
            {
                var second = runner.BuildPlans();
                Check("nothing left to do", !InstallRunner.HasWork(second));
                runner.PreparePackage(second);
                Check("and nothing downloaded", second.All(r => r.Plan.Items.Count == 0));
            }
        }

        private static void Print(ProgressLine line)
        {
            // Download ticks share a key and would print several hundred lines;
            // only the milestones and the one-off lines are worth reading back.
            if (line.Milestone || line.Key == null || !line.Text.Contains("%)"))
                Console.WriteLine("    " + line.Text);
        }

        // ── self-update (from the Sku installer's harness) ───────────────────

        /// <summary>
        /// The whole self-update chain except the window and the restart: fetch
        /// installer-version.txt, compare, download the published exe, check it
        /// against the published SHA-256 and its own version resource. Proves
        /// build.ps1 published the exe and its checksum as a matching pair; a
        /// mismatch here means every installed updater would offer an update it
        /// then refuses to apply. Run it after every release.
        /// </summary>
        private static void RunSelfUpdateTest(string poseAs)
        {
            Console.WriteLine("=== selfupdate: the published installer ===");
            Console.WriteLine($"    posing as    : {poseAs}");
            Console.WriteLine($"    version file : {GitHubClient.BuildInstallerDownloadUrl(SelfUpdater.VersionAssetName)}");

            var info = SelfUpdater.Check(poseAs);
            if (info == null)
            {
                Console.WriteLine("    -> no update offered.");
                Console.WriteLine($"       reason: {Logger.LastLine}");
                Check("an update is offered to an older installer", false);
                return;
            }

            Console.WriteLine($"    offered      : {info.Version}");
            Console.WriteLine($"    download     : {info.DownloadUrl}");
            string staged = null;
            try
            {
                staged = SelfUpdater.DownloadAsync(info, null, CancellationToken.None).GetAwaiter().GetResult();
                Check("hash and version resource both check out", true);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"    {ex.Message}");
                Check("hash and version resource both check out", false);
            }
            finally
            {
                // The swap itself is deliberately NOT exercised: it would rename
                // this harness out from under itself for no gain.
                try { if (staged != null && File.Exists(staged)) File.Delete(staged); } catch { }
            }
        }

        /// <summary>
        /// The verification half of the self-updater in both directions, against
        /// the exe that is published right now: the true hash is accepted, a wrong
        /// hash and a not-newer exe are refused. A test of the happy path alone
        /// would pass just as well if the hash comparison were missing.
        /// </summary>
        private static void RunSelfUpdateProof()
        {
            string url = GitHubClient.BuildInstallerDownloadUrl(Config.InstallerExeName);
            Console.WriteLine("=== selfupdateproof ===");
            Console.WriteLine($"    published exe : {url}");

            string probe = Path.Combine(Path.GetTempPath(), "WowVisionSelfUpdateProof.exe");
            string trueHash, publishedVersion;
            try
            {
                using (var github = new GitHubClient())
                    github.DownloadFileAsync(url, probe).GetAwaiter().GetResult();
                trueHash = Sha256(probe);
                publishedVersion = FileVersionInfo.GetVersionInfo(probe).FileVersion;
                Console.WriteLine($"    version       : {publishedVersion}");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"    could not fetch the published exe: {ex.Message}");
                Check("published exe reachable", false);
                return;
            }
            finally { try { if (File.Exists(probe)) File.Delete(probe); } catch { } }

            Check("correct hash accepted", TryDownload(url, publishedVersion, trueHash, "0.1"));
            Check("wrong hash rejected", !TryDownload(url, publishedVersion, new string('a', 64), "0.1"));
            Check("not-newer exe rejected", !TryDownload(url, publishedVersion, trueHash, "999.0"));
        }

        private static bool TryDownload(string url, string version, string sha, string poseAs)
        {
            var info = new SelfUpdateInfo { Version = version, RunningVersion = poseAs, Sha256 = sha, DownloadUrl = url };
            string staged = null;
            try
            {
                staged = SelfUpdater.DownloadAsync(info, null, CancellationToken.None).GetAwaiter().GetResult();
                return true;
            }
            catch { return false; }
            finally { try { if (staged != null && File.Exists(staged)) File.Delete(staged); } catch { } }
        }

        /// <summary>
        /// Reads a version file exactly as the installer would (default:
        /// dist\installer-version.txt as build.ps1 writes it). Guards the
        /// coupling between a PowerShell writer and a C# reader that nothing else
        /// would notice breaking: an unreadable file just makes the installer say
        /// nothing, which looks exactly like "no update".
        /// </summary>
        private static void RunVersionFileTest(string path)
        {
            if (string.IsNullOrEmpty(path))
                path = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\..\..\dist\installer-version.txt");
            path = Path.GetFullPath(path);

            Console.WriteLine("=== versionfile ===");
            Console.WriteLine($"    file : {path}");
            if (!File.Exists(path))
            {
                Console.WriteLine("    -> not found. Run build.ps1 first.");
                Check("version file present", false);
                return;
            }

            string text = new UTF8Encoding(false).GetString(File.ReadAllBytes(path));
            SelfUpdater.ParseVersionFile(text, out string version, out string sha);
            Console.WriteLine($"    version : {version ?? "(none)"}");
            Console.WriteLine($"    sha256  : {sha ?? "(none)"}");

            Check("version is dotted digits", !string.IsNullOrEmpty(version) && Regex.IsMatch(version, @"^\d+(\.\d+)*$"));
            Check("sha256 is 64 lower-case hex", !string.IsNullOrEmpty(sha) && Regex.IsMatch(sha, "^[0-9a-f]{64}$"));
            SelfUpdater.ParseVersionFile(text.Replace("\n", "\r\n"), out string v2, out string s2);
            Check("CRLF parses the same", v2 == version && s2 == sha);
            SelfUpdater.ParseVersionFile("﻿" + text, out string v3, out string s3);
            Check("leading BOM tolerated", v3 == version && s3 == sha);

            string exe = Path.Combine(Path.GetDirectoryName(path), Config.InstallerExeName);
            if (File.Exists(exe))
                Check($"hash matches {Config.InstallerExeName} beside it", Sha256(exe) == sha);
        }

        /// <summary>
        /// Proves the SWAP: a running exe can be renamed out of its own path and a
        /// different file moved into it — the one Windows-specific assumption the
        /// self-updater rests on. Copies the harness into %TEMP% and has that copy
        /// do the renaming on itself; nothing else is touched.
        /// </summary>
        private static void RunSwapTest(bool isChild)
        {
            string sandbox = Path.Combine(Path.GetTempPath(), "WowVisionSwapTest");

            if (isChild)
            {
                string running = System.Reflection.Assembly.GetExecutingAssembly().Location;
                string dir = Path.GetDirectoryName(running) ?? "";
                string staged = Path.Combine(dir, "WowVisionUpdater.new.exe");
                File.Copy(running, staged, overwrite: true);
                SelfUpdater.Apply(staged);
                bool ok = File.Exists(running) && File.Exists(Path.Combine(dir, "WowVisionUpdater.old.exe")) && !File.Exists(staged);
                Console.WriteLine(ok ? "    CHILD-PASS" : "    CHILD-FAIL");
                return;
            }

            Console.WriteLine("=== swaptest: rename a running exe ===");
            try { if (Directory.Exists(sandbox)) Directory.Delete(sandbox, true); } catch { }
            Directory.CreateDirectory(sandbox);
            string self = System.Reflection.Assembly.GetExecutingAssembly().Location;
            foreach (var f in Directory.GetFiles(Path.GetDirectoryName(self) ?? ""))
                File.Copy(f, Path.Combine(sandbox, Path.GetFileName(f)), overwrite: true);

            var psi = new ProcessStartInfo(Path.Combine(sandbox, Path.GetFileName(self)), "swaptest child")
            { UseShellExecute = false, RedirectStandardOutput = true, WorkingDirectory = sandbox };
            string output;
            using (var p = Process.Start(psi)) { output = p.StandardOutput.ReadToEnd(); p.WaitForExit(); }
            Console.Write(output);

            bool pass = output.Contains("CHILD-PASS");
            Console.WriteLine(pass ? "    [PASS] a running exe can be renamed aside and replaced in place"
                                   : "    [FAIL] the swap did not complete");
            if (!pass) Environment.ExitCode = 1;
            try { Directory.Delete(sandbox, true); } catch { }
        }

        private static string Sha256(string path)
        {
            using (var sha = System.Security.Cryptography.SHA256.Create())
            using (var fs = File.OpenRead(path))
            {
                var sb = new StringBuilder();
                foreach (byte b in sha.ComputeHash(fs)) sb.Append(b.ToString("x2"));
                return sb.ToString();
            }
        }
    }
}
