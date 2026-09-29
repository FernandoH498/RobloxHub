# 🌌 GoHub V13 — Definitive Rayfield & Realistic Shader Suite

> **Suite Universal para Roblox** com interface moderna baseada na biblioteca **Rayfield**, pipeline cinemático de iluminação (**Golden Hour Shaders & God Rays**), motor de física avançado, combate com Raycast, suíte completa para Murder Mystery 2 e roda radial de danças personalizável.

---

## ⚡ Carregamento Rápido (Loadstring)

Cole o comando abaixo diretamente no seu executor de preferência:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/FernandoH498/RobloxHub/main/main.lua"))()
```

*Alternativa carregando diretamente a V13:*
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/FernandoH498/RobloxHub/main/GoHubV13.lua"))()
```

---

## ✨ Principais Funcionalidades

### 🎨 1. Interface Rayfield & Sistema de Temas
- Interface moderna, fluida e redimensionável.
- **9 Temas Visuais Integrados:** `Bloom`, `Default`, `AmberGlow`, `Amethyst`, `DarkBlue`, `Green`, `Light`, `Ocean`, `Serenity`.
- **Persistência em Disco:** O tema selecionado é salvo automaticamente em `GoHubV13/SelectedTheme.txt`.
- ColorPickers em tempo real para a cor de destaque (Accent) e cores de funções MM2.

### 🌅 2. Pipeline de Shaders Cinemáticos (Golden Hour)
- **Skybox Fotorrealista:** 6 texturas de alta definição em ângulo crepuscular e céu estrelado.
- **Pós-processamento Cinemático:** Bloom balanceado (0.3/10/0.8), Blur anti-aliasing (5), ColorCorrection e SunRays (God Rays).
- **Reconciliação Não-Destrutiva:** Coexistência inteligente com **Fullbright** e **NoFog** sem deletar ou corromper os efeitos visuais nativos do jogo.
- Comandos dedicados de terminal: `;shader [on/off]`, `;rtx` e `;unshader`.

### 💥 3. DropKick Fling & Física de Arremesso
- **DropKick na Tecla `K`:** Acionamento instantâneo com impulso direcional de 5000.
- **Anti-AutoFling (Recoil Fix):** Trava de velocidade linear e zeragem de rotação angular para que apenas o alvo seja arremessado, mantendo seu personagem 100% estável no chão.
- **Modos Adicionais:** WalkFling, SpinFling com pulso de torque, LoopFling contínuo e Anti-Fling protetor.

### 🔪 4. Murder Mystery 2 (MM2) Suite
- **Detecção Híbrida de Papéis:** Monitoramento simultâneo via listeners de `RemoteEvents` do servidor e varredura de inventário/ferramentas.
- **Identificação Visual:**
  - 🔴 **Assassino:** Destaque vermelho e aviso no chat/notificação.
  - 🔵 **Xerife:** Destaque azul celeste na arma e personagem.
  - 🟢 **Inocentes:** Destaque verde vibrante para identificação imediata.
- **Utilitários:** Coin ESP (Highlight dourado), Auto-Grab Gun (pega a arma caída instantaneamente) e Hitbox Expander ajustável.

### 💃 5. Danças & Roda Radial Circular
- **Roda Radial na Tecla `C`:** Menu circular estilo Roblox com 8 slots de dança favoritos e animações elásticas via TweenService.
- **Atalhos Numéricos:** Teclas `1` a `8` disparam os slots da roda diretamente.
- **Parada Instantânea na Tecla `X`:** Cancela qualquer animação ativa com prioridade de ação.
- **Catálogo Integrado:** Mais de 25 danças (Jamal, Breakdance, Pop & Lock, Floss, Dab, etc.) e suporte a importação de novas animações por ID numérico.

### 👤 6. Skins & Morphs
- **Clonador Completo:** Copia roupas, acessórios, escala e pacote de animações de qualquer jogador próximo ou por User ID.
- **Modificadores Corporais:** Ativação instantânea de `Headless` e `Korblox`.
- **Restauração Perfeita:** Volta ao seu avatar original com um único clique.

### 🎯 7. Combate & Aimbot
- Mira assistida com checagem de visibilidade por **Raycast** (não trava através de paredes).
- Círculo de FOV dinâmico renderizado na tela (suporte a Drawing API nativo com fallback em GUI).
- Interpolação de câmera ajustável (Smoothness).

---

## ⌨️ Teclas Rápidas & Hotkeys

| Tecla / Atalho | Ação Executada |
|---|---|
| `2x W` (Duplo toque) | **Sprint Inteligente** (Velocidade = 25 SPS) |
| `2x Espaço` (Duplo salto) | **Alternar Voo Suave** (Velocidade = 70 SPS) |
| `R` | **Alternar X-Ray** (Paredes do mapa transparentes) |
| `M` | **Alternar MM2 Role ESP** (Assassino, Xerife, Inocentes) |
| `K` | **Drop Kick Fling** (Arremesso direcional com recoil-fix) |
| `C` | **Abrir/Fechar Roda Radial de Danças** |
| `X` | **Parar Dança** imediatamente |
| `1` a `8` | **Selecionar Slot da Roda Radial** |
| `;` ou `'` | **Abrir Command Bar Retrátil** |

---

## 💻 Comandos da Command Bar (`;`)

| Comando | Descrição |
|---|---|
| `;fly` / `;unfly` | Ativa ou desativa o voo suave |
| `;speed [valor]` / `;ws [valor]` | Define a velocidade de caminhada (ex: `;speed 50`) |
| `;noclip` / `;clip` | Atravessar paredes e objetos colidíveis |
| `;infjump` / `;uninfjump` | Pulo infinito |
| `;clicktp` | Segure `Ctrl` e clique com o botão esquerdo para teleportar |
| `;tptool` | Cria uma ferramenta no inventário para teleporte via clique |
| `;tp [alvo]` / `;goto [alvo]` | Teleporta até um jogador (ex: `;tp fer`) |
| `;dropkick [força]` / `;kick` | Executa o Drop Kick com impulso ajustável |
| `;fling [alvo]` | Arremesso instantâneo contra o alvo |
| `;walkfling` / `;loopfling [alvo]` | Modos contínuos de fling |
| `;antifling` | Escudo contra tentativas de arremesso |
| `;shader [on/off]` / `;rtx` | Alterna os shaders realistas Golden Hour |
| `;fullbright` / `;nofog` / `;xray` | Ajustes visuais de iluminação e transparência |
| `;dance [nome/id]` / `;stopdance` | Execução e interrupção de animações |
| `;copy [alvo]` / `;skin [userId]` | Clonar avatar ou aplicar por ID |
| `;headless` / `;korblox` / `;unskin` | Modificações corporais e reset de skin |
| `;serverhop` / `;rejoin` / `;respawn` | Gerenciamento de conexão e personagem |

---

## 🛡️ Compatibilidade de Executores

O GoHub V13 possui arquitetura resiliente desenvolvida para funcionar nos principais executores do ecossistema Roblox:
- ✅ **PC:** Synapse, Wave, KRNL, Script-Ware, Fluxus, Delta, Solara.
- ✅ **Mobile (Android/iOS):** Delta, Fluxus Mobile, Codex, Arceus X.
- ✅ **Fallback de GUI:** Detecção automática de `gethui()`, `get_hidden_gui()`, `syn.protect_gui()` e `CoreGui`.
