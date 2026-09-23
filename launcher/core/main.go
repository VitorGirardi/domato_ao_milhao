package main

import (
	"archive/tar"
	"archive/zip"
	"compress/gzip"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"time"
	"unicode/utf16"
)

const repo = "VitorGirardi/domato_ao_milhao"
const maxArchive = int64(2 << 30)
const maxExpanded = int64(4 << 30)

var client = &http.Client{Timeout: 10 * time.Minute}
var tagPattern = regexp.MustCompile(`^v[0-9]+\.[0-9]+\.[0-9]+$`)

type Asset struct {
	Name   string
	URL    string `json:"browser_download_url"`
	Digest string
	Size   int64
}
type Release struct {
	Tag        string `json:"tag_name"`
	Body       string
	Draft      bool
	Prerelease bool
	Assets     []Asset
}
type Install struct {
	Version    string
	Dir        string
	Executable string
}
type State struct {
	Current  Install
	Previous Install
}
type Reply struct {
	OK       bool
	Message  string
	Current  string
	Previous string
	Latest   string
	Notes    string
	Running  bool
}

func main() {
	reply := Reply{}
	if len(os.Args) < 3 {
		reply.Message = "Uso: updater <status|check|update|play|rollback> <pasta>"
	} else {
		root, err := filepath.Abs(os.Args[2])
		if err == nil {
			err = os.MkdirAll(root, 0755)
		}
		if err == nil {
			reply, err = run(root, os.Args[1])
		}
		if err != nil {
			reply.Message = err.Error()
			reply.OK = false
		}
	}
	writeReply(os.Stdout, reply)
	if !reply.OK {
		os.Exit(1)
	}
}

// ASCII JSON survives Windows console-codepage decoding in Godot's OS.execute.
func writeReply(w io.Writer, reply Reply) {
	b, _ := json.Marshal(reply)
	for _, r := range string(b) {
		if r > 127 {
			for _, unit := range utf16.Encode([]rune{r}) {
				fmt.Fprintf(w, "\\u%04x", unit)
			}
		} else {
			fmt.Fprintf(w, "%c", r)
		}
	}
	fmt.Fprintln(w)
}

func run(root, action string) (Reply, error) {
	s, err := readState(root)
	if err != nil {
		return Reply{}, err
	}
	r := Reply{OK: true, Current: s.Current.Version, Previous: s.Previous.Version}
	if action == "status" {
		unlock, e := lock(root)
		if e != nil {
			r.Running = true
		} else {
			unlock()
		}
		return r, nil
	}
	if action == "check" {
		rel, e := latest()
		if e != nil {
			return r, e
		}
		r.Latest = rel.Tag
		r.Notes = rel.Body
		return r, nil
	}
	unlock, err := lock(root)
	if err != nil {
		return r, errors.New("O jogo ou outra atualização está aberto. Feche e tente novamente.")
	}
	defer unlock()
	// Re-read after acquiring the interprocess lock.
	s, err = readState(root)
	if err != nil {
		return r, err
	}
	switch action {
	case "update":
		rel, e := latest()
		if e != nil {
			return r, e
		}
		r.Latest = rel.Tag
		r.Notes = rel.Body
		if rel.Tag == s.Current.Version {
			if _, e = validInstall(root, s.Current); e == nil {
				r.Message = "Você já está na última versão."
				return r, nil
			}
		}
		next, e := installRelease(root, rel, runtime.GOOS)
		if e != nil {
			return r, e
		}
		nextState := State{Current: next, Previous: s.Current}
		if e = writeState(root, nextState); e != nil {
			return r, e
		}
		r.Current = next.Version
		r.Previous = s.Current.Version
		r.Message = "Atualização concluída. Sua fazenda está pronta!"
	case "rollback":
		if _, err = validInstall(root, s.Previous); err != nil {
			return r, errors.New("Não há versão anterior disponível.")
		}
		s.Current, s.Previous = s.Previous, s.Current
		if err = writeState(root, s); err != nil {
			return r, err
		}
		r.Current = s.Current.Version
		r.Previous = s.Previous.Version
		r.Message = "Versão anterior selecionada."
	case "play":
		path, e := validInstall(root, s.Current)
		if e != nil {
			return r, e
		}
		cmd := exec.Command(path)
		cmd.Dir = filepath.Dir(path)
		log, e := os.OpenFile(filepath.Join(root, "game.log"), os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0644)
		if e != nil {
			return r, e
		}
		defer log.Close()
		cmd.Stdout = log
		cmd.Stderr = log
		// This process holds the lock until the game exits, even if the launcher closes.
		if e = cmd.Run(); e != nil {
			return r, fmt.Errorf("O jogo fechou com erro. Consulte game.log: %w", e)
		}
		r.Message = "Até a próxima visita à fazenda!"
	default:
		return r, errors.New("Ação desconhecida.")
	}
	return r, nil
}

func readState(root string) (State, error) {
	var s State
	b, e := os.ReadFile(filepath.Join(root, "installed.json"))
	if os.IsNotExist(e) {
		return s, nil
	}
	if e != nil {
		return s, e
	}
	if e = json.Unmarshal(b, &s); e != nil {
		return s, errors.New("Registro de instalação inválido. Seus saves continuam separados e preservados.")
	}
	return s, nil
}
func writeState(root string, s State) error {
	b, e := json.MarshalIndent(s, "", "  ")
	if e != nil {
		return e
	}
	f, e := os.CreateTemp(root, "state-*.tmp")
	if e != nil {
		return e
	}
	defer os.Remove(f.Name())
	if _, e = f.Write(b); e == nil {
		e = f.Sync()
	}
	closeErr := f.Close()
	if e != nil {
		return e
	}
	if closeErr != nil {
		return closeErr
	}
	return replaceFile(f.Name(), filepath.Join(root, "installed.json"))
}
func validInstall(root string, i Install) (string, error) {
	if i.Version == "" || !tagPattern.MatchString(i.Version) || !safeName(i.Dir) || !safeName(i.Executable) {
		return "", errors.New("Instale o jogo usando Atualizar e jogar.")
	}
	if !strings.HasPrefix(filepath.ToSlash(i.Dir), "versions/") {
		return "", errors.New("Pasta de instalação inválida.")
	}
	p := filepath.Join(root, i.Dir, i.Executable)
	real, e := filepath.EvalSymlinks(p)
	if e != nil {
		return "", errors.New("Jogo não encontrado. Use Atualizar e jogar.")
	}
	base, e := filepath.EvalSymlinks(filepath.Join(root, "versions"))
	if e != nil {
		return "", e
	}
	rel, e := filepath.Rel(base, real)
	if e != nil || !safeName(rel) {
		return "", errors.New("Instalação fora da pasta de versões.")
	}
	st, e := os.Stat(real)
	if e != nil || !st.Mode().IsRegular() {
		return "", errors.New("Executável inválido.")
	}
	return real, nil
}
func safeName(name string) bool {
	n := filepath.ToSlash(name)
	if strings.Contains(n, "\\") || strings.Contains(n, ":") || strings.HasPrefix(n, "/") {
		return false
	}
	for _, p := range strings.Split(n, "/") {
		if p == ".." {
			return false
		}
	}
	return filepath.IsLocal(name) && name != "."
}
func get(raw string, limit int64) ([]byte, error) {
	resp, e := requestTimeout(raw, 25*time.Second)
	if e != nil {
		return nil, e
	}
	defer resp.Body.Close()
	b, e := io.ReadAll(io.LimitReader(resp.Body, limit+1))
	if e != nil {
		return nil, e
	}
	if int64(len(b)) > limit {
		return nil, errors.New("Resposta maior que o limite permitido.")
	}
	return b, nil
}
func request(raw string) (*http.Response, error) {
	return requestTimeout(raw, 10*time.Minute)
}
func requestTimeout(raw string, timeout time.Duration) (*http.Response, error) {
	u, e := url.Parse(raw)
	if e != nil || u.Scheme != "https" || (u.Host != "api.github.com" && u.Host != "github.com") {
		return nil, errors.New("Endereço de atualização inválido.")
	}
	req, e := http.NewRequest("GET", raw, nil)
	if e != nil {
		return nil, e
	}
	req.Header.Set("User-Agent", "DoMatoAoMilhao-Launcher/1.0")
	req.Header.Set("Accept", "application/vnd.github+json")
	bounded := *client
	bounded.Timeout = timeout
	response, e := bounded.Do(req)
	if e != nil {
		return nil, fmt.Errorf("Sem conexão com o GitHub. Você ainda pode jogar a versão instalada. %w", e)
	}
	if response.StatusCode != 200 {
		response.Body.Close()
		return nil, fmt.Errorf("GitHub retornou HTTP %d. Tente novamente depois; jogar offline continua disponível.", response.StatusCode)
	}
	return response, nil
}
func latest() (Release, error) {
	var r Release
	b, e := get("https://api.github.com/repos/"+repo+"/releases/latest", 2<<20)
	if e != nil {
		return r, e
	}
	if e = json.Unmarshal(b, &r); e != nil {
		return r, e
	}
	if r.Draft || r.Prerelease || !tagPattern.MatchString(r.Tag) {
		return r, errors.New("Nenhuma versão estável compatível foi publicada.")
	}
	return r, nil
}
func assetFor(r Release, platform string) (Asset, error) {
	name := "DoMatoAoMilhao-Windows-" + r.Tag + ".zip"
	if platform == "linux" {
		name = "DoMatoAoMilhao-Linux-" + r.Tag + "-x86_64.tar.gz"
	} else if platform != "windows" {
		return Asset{}, errors.New("Sistema não suportado.")
	}
	for _, a := range r.Assets {
		if a.Name == name && a.Size > 0 && a.Size <= maxArchive {
			return a, nil
		}
	}
	return Asset{}, errors.New("A versão publicada ainda não tem o pacote deste sistema. Tente depois.")
}
func expectedHash(r Release, a Asset) (string, error) {
	if strings.HasPrefix(a.Digest, "sha256:") {
		h := strings.TrimPrefix(a.Digest, "sha256:")
		if b, e := hex.DecodeString(h); e == nil && len(b) == 32 {
			return strings.ToLower(h), nil
		}
	}
	for _, sum := range r.Assets {
		if sum.Name == "SHA256SUMS-"+r.Tag+".txt" {
			b, e := get(sum.URL, 65536)
			if e != nil {
				return "", e
			}
			for _, line := range strings.Split(string(b), "\n") {
				f := strings.Fields(strings.TrimPrefix(line, "\ufeff"))
				if len(f) == 2 && strings.TrimPrefix(f[1], "*") == a.Name {
					if h, e := hex.DecodeString(f[0]); e == nil && len(h) == 32 {
						return strings.ToLower(f[0]), nil
					}
				}
			}
		}
	}
	return "", errors.New("A publicação não inclui SHA-256 válido. A instalação atual foi mantida.")
}
func installRelease(root string, r Release, platform string) (Install, error) {
	a, e := assetFor(r, platform)
	if e != nil {
		return Install{}, e
	}
	hash, e := expectedHash(r, a)
	if e != nil {
		return Install{}, e
	}
	if e = os.MkdirAll(filepath.Join(root, "versions"), 0755); e != nil {
		return Install{}, e
	}
	stage, e := os.MkdirTemp(filepath.Join(root, "versions"), "install-")
	if e != nil {
		return Install{}, e
	}
	keep := false
	defer func() {
		if !keep {
			os.RemoveAll(stage)
		}
	}()
	archive := filepath.Join(stage, "package.download")
	response, e := request(a.URL)
	if e != nil {
		return Install{}, e
	}
	f, e := os.Create(archive)
	if e != nil {
		response.Body.Close()
		return Install{}, e
	}
	h := sha256.New()
	n, e := io.Copy(io.MultiWriter(f, h), io.LimitReader(response.Body, maxArchive+1))
	response.Body.Close()
	ce := f.Close()
	if e != nil {
		return Install{}, e
	}
	if ce != nil {
		return Install{}, ce
	}
	if n != a.Size || hex.EncodeToString(h.Sum(nil)) != hash {
		return Install{}, errors.New("Download incompleto ou SHA-256 divergente. Sua versão atual foi mantida; tente novamente.")
	}
	content := filepath.Join(stage, "game")
	if e = os.Mkdir(content, 0755); e != nil {
		return Install{}, e
	}
	exe, e := extract(archive, content, platform)
	if e != nil {
		return Install{}, e
	}
	os.Remove(archive)
	rel, e := filepath.Rel(root, content)
	if e != nil {
		return Install{}, e
	}
	i := Install{Version: r.Tag, Dir: rel, Executable: exe}
	if _, e = validInstall(root, i); e != nil {
		return Install{}, e
	}
	keep = true
	return i, nil
}
func extract(archive, dest, platform string) (string, error) {
	total := int64(0)
	count := 0
	write := func(name string, size int64, mode os.FileMode, reader io.Reader) error {
		if !safeName(name) || mode&os.ModeSymlink != 0 || (!mode.IsRegular() && !mode.IsDir()) {
			return fmt.Errorf("Arquivo inseguro no pacote: %q", name)
		}
		count++
		total += size
		if count > 10000 || size < 0 || total > maxExpanded {
			return errors.New("Pacote excede os limites de extração.")
		}
		p := filepath.Join(dest, filepath.FromSlash(name))
		if mode.IsDir() {
			return os.MkdirAll(p, 0755)
		}
		if e := os.MkdirAll(filepath.Dir(p), 0755); e != nil {
			return e
		}
		f, e := os.OpenFile(p, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0644)
		if e != nil {
			return e
		}
		n, e := io.CopyN(f, reader, size)
		ce := f.Close()
		if e != nil {
			return e
		}
		if ce != nil {
			return ce
		}
		if n != size {
			return io.ErrUnexpectedEOF
		}
		return nil
	}
	if platform == "windows" {
		z, e := zip.OpenReader(archive)
		if e != nil {
			return "", e
		}
		defer z.Close()
		for _, f := range z.File {
			r, e := f.Open()
			if e != nil {
				return "", e
			}
			e = write(f.Name, int64(f.UncompressedSize64), f.Mode(), r)
			r.Close()
			if e != nil {
				return "", e
			}
		}
	} else {
		f, e := os.Open(archive)
		if e != nil {
			return "", e
		}
		defer f.Close()
		g, e := gzip.NewReader(f)
		if e != nil {
			return "", e
		}
		defer g.Close()
		t := tar.NewReader(g)
		for {
			h, e := t.Next()
			if e == io.EOF {
				break
			}
			if e != nil {
				return "", e
			}
			if h.Name == "." || h.Name == "./" {
				continue
			}
			if h.Typeflag != tar.TypeReg && h.Typeflag != tar.TypeDir {
				return "", errors.New("Links e arquivos especiais não são permitidos.")
			}
			if e = write(h.Name, h.Size, h.FileInfo().Mode(), t); e != nil {
				return "", e
			}
		}
	}
	target := "DoMatoAoMilhao.exe"
	if platform == "linux" {
		target = "DoMatoAoMilhao.x86_64"
	}
	found := ""
	e := filepath.WalkDir(dest, func(p string, d os.DirEntry, e error) error {
		if e != nil {
			return e
		}
		if !d.IsDir() && d.Name() == target {
			if found != "" {
				return errors.New("Pacote contém executáveis duplicados.")
			}
			found = p
		}
		return nil
	})
	if e != nil {
		return "", e
	}
	if found == "" {
		return "", errors.New("Executável do jogo ausente no pacote.")
	}
	if e = os.Chmod(found, 0755); e != nil {
		return "", e
	}
	return filepath.Rel(dest, found)
}
