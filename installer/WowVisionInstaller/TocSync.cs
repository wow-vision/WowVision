using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace WowVisionInstaller
{
    /// <summary>
    /// Keeps the "## Interface:" line of the TOC each client loads in step with
    /// that client's build (see <see cref="WowLocator.ClientInterface"/>). A
    /// client patch bumps the interface number (Classic Era 1.15.8 -> 1.15.9, i.e.
    /// 11508 -> 11509); the classic clients refuse an addon whose TOC does not
    /// name their EXACT build, and "Load out of date AddOns" (checkAddonVersion 0)
    /// does not cover that. The WowVision V0.9.0 zip is a live example: its
    /// WowVision_Vanilla.toc says 11508 while Classic Era runs 11509.
    ///
    /// What is rewritten, per client and addon folder:
    ///   * only the TOC this client loads (<see cref="WowLocator.TocFor"/>) — the
    ///     zip carries one TOC per client, and the others are not this client's
    ///     business;
    ///   * only the entries of this client's own game family
    ///     (<see cref="ClientInfo.OwnsInterface"/>): they are replaced by the
    ///     client's number. Entries of other families stay, so a shared plain TOC
    ///     like WowVision_MapData_TBC's "20506, 16001" keeps working on both;
    ///   * a plain TOC with no entry of this family is left alone — it was not
    ///     written for this client, and making it load there would change what
    ///     the addon's authors decided.
    /// A TOC that already names the client's number is never touched.
    ///
    /// Idempotent and BOM-safe; a symlinked/junctioned folder (a developer's git
    /// checkout) is never written through.
    /// </summary>
    public static class TocSync
    {
        // The first "## Interface:" directive line, anchored to line start and
        // stopping before the end-of-line chars so we never consume a trailing
        // \r / \n (keeps CRLF vs LF intact when we rewrite just the value).
        private static readonly Regex InterfaceLine =
            new Regex(@"^[ \t]*##[ \t]*Interface[ \t]*:[^\r\n]*", RegexOptions.Multiline);

        private static readonly byte[] Utf8Bom = { 0xEF, 0xBB, 0xBF };

        /// <summary>
        /// The interface value this client's TOC of the folder should carry, or
        /// null when nothing should change (already in step, no TOC, a plain TOC
        /// meant for other clients, or no client number known).
        /// <paramref name="current"/> is the value found ("" when unreadable).
        /// </summary>
        public static string Desired(string addonsFolder, string folderName, string product,
                                     int clientInterface, out string current)
        {
            current = "";
            var client = WowLocator.Client(product);
            if (client == null || clientInterface <= 0) return null;

            string toc = WowLocator.TocFor(addonsFolder, folderName, product, out bool isSuffixToc);
            if (toc == null) return null;

            try
            {
                var m = InterfaceLine.Match(ReadBody(toc, out _));
                if (!m.Success) return null;
                current = ValueAfterColon(m.Value);
            }
            catch (Exception ex)
            {
                Logger.Warning($"Could not read {folderName} TOC interface: {ex.Message}");
                return null;
            }

            return DesiredValue(current, client, clientInterface, isSuffixToc);
        }

        /// <summary>
        /// The rewrite rule on its own (no files), so the self-test can check it:
        /// replace this family's entries with the client number, keep the rest.
        /// </summary>
        internal static string DesiredValue(string current, ClientInfo client, int clientInterface, bool isSuffixToc)
        {
            var entries = new List<int>();
            foreach (string part in (current ?? "").Split(','))
                if (int.TryParse(part.Trim(), out int n)) entries.Add(n);

            if (entries.Contains(clientInterface)) return null;                    // in step
            bool hasFamily = entries.Any(client.OwnsInterface);
            if (!hasFamily && !isSuffixToc) return null;                           // not for this client

            var result = new List<int>();
            bool placed = false;
            foreach (int n in entries)
            {
                if (!client.OwnsInterface(n)) { result.Add(n); continue; }
                if (!placed) { result.Add(clientInterface); placed = true; }       // first family slot
            }
            if (!placed) result.Insert(0, clientInterface);

            return string.Join(", ", result);
        }

        /// <summary>
        /// Rewrites the interface line of this client's TOC of the folder when
        /// <see cref="Desired"/> says so. Returns true if a change was written.
        /// Preserves the UTF-8 BOM and the file's existing line endings.
        /// </summary>
        public static bool SyncInterface(string addonsFolder, string folderName, string product,
                                         int clientInterface, Action<string> report)
        {
            // Dev safety: never write through a symlink into a git checkout.
            if (AddonInstaller.IsSymlinked(addonsFolder, folderName))
            {
                Logger.Info($"{folderName}: symlinked — leaving TOC interface untouched.");
                return false;
            }

            string desired = Desired(addonsFolder, folderName, product, clientInterface, out string current);
            if (desired == null) return false;

            string toc = WowLocator.TocFor(addonsFolder, folderName, product, out _);
            try
            {
                string body = ReadBody(toc, out bool hadBom);

                // MatchEvaluator (not a replacement string) so "$" in a value could
                // never be treated as a substitution; limit to the first match.
                string updated = InterfaceLine.Replace(body, _ => "## Interface: " + desired, 1);

                var bytes = Encoding.UTF8.GetBytes(updated);
                using (var fs = new FileStream(toc, FileMode.Create, FileAccess.Write))
                {
                    if (hadBom) fs.Write(Utf8Bom, 0, Utf8Bom.Length);
                    fs.Write(bytes, 0, bytes.Length);
                }

                report?.Invoke(Loc.Format("toc.synced", Path.GetFileName(toc), current, desired));
                Logger.Info($"{Path.GetFileName(toc)}: TOC interface {current} -> {desired}.");
                return true;
            }
            catch (IOException ex)
            {
                // Locked by the running game — harmless, retried next run.
                Logger.Warning($"{folderName}: TOC in use, interface not updated ({ex.Message}).");
                return false;
            }
            catch (Exception ex)
            {
                Logger.Warning($"{folderName}: could not update TOC interface: {ex.Message}");
                return false;
            }
        }

        /// <summary>The current "## Interface:" value of this client's TOC of the folder, or null.</summary>
        public static string ReadInterface(string addonsFolder, string folderName, string product)
        {
            string toc = WowLocator.TocFor(addonsFolder, folderName, product, out _);
            if (toc == null) return null;
            try
            {
                var m = InterfaceLine.Match(ReadBody(toc, out _));
                return m.Success ? ValueAfterColon(m.Value) : null;
            }
            catch { return null; }
        }

        /// <summary>
        /// Reads the TOC as UTF-8, stripping and reporting a leading BOM ourselves
        /// (File.ReadAllText would swallow the BOM, so we couldn't round-trip it).
        /// </summary>
        private static string ReadBody(string toc, out bool hadBom)
        {
            byte[] raw = File.ReadAllBytes(toc);
            hadBom = raw.Length >= 3 && raw[0] == Utf8Bom[0]
                                     && raw[1] == Utf8Bom[1] && raw[2] == Utf8Bom[2];
            int off = hadBom ? Utf8Bom.Length : 0;
            return Encoding.UTF8.GetString(raw, off, raw.Length - off);
        }

        private static string ValueAfterColon(string line)
        {
            int colon = line.IndexOf(':');
            return colon >= 0 ? line.Substring(colon + 1).Trim() : "";
        }
    }
}
