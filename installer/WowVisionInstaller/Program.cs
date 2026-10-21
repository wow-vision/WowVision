using System;
using System.Collections.Generic;
using System.Security.Principal;
using System.Windows.Forms;

namespace WowVisionInstaller
{
    internal static class Program
    {
        [STAThread]
        private static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            Loc.Init(); // English/German/French, auto-detected from the OS UI culture
            Logger.Info("WowVision Installer starting…");
            Logger.Info($"Admin: {IsAdmin()}, Lang: {Loc.Current}");

            // CLI: an explicit AddOns path can be passed as the first non-flag arg.
            string pathArg = null;
            foreach (var a in args)
                if (!a.StartsWith("/") && !a.StartsWith("-"))
                    pathArg = a;

            if (!IsAdmin())
            {
                // We still let it run (a user-writable AddOns folder is possible),
                // but warn — writing under Program Files will fail without elevation.
                Logger.Warning("Not running as administrator.");
            }

            // Keep the updater itself current, before anything else happens.
            //
            // First, because a self-update ends in a restart: asking later would
            // mean discarding choices the user had already made, and a window that
            // disappears and comes back mid-install is exactly the sort of thing
            // that cannot be followed by ear. It is also the cheapest possible
            // check — a two-line text file.
            //
            // Every branch here falls through to a normal run. Offline, no version
            // file published, hash mismatch, user says no: the installer carries on
            // with the exe that is already here and can still install WowVision.
            // Stable or beta: one remembered choice for every game version. Read
            // first, because the installer's own update follows it too (the beta
            // release carries the newest installer build).
            Config.SetChannel(ChannelPrefs.Load());
            Logger.Info($"Channel: {Config.CurrentChannel}");

            SelfUpdater.CleanUpPreviousVersion(args);

            if (SelfUpdater.ShouldCheck(args))
            {
                var offer = SelfUpdater.Check();
                if (offer != null)
                {
                    var selfPrompt = new SelfUpdatePromptForm(offer);
                    Application.Run(selfPrompt);

                    if (selfPrompt.Choice == SelfUpdateChoice.Restart)
                    {
                        SelfUpdater.RestartAndExit(args);
                        return;
                    }
                }
            }

            // Discover the newest WowVision release from the github.com "latest"
            // redirect so this exe keeps finding releases published after it was
            // built. Must run before anything reads Config.LatestTag — which the
            // opening screen does, to say whether an update exists. On failure the
            // build-time pin stays in effect.
            GitHubClient.ResolveAndAdoptLatestRelease();

            // Resolve the extra addons' newest releases too (Questie, DBM, BugSack,
            // Pawn — the ones with GitHub releases), in parallel and time-boxed;
            // anything unresolved stays on its baked-in pin. Runs before the
            // opening screen so it can report their pending updates.
            using (var github = new GitHubClient())
                ManagedAddons.ResolveAll(github, TimeSpan.FromSeconds(10));

            var targets = InstallTarget.BuildAll();
            ApplyPathArgument(targets, pathArg);

            foreach (var t in targets)
                Logger.Info($"Target {t.Product}: path={t.AddOnsPath ?? "(none)"}, " +
                            $"installed={t.InstalledVersion ?? "(none)"}, latest={Config.LatestTag}");

            // Loop, so that Back on the wizard's first page returns to the opening
            // screen instead of dropping the user out of the installer.
            while (true)
            {
                var prompt = new UpdatePromptForm(targets);
                Application.Run(prompt);

                if (prompt.Choice == UpdateChoice.UpdateNow)
                {
                    RunOneClick(prompt.OneClickTargets);
                    return;
                }

                if (prompt.Choice == UpdateChoice.Customize)
                {
                    if (RunWizard(targets)) return;
                    continue;   // Back from the first wizard page — reopen the start
                }

                Logger.Info("User closed the opening screen without acting.");
                return;
            }
        }

        /// <summary>
        /// Honours an AddOns path passed on the command line by filing it under
        /// the client it belongs to, so the rest of the wizard treats it as that
        /// client rather than as an anonymous folder.
        /// </summary>
        private static void ApplyPathArgument(List<InstallTarget> targets, string pathArg)
        {
            if (string.IsNullOrEmpty(pathArg)) return;

            string resolved = WowLocator.ResolveUserPickedFolder(pathArg);
            if (resolved == null)
            {
                Logger.Warning($"Ignoring unrecognised path argument: {pathArg}");
                return;
            }

            string product = WowLocator.ProductForAddOnsFolder(resolved);
            var target = targets.Find(t => t.Product == product) ?? targets[0];
            target.AddOnsPath = resolved;
            target.AutoDetected = false;
            target.RefreshInstalledVersion();
            Logger.Info($"Path argument applied to {target.Product}: {resolved}");
        }

        /// <summary>"Update now": no further questions, the recommended options.</summary>
        private static void RunOneClick(List<InstallTarget> selected)
        {
            if (selected == null || selected.Count == 0)
            {
                Logger.Warning("One-click update requested with no usable target.");
                return;
            }

            Logger.Info("User chose the one-click update.");
            Application.Run(new ProgressForm(selected, new InstallOptions()));
        }

        /// <summary>
        /// The full wizard: which clients, where they live, what to include, then
        /// the run. Written as a step loop rather than nested calls so Back works
        /// at every stage.
        ///
        /// Returns true when the installer is finished with the user (they ran the
        /// install, or cancelled outright), false when they pressed Back off the
        /// first page and should land on the opening screen again.
        /// </summary>
        private static bool RunWizard(List<InstallTarget> targets)
        {
            Logger.Info("User chose to change what gets installed.");

            List<InstallTarget> selected = null;
            var options = new InstallOptions();
            int step = 0;

            while (true)
            {
                switch (step)
                {
                    case 0:
                    {
                        var form = new VersionSelectForm(targets);
                        Application.Run(form);
                        if (form.Result == WizardResult.Back) return false;  // back to the start
                        if (form.Result != WizardResult.Next) return true;   // cancelled
                        selected = form.Selected;
                        step = 1;
                        break;
                    }

                    case 1:
                    {
                        // Always shown, listing exactly the clients that were
                        // ticked, so the user can always see — and correct — where
                        // the install is going.
                        var form = new FolderConfirmForm(selected);
                        Application.Run(form);
                        if (form.Result == WizardResult.Back) { step = 0; break; }
                        if (form.Result != WizardResult.Next) return true;
                        step = 2;
                        break;
                    }

                    case 2:
                    {
                        var form = new ComponentsForm(options, selected);
                        Application.Run(form);
                        if (form.Result == WizardResult.Back) { step = 1; break; }
                        if (form.Result != WizardResult.Next) return true;
                        options = form.Options;
                        step = 3;
                        break;
                    }

                    default:
                        Application.Run(new ProgressForm(selected, options));
                        return true;
                }
            }
        }

        private static bool IsAdmin()
        {
            try
            {
                using (var id = WindowsIdentity.GetCurrent())
                    return new WindowsPrincipal(id).IsInRole(WindowsBuiltInRole.Administrator);
            }
            catch { return false; }
        }
    }
}
