package natonctl

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func TestUpdateSetting(t *testing.T) {
	settings := settingsDefaults()

	if !updateSetting(settings, "themeName", "light") {
		t.Fatal("updateSetting returned false for a known setting")
	}
	if got := settings["themeName"]; got != "light" {
		t.Errorf("themeName = %q; want %q", got, "light")
	}
	if updateSetting(settings, "unknown", "value") {
		t.Error("updateSetting returned true for an unknown setting")
	}
}

func TestWriteSettingsSynchronizesWallpaperDirectory(t *testing.T) {
	previousHomeDir := homeDir
	homeDir = t.TempDir()
	t.Cleanup(func() { homeDir = previousHomeDir })

	settings := settingsDefaults()
	settings["wallpaperDir"] = "~/Pictures/wallpapers"
	writeSettings(settings, "wallpaperDir")

	var persisted, wallutil map[string]string
	readJSONFile(t, settingsPath(), &persisted)
	readJSONFile(t, wallutilPath(), &wallutil)
	if got := persisted["wallpaperDir"]; got != settings["wallpaperDir"] {
		t.Errorf("persisted wallpaperDir = %q; want %q", got, settings["wallpaperDir"])
	}
	if got := wallutil["wallDir"]; got != settings["wallpaperDir"] {
		t.Errorf("wallutil wallDir = %q; want %q", got, settings["wallpaperDir"])
	}
}

func readJSONFile(t *testing.T, path string, value any) {
	t.Helper()
	data, err := os.ReadFile(filepath.Clean(path))
	if err != nil {
		t.Fatalf("read %s: %v", path, err)
	}
	if err := json.Unmarshal(data, value); err != nil {
		t.Fatalf("parse %s: %v", path, err)
	}
}
