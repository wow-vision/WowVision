using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Windows.Forms;

namespace WowVisionInstaller
{
    /// <summary>
    /// "What should be installed alongside WowVision?" — the installer's own
    /// language and the optional components.
    ///
    /// The important part is not the layout, it is the accessible names. Each
    /// control announces its label AND what it does, and the visible description
    /// says the same thing. (The Sku installer once had an explanation on screen
    /// that the checkbox's accessible name withheld — from exactly the users who
    /// could not see it.)
    ///
    /// The Sku page it comes from, without the voice-pack choice: WowVision's
    /// sounds are inside the one release zip. The extra-addons list is Sku's, and
    /// each line says for which of the chosen game versions an addon does not
    /// exist, so ticking it never promises something a client will not get.
    /// </summary>
    public class ComponentsForm : WizardForm
    {
        private Label _installerLangLabel;
        private ComboBox _installerLangCombo;
        private Label _channelLabel, _channelDesc;
        private ComboBox _channelCombo;

        // Combo order == this array.
        private static readonly Channel[] _channelOrder = { Channel.Beta, Channel.Stable };
        private CheckBox _forceCheck, _shortcutCheck, _sapi2srCheck, _windowsVoicesCheck, _loginToolCheck;
        private Label _forceDesc, _shortcutDesc, _sapi2srDesc, _windowsVoicesDesc, _loginToolDesc;
        private Label _managedLabel;
        private CheckedListBox _managedList;

        /// <summary>The clients ticked on the first page; decides what the list says.</summary>
        private readonly List<InstallTarget> _selected;

        // Combo order == this array, so adding a language is a one-line change
        // and no index literal anywhere has to be kept in step. Each entry is
        // named in its OWN language: someone looking for French is looking for
        // "Français", not for whatever the current UI language calls it.
        private static readonly Lang[] _langOrder = { Lang.En, Lang.De, Lang.Fr };

        private static string LangDisplayName(Lang l)
        {
            if (l == Lang.De) return "Deutsch";
            if (l == Lang.Fr) return "Français";
            return "English";
        }

        /// <summary>The chosen options. Valid once Result is Next.</summary>
        public InstallOptions Options { get; private set; } = new InstallOptions();

        public ComponentsForm(InstallOptions initial, List<InstallTarget> selected)
        {
            Options = initial ?? new InstallOptions();
            _selected = selected ?? new List<InstallTarget>();
            BuildContent();
            ApplyTexts();
        }

        private void BuildContent()
        {
            int y = ContentTop;

            _installerLangLabel = AddContentLabel(ContentLeft, y, ContentWidth, 18);
            y += 20;
            _installerLangCombo = new ComboBox
            {
                Location = new Point(ContentLeft, y),
                Size = new Size(240, 24),
                DropDownStyle = ComboBoxStyle.DropDownList,
            };
            foreach (var l in _langOrder)
                _installerLangCombo.Items.Add(LangDisplayName(l));
            _installerLangCombo.SelectedIndex = Math.Max(0, Array.IndexOf(_langOrder, Loc.Current));
            _installerLangCombo.SelectedIndexChanged += OnInstallerLanguageChanged;
            Controls.Add(_installerLangCombo);
            y += 40;

            // Stable or beta: one choice for every selected game version.
            _channelLabel = AddContentLabel(ContentLeft, y, ContentWidth, 18);
            y += 20;
            _channelCombo = new ComboBox
            {
                Location = new Point(ContentLeft, y),
                Size = new Size(ContentWidth, 24),
                DropDownStyle = ComboBoxStyle.DropDownList,
            };
            foreach (var c in _channelOrder) _channelCombo.Items.Add("");
            _channelCombo.SelectedIndex = Math.Max(0, Array.IndexOf(_channelOrder, Config.CurrentChannel));
            _channelCombo.SelectedIndexChanged += (s, e) => RefreshChannelTexts();
            Controls.Add(_channelCombo);
            y += 28;
            _channelDesc = AddContentLabel(ContentLeft + 22, y, ContentWidth - 22, 32);
            y += 40;

            AddOption(ref _shortcutCheck, ref _shortcutDesc, ref y, Options.DesktopShortcut);
            AddOption(ref _sapi2srCheck, ref _sapi2srDesc, ref y, Options.InstallSapi2Sr);
            AddOption(ref _windowsVoicesCheck, ref _windowsVoicesDesc, ref y, Options.InstallWindowsVoices);
            AddOption(ref _loginToolCheck, ref _loginToolDesc, ref y, Options.InstallLoginTool);
            AddOption(ref _forceCheck, ref _forceDesc, ref y, Options.Force);

            // Extra addons. A CheckedListBox rather than more checkbox+description
            // rows: it is one tab stop, arrow keys walk the entries, Space toggles —
            // and NVDA/JAWS announce item text and checked state natively.
            _managedLabel = AddContentLabel(ContentLeft, y, ContentWidth, 18);
            _managedLabel.Font = new Font(Font.FontFamily, 9.5f, FontStyle.Bold);
            y += 22;
            _managedList = new CheckedListBox
            {
                Location = new Point(ContentLeft, y),
                Size = new Size(ContentWidth, ManagedAddons.Entries.Count * 19 + 8),
                CheckOnClick = true,
                IntegralHeight = false,
                HorizontalScrollbar = true,
            };
            var enabled = Options.EffectiveManaged();
            foreach (var entry in ManagedAddons.Entries)
            {
                bool on = enabled.TryGetValue(entry.PrefKey, out bool v) ? v : entry.DefaultEnabled;
                _managedList.Items.Add(ManagedItemText(entry), on);
            }
            Controls.Add(_managedList);
            y += _managedList.Height + 12;

            SetContentHeight(y);
            ActiveControl = _channelCombo;
        }

        /// <summary>
        /// One list row: the addon's proper name, the version this run would
        /// install, and the chosen game versions it does not exist for, e.g.
        /// "AtlasLoot Continued — 12488 (not available for: Retail)". The names are
        /// proper nouns and stay untranslated.
        /// </summary>
        private string ManagedItemText(ManagedEntry entry)
        {
            string version = ManagedAddons.Resolved(entry.Packages[0]).Version ?? "";
            string text = $"{entry.DisplayName} — {ManagedAddons.DisplayVersion(version)}";
            var missing = _selected.Where(t => !ManagedAddons.AvailableFor(entry, t.Product))
                                   .Select(t => t.DisplayName).ToList();
            if (missing.Count > 0)
                text += " (" + Loc.Format("managed.notAvailable", string.Join(", ", missing)) + ")";
            return text;
        }

        /// <summary>Adds a checkbox plus its own description label underneath.</summary>
        private void AddOption(ref CheckBox check, ref Label desc, ref int y, bool initial)
        {
            check = new CheckBox
            {
                Location = new Point(ContentLeft, y),
                Size = new Size(ContentWidth, 22),
                Font = new Font(Font.FontFamily, 9.5f, FontStyle.Bold),
                Checked = initial,
            };
            Controls.Add(check);
            y += 22;

            desc = AddContentLabel(ContentLeft + 22, y, ContentWidth - 22, 32);
            y += 40;
        }

        private void OnInstallerLanguageChanged(object sender, EventArgs e)
        {
            int i = _installerLangCombo.SelectedIndex;
            Loc.Set(i >= 0 && i < _langOrder.Length ? _langOrder[i] : Lang.En);
            ApplyTexts();
        }

        private void ApplyTexts()
        {
            Text = Loc.Get("app.title") + " " + InstallerVersion();
            HeadingLabel.Text = Loc.Get("components.heading");
            BodyLabel.Text = Loc.Get("components.body");
            BackButton.Text = Loc.Get("nav.back");
            NextButton.Text = Loc.Get("nav.install");

            _installerLangLabel.Text = Loc.Get("ui.installerLanguage");
            _installerLangCombo.AccessibleName = Loc.Get("acc.installerLanguage");

            _channelLabel.Text = Loc.Get("channel.label");
            int keep = _channelCombo.SelectedIndex;
            for (int i = 0; i < _channelOrder.Length; i++)
                _channelCombo.Items[i] = Loc.Get(_channelOrder[i] == Channel.Beta ? "channel.beta" : "channel.stable");
            _channelCombo.SelectedIndex = keep;
            RefreshChannelTexts();

            SetOptionText(_shortcutCheck, _shortcutDesc, "shortcut");
            SetOptionText(_sapi2srCheck, _sapi2srDesc, "sapi2sr");
            SetOptionText(_windowsVoicesCheck, _windowsVoicesDesc, "windowsVoices");
            SetOptionText(_loginToolCheck, _loginToolDesc, "loginTool");
            SetOptionText(_forceCheck, _forceDesc, "force");

            _managedLabel.Text = Loc.Get("managed.label");
            _managedList.AccessibleName = Loc.Get("managed.acc");
            // Re-worded for a language switch; the ticks are put back explicitly
            // rather than trusting the list to keep them across the replacement.
            for (int i = 0; i < ManagedAddons.Entries.Count; i++)
            {
                bool on = _managedList.GetItemChecked(i);
                _managedList.Items[i] = ManagedItemText(ManagedAddons.Entries[i]);
                _managedList.SetItemChecked(i, on);
            }

            AnnouncePage();
        }

        private Channel SelectedChannel =>
            _channelOrder[Math.Max(0, Math.Min(_channelOrder.Length - 1, _channelCombo.SelectedIndex))];

        /// <summary>
        /// The description under the channel list says what the selected entry
        /// means, and the list's accessible name carries it, so arrowing to
        /// "Stable" explains itself.
        /// </summary>
        private void RefreshChannelTexts()
        {
            _channelDesc.Text = Loc.Get(SelectedChannel == Channel.Beta ? "channel.betaDesc" : "channel.stableDesc");
            _channelCombo.AccessibleName = $"{Loc.Get("channel.acc")}. {_channelDesc.Text}";
        }

        /// <summary>
        /// Applies an option's label and description, and composes the two into
        /// the accessible name so focusing the checkbox explains it.
        /// </summary>
        private static void SetOptionText(CheckBox check, Label desc, string key)
        {
            check.Text = Loc.Get("opt." + key + ".label");
            desc.Text = Loc.Get("opt." + key + ".desc");
            check.AccessibleName = $"{check.Text}. {desc.Text}";
        }

        protected override void OnNext()
        {
            var managed = new Dictionary<string, bool>(StringComparer.OrdinalIgnoreCase);
            for (int i = 0; i < ManagedAddons.Entries.Count; i++)
                managed[ManagedAddons.Entries[i].PrefKey] = _managedList.GetItemChecked(i);
            ManagedPrefs.Save(managed);   // one-click runs reuse the same choices

            // A changed channel takes effect now: the release to install is the
            // other channel's, so it is looked up again (a second or two).
            if (SelectedChannel != Config.CurrentChannel)
            {
                Cursor previous = Cursor;
                Cursor = Cursors.WaitCursor;
                try
                {
                    Config.SetChannel(SelectedChannel);
                    GitHubClient.ResolveAndAdoptLatestRelease();
                }
                finally { Cursor = previous; }
                Logger.Info($"Channel changed to {Config.CurrentChannel}.");
            }
            ChannelPrefs.Save(Config.CurrentChannel);

            Options = new InstallOptions
            {
                DesktopShortcut = _shortcutCheck.Checked,
                InstallSapi2Sr = _sapi2srCheck.Checked,
                InstallWindowsVoices = _windowsVoicesCheck.Checked,
                InstallLoginTool = _loginToolCheck.Checked,
                Force = _forceCheck.Checked,
                ManagedEnabled = managed,
            };
            Result = WizardResult.Next;
            Close();
        }
    }
}
