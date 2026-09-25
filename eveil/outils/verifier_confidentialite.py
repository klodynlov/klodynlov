"""Garde-fou de confidentialité : le code Swift de la suite Éveil ne doit rien envoyer.

Promesse produit : aucune donnée ne quitte l'iPad, aucun traçage, aucun son
stocké. Ce script la rend VÉRIFIABLE à chaque modification (et en CI) :

- interdit : réseau (URLSession, NWConnection…), URL http(s) dans le code,
  SDK d'analytics/publicité/crash, identifiant publicitaire, CloudKit,
  enregistrement audio sur disque (AVAudioRecorder, AVAudioFile en écriture),
  reconnaissance vocale serveur (`requiresOnDeviceRecognition = false`) ;
- exigé : toute requête Speech force `requiresOnDeviceRecognition = true` ;
  toute configuration SwiftData déclare `cloudKitDatabase: .none`.

Usage : python3 eveil/outils/verifier_confidentialite.py [racine]   (défaut : eveil/ios)
Code de sortie 1 si une règle est violée. Stdlib uniquement.
"""
from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path

FORBIDDEN: list[tuple[str, str]] = [
    (r"\bURLSession\b", "appel réseau (URLSession)"),
    (r"\bURLRequest\b", "requête réseau (URLRequest)"),
    (r"\bNW(Connection|Listener|Browser)\b", "réseau bas niveau (Network.framework)"),
    (r"\bhttps?://", "URL dans le code"),
    (r"^\s*import\s+(Firebase\w*|GoogleMobileAds|AdSupport|AppTrackingTransparency|Mixpanel|Amplitude\w*"
     r"|Sentry|Bugsnag|Crashlytics|FBSDK\w*|AppsFlyer\w*|Adjust\w*|CloudKit)\b",
     "SDK tiers / suivi / CloudKit"),
    (r"\b(ASIdentifierManager|ATTrackingManager)\b", "identifiant publicitaire / suivi"),
    (r"\bCKContainer\b", "CloudKit"),
    (r"cloudKitDatabase:\s*\.(automatic|private)", "synchronisation iCloud de SwiftData"),
    (r"\bAVAudioRecorder\b", "enregistrement audio sur disque"),
    (r"AVAudioFile\s*\(\s*forWriting", "écriture de fichier audio"),
    (r"requiresOnDeviceRecognition\s*=\s*false", "reconnaissance vocale sur serveur"),
]

REQUIRED_IF: list[tuple[str, str, str]] = [
    (r"\bSF\w*RecognitionRequest\b", r"requiresOnDeviceRecognition\s*=\s*true",
     "requête Speech sans `requiresOnDeviceRecognition = true`"),
    (r"\bModelConfiguration\s*\(", r"cloudKitDatabase:\s*\.none",
     "ModelConfiguration sans `cloudKitDatabase: .none`"),
]


@dataclass(frozen=True)
class Violation:
    path: str
    line: int
    rule: str
    text: str

    def __str__(self) -> str:
        return f"{self.path}:{self.line}: {self.rule} — {self.text.strip()}"


def strip_comments(source: str) -> str:
    """Retire commentaires `//` et `/* */` en préservant les numéros de ligne.

    Approximation volontairement simple : les chaînes contenant « // » sont rares
    ici, et une URL dans une chaîne resterait de toute façon suspecte.
    """
    source = re.sub(r"/\*.*?\*/", lambda m: "\n" * m.group(0).count("\n"), source, flags=re.S)
    return "\n".join(re.sub(r"(?<!:)//.*$", "", line) for line in source.split("\n"))


def check_source(path: str, source: str) -> list[Violation]:
    code = strip_comments(source)
    lines = code.split("\n")
    out: list[Violation] = []
    for pattern, rule in FORBIDDEN:
        rx = re.compile(pattern, re.M)
        for i, line in enumerate(lines, start=1):
            if rx.search(line):
                out.append(Violation(path, i, rule, line))
    for trigger, required, rule in REQUIRED_IF:
        m = re.search(trigger, code)
        if m and not re.search(required, code):
            line = code[:m.start()].count("\n") + 1
            out.append(Violation(path, line, rule, lines[line - 1]))
    return out


def swift_sources(root: Path) -> list[Path]:
    """Les sources Swift du dépôt, sans les produits de compilation.

    `swift test` et Xcode génèrent du Swift dans `.build/`, `.swiftpm/` ou
    `DerivedData/` (point d'entrée des tests, dépendances clonées) : ce n'est
    pas notre code, et le verdict ne doit pas dépendre d'une compilation passée.
    """
    return sorted(p for p in root.rglob("*.swift")
                  if not any(part.startswith(".") or part == "DerivedData"
                             for part in p.relative_to(root).parts[:-1]))


def check_tree(root: Path) -> list[Violation]:
    out: list[Violation] = []
    for p in swift_sources(root):
        out.extend(check_source(str(p), p.read_text(encoding="utf-8")))
    return out


def main(argv: list[str]) -> int:
    root = Path(argv[1]) if len(argv) > 1 else Path(__file__).resolve().parents[1] / "ios"
    violations = check_tree(root)
    files = len(swift_sources(root))
    if violations:
        for v in violations:
            print(v)
        print(f"\n✗ {len(violations)} violation(s) de la promesse « rien ne quitte l'iPad » ({files} fichiers).")
        return 1
    print(f"✓ Confidentialité : {files} fichiers Swift vérifiés, aucune violation.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
