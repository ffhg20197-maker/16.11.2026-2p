#!/usr/bin/env python3
"""WordPress core integrity monitor: official MD5 checksums or local SHA-256 baseline."""
import argparse, hashlib, json, logging, sys, urllib.error, urllib.request
from pathlib import Path
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
def digest(path):
    sha=hashlib.sha256(); md5=hashlib.md5()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024*1024), b""):
            sha.update(chunk); md5.update(chunk)
    return sha.hexdigest(), md5.hexdigest()
def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root",required=True); parser.add_argument("--version",required=True)
    parser.add_argument("--locale",default="en_US"); parser.add_argument("--baseline")
    args=parser.parse_args(); root=Path(args.root).resolve()
    if not root.is_dir(): parser.error("--root must be an existing directory")
    if args.baseline: expected=json.loads(Path(args.baseline).read_text(encoding="utf-8"))
    else:
        url=f"https://api.wordpress.org/core/checksums/1.0/?version={args.version}&locale={args.locale}"
        try:
            request=urllib.request.Request(url,headers={"User-Agent":"CMS-Shield-FIM/1.0"})
            with urllib.request.urlopen(request,timeout=20) as response: expected=json.load(response)
        except (urllib.error.URLError,json.JSONDecodeError) as error:
            logging.error("Checksum API unavailable: %s",error); return 2
    changed=[]; missing=[]; checked=0
    for relative, expected_hash in expected.items():
        path=(root/relative).resolve()
        if root not in path.parents and path!=root:
            logging.warning("Unsafe checksum path skipped: %s",relative); continue
        if not path.is_file(): missing.append(relative); continue
        checked+=1; sha,md5=digest(path); expected_hash=str(expected_hash).lower()
        actual=sha if len(expected_hash)==64 else md5
        if actual.lower()!=expected_hash: changed.append(relative)
    for name in changed: logging.error("HASH MISMATCH %s",name)
    for name in missing: logging.warning("MISSING %s",name)
    logging.info("checked=%d changed=%d missing=%d",checked,len(changed),len(missing))
    return 1 if changed else 0
if __name__=="__main__": sys.exit(main())
