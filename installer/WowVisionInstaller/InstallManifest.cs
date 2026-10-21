using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

namespace WowVisionInstaller
{
    /// <summary>
    /// Tiny record of what we installed, written as JSON into the AddOns folder
    /// (<see cref="Config.ManifestFileName"/>):
    ///   "addons": folder or extra-addon package key -&gt; release tag it came from;
    ///   "builds": WowVision folder -&gt; beta build it came from, "id|yyyy-MM-dd".
    /// The tag lets a routine "check for updates" skip the download when it hasn't
    /// moved. The beta's tag never moves ("beta"), so its build id is what tells
    /// one beta from the next (see <see cref="Config.LatestBuild"/>).
    ///
    /// Hand-rolled JSON (no Newtonsoft dependency) — the shape is flat and tiny:
    ///   { "version": 1,
    ///     "addons": { "WowVision": "beta", "CurseQuestie": "bundle/v12.1.0+v1.0.6" },
    ///     "builds": { "WowVision": "b107f80f-…|2026-10-16" } }
    /// </summary>
    public class InstallManifest
    {
        public Dictionary<string, string> InstalledTags { get; } =
            new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        public Dictionary<string, string> InstalledBuilds { get; } =
            new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

        public string GetTag(string folderName) =>
            InstalledTags.TryGetValue(folderName, out var tag) ? tag : null;

        public void SetTag(string folderName, string tag) =>
            InstalledTags[folderName] = tag;

        /// <summary>The beta build id a folder came from, or null (a release, or unknown).</summary>
        public string GetBuild(string folderName) =>
            InstalledBuilds.TryGetValue(folderName, out var b) ? b.Split('|')[0] : null;

        /// <summary>When that beta build was uploaded, or null.</summary>
        public DateTime? GetBuildDate(string folderName)
        {
            if (!InstalledBuilds.TryGetValue(folderName, out var b)) return null;
            var parts = b.Split('|');
            return parts.Length > 1 && DateTime.TryParse(parts[1], System.Globalization.CultureInfo.InvariantCulture,
                                                          System.Globalization.DateTimeStyles.AssumeUniversal |
                                                          System.Globalization.DateTimeStyles.AdjustToUniversal, out var d)
                ? d : (DateTime?)null;
        }

        /// <summary>Records the beta build of a folder; a null id clears it (a release went in).</summary>
        public void SetBuild(string folderName, string id, DateTime? date)
        {
            if (string.IsNullOrEmpty(id)) { InstalledBuilds.Remove(folderName); return; }
            InstalledBuilds[folderName] = id + (date.HasValue ? "|" + date.Value.ToString("yyyy-MM-dd") : "");
        }

        public static InstallManifest Load(string addonsFolder)
        {
            var manifest = new InstallManifest();
            string path = Path.Combine(addonsFolder, Config.ManifestFileName);
            if (!File.Exists(path))
                return manifest;

            try
            {
                string json = File.ReadAllText(path);
                ReadObject(json, "addons", manifest.InstalledTags);
                ReadObject(json, "builds", manifest.InstalledBuilds);
            }
            catch (Exception ex)
            {
                Logger.Warning($"Could not read manifest, treating as empty: {ex.Message}");
            }

            return manifest;
        }

        /// <summary>
        /// Minimal parse: the "key": "value" pairs of one flat object. Good enough
        /// for our own file; values never contain quotes.
        /// </summary>
        private static void ReadObject(string json, string name, Dictionary<string, string> into)
        {
            int idx = json.IndexOf("\"" + name + "\"", StringComparison.OrdinalIgnoreCase);
            if (idx < 0) return;
            int brace = json.IndexOf('{', idx);
            int end = brace >= 0 ? json.IndexOf('}', brace) : -1;
            if (brace < 0 || end < 0) return;

            foreach (Match m in Regex.Matches(json.Substring(brace + 1, end - brace - 1), "\"([^\"]*)\"\\s*:\\s*\"([^\"]*)\""))
                if (m.Groups[1].Value.Length > 0)
                    into[m.Groups[1].Value] = m.Groups[2].Value;
        }

        public void Save(string addonsFolder)
        {
            string path = Path.Combine(addonsFolder, Config.ManifestFileName);
            var sb = new StringBuilder();
            sb.AppendLine("{");
            sb.AppendLine("  \"version\": 1,");
            WriteObject(sb, "addons", InstalledTags, last: false);
            WriteObject(sb, "builds", InstalledBuilds, last: true);
            sb.AppendLine("}");

            try
            {
                File.WriteAllText(path, sb.ToString());
            }
            catch (Exception ex)
            {
                Logger.Warning($"Could not write manifest: {ex.Message}");
            }
        }

        private static void WriteObject(StringBuilder sb, string name, Dictionary<string, string> map, bool last)
        {
            sb.AppendLine($"  \"{name}\": {{");
            int i = 0;
            foreach (var kv in map)
            {
                string comma = (++i < map.Count) ? "," : "";
                sb.AppendLine($"    \"{kv.Key}\": \"{kv.Value}\"{comma}");
            }
            sb.AppendLine(last ? "  }" : "  },");
        }
    }
}
