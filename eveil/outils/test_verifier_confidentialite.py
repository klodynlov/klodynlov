"""Tests du garde-fou de confidentialité (et vérification du vrai code Swift)."""
from __future__ import annotations

import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from verifier_confidentialite import check_source, check_tree, strip_comments  # noqa: E402

IOS = Path(__file__).resolve().parents[1] / "ios"


class TestRules(unittest.TestCase):
    def rules(self, src: str) -> list[str]:
        return [v.rule for v in check_source("x.swift", src)]

    def test_network_is_forbidden(self):
        self.assertTrue(self.rules("let s = URLSession.shared"))
        self.assertTrue(self.rules('let u = "https://tracker.example"'))
        self.assertTrue(self.rules("import FirebaseAnalytics"))
        self.assertTrue(self.rules("import AppTrackingTransparency"))

    def test_audio_must_not_be_persisted(self):
        self.assertTrue(self.rules("let r = try AVAudioRecorder(url: u, settings: [:])"))
        self.assertTrue(self.rules("let f = try AVAudioFile(forWriting: u, settings: s)"))

    def test_speech_must_stay_on_device(self):
        self.assertTrue(self.rules("let r = SFSpeechAudioBufferRecognitionRequest()"))
        ok = "let r = SFSpeechAudioBufferRecognitionRequest()\nr.requiresOnDeviceRecognition = true"
        self.assertEqual(self.rules(ok), [])
        self.assertTrue(self.rules(ok + "\nr.requiresOnDeviceRecognition = false"))

    def test_swiftdata_must_not_sync(self):
        self.assertTrue(self.rules("ModelConfiguration(isStoredInMemoryOnly: false)"))
        self.assertEqual(self.rules("ModelConfiguration(cloudKitDatabase: .none)"), [])
        self.assertTrue(self.rules("ModelConfiguration(cloudKitDatabase: .automatic)"))

    def test_comments_are_ignored(self):
        self.assertEqual(self.rules("// voir https://developer.apple.com\nlet x = 1"), [])
        self.assertEqual(self.rules("/* URLSession est interdit */\nlet x = 1"), [])
        self.assertEqual(strip_comments("a\n/* b\nc */\nd").count("\n"), 3)   # lignes préservées


class TestRealCode(unittest.TestCase):
    def test_eveil_swift_code_is_clean(self):
        self.assertTrue(list(IOS.rglob("*.swift")), "aucun fichier Swift trouvé")
        violations = check_tree(IOS)
        self.assertEqual([str(v) for v in violations], [])


if __name__ == "__main__":
    unittest.main()
