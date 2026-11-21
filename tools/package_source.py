"""Create a submission source archive without build outputs or local secrets."""
from pathlib import Path
import zipfile

root = Path(__file__).resolve().parents[1]
output = root / 'deliverables' / 'soundify-source.zip'
roots = ['lib', 'android', 'assets', 'test', 'integration_test', 'tools', 'docs', 'video']
files = ['README.md', 'SUBMISSION_LINKS.txt', 'pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', '.gitignore', '.gitattributes', '.metadata']
excluded_dirs = {'.gradle', '.kotlin', 'build', '.dart_tool', '.git', '.idea', '__pycache__', '.cxx'}
excluded_files = {'local.properties', 'key.properties', '.DS_Store'}
excluded_names = {'DEMO_SCRIPT.fa.md', 'recording-guide.fa.md'}

def eligible(path):
    relative = path.relative_to(root)
    return path.is_file() and not any(part in excluded_dirs for part in relative.parts) and \
        path.name not in excluded_files | excluded_names and path.suffix.lower() not in {'.jks', '.keystore', '.mp4', '.zip', '.iml', '.apk'}

def main():
    output.parent.mkdir(exist_ok=True)
    paths = [root / f for f in files if (root / f).exists()]
    for folder in roots:
        paths.extend(p for p in (root / folder).rglob('*') if eligible(p))
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for p in sorted(set(paths)):
            archive.write(p, p.relative_to(root).as_posix())
    with zipfile.ZipFile(output) as archive:
        assert archive.testzip() is None
        assert not any('.private' in n or n.endswith('key.properties') or '/build/' in n for n in archive.namelist())
    print(f'Packaged {len(paths)} source files: {output.name} ({output.stat().st_size:,} bytes)')

if __name__ == '__main__':
    main()
