package natonctl

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

// presetThemes are the 16-color ANSI palettes ported from aether
// (frontend/src/lib/constants/colors.ts). Slot 0 = background,
// 7 = foreground, 8 = dim, 1-6 = accent hues.
type presetTheme struct {
	Name   string     `json:"name"`
	Colors [16]string `json:"colors"`
	Accent string     `json:"accent,omitempty"` // optional explicit accent override (not ANSI red)
}

var presetThemes = []presetTheme{
	{Name: "Aether", Colors: [16]string{
		"#141114",
		"#ff637e",
		"#b4e173",
		"#ffd568",
		"#ff9b66",
		"#c09ef5",
		"#76ecdb",
		"#ffffff",
		"#766974",
		"#ff637e",
		"#b4e173",
		"#ffd568",
		"#ff9b66",
		"#c09ef5",
		"#76ecdb",
		"#ffffff",
	}},
	{Name: "Pina", Colors: [16]string{
		"#171a18",
		"#7db085",
		"#b8c082",
		"#e0d480",
		"#7dd2b8",
		"#b5c9a4",
		"#c5e8c5",
		"#d4d5d5",
		"#6b8071",
		"#8cc098",
		"#cdd590",
		"#f2e590",
		"#92e2c8",
		"#c8dab8",
		"#d8f5d8",
		"#e2e3e3",
	}},
	{Name: "Sakura", Colors: [16]string{
		"#0d0509",
		"#E85F6F",
		"#F29B9A",
		"#D4A882",
		"#D9A56C",
		"#D1B399",
		"#E8C099",
		"#f0eaed",
		"#4a3c45",
		"#FF7A8A",
		"#FFB5B4",
		"#E6BA94",
		"#EBB97E",
		"#E3C5AB",
		"#FBD2AB",
		"#ffffff",
	}},
	{Name: "Fireside", Colors: [16]string{
		"#0a1220",
		"#e06b58",
		"#889889",
		"#b8b5a2",
		"#b8b8b6",
		"#e48b7a",
		"#d0cac7",
		"#f0f2f5",
		"#555c65",
		"#e06b58",
		"#9eaca1",
		"#c8c3b8",
		"#cdcbc9",
		"#f0a19a",
		"#e3ddda",
		"#f0f2f5",
	}},
	{Name: "Frost", Colors: [16]string{
		"#0a0f1c",
		"#869AAC",
		"#95A8B8",
		"#9FADB8",
		"#9BB0C2",
		"#A8B9C6",
		"#B8C7D0",
		"#d4d5d9",
		"#5f6374",
		"#869AAC",
		"#95A8B8",
		"#9FADB8",
		"#9BB0C2",
		"#A8B9C6",
		"#B8C7D0",
		"#d4d5d9",
	}},
	{Name: "Dracula", Colors: [16]string{
		"#282a36",
		"#ff5555",
		"#50fa7b",
		"#f1fa8c",
		"#bd93f9",
		"#ff79c6",
		"#8be9fd",
		"#f8f8f2",
		"#6272a4",
		"#ff6e6e",
		"#69ff94",
		"#ffffa5",
		"#d6acff",
		"#ff92df",
		"#a4ffff",
		"#ffffff",
	}},
	{Name: "Nord", Colors: [16]string{
		"#2e3440",
		"#bf616a",
		"#a3be8c",
		"#ebcb8b",
		"#81a1c1",
		"#b48ead",
		"#88c0d0",
		"#e5e9f0",
		"#4c566a",
		"#d08770",
		"#a3be8c",
		"#ebcb8b",
		"#81a1c1",
		"#b48ead",
		"#8fbcbb",
		"#eceff4",
	}},
	{Name: "Gruvbox Dark", Colors: [16]string{
		"#282828",
		"#cc241d",
		"#98971a",
		"#d79921",
		"#458588",
		"#b16286",
		"#689d6a",
		"#ebdbb2",
		"#928374",
		"#fb4934",
		"#b8bb26",
		"#fabd2f",
		"#83a598",
		"#d3869b",
		"#8ec07c",
		"#fbf1c7",
	}},
	{Name: "Gruvbox Material", Colors: [16]string{
		"#1d2021",
		"#ea6962",
		"#a9b665",
		"#d8a657",
		"#7daea3",
		"#d3869b",
		"#89b482",
		"#d4be98",
		"#32302f",
		"#ea6962",
		"#a9b665",
		"#d8a657",
		"#7daea3",
		"#d3869b",
		"#89b482",
		"#ddc7a1",
	}},
	{Name: "Solarized Dark", Colors: [16]string{
		"#002b36",
		"#dc322f",
		"#859900",
		"#b58900",
		"#268bd2",
		"#d33682",
		"#2aa198",
		"#839496",
		"#073642",
		"#cb4b16",
		"#586e75",
		"#657b83",
		"#839496",
		"#6c71c4",
		"#93a1a1",
		"#fdf6e3",
	}},
	{Name: "Tokyo Night", Colors: [16]string{
		"#1a1b26",
		"#f7768e",
		"#9ece6a",
		"#e0af68",
		"#7aa2f7",
		"#bb9af7",
		"#7dcfff",
		"#a9b1d6",
		"#414868",
		"#f7768e",
		"#9ece6a",
		"#e0af68",
		"#7aa2f7",
		"#bb9af7",
		"#7dcfff",
		"#c0caf5",
	}},
	{Name: "Catppuccin Mocha", Colors: [16]string{
		"#1e1e2e",
		"#f38ba8",
		"#a6e3a1",
		"#f9e2af",
		"#89b4fa",
		"#cba6f7",
		"#94e2d5",
		"#cdd6f4",
		"#45475a",
		"#f38ba8",
		"#a6e3a1",
		"#f9e2af",
		"#89b4fa",
		"#cba6f7",
		"#94e2d5",
		"#bac2de",
	}},
	{Name: "One Dark", Colors: [16]string{
		"#282c34",
		"#e06c75",
		"#98c379",
		"#e5c07b",
		"#61afef",
		"#c678dd",
		"#56b6c2",
		"#abb2bf",
		"#5c6370",
		"#e06c75",
		"#98c379",
		"#e5c07b",
		"#61afef",
		"#c678dd",
		"#56b6c2",
		"#ffffff",
	}},
	{Name: "Monokai Pro", Colors: [16]string{
		"#2d2a2e",
		"#ff6188",
		"#a9dc76",
		"#ffd866",
		"#fc9867",
		"#ab9df2",
		"#78dce8",
		"#fcfcfa",
		"#727072",
		"#ff6188",
		"#a9dc76",
		"#ffd866",
		"#fc9867",
		"#ab9df2",
		"#78dce8",
		"#fcfcfa",
	}},
	{Name: "Palenight", Colors: [16]string{
		"#292d3e",
		"#f07178",
		"#c3e88d",
		"#ffcb6b",
		"#82aaff",
		"#c792ea",
		"#89ddff",
		"#bfc7d5",
		"#676e95",
		"#f07178",
		"#c3e88d",
		"#ffcb6b",
		"#82aaff",
		"#c792ea",
		"#89ddff",
		"#ffffff",
	}},
	{Name: "Rose Pine", Colors: [16]string{
		"#191724",
		"#eb6f92",
		"#9ccfd8",
		"#f6c177",
		"#31748f",
		"#c4a7e7",
		"#ebbcba",
		"#e0def4",
		"#26233a",
		"#eb6f92",
		"#9ccfd8",
		"#f6c177",
		"#31748f",
		"#c4a7e7",
		"#ebbcba",
		"#e0def4",
	}},
	{Name: "Everforest", Colors: [16]string{
		"#2d353b",
		"#e67e80",
		"#a7c080",
		"#dbbc7f",
		"#7fbbb3",
		"#d699b6",
		"#83c092",
		"#d3c6aa",
		"#475258",
		"#e67e80",
		"#a7c080",
		"#dbbc7f",
		"#7fbbb3",
		"#d699b6",
		"#83c092",
		"#d3c6aa",
	}},
	{Name: "Matte Black", Colors: [16]string{
		"#121212",
		"#D35F5F",
		"#FFC107",
		"#b91c1c",
		"#e68e0d",
		"#D35F5F",
		"#bebebe",
		"#bebebe",
		"#8a8a8d",
		"#B91C1C",
		"#FFC107",
		"#b90a0a",
		"#f59e0b",
		"#B91C1C",
		"#eaeaea",
		"#ffffff",
	}},
	{Name: "Osaka Jade", Colors: [16]string{
		"#111c18",
		"#FF5345",
		"#549e6a",
		"#459451",
		"#509475",
		"#D2689C",
		"#2DD5B7",
		"#C1C497",
		"#53685B",
		"#db9f9c",
		"#63b07a",
		"#E5C736",
		"#ACD4CF",
		"#75bbb3",
		"#8CD3CB",
		"#9eebb3",
	}},
	{Name: "Ristretto", Colors: [16]string{
		"#2c2525",
		"#fd6883",
		"#adda78",
		"#f9cc6c",
		"#f38d70",
		"#a8a9eb",
		"#85dacc",
		"#e6d9db",
		"#948a8b",
		"#ff8297",
		"#c8e292",
		"#fcd675",
		"#f8a788",
		"#bebffd",
		"#9bf1e1",
		"#f1e5e7",
	}},
	{Name: "Kanagawa", Colors: [16]string{
		"#1f1f28",
		"#c34043",
		"#76946a",
		"#c0a36e",
		"#7e9cd8",
		"#957fb8",
		"#6a9589",
		"#dcd7ba",
		"#363646",
		"#e82424",
		"#98bb6c",
		"#e6c384",
		"#7fb4ca",
		"#938aa9",
		"#7aa89f",
		"#c8c093",
	}},
	{Name: "Nightfox", Colors: [16]string{
		"#192330",
		"#c94f6d",
		"#81b29a",
		"#dbc074",
		"#719cd6",
		"#9d79d6",
		"#63cdcf",
		"#cdcecf",
		"#526176",
		"#c94f6d",
		"#81b29a",
		"#dbc074",
		"#719cd6",
		"#9d79d6",
		"#63cdcf",
		"#cdcecf",
	}},
	{Name: "Ayu Mirage", Colors: [16]string{
		"#1f2430",
		"#f28779",
		"#d5ff80",
		"#ffd173",
		"#73d0ff",
		"#dfbfff",
		"#95e6cb",
		"#cbccc6",
		"#707a8c",
		"#f28779",
		"#d5ff80",
		"#ffd173",
		"#73d0ff",
		"#dfbfff",
		"#95e6cb",
		"#cbccc6",
	}},
	{Name: "Oceanic Next", Colors: [16]string{
		"#1b2b34",
		"#ec5f67",
		"#99c794",
		"#fac863",
		"#6699cc",
		"#c594c5",
		"#5fb3b3",
		"#d8dee9",
		"#65737e",
		"#ec5f67",
		"#99c794",
		"#fac863",
		"#6699cc",
		"#c594c5",
		"#5fb3b3",
		"#d8dee9",
	}},
	{Name: "Horizon", Colors: [16]string{
		"#1c1e26",
		"#e95678",
		"#29d398",
		"#fab795",
		"#26bbd9",
		"#ee64ac",
		"#59e3e3",
		"#fadad1",
		"#6c6f93",
		"#ec6a88",
		"#3fdaa4",
		"#fbc3a7",
		"#3fc4de",
		"#f075b5",
		"#6be4e6",
		"#fadad1",
	}},
	{Name: "Andromeda", Colors: [16]string{
		"#23262e",
		"#ee5d43",
		"#96e072",
		"#ffe66d",
		"#00a9f9",
		"#f92aad",
		"#4dd9d7",
		"#d5ced9",
		"#666b81",
		"#ee5d43",
		"#96e072",
		"#ffe66d",
		"#00a9f9",
		"#f92aad",
		"#4dd9d7",
		"#d5ced9",
	}},
	{Name: "Synthwave 84", Colors: [16]string{
		"#241b2f",
		"#fe4450",
		"#72f1b8",
		"#fede5d",
		"#03edf9",
		"#ff7edb",
		"#36f9f6",
		"#f7f7f7",
		"#495495",
		"#fe4450",
		"#72f1b8",
		"#fede5d",
		"#03edf9",
		"#ff7edb",
		"#36f9f6",
		"#ffffff",
	}},
	{Name: "Solarized Light", Colors: [16]string{
		"#fdf6e3",
		"#dc322f",
		"#859900",
		"#b58900",
		"#268bd2",
		"#d33682",
		"#2aa198",
		"#657b83",
		"#eee8d5",
		"#cb4b16",
		"#93a1a1",
		"#839496",
		"#657b83",
		"#6c71c4",
		"#586e75",
		"#073642",
	}},
	{Name: "Gruvbox Light", Colors: [16]string{
		"#fbf1c7",
		"#cc241d",
		"#98971a",
		"#d79921",
		"#458588",
		"#b16286",
		"#689d6a",
		"#3c3836",
		"#ebdbb2",
		"#9d0006",
		"#79740e",
		"#b57614",
		"#076678",
		"#8f3f71",
		"#427b58",
		"#282828",
	}},
	{Name: "Catppuccin Latte", Colors: [16]string{
		"#eff1f5",
		"#d20f39",
		"#40a02b",
		"#df8e1d",
		"#1e66f5",
		"#ea76cb",
		"#179299",
		"#4c4f69",
		"#ccd0da",
		"#d20f39",
		"#40a02b",
		"#df8e1d",
		"#1e66f5",
		"#ea76cb",
		"#179299",
		"#5c5f77",
	}},
	{Name: "One Light", Colors: [16]string{
		"#fafafa",
		"#e45649",
		"#50a14f",
		"#c18401",
		"#4078f2",
		"#a626a4",
		"#0184bc",
		"#383a42",
		"#e5e5e6",
		"#e45649",
		"#50a14f",
		"#c18401",
		"#4078f2",
		"#a626a4",
		"#0184bc",
		"#090a0b",
	}},
	{Name: "Rose Pine Dawn", Colors: [16]string{
		"#faf4ed",
		"#b4637a",
		"#56949f",
		"#ea9d34",
		"#286983",
		"#907aa9",
		"#d7827e",
		"#575279",
		"#fffaf3",
		"#b4637a",
		"#56949f",
		"#ea9d34",
		"#286983",
		"#907aa9",
		"#d7827e",
		"#575279",
	}},
	{Name: "Everforest Light", Colors: [16]string{
		"#fdf6e3",
		"#f85552",
		"#8da101",
		"#dfa000",
		"#3a94c5",
		"#df69ba",
		"#35a77c",
		"#5c6a72",
		"#f0f0f0",
		"#f85552",
		"#8da101",
		"#dfa000",
		"#3a94c5",
		"#df69ba",
		"#35a77c",
		"#5c6a72",
	}},
	{Name: "Tokyo Night Day", Colors: [16]string{
		"#d5d6db",
		"#f52a65",
		"#587539",
		"#8c6c3e",
		"#2e7de9",
		"#9854f1",
		"#007197",
		"#3760bf",
		"#9699a3",
		"#f52a65",
		"#587539",
		"#8c6c3e",
		"#2e7de9",
		"#9854f1",
		"#007197",
		"#3760bf",
	}},
	{Name: "GitHub Dark", Colors: [16]string{
		"#0d1117",
		"#ff7b72",
		"#3fb950",
		"#d29922",
		"#58a6ff",
		"#bc8cff",
		"#39c5cf",
		"#b1bac4",
		"#484f58",
		"#ffa198",
		"#56d364",
		"#e3b341",
		"#79c0ff",
		"#d2a8ff",
		"#56d4dd",
		"#f0f6fc",
	}},
	{Name: "GitHub Light", Colors: [16]string{
		"#ffffff",
		"#cf222e",
		"#116329",
		"#4d2d00",
		"#0969da",
		"#8250df",
		"#1b7c83",
		"#24292f",
		"#f6f8fa",
		"#a40e26",
		"#1a7f37",
		"#633c01",
		"#0550ae",
		"#8250df",
		"#1b7c83",
		"#1f2328",
	}},
	{Name: "Monochrome Dark", Colors: [16]string{
		"#000000",
		"#7c7c7c",
		"#8b8b8b",
		"#a0a0a0",
		"#686868",
		"#747474",
		"#868686",
		"#b9b9b9",
		"#525252",
		"#7c7c7c",
		"#8b8b8b",
		"#a0a0a0",
		"#686868",
		"#747474",
		"#868686",
		"#ffffff",
	}},
	{Name: "Monochrome Light", Colors: [16]string{
		"#ffffff",
		"#5a5a5a",
		"#6e6e6e",
		"#808080",
		"#4a4a4a",
		"#5e5e5e",
		"#707070",
		"#1a1a1a",
		"#d4d4d4",
		"#5a5a5a",
		"#6e6e6e",
		"#808080",
		"#4a4a4a",
		"#5e5e5e",
		"#707070",
		"#000000",
	}},
	{Name: "Eldritch", Colors: [16]string{
		"#21222c",
		"#f9515d",
		"#37f499",
		"#e9f941",
		"#9071f4",
		"#f265b5",
		"#04d1f9",
		"#ebfafa",
		"#7081d0",
		"#f16c75",
		"#69f8b3",
		"#f1fc79",
		"#a48cf2",
		"#fd92ce",
		"#66e4fd",
		"#ffffff",
	}},
	{Name: "Noctalia", Colors: [16]string{
		"#11112d",
		"#fd4663",
		"#9bfece",
		"#fff59b",
		"#a9aefe",
		"#fd4663",
		"#9bfece",
		"#f3edf7",
		"#21215f",
		"#fd4663",
		"#9bfece",
		"#fff59b",
		"#a9aefe",
		"#fd4663",
		"#9bfece",
		"#ffffff",
	}},
	{Name: "macOS Classic Dark", Accent: "#077CFD", Colors: [16]string{
		"#131313",
		"#FF5257",
		"#30D158",
		"#CC9E00",
		"#419CFF",
		"#A550A7",
		"#0AC2A2",
		"#DEDEDE",
		"#8F8F8F",
		"#FF696D",
		"#68DC7C",
		"#DBBB76",
		"#7FAEF9",
		"#B283F8",
		"#5CDBC6",
		"#F2F9FF",
	}},
	{Name: "macOS Classic Light", Accent: "#0060DE", Colors: [16]string{
		"#F9F9F9",
		"#D21F07",
		"#319A00",
		"#B59A00",
		"#0060DE",
		"#9A0068",
		"#007E8A",
		"#000000",
		"#555555",
		"#C5060B",
		"#036A07",
		"#957931",
		"#0433FF",
		"#6F42C1",
		"#007FFF",
		"#000000",
	}},
	{Name: "Nothing Phone", Accent: "#E64536", Colors: [16]string{
		"#000000",
		"#E64536",
		"#D4D4D4",
		"#F5F5F5",
		"#A8A8A8",
		"#8A8A8A",
		"#C0C0C0",
		"#FFFFFF",
		"#2E2E2E",
		"#FF6B5E",
		"#E8E8E8",
		"#FFFFFF",
		"#C0C0C0",
		"#A0A0A0",
		"#D0D0D0",
		"#FFFFFF",
	}},
	{Name: "Terraria", Colors: [16]string{
		"#17130E",
		"#C34A2C",
		"#7CB342",
		"#D9B64E",
		"#4E7FB5",
		"#9C6BC4",
		"#58A87C",
		"#E4D8B8",
		"#3A3226",
		"#E0643E",
		"#9CCB5E",
		"#E8C86E",
		"#6FA3D9",
		"#B888E8",
		"#6FC89E",
		"#FFF4D8",
	}},
}

// themeInfo is the unified semantic theme shape served to the shell. Built-in
// ANSI presets are expanded into it; user JSON themes are normalized into it.
// Accent is explicit and independent from the ANSI red slot, so a theme can
// carry a blue accent while red stays reserved for danger/status colors.
type themeInfo struct {
	Name             string     `json:"name"`
	Mode             string     `json:"mode"`
	Accent           string     `json:"accent"`
	Background       string     `json:"background"`
	Foreground       string     `json:"foreground"`
	Layer            string     `json:"layer"`
	Selection        string     `json:"selection"`
	Muted            string     `json:"muted"`
	Red              string     `json:"red"`
	Green            string     `json:"green"`
	Yellow           string     `json:"yellow"`
	Blue             string     `json:"blue"`
	Magenta          string     `json:"magenta"`
	Cyan             string     `json:"cyan"`
	BrightRed        string     `json:"brightRed"`
	BrightGreen      string     `json:"brightGreen"`
	BrightYellow     string     `json:"brightYellow"`
	BrightBlue       string     `json:"brightBlue"`
	BrightMagenta    string     `json:"brightMagenta"`
	BrightCyan       string     `json:"brightCyan"`
	BrightForeground string     `json:"brightForeground"`
	Colors           [16]string `json:"colors"`
	File             string     `json:"file,omitempty"`
}

func isHexColor(s string) bool {
	if len(s) != 7 || s[0] != '#' {
		return false
	}
	for i := 1; i < len(s); i++ {
		c := s[i]
		if !(c >= '0' && c <= '9' || c >= 'a' && c <= 'f' || c >= 'A' && c <= 'F') {
			return false
		}
	}
	return true
}

func upperHex(s string) string {
	if !isHexColor(s) {
		return ""
	}
	return strings.ToUpper(s)
}

func hexLuminance(hex string) float64 {
	r, _ := strconv.ParseInt(hex[1:3], 16, 64)
	g, _ := strconv.ParseInt(hex[3:5], 16, 64)
	b, _ := strconv.ParseInt(hex[5:7], 16, 64)
	return (0.2126*float64(r) + 0.7152*float64(g) + 0.0722*float64(b)) / 255
}

func themeFromBuiltin(p presetTheme) themeInfo {
	c := p.Colors
	mode := "dark"
	if hexLuminance(c[0]) > 0.52 {
		mode = "light"
	}
	accent := upperHex(p.Accent)
	if accent == "" {
		accent = c[1]
	}
	return themeInfo{
		Name:             p.Name,
		Mode:             mode,
		Accent:           accent,
		Background:       c[0],
		Foreground:       c[7],
		Layer:            c[8],
		Selection:        c[8],
		Muted:            c[8],
		Red:              c[1],
		Green:            c[2],
		Yellow:           c[3],
		Blue:             c[4],
		Magenta:          c[5],
		Cyan:             c[6],
		BrightRed:        c[9],
		BrightGreen:      c[10],
		BrightYellow:     c[11],
		BrightBlue:       c[12],
		BrightMagenta:    c[13],
		BrightCyan:       c[14],
		BrightForeground: c[15],
		Colors:           c,
	}
}

// userTheme is the JSON schema for a theme file in ~/.config/quickshell/presets/.
// Only name, background and foreground are required; everything else falls back
// to the colors array or is derived.
type userTheme struct {
	Name             string   `json:"name"`
	Mode             string   `json:"mode"`
	Accent           string   `json:"accent"`
	Background       string   `json:"background"`
	Foreground       string   `json:"foreground"`
	Layer            string   `json:"layer"`
	Selection        string   `json:"selection"`
	Muted            string   `json:"muted"`
	Red              string   `json:"red"`
	Green            string   `json:"green"`
	Yellow           string   `json:"yellow"`
	Blue             string   `json:"blue"`
	Magenta          string   `json:"magenta"`
	Cyan             string   `json:"cyan"`
	BrightRed        string   `json:"brightRed"`
	BrightGreen      string   `json:"brightGreen"`
	BrightYellow     string   `json:"brightYellow"`
	BrightBlue       string   `json:"brightBlue"`
	BrightMagenta    string   `json:"brightMagenta"`
	BrightCyan       string   `json:"brightCyan"`
	BrightForeground string   `json:"brightForeground"`
	Colors           []string `json:"colors"`
}

func pick(values ...string) string {
	for _, v := range values {
		if v = upperHex(v); v != "" {
			return v
		}
	}
	return ""
}

func parseUserTheme(data []byte) (themeInfo, bool) {
	var u userTheme
	if err := json.Unmarshal(data, &u); err != nil {
		fmt.Fprintf(os.Stderr, "natonctl: skipping invalid preset: %v\n", err)
		return themeInfo{}, false
	}
	if strings.TrimSpace(u.Name) == "" {
		fmt.Fprintln(os.Stderr, "natonctl: skipping preset without a name")
		return themeInfo{}, false
	}
	var c [16]string
	if len(u.Colors) == 16 {
		for i, v := range u.Colors {
			c[i] = upperHex(v)
		}
	}
	c[0] = pick(u.Background, c[0])
	c[1] = pick(u.Red, u.Accent, c[1])
	c[2] = pick(u.Green, c[2])
	c[3] = pick(u.Yellow, c[3])
	c[4] = pick(u.Blue, c[4])
	c[5] = pick(u.Magenta, c[5])
	c[6] = pick(u.Cyan, c[6])
	c[7] = pick(u.Foreground, c[7])
	c[8] = pick(u.Layer, u.Muted, c[8])
	c[9] = pick(u.BrightRed, c[9], u.Red)
	c[10] = pick(u.BrightGreen, c[10], u.Green)
	c[11] = pick(u.BrightYellow, c[11], u.Yellow)
	c[12] = pick(u.BrightBlue, c[12], u.Blue)
	c[13] = pick(u.BrightMagenta, c[13], u.Magenta)
	c[14] = pick(u.BrightCyan, c[14], u.Cyan)
	c[15] = pick(u.BrightForeground, c[15], u.Foreground)
	if c[0] == "" || c[7] == "" {
		fmt.Fprintf(os.Stderr, "natonctl: skipping preset %q: background and foreground are required\n", u.Name)
		return themeInfo{}, false
	}
	mode := u.Mode
	if mode != "light" && mode != "dark" {
		if hexLuminance(c[0]) > 0.52 {
			mode = "light"
		} else {
			mode = "dark"
		}
	}
	return themeInfo{
		Name:             u.Name,
		Mode:             mode,
		Accent:           pick(u.Accent, c[1]),
		Background:       c[0],
		Foreground:       c[7],
		Layer:            c[8],
		Selection:        pick(u.Selection, c[8]),
		Muted:            pick(u.Muted, c[8]),
		Red:              c[1],
		Green:            c[2],
		Yellow:           c[3],
		Blue:             c[4],
		Magenta:          c[5],
		Cyan:             c[6],
		BrightRed:        c[9],
		BrightGreen:      c[10],
		BrightYellow:     c[11],
		BrightBlue:       c[12],
		BrightMagenta:    c[13],
		BrightCyan:       c[14],
		BrightForeground: c[15],
		Colors:           c,
	}, true
}

func userPresetsDir() string { return filepath.Join(homeDir, ".config/quickshell/presets") }

func userThemeFiles() []themeInfo {
	entries, err := os.ReadDir(userPresetsDir())
	if err != nil {
		return nil
	}
	var out []themeInfo
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".json") {
			continue
		}
		path := filepath.Join(userPresetsDir(), e.Name())
		data, err := os.ReadFile(path)
		if err != nil {
			continue
		}
		t, ok := parseUserTheme(data)
		if !ok {
			continue
		}
		t.File = path
		out = append(out, t)
	}
	return out
}

func cmdPresets() {
	byName := map[string]themeInfo{}
	for _, p := range presetThemes {
		t := themeFromBuiltin(p)
		byName[t.Name] = t
	}
	for _, t := range userThemeFiles() {
		byName[t.Name] = t // user themes override built-ins
	}
	out := make([]themeInfo, 0, len(byName))
	for _, t := range byName {
		out = append(out, t)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Name < out[j].Name })
	output(out)
}
