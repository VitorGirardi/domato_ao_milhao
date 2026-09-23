package main

import (
	"archive/tar"
	"archive/zip"
	"bytes"
	"compress/gzip"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

type fakeTransport struct {
	body []byte
	code int
}

func (f fakeTransport) RoundTrip(r *http.Request) (*http.Response, error) {
	return &http.Response{StatusCode: f.code, Body: io.NopCloser(bytes.NewReader(f.body)), Header: make(http.Header)}, nil
}
func mockDownload(t *testing.T, b []byte) {
	old := client
	client = &http.Client{Transport: fakeTransport{b, 200}}
	t.Cleanup(func() { client = old })
}
func makeZip(t *testing.T, entries map[string]string) []byte {
	var b bytes.Buffer
	w := zip.NewWriter(&b)
	for name, body := range entries {
		f, e := w.Create(name)
		if e != nil {
			t.Fatal(e)
		}
		f.Write([]byte(body))
	}
	if e := w.Close(); e != nil {
		t.Fatal(e)
	}
	return b.Bytes()
}
func fixture(t *testing.T, platform string) []byte {
	if platform == "windows" {
		return makeZip(t, map[string]string{"DoMatoAoMilhao-v0.31.0/DoMatoAoMilhao.exe": "fake game", "DoMatoAoMilhao-v0.31.0/LEIA-ME.txt": "test"})
	}
	var b bytes.Buffer
	g := gzip.NewWriter(&b)
	w := tar.NewWriter(g)
	w.WriteHeader(&tar.Header{Name: "./", Typeflag: tar.TypeDir, Mode: 0755})
	body := []byte("#!/bin/sh\nexit 0\n")
	w.WriteHeader(&tar.Header{Name: "./DoMatoAoMilhao.x86_64", Mode: 0755, Size: int64(len(body))})
	w.Write(body)
	w.Close()
	g.Close()
	return b.Bytes()
}
func release(t *testing.T, platform string, b []byte) Release {
	name := "DoMatoAoMilhao-Windows-v0.31.0.zip"
	if platform == "linux" {
		name = "DoMatoAoMilhao-Linux-v0.31.0-x86_64.tar.gz"
	}
	h := sha256.Sum256(b)
	return Release{Tag: "v0.31.0", Assets: []Asset{{Name: name, URL: "https://github.com/" + repo + "/releases/download/v0.31.0/" + name, Size: int64(len(b)), Digest: "sha256:" + hex.EncodeToString(h[:])}}}
}
func TestInstallBothArchiveLayouts(t *testing.T) {
	for _, p := range []string{"windows", "linux"} {
		t.Run(p, func(t *testing.T) {
			b := fixture(t, p)
			mockDownload(t, b)
			root := t.TempDir()
			i, e := installRelease(root, release(t, p, b), p)
			if e != nil {
				t.Fatal(e)
			}
			if _, e = validInstall(root, i); e != nil {
				t.Fatal(e)
			}
			if e = writeState(root, State{Current: i}); e != nil {
				t.Fatal(e)
			}
			r, e := run(root, "status")
			if e != nil || r.Current != "v0.31.0" {
				t.Fatalf("%+v %v", r, e)
			}
		})
	}
}
func TestCorruptAndInterruptedDownloadsPreserveState(t *testing.T) {
	for _, bad := range []string{"corrupt", "short"} {
		t.Run(bad, func(t *testing.T) {
			b := fixture(t, "windows")
			r := release(t, "windows", b)
			if bad == "short" {
				b = b[:len(b)/2]
			} else {
				b[10] ^= 0xff
			}
			mockDownload(t, b)
			root := t.TempDir()
			original := []byte(`{"Current":{"Version":"v0.30.0"}}`)
			os.WriteFile(filepath.Join(root, "installed.json"), original, 0644)
			if _, e := installRelease(root, r, "windows"); e == nil {
				t.Fatal("bad download accepted")
			}
			after, _ := os.ReadFile(filepath.Join(root, "installed.json"))
			if !bytes.Equal(original, after) {
				t.Fatal("state changed")
			}
			entries, _ := os.ReadDir(filepath.Join(root, "versions"))
			if len(entries) != 0 {
				t.Fatal("failed staging leaked")
			}
		})
	}
}
func TestUnsafeArchivesRejected(t *testing.T) {
	for _, name := range []string{"../escape.exe", "/escape.exe", "C:/escape.exe", "dir/../../escape.exe", "dir\\escape.exe"} {
		t.Run(name, func(t *testing.T) {
			root := t.TempDir()
			p := filepath.Join(root, "bad.zip")
			os.WriteFile(p, makeZip(t, map[string]string{name: "bad"}), 0644)
			dest := filepath.Join(root, "out")
			os.Mkdir(dest, 0755)
			if _, e := extract(p, dest, "windows"); e == nil {
				t.Fatal("unsafe path accepted")
			}
		})
	}
}
func TestTarSymlinkRejected(t *testing.T) {
	var b bytes.Buffer
	g := gzip.NewWriter(&b)
	w := tar.NewWriter(g)
	w.WriteHeader(&tar.Header{Name: "link", Typeflag: tar.TypeSymlink, Linkname: "../../outside", Mode: 0777})
	w.Close()
	g.Close()
	root := t.TempDir()
	p := filepath.Join(root, "bad.tar.gz")
	os.WriteFile(p, b.Bytes(), 0644)
	if _, e := extract(p, filepath.Join(root, "out"), "linux"); e == nil {
		t.Fatal("symlink accepted")
	}
}
func TestLockAndRollback(t *testing.T) {
	root := t.TempDir()
	unlock, e := lock(root)
	if e != nil {
		t.Fatal(e)
	}
	if u, e := lock(root); e == nil {
		u()
		t.Fatal("second lock accepted")
	}
	if _, e := run(root, "rollback"); e == nil {
		t.Fatal("mutation allowed under lock")
	}
	unlock()
	b := fixture(t, runtime.GOOS)
	mockDownload(t, b)
	r := release(t, runtime.GOOS, b)
	first, e := installRelease(root, r, runtime.GOOS)
	if e != nil {
		t.Fatal(e)
	}
	second, e := installRelease(root, r, runtime.GOOS)
	if e != nil {
		t.Fatal(e)
	}
	second.Version = "v0.32.0"
	if e = writeState(root, State{Current: second, Previous: first}); e != nil {
		t.Fatal(e)
	}
	result, e := run(root, "rollback")
	if e != nil || result.Current != "v0.31.0" || result.Previous != "v0.32.0" {
		t.Fatalf("%+v %v", result, e)
	}
	// Saves outside the managed folder are never accessed by updater operations.
	sentinel := filepath.Join(t.TempDir(), "farm_v1.json")
	os.WriteFile(sentinel, []byte("keep"), 0644)
	if _, e = run(root, "rollback"); e != nil {
		t.Fatal(e)
	}
	got, _ := os.ReadFile(sentinel)
	if string(got) != "keep" {
		t.Fatal("save changed")
	}
}
func TestAPIAndAssetValidation(t *testing.T) {
	if _, e := request("http://github.com/test"); e == nil {
		t.Fatal("HTTP accepted")
	}
	if _, e := request("https://evil.example/test"); e == nil {
		t.Fatal("unknown host accepted")
	}
	r := Release{Tag: "v0.31.0"}
	if _, e := assetFor(r, "linux"); e == nil {
		t.Fatal("missing asset accepted")
	}
	if _, e := expectedHash(r, Asset{}); e == nil {
		t.Fatal("missing checksum accepted")
	}
	mockDownload(t, []byte(`{"tag_name":"../../bad"}`))
	if _, e := latest(); e == nil {
		t.Fatal("bad tag accepted")
	}
}
func TestOfflineAndMissingExecutable(t *testing.T) {
	old := client
	client = &http.Client{Transport: fakeTransport{nil, 503}}
	defer func() { client = old }()
	root := t.TempDir()
	if _, e := run(root, "check"); e == nil {
		t.Fatal("503 accepted")
	}
	if r, e := run(root, "status"); e != nil || !r.OK {
		t.Fatal("offline local status failed")
	}
	if _, e := run(root, "play"); e == nil {
		t.Fatal("empty install started")
	}
	p := filepath.Join(root, "no-game.zip")
	os.WriteFile(p, makeZip(t, map[string]string{"readme.txt": "hello"}), 0644)
	if _, e := extract(p, filepath.Join(root, "out"), "windows"); e == nil {
		t.Fatal("missing executable accepted")
	}
}
func TestUpdateNoopAndFailure(t *testing.T) {
	b := fixture(t, runtime.GOOS)
	mockDownload(t, b)
	root := t.TempDir()
	rel := release(t, runtime.GOOS, b)
	i, e := installRelease(root, rel, runtime.GOOS)
	if e != nil {
		t.Fatal(e)
	}
	writeState(root, State{Current: i})
	data, _ := json.Marshal(rel)
	client.Transport = fakeTransport{data, 200}
	r, e := run(root, "update")
	if e != nil || !strings.Contains(r.Message, "última") {
		t.Fatalf("%+v %v", r, e)
	}
}

func TestReplyEncoding(t *testing.T) {
	var out bytes.Buffer
	want := Reply{OK: true, Message: "Construção, comércio, Milhão 🌽"}
	writeReply(&out, want)
	for _, b := range out.Bytes() {
		if b > 127 {
			t.Fatal("non-ASCII transport")
		}
	}
	var got Reply
	if e := json.Unmarshal(out.Bytes(), &got); e != nil || got.Message != want.Message {
		t.Fatalf("%+v %v", got, e)
	}
}
