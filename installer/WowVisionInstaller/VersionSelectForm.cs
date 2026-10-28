using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;

namespace WowVisionInstaller
{
    /// <summary>
    /// "Which WoW versions should WowVision be installed into?" — one checkbox per
    /// supported client, so several clients can be done in a single run instead of
    /// walking the whole installer once per client.
    ///
    /// Every supported client is listed whether or not it was auto-detected. An
    /// undetected one can still be ticked; the next page then asks where it lives.
    /// That ordering is the point: the user says what they WANT first, and the
    /// installer does the finding afterwards — rather than a Browse button sitting
    /// on the front page as if locating folders were the user's job.
    ///
    /// Each checkbox folds its status line into
    /// <see cref="Control.AccessibleName"/>, so focusing "Anniversary (TBC)" reads
    /// the whole story — "WowVision 0.8.0 installed, 0.9.0 available" — rather
    /// than just a bare name the user then has to go and interpret.
    /// </summary>
    public class VersionSelectForm : WizardForm
    {
        private readonly List<InstallTarget> _targets;
        private readonly List<CheckBox> _checks = new List<CheckBox>();
        private readonly List<Label> _descriptions = new List<Label>();

        /// <summary>The clients the user ticked. Valid once Result is Next.</summary>
        public List<InstallTarget> Selected { get; private set; } = new List<InstallTarget>();

        public VersionSelectForm(List<InstallTarget> targets)
        {
            _targets = targets;
            BuildContent();
            ApplyTexts();
        }

        private void BuildContent()
        {
            int y = ContentTop;

            foreach (var t in _targets)
            {
                var check = new CheckBox
                {
                    Location = new Point(ContentLeft, y),
                    Size = new Size(ContentWidth, 24),
                    Font = new Font(Font.FontFamily, 9.5f, FontStyle.Bold),
                    // Default: tick the clients that already have WowVision. If
                    // none do, this is a first install and we pre-tick every client
                    // we actually found, which is the overwhelmingly common intent.
                    Checked = t.HasAddon || (!AnyTargetHasAddon() && t.ClientFound),
                };
                check.CheckedChanged += (s, e) => RefreshAccessibleNames();
                Controls.Add(check);
                _checks.Add(check);
                y += 26;

                var desc = AddContentLabel(ContentLeft + 22, y, ContentWidth - 22, 34);
                _descriptions.Add(desc);
                y += 44;
            }

            SetContentHeight(y);
            ActiveControl = _checks.Count > 0 ? (Control)_checks[0] : NextButton;
        }

        private bool AnyTargetHasAddon() => _targets.Exists(t => t.HasAddon);

        private void ApplyTexts()
        {
            HeadingLabel.Text = Loc.Get("versions.heading");
            BodyLabel.Text = Loc.Get("versions.body");
            BackButton.Text = Loc.Get("nav.back");
            NextButton.Text = Loc.Get("nav.next");

            for (int i = 0; i < _targets.Count; i++)
            {
                _checks[i].Text = _targets[i].DisplayName;
                _descriptions[i].Text = _targets[i].StatusLine();
            }

            RefreshAccessibleNames();
            AnnouncePage();
        }

        /// <summary>
        /// Recomposes each checkbox's accessible name from its label plus its
        /// status line. Re-run whenever a tick changes so the announcement never
        /// describes a stale state.
        /// </summary>
        private void RefreshAccessibleNames()
        {
            for (int i = 0; i < _targets.Count; i++)
                _checks[i].AccessibleName = $"{_checks[i].Text}. {_descriptions[i].Text}";
        }

        protected override void OnNext()
        {
            var picked = new List<InstallTarget>();
            for (int i = 0; i < _targets.Count; i++)
                if (_checks[i].Checked) picked.Add(_targets[i]);

            // Nothing ticked: say so out loud rather than disabling Next. A
            // disabled button leaves a screen-reader user stuck with no clue why.
            if (picked.Count == 0)
            {
                MessageBox.Show(this, Loc.Get("versions.needOne.text"),
                    Loc.Get("versions.needOne.title"),
                    MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            Selected = picked;
            Logger.Info($"Version selection: {string.Join(", ", picked.ConvertAll(t => t.Product))}");
            Result = WizardResult.Next;
            Close();
        }
    }
}
