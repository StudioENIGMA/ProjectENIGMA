# Project ENIGMA — Sistema de Mods

Este diretório contém o **mod loader** do Project ENIGMA e os mods que viajam junto com o repositório (built-in).

O sistema é inspirado em Minecraft Forge: o jogo base permanece quase intacto, e mods são pacotes externos que injetam conteúdo e código no boot.

## Como usar (para jogadores)

1. Abre o jogo
2. No menu principal, clica em **MODS**
3. Marca os mods que quer ativar
4. Clica em **Salvar**
5. **Reinicia o jogo** — mudanças só são aplicadas no próximo boot

Mods built-in (que vêm com a branch `/mods`) ficam em `res://mods/available/`.
Mods de terceiros ficam em `user://mods/`, que no Linux é:
```
~/.local/share/godot/app_userdata/Project ENIGMA/mods/
```

## Como criar um mod

### Estrutura mínima

```
meu_mod/
├── mod.json        # manifesto (obrigatório)
├── data/           # JSON drop-in (opcional)
├── assets/         # imagens, sons (opcional)
└── main.gd         # script com hooks (opcional)
```

### `mod.json` — manifesto

```json
{
  "id": "seunome.nome_do_mod",
  "name": "Nome Visível",
  "version": "0.1.0",
  "authors": ["Seu Nome"],
  "description": "Explicação do que o mod faz.",
  "priority": 100,
  "depends": [],
  "data": {
    "messages_dir": "data/messages",
    "news": { "path": "data/news.json", "mode": "merge" }
  },
  "main_script": "main.gd"
}
```

Campos:

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `id` | string | sim | Identificador único. Use namespace (`autor.nome`). |
| `name` | string | não | Nome exibido na UI. Default: `id`. |
| `version` | string | não | Semver. Default: `0.0.0`. |
| `authors` | array | não | Lista de autores. |
| `description` | string | não | Texto mostrado na tela MODS. |
| `priority` | int | não | Maior carrega primeiro. Default: `0`. |
| `depends` | array | não | IDs de outros mods exigidos pra carregar. |
| `data` | object | não | Sobreposição de dados JSON do jogo. Ver abaixo. |
| `main_script` | string | não | Path relativo de um `.gd` com hooks. |
| `assets` | string | não | Path relativo da pasta de assets. |
| `pack` | string | não | Path relativo de um `.pck` que sobrescreve scripts do jogo. |

### Data targets disponíveis

Cada chave em `"data"` aponta para um lugar específico do jogo:

| Chave | Tipo | Caminho no jogo |
|---|---|---|
| `messages_dir` | diretório | `res://data/messages` |
| `emails_dir` | diretório | `res://data/emails` |
| `tasks_dir` | diretório | `res://data/random/tasks` |
| `scams_dir` | diretório | `res://data/random/scams` |
| `events` | arquivo | `res://data/events/events.json` |
| `news` | arquivo | `res://data/news.json` |
| `shops_items` | arquivo | `res://data/browser/shops_items.json` |
| `pix_codes` | arquivo | `res://data/bank/pix_codes_data.json` |
| `ticket_codes` | arquivo | `res://data/bank/ticket_codes_data.json` |
| `reviews` | arquivo | `res://data/browser/reviewed_companies.json` |

**Diretórios** são aditivos: os JSONs do seu mod são lidos junto com os do jogo base, ordenados alfabeticamente.

**Arquivos** suportam dois modos:
- `"mode": "merge"` (default) — deep merge: dicionários combinam por chave, arrays concatenam, escalares são sobrescritos
- `"mode": "replace"` — substitui o conteúdo inteiro

### `main.gd` — hooks GDScript

```gdscript
extends Node

var api: ModLoaderAPI

func _on_mod_load(mod_api: ModLoaderAPI) -> void:
    api = mod_api
    api.info("inicializado")
    api.hook("post_data_load", _on_data_loaded)
    api.hook("apps_data_loaded", _on_apps_loaded)

func _on_data_loaded(roots: Dictionary) -> void:
    # roots contém: messages, emails, tasks, scams, reviews,
    # shops, pix, tickets, events — todos já com overlays aplicados
    api.info("dados carregados: %d threads de mensagens" % roots.messages.size())

func _on_apps_loaded(apps_data: Dictionary) -> void:
    # apps_data é o dicionário GameData.apps_data
    # Você pode mutar in-place (mudar ícones, descrições, etc)
    pass
```

A API (`ModLoaderAPI`) expõe:

| Método | Descrição |
|---|---|
| `hook(name, callable)` | Registra callback pra um evento. |
| `info(msg)` / `warn(msg)` | Logging com prefixo do mod. |
| `mod_path()` | Retorna o caminho absoluto do mod. |
| `resolve_asset(rel_path)` | Resolve `mod://seu_id/foo.png` pra path real. |

Hooks disponíveis no v1:

| Hook | Args | Quando |
|---|---|---|
| `post_data_load` | `(roots: Dictionary)` | Depois dos JSONs serem carregados, antes dos directors consumirem |
| `apps_data_loaded` | `(apps_data: Dictionary)` | Depois do `GameData._ready` registrar os apps |

### Assets

Coloca arquivos em `assets/` e referencia via URI `mod://`:

```gdscript
var icon_path = api.resolve_asset("icons/meu_icone.png")
var texture = load(icon_path)
```

### Substituindo scripts inteiros (avançado)

Pra mods que precisam reescrever lógica do jogo (estilo Forge bytecode injection), use o campo `"pack"` no manifesto apontando pra um `.pck`:

```json
{
  "id": "seu.mod",
  "pack": "patches.pck"
}
```

O loader chama `ProjectSettings.load_resource_pack(path, replace_files=true)` — arquivos do `.pck` substituem os do jogo base com mesmo path.

Como buildar o `.pck`: usar o Godot editor com um projeto separado que tem só os arquivos modificados na mesma estrutura `res://`. Ferramenta: **Project > Export > Add... > Export PCK/ZIP**.

## Segurança

Mods em `user://mods/` que incluem `main_script` têm **acesso total às APIs do GDScript**: podem ler/escrever arquivos, chamar `OS.execute`, fazer requisições de rede etc. Trate-os como qualquer plugin de terceiros — instala só de fontes confiáveis.

O loader emite um warning no console quando carrega script de mod do `user://`.

## Layout do diretório `mods/`

```
mods/
├── README.md                       # este arquivo
├── loader/                         # implementação do loader
│   ├── mod_descriptor.gd           # parser do mod.json
│   ├── mod_loader_api.gd           # fachada que mods recebem
│   └── ui/
│       ├── mods_screen.tscn        # tela MODS do menu principal
│       ├── mods_screen.gd
│       └── mods_button_handler.gd  # handler do botão MODS
└── available/                      # mods built-in
    └── exemplo_basico/
        ├── mod.json
        ├── main.gd
        └── data/messages/modsbot_branches.json
```

A lógica central (`ModLoader` autoload) está em [scripts/singletons/mod_loader.gd](../scripts/singletons/mod_loader.gd).
