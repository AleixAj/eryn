# Eryn

Un RPG de combate por turnos con sabor a gacha que estoy construyendo en Godot 4. Empezó como excusa para entender qué hace que un JRPG se sienta *bien* — el ritmo de los turnos, los críticos saltando dorados del enemigo, las barras de HP bajando suaves en lugar de de golpe — y se está convirtiendo en algo un poco más serio.

Va a su ritmo. Toco el proyecto cuando me apetece.

## Qué hay funcionando

- Pantalla principal con título medieval, animación en cascada y navegación con fades.
- Selección de personaje con 3 héroes (cada uno con stats y estilo propios).
- Combate por turnos 1v1 con animaciones de ataque, hit reaction y muerte.
- Combate 2v1 contra un dragón (Guerrero + Mago) con turnos por aliado, skill propia para cada uno (corte pesado del guerrero, hechizo con orbe del mago), aliento de fuego del dragón y reacciones de daño.
- Sombras dinámicas que se anclan automáticamente a los pies del sprite y se reescalan al cambiar el tamaño del personaje (`SpriteShadow.gd`, `@tool`).
- HP bars con `StyleBoxFlat` custom: marco dorado, brillo superior, sombra inferior, gradiente por color de personaje.
- Botones con estilo medieval (marrón/dorado) y paneles transparentes para que el escenario respire.
- Números de daño flotantes; los críticos salen dorados con scale-pop.
- Skill diferenciada del ataque básico — doble golpe con animación propia y daño total ~140%.
- Barras de HP con tween cúbico, sincronizadas con un contador numérico encima.
- Estados del combate en una FSM pequeña: `PLAYER_TURN → PLAYER_ACTING → ENEMY_ACTING → VICTORY/DEFEAT`.
- Transiciones globales entre escenas con un autoload `SceneTransition` (fade negro, bloqueo de input durante el cambio).
- Build configurada para móvil: orientación landscape forzada, aspect-keep, ETC2/ASTC.

## Stack

- **Engine**: Godot 4.6 (renderer Mobile, backend D3D12).
- **Lenguaje**: GDScript con tipado estático.
- **Datos**: los héroes viven en `data/heroes.json`. Las skills, ítems y enemigos seguirán el mismo patrón.
- **Autoloads**: `GameState` (datos cargados + héroe seleccionado) y `SceneTransition` (fades reutilizables).

## Estructura

```
eryn/
├── assets/         sprites, animaciones, UI, sonidos, fuentes
├── data/           heroes.json, skills.json, enemies.json, items.json
├── scenes/
│   ├── ui/         MainMenu, CharacterSelect…
│   ├── game/       CombatScene, WorldMap…
│   └── bosses/     una escena por boss
├── scripts/
│   ├── entities/   Combatant (base), Hero, Boss
│   ├── managers/   CombatManager (FSM del combate), TestBattle (2v1), GachaManager…
│   ├── ui/         MainMenu, CharacterSelect, widgets reutilizables
│   └── utils/      SpriteShadow (sombras dinámicas), helpers
└── singletons/     GameState, SceneTransition (y los que vendrán: AudioManager, SaveManager…)
```

La separación `data/` ↔ `scripts/` es a propósito: añadir un héroe o ajustar el daño de una skill debería ser tocar JSON, no tocar código. La selección de personaje ya construye sus cards leyendo `heroes.json`, sin un solo dato hardcoded en el `.tscn`.

## Diseño del combate

`Combatant` es la clase base. Centraliza HP, daño, críticos, animaciones y muerte. `Hero` y `Boss` solo enlazan sus nodos hijos del `.tscn` y heredan todo lo demás — así, cuando añada `Mage`, `Rogue` o `Witch`, el combate sigue funcionando sin tocarse.

`Hero` además, al entrar en escena, lee `GameState.selected_hero` y aplica los stats y el tint del personaje elegido. La selección está totalmente desacoplada del combate: si arranco `CombatScene.tscn` directamente desde el editor, los stats por defecto siguen funcionando.

`CombatManager` orquesta los turnos con `await` y nunca toca sprites: cada entidad se anima a sí misma. Así el flujo se lee casi como pseudocódigo:

```gdscript
var result := await hero.attack(boss)
if result.crit:
    add_log("★ ¡CRÍTICO! Eryn ataca por %d." % result.damage)
```

Sin estados intermedios feos, sin polling de animaciones, sin acoplar la lógica al render.

## Flujo del juego

```
                     ┌─JUGAR──▶ [CharacterSelect] ──CONFIRMAR──▶ [Combate 1v1]
[MainMenu] ──────────┼─TEST───▶ [Combate 2v1 vs dragón]
                     └─SALIR──▶ ✕

[CharacterSelect] ──ATRÁS──▶ [MainMenu]
[Combate]         ──MENÚ / REINICIAR──▶ [MainMenu] / [Combate]
```

Cada flecha pasa por un fade negro de `SceneTransition`. Mientras el fade está activo, los clicks quedan bloqueados — un detalle pequeño que evita un montón de race conditions con el doble-click.

## Roadmap

- [x] Combate por turnos con animaciones, críticos y skill
- [x] HP bars con número sincronizado y feedback de daño
- [x] Cargar héroes desde JSON
- [x] Pantalla de selección de personaje
- [x] Sistema de transiciones entre escenas
- [x] Build configurada para Android (landscape, aspect-keep, ETC2/ASTC)
- [x] Combate 2v1 (Guerrero + Mago vs dragón) con animaciones propias por skill
- [x] Sombras dinámicas reutilizables (`SpriteShadow.gd`)
- [ ] Unificar el 2v1 con el flujo principal (selección de party, no escena suelta)
- [ ] Cargar enemigos y skills desde JSON
- [ ] Mapa con nodos y combates encadenados
- [ ] Sistema de gacha (pulls, rareza, pity)
- [ ] Audio (música del combate + SFX de hits y críticos)
- [ ] Persistencia local

## Cómo probarlo

```bash
git clone https://github.com/AleixAj/eryn
```

1. Abrir la carpeta desde Godot 4.6+.
2. `F5` arranca en el menú principal.
3. JUGAR → elige un héroe → CONFIRMAR → combate 1v1.
4. TEST → combate 2v1 (Guerrero + Mago vs dragón) directamente, sin selección.

Para probar en Android, el preset de export `Android (Runnable)` ya está. Con un móvil en modo desarrollador conectado por USB, **One-Click Deploy** desde el editor compila e instala en una pulsación.

## Cosas con las que me he estado peleando

- Darle *juice* al combate sin pasarme — el punto donde se siente reactivo pero no marea.
- Diseñar `Combatant` para que aguante héroes con builds, enemigos con resistencias y bosses con fases sin reescribirla cada vez.
- Entender los recovecos de `TextureProgressBar` — `nine_patch_stretch` y los `stretch_margin_*` hacen más cosas de las que parecían a simple vista.
- Mantener la lógica del combate desacoplada del render: `CombatManager` solo orquesta, las entidades se preocupan de cómo se ven.
- Construir las cards de selección de personaje proceduralmente desde JSON, en lugar de duplicar `.tscn` por cada héroe.
- Que `SceneTransition` no entre en bucles raros con `process_frame` ni se quede a medias si haces doble-click — guard interno y bloqueo de input mediante `mouse_filter`.
- Hacer que las sombras de los personajes sigan a su sprite y se reescalen automáticamente sin que el editor las "cuajara" en el `.tscn`. La solución acabó siendo anclar al borde inferior de la textura (`texture.get_size().y / 2 * scale.y`) y guardar el ajuste fino en píxeles de textura, no de pantalla.

## Inspiraciones

Honkai: Star Rail, Persona 5, Octopath Traveler. Cosas con turnos lentos y peso visual en cada golpe.

## Licencia

MIT.
