using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;

namespace WowVisionInstaller
{
    /// <summary>Everything the user chose on the components page.</summary>
    public class InstallOptions
    {
        public bool DesktopShortcut = true;
        public bool InstallSapi2Sr = true;
        public bool InstallWindowsVoices = true;
        public bool InstallLoginTool = true;

        /// <summary>
        /// Which extra addons to handle, keyed by <see cref="ManagedEntry.PrefKey"/>.
        /// Null = load the persisted choices (<see cref="ManagedPrefs"/>) — the
        /// one-click path.
        /// </summary>
        public Dictionary<string, bool> ManagedEnabled;

        /// <summary>The effective extra-addon choices, loading the persisted store on demand.</summary>
        public Dictionary<string, bool> EffectiveManaged()
            => ManagedEnabled ?? (ManagedEnabled = ManagedPrefs.Load());

        /// <summary>Reinstall everything, ignoring version checks (repair).</summary>
        public bool Force = false;

        /// <summary>
        /// Test hook: skip the machine-wide steps (voice bridge, Windows voices,
        /// persistent copy, shortcuts) so WowVisionSelfTest can run the real
        /// pipeline against a throwaway folder without touching the machine.
        /// </summary>
        internal bool SkipMachineWide = false;
    }

    /// <summary>
    /// One line for the progress window.
    ///
    /// <see cref="Key"/> is what turns a torrent of download ticks into a single
    /// row that counts up: lines sharing a key replace each other in the history
    /// instead of piling up. A null key means "this is its own event" and always
    /// appends — which is what every one-shot message wants.
    /// </summary>
    public class ProgressLine
    {
        public string Text;
        public bool Milestone;
        public string Key;
    }

    /// <summary>What happened for one client.</summary>
    public class TargetResult
    {
        public InstallTarget Target;
        public InstallPlan Plan;

        /// <summary>Set when this client failed; the others still run.</summary>
        public Exception Error;
    }

    /// <summary>
    /// Runs the install across every selected client in ONE pass.
    ///
    /// Three steps, because two things sit between them that need the UI thread
    /// or the network:
    ///   1. <see cref="BuildPlans"/> — what each client needs. No changes made.
    ///   2. <see cref="PreparePackage"/> — download and extract the release ONCE,
    ///      if any client needs it, and work out which folders that brings. The
    ///      game may still be running; the download is the long part.
    ///   3. the "close the game first" gate (ProgressForm), asked once for the
    ///      whole run, then <see cref="Execute"/>.
    ///
    /// A failure on one client is recorded and the run continues to the next.
    /// Losing one client is no reason to abandon an update of another that would
    /// have worked.
    /// </summary>
    public class InstallRunner : IDisposable
    {
        private readonly List<InstallTarget> _targets;
        private readonly InstallOptions _options;
        private readonly GitHubClient _github;
        private readonly Action<ProgressLine> _report;
        private ReleasePackage _package;

        /// <summary>
        /// Namespaces row keys to the client currently being worked on, so the
        /// second client's ticks start rows of their own instead of overwriting
        /// the first client's finished ones.
        /// </summary>
        private string _keyScope = "";

        /// <summary>Short tag ("TBC" / "Forever") prefixed onto the current client's rows.</summary>
        private string _scopeLabel = "";

        private readonly CancellationToken _cancel;

        /// <summary>True when the user stopped the run before it finished.</summary>
        public bool WasCancelled { get; private set; }

        public InstallRunner(List<InstallTarget> targets, InstallOptions options,
                             GitHubClient github, Action<ProgressLine> report,
                             CancellationToken cancel = default(CancellationToken))
        {
            _targets = targets;
            _options = options;
            _github = github;
            _report = report;
            _cancel = cancel;
        }

        private void Say(string message, bool milestone = false, string key = null) =>
            _report?.Invoke(new ProgressLine { Text = message, Milestone = milestone, Key = key });

        /// <summary>
        /// A line belonging to the client currently being worked on, prefixed with
        /// its short tag ("TBC: …"). Only the sub-steps get the prefix; the
        /// client-level headlines already name the client in full.
        /// </summary>
        private void SayScoped(string message, bool milestone = false, string key = null) =>
            Say(string.IsNullOrEmpty(_scopeLabel) ? message : _scopeLabel + ": " + message,
                milestone, key);

        /// <summary>Background: work out what each client needs. No changes made.</summary>
        public List<TargetResult> BuildPlans()
        {
            AddonInstaller.CleanupTempRoot();   // leftovers of a crashed run
            var results = new List<TargetResult>();

            foreach (var target in _targets)
            {
                _keyScope = "plan:" + target.Product;
                _scopeLabel = target.ShortName;
                Say(Loc.Format("status.checkingClient", target.DisplayName), true);

                var result = new TargetResult { Target = target };
                try
                {
                    var manifest = InstallManifest.Load(target.AddOnsPath);
                    result.Plan = BuildPlanFor(target, manifest);
                    // Adopted tags (a manual install found current) are worth
                    // keeping even if the user stops before Execute.
                    manifest.Save(target.AddOnsPath);
                }
                catch (Exception ex)
                {
                    Logger.Error($"Planning failed for {target.DisplayName}", ex);
                    result.Error = ex;
                }
                results.Add(result);
            }

            _scopeLabel = "";
            return results;
        }

        /// <summary>
        /// Background: download and extract the release if any client needs it,
        /// then fill each plan with the folders it will receive and whether the
        /// game must be closed for them. Throws on a failed download (nothing has
        /// been changed at that point); cancellable.
        /// </summary>
        public void PreparePackage(List<TargetResult> results)
        {
            if (!results.Any(r => r.Plan != null && r.Plan.AddonNeedsWork)) return;

            _keyScope = "package";
            Say(Loc.Format("status.downloading", Config.DisplayName, Config.LatestVersion), true);
            _package = ReleasePackage.DownloadAsync(_github, Config.LatestTag, Config.AssetName,
                                                    OnProgress, _cancel).GetAwaiter().GetResult();

            foreach (var r in results)
            {
                if (r.Plan == null || !r.Plan.AddonNeedsWork) continue;
                foreach (string folder in _package.Folders)
                {
                    bool symlink = AddonInstaller.IsSymlinked(r.Target.AddOnsPath, folder);
                    if (symlink) continue;   // a developer's checkout: never written to

                    // The other folders of the zip go only where they can load:
                    // WowVision_MapData_TBC ("## Interface: 20506, 16001") belongs
                    // in Anniversary and WoW Forever, not in Era, Mists or Retail.
                    // The main folder serves every client by its own TOCs.
                    bool primary = string.Equals(folder, Config.PrimaryFolder, StringComparison.OrdinalIgnoreCase);
                    if (!primary && !WowLocator.FolderServesClient(_package.Root, folder, r.Target.Product))
                    {
                        Logger.Info($"{folder}: not written for {r.Target.Product}; not installed there.");
                        continue;
                    }

                    var item = new PlanItem
                    {
                        FolderName = folder,
                        FirstInstall = !Directory.Exists(Path.Combine(r.Target.AddOnsPath, folder)),
                    };
                    r.Plan.Items.Add(item);
                    if (AddonInstaller.RequiresGameClosed(item)) r.Plan.NeedsGameClosed = true;
                }
            }
        }

        /// <summary>True when any client's plan requires WoW to be closed.</summary>
        public static bool NeedsGameClosed(List<TargetResult> results) =>
            results.Any(r => r.Plan != null && r.Plan.NeedsGameClosed);

        /// <summary>True when any client failed to plan or to install.</summary>
        public static bool AnyFailed(List<TargetResult> results) =>
            results.Any(r => r.Error != null || r.Plan == null);

        /// <summary>True when at least one client actually has work to do.</summary>
        public static bool HasWork(List<TargetResult> results) =>
            results.Any(r => r.Plan != null && r.Plan.HasWork);

        /// <summary>Background: carry out every plan, then the machine-wide extras.</summary>
        public void Execute(List<TargetResult> results)
        {
            foreach (var r in results)
            {
                if (r.Plan == null || r.Error != null) continue;   // planning already failed

                // Between clients is a clean stopping point: nothing is half
                // written, so a cancelled run simply covers fewer clients.
                if (_cancel.IsCancellationRequested) { WasCancelled = true; break; }

                try
                {
                    _keyScope = "run:" + r.Target.Product;
                    _scopeLabel = r.Target.ShortName;
                    Say(Loc.Format("status.installingClient", r.Target.DisplayName), true);

                    var manifest = InstallManifest.Load(r.Target.AddOnsPath);
                    var installer = new AddonInstaller(r.Target.AddOnsPath, r.Target.Product, manifest, OnProgress);

                    // Past this point the work is local and short (folder copies),
                    // so there is no cancellation check between the folders of one
                    // client: interrupting halfway is how you get an addon whose
                    // data addon is a release behind. The download is the long part
                    // and it is cancellable.
                    foreach (var item in r.Plan.Items)
                    {
                        SayScoped(Loc.Format("status.installingAddon", item.FolderName), true);
                        installer.InstallFolder(_package, item.FolderName);
                    }

                    // The extra addons each download on their own; between them is
                    // a clean stopping point.
                    foreach (var managed in r.Plan.ManagedItems)
                    {
                        if (_cancel.IsCancellationRequested) { WasCancelled = true; break; }

                        SayScoped(Loc.Format("status.installingAddon", managed.Entry.DisplayName), true);
                        ManagedAddonInstaller.InstallEntryAsync(
                                r.Target.AddOnsPath, r.Target.Product, managed.Entry, _github,
                                manifest, OnProgress, _options.Force, _cancel)
                            .GetAwaiter().GetResult();
                    }

                    if (WasCancelled) break;

                    if (r.Plan.SettingsNeedWriting)
                    {
                        SayScoped(Loc.Get("status.writingSettings"), true);
                        GameSettings.Apply(r.Target.AddOnsPath, m => SayScoped(m));
                    }

                    // Keep every installed folder's TOC in step with the client.
                    // Unconditional and idempotent, so a just-copied TOC that lags
                    // the client (V0.9.0's Vanilla TOC on Classic Era 11509) is
                    // corrected in the same run.
                    if (r.Plan.ClientInterface > 0)
                    {
                        bool announced = false;
                        foreach (string folder in InstalledFolders(r.Target.AddOnsPath, manifest))
                        {
                            if (TocSync.Desired(r.Target.AddOnsPath, folder, r.Target.Product,
                                                r.Plan.ClientInterface, out _) == null) continue;
                            if (!announced)
                            {
                                SayScoped(Loc.Format("status.syncingToc", r.Plan.ClientInterface), true);
                                announced = true;
                            }
                            if (TocSync.SyncInterface(r.Target.AddOnsPath, folder, r.Target.Product,
                                                      r.Plan.ClientInterface, m => SayScoped(m)))
                                r.Plan.TocInterfaceNeedsSync = true;
                        }
                    }

                    if (_options.InstallLoginTool && LoginToolInstaller.ClientSupported(r.Target.Product))
                    {
                        SayScoped(Loc.Format("status.loginTool", r.Target.DisplayName), true);
                        LoginToolInstaller.Install(r.Target.AddOnsPath, _github,
                                                   m => SayScoped(m), _options.Force, r.Target.Product);
                    }

                    manifest.Save(r.Target.AddOnsPath);
                    r.Target.RefreshInstalledVersion();

                    // Remember where this client actually lives, so a game outside
                    // the probed default locations is browsed to once and found by
                    // itself from now on. Written here — after a client installed
                    // cleanly — so a cancelled or failed run never leaves a folder
                    // on record.
                    PathMemory.Remember(r.Target.Product, r.Target.AddOnsPath);

                    // Close each client with an explicit verdict, so a multi-client
                    // run is audibly a sequence of finished steps.
                    Say(Loc.Format("status.clientOk", r.Target.DisplayName), true);
                }
                catch (OperationCanceledException)
                {
                    WasCancelled = true;
                    Logger.Info($"Cancelled during {r.Target.DisplayName}");
                    break;
                }
                catch (Exception ex)
                {
                    Logger.Error($"Install failed for {r.Target.DisplayName}", ex);
                    r.Error = ex;
                    Say(Loc.Format("status.clientFailed", r.Target.DisplayName, ex.Message), true);
                }
            }

            _scopeLabel = "";   // machine-wide steps belong to no single client

            if (WasCancelled)
            {
                Say(Loc.Get("status.cancelled"), true);
                return;
            }

            if (_options.SkipMachineWide)
            {
                Say(Loc.Get("status.done"), true);
                return;
            }

            // Machine-wide, so once per run rather than once per client.
            if (_options.InstallSapi2Sr)
            {
                Say(Loc.Get("status.sapi2sr"), true);
                try { Sapi2SrInstaller.Install(m => Say(m)); }
                catch (Exception ex) { Logger.Error("SAPI2SR install failed", ex); Say(ex.Message); }
            }
            if (_options.InstallWindowsVoices)
            {
                Say(Loc.Get("status.windowsVoices"), true);
                try { WindowsVoicesInstaller.Install(m => Say(m)); }
                catch (Exception ex) { Logger.Error("Windows voices failed", ex); Say(ex.Message); }
            }

            try
            {
                Shortcut.InstallPersistentCopy();
                Shortcut.CreateShortcuts(desktop: _options.DesktopShortcut, startMenu: true);
            }
            catch (Exception ex) { Logger.Error("Shortcut creation failed", ex); }

            Say(Loc.Get("status.done"), true);
        }

        private void OnProgress(InstallProgress p)
        {
            // The row key is (scope, addon, phase) — NOT the message text: the
            // download message embeds the running byte count and changes on every
            // tick, so keying on it would start a new row each time.
            string key = (!string.IsNullOrEmpty(p.Addon) && !string.IsNullOrEmpty(p.Phase))
                ? $"{_keyScope}|{p.Addon}|{p.Phase}"
                : null;

            // A percentage is only worth showing while it is still moving.
            string text = (p.Percent >= 0 && p.Percent < 100)
                ? $"{p.Message} ({p.Percent}%)"
                : p.Message;

            // Percentage ticks stay out of the screen reader: routing them through
            // would talk over everything else several times a second. The
            // heartbeat in ProgressForm still speaks one now and then.
            SayScoped(text, false, key);
        }

        /// <summary>
        /// Every addon folder of WowVision's in this AddOns folder: the main one
        /// plus whatever the manifest records (WowVision_MapData_TBC, …).
        /// </summary>
        private static IEnumerable<string> InstalledFolders(string addonsFolder, InstallManifest manifest)
        {
            var names = new List<string> { Config.PrimaryFolder };
            names.AddRange(manifest.InstalledTags.Keys.Where(k => !ManagedAddons.IsManagedKey(k)));
            return names.Distinct(StringComparer.OrdinalIgnoreCase)
                        .Where(n => Directory.Exists(Path.Combine(addonsFolder, n)));
        }

        /// <summary>
        /// Works out what one client needs: whether the release goes in, whether
        /// game settings must be written, and whether any TOC interface line has
        /// drifted from the client build.
        /// </summary>
        private InstallPlan BuildPlanFor(InstallTarget target, InstallManifest manifest)
        {
            string addonsFolder = target.AddOnsPath;
            var plan = new InstallPlan();
            var installer = new AddonInstaller(addonsFolder, target.Product, manifest, OnProgress);

            if (_options.Force)
            {
                // Reinstall all — but never overwrite a symlinked dev folder.
                plan.FirstInstall = !InstallTarget.AddonInstalled(addonsFolder);
                plan.AddonNeedsWork = !AddonInstaller.IsSymlinked(addonsFolder, Config.PrimaryFolder);
            }
            else
            {
                plan.AddonNeedsWork = installer.NeedsWork(Config.LatestTag, out bool firstInstall);
                plan.FirstInstall = firstInstall;
            }
            if (plan.FirstInstall) plan.NeedsGameClosed = true;

            // Extra addons: each client gets the packages that exist for it. Any
            // work here forces the game closed: these are whole-folder swaps of
            // addons the running client may hold open.
            if (ManagedAddons.AppliesTo(target))
            {
                var enabled = _options.EffectiveManaged();
                foreach (var entry in ManagedAddons.Entries)
                {
                    if (!enabled.TryGetValue(entry.PrefKey, out bool on) || !on) continue;
                    if (!ManagedAddons.AvailableFor(entry, target.Product)) continue;
                    bool installed = ManagedAddons.EntryInstalled(addonsFolder, target.Product, entry);
                    if (_options.Force ||
                        ManagedAddons.EntryNeedsWork(addonsFolder, target.Product, manifest, entry))
                    {
                        plan.ManagedItems.Add(new ManagedPlanItem { Entry = entry, FirstInstall = !installed });
                        plan.NeedsGameClosed = true;
                    }
                }
            }

            plan.SettingsIssues = GameSettings.CheckNeeded(addonsFolder);
            if (plan.SettingsIssues.Count > 0)
            {
                plan.SettingsNeedWriting = true;
                plan.NeedsGameClosed = true;
            }

            // TOC drift alone counts as work (so a pure "client got patched" run
            // isn't reported as up to date) but does NOT force the game closed — a
            // TOC is a tiny text file, safe to rewrite live and picked up on the
            // next restart. Symlinked dev folders are left alone.
            plan.ClientInterface = WowLocator.ClientInterface(addonsFolder, target.Product);
            if (plan.ClientInterface > 0)
            {
                foreach (string folder in InstalledFolders(addonsFolder, manifest))
                {
                    if (AddonInstaller.IsSymlinked(addonsFolder, folder)) continue;
                    string want = TocSync.Desired(addonsFolder, folder, target.Product,
                                                  plan.ClientInterface, out string cur);
                    if (want != null)
                        plan.TocInterfaceIssues.Add($"{folder}: {cur} -> {want}");
                }
                plan.TocInterfaceNeedsSync = plan.TocInterfaceIssues.Count > 0;
            }
            else
            {
                Logger.Warning($"Could not determine the interface version of {target.DisplayName}; skipping TOC sync.");
            }

            return plan;
        }

        /// <summary>
        /// The end-of-run summary: one section per client saying what it got, then
        /// the single next step. Only lines that apply are included, so the message
        /// stays short and truthful and a screen reader reads it top to bottom in
        /// one pass.
        /// </summary>
        public string ComposeSummary(List<TargetResult> results)
        {
            var blocks = new List<string>
            {
                HasWork(results) ? Loc.Get("summary.headline.done")
                                 : Loc.Get("summary.headline.upToDate"),
            };

            foreach (var r in results)
            {
                // Outcome first, identifiers and version numbers after. Heard
                // aloud, "Failed — Classic Era" tells you what you need to know in
                // the first word.
                var lines = new List<string>();

                if (r.Error != null)
                {
                    lines.Add(Loc.Format("summary.clientFailed", r.Target.DisplayName, r.Error.Message));
                }
                else if (r.Plan == null)
                {
                    lines.Add(Loc.Format("summary.clientFailed", r.Target.DisplayName,
                                         Loc.Get("summary.unknownError")));
                }
                else
                {
                    lines.Add(Loc.Format("summary.clientOk", r.Target.DisplayName));
                    foreach (var item in r.Plan.Items)
                        lines.Add(Loc.Format("summary.updated", item.FolderName,
                                             Config.SpokenVersion(Config.LatestTag, Config.LatestBuildDate)));
                    var manifest = InstallManifest.Load(r.Target.AddOnsPath);
                    foreach (var managed in r.Plan.ManagedItems)
                    {
                        var first = ManagedAddons.PackagesFor(managed.Entry, r.Target.Product).FirstOrDefault();
                        if (first != null && ManagedAddons.KnownUnavailable(manifest, first))
                        {
                            lines.Add(Loc.Format("managed.notForClient", managed.Entry.DisplayName, r.Target.DisplayName));
                            continue;
                        }
                        string ver = first == null ? "" : (ManagedAddons.Resolved(first).Version ?? "");
                        lines.Add(Loc.Format("summary.updated", managed.Entry.DisplayName,
                                             ManagedAddons.DisplayVersion(ver)));
                    }
                    if (r.Plan.Items.Count == 0 && r.Plan.ManagedItems.Count == 0)
                        lines.Add(r.Target.HasTestBuild
                            ? Loc.Format("summary.testBuildKept", InstallTarget.Spoken(r.Target.InstalledVersion))
                            : Loc.Get("summary.addonsCurrent"));
                    if (r.Plan.SettingsNeedWriting)
                        lines.Add(Loc.Get("summary.settings"));
                    if (r.Plan.TocInterfaceNeedsSync)
                        lines.Add(Loc.Format("summary.client", r.Plan.ClientInterface));
                    if (_options.InstallLoginTool && LoginToolInstaller.ClientSupported(r.Target.Product) &&
                        LoginToolInstaller.IsInstalled(r.Target.AddOnsPath))
                        lines.Add(Loc.Get("summary.loginTool"));
                }

                blocks.Add(string.Join(Environment.NewLine, lines));
            }

            // A rewritten TOC is only read at client start, not on /reload, so a
            // run that synced one asks for a restart too.
            bool restart = NeedsGameClosed(results) ||
                           results.Any(r => r.Plan != null && r.Plan.TocInterfaceNeedsSync);
            if (HasWork(results))
                blocks.Add(restart ? Loc.Get("summary.battlenet") : Loc.Get("summary.reload"));

            return string.Join(Environment.NewLine + Environment.NewLine, blocks);
        }

        public void Dispose() => _package?.Dispose();
    }
}
