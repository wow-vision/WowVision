using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;

namespace WowVisionInstaller
{
    /// <summary>
    /// The release zip, downloaded and extracted ONCE per run and then copied into
    /// every selected client. The Sku installer fetched each addon per client;
    /// WowVision is one ~80 MB zip that is identical for all five clients, so a
    /// user installing into three of them downloads it once instead of three times.
    ///
    /// Every top-level folder of the zip is an addon folder (WowVision, and from
    /// the release after V0.9.0 on also WowVision_MapData_TBC). The list is read
    /// from the zip itself, so a folder the maintainers add or drop later needs no
    /// installer change. A zip without the <see cref="Config.PrimaryFolder"/> is
    /// refused: installing it would leave clients with a WowVision whose version
    /// nothing can read.
    ///
    /// Lives under <see cref="AddonInstaller.TempRoot"/>; <see cref="Dispose"/>
    /// removes it, success or failure, so 170 MB never linger in %TEMP%.
    /// </summary>
    public sealed class ReleasePackage : IDisposable
    {
        public string Tag { get; private set; }
        public string AssetName { get; private set; }

        /// <summary>
        /// Beta only: the id of the zip that was actually downloaded (it may be a
        /// newer upload than the one checked at startup), and its upload time when
        /// that is the build checked. Null for a stable release.
        /// </summary>
        public string Build { get; private set; }
        public DateTime? BuildDate { get; private set; }

        /// <summary>Folder holding the extracted top-level addon folders.</summary>
        public string Root { get; private set; }

        /// <summary>The addon folders in the zip, primary first.</summary>
        public List<string> Folders { get; private set; } = new List<string>();

        private string _zipPath;

        private ReleasePackage() { }

        /// <summary>
        /// Downloads and extracts <paramref name="assetName"/> from release
        /// <paramref name="tag"/>. Cancellable during the download (the long
        /// part); throws on any failure after cleaning up.
        /// </summary>
        public static async Task<ReleasePackage> DownloadAsync(GitHubClient github, string tag, string assetName,
                                                               Action<InstallProgress> report,
                                                               CancellationToken cancel)
        {
            report = report ?? (_ => { });
            var pkg = new ReleasePackage { Tag = tag, AssetName = assetName };
            try
            {
                Directory.CreateDirectory(AddonInstaller.TempRoot);
                pkg._zipPath = Path.Combine(AddonInstaller.TempRoot, assetName);
                pkg.Root = Path.Combine(AddonInstaller.TempRoot, "package_" + Guid.NewGuid().ToString("N"));

                string url = GitHubClient.BuildAddonDownloadUrl(tag, assetName);
                Logger.Info($"Downloading {url}");
                string label = Config.DisplayName;
                int lastPct = -2;
                long lastMb = -1;
                string servedId = await github.DownloadFileWithIdAsync(url, pkg._zipPath, (done, total) =>
                {
                    int pct = total > 0 ? (int)(done * 100 / total) : -1;
                    long mbDone = done / 1048576;

                    // Throttle: the callback fires per 64 KB chunk. Only surface a
                    // line when the percentage moves (or, for unknown size, each
                    // whole MB) so we don't flood the log / screen reader.
                    bool changed = total > 0 ? (pct != lastPct) : (mbDone != lastMb);
                    if (!changed) return;
                    lastPct = pct;
                    lastMb = mbDone;

                    string mb = total > 0 ? $"{mbDone} / {total / 1048576} MB" : $"{mbDone} MB";
                    report(new InstallProgress { Addon = label, Phase = "download", Percent = pct,
                        Message = Loc.Format("ai.downloading", label, mb) });
                }, cancel);

                cancel.ThrowIfCancellationRequested();

                if (AddonInstaller.IsBeta(tag))
                {
                    pkg.Build = servedId ?? Config.LatestBuild;
                    pkg.BuildDate = string.Equals(pkg.Build, Config.LatestBuild, StringComparison.OrdinalIgnoreCase)
                        ? Config.LatestBuildDate : null;
                    Logger.Info($"Beta build downloaded: {pkg.Build ?? "(unknown)"}.");
                }

                report(new InstallProgress { Addon = label, Phase = "extract", Percent = -1,
                    Message = Loc.Format("ai.extracting", label) });
                Directory.CreateDirectory(pkg.Root);
                ZipFile.ExtractToDirectory(pkg._zipPath, pkg.Root);
                TryDelete(pkg._zipPath);   // extracted; the zip itself is no longer needed

                pkg.Folders = Directory.GetDirectories(pkg.Root)
                    .Select(Path.GetFileName)
                    .OrderBy(n => string.Equals(n, Config.PrimaryFolder, StringComparison.OrdinalIgnoreCase) ? 0 : 1)
                    .ThenBy(n => n, StringComparer.OrdinalIgnoreCase)
                    .ToList();

                if (!pkg.Folders.Exists(n => string.Equals(n, Config.PrimaryFolder, StringComparison.OrdinalIgnoreCase)))
                    throw new InvalidDataException(Loc.Format("ai.noPrimary", assetName, Config.PrimaryFolder));

                Logger.Info($"Release {tag} holds: {string.Join(", ", pkg.Folders)}");
                report(new InstallProgress { Addon = label, Phase = "ready", Percent = 100,
                    Message = Loc.Format("ai.packageReady", label, Config.SpokenVersion(tag, pkg.BuildDate),
                                         string.Join(", ", pkg.Folders)) });
                return pkg;
            }
            catch
            {
                pkg.Dispose();
                throw;
            }
        }

        /// <summary>Where one addon folder of the package sits on disk.</summary>
        public string SourceOf(string folderName) => Path.Combine(Root, folderName);

        public void Dispose()
        {
            TryDelete(_zipPath);
            try { if (Root != null && Directory.Exists(Root)) Directory.Delete(Root, true); }
            catch (Exception ex) { Logger.Warning($"Could not delete {Root}: {ex.Message}"); }
        }

        private static void TryDelete(string file)
        {
            try { if (file != null && File.Exists(file)) File.Delete(file); } catch { }
        }
    }
}
