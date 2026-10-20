"""Readability guarantees at the HTML renderer's plain-text output."""

import subprocess
import unittest


HTML = b"""<!doctype html><html><head>
<style>.example {color:red} /* STYLE_SECRET */</style>
<script>var SCRIPT_SECRET = 1;</script></head><body>
<h1>Project update</h1><p>Hello &amp; welcome.</p>
<table><tr><th>Item</th><th>Status</th></tr><tr><td>Build</td><td>Ready</td></tr></table>
<p><a href="https://example.invalid/help?tracking=long-unhelpful-token">Read the guide</a></p>
<img src="https://example.invalid/pixel.gif" width="1" height="1" alt="">
</body></html>"""


class HtmlRendererTest(unittest.TestCase):
    def render(self, *arguments):
        result = subprocess.run(["mail-html", *arguments], input=HTML, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stderr.decode())
        return result.stdout.decode()

    def test_default_preserves_content_without_tracking_url_clutter(self):
        output = self.render()
        for text in ("Project update", "Hello & welcome.", "Build", "Ready", "Read the guide"):
            self.assertIn(text, output)
        for text in ("SCRIPT_SECRET", "STYLE_SECRET", "long-unhelpful-token"):
            self.assertNotIn(text, output)

    def test_comparison_includes_all_three_variants(self):
        output = self.render("--compare")
        for name in ("lynx", "w3m", "aerc"):
            self.assertIn(f"=== {name} ===", output)
        self.assertEqual(output.count("Project update"), 3)


if __name__ == "__main__":
    unittest.main()
