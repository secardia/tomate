#!/usr/bin/env python3
"""PNG clairs : événements · barre vue Jour · colonnes stats."""

from __future__ import annotations

import shutil
from dataclasses import dataclass
from pathlib import Path

import matplotlib.patches as mpatches
import matplotlib.pyplot as plt
from matplotlib.axes import Axes

ROOT = Path(__file__).resolve().parent.parent
OUT_DIR = ROOT / "docs" / "test-timelines"
INDEX_PATH = OUT_DIR / "00-index.png"

# AppColors
C_FOCUS = "#E67873"
C_REST = "#8C94D9"
C_IDLE = "#383838"
C_BAR_BG = "#292929"
C_BG = "#1C1C1F"
C_PANEL = "#222226"
C_SECTION = "#2A2A2E"
C_TEXT = "#E8E8E8"
C_MUTED = "#9A9A9A"
C_ACCENT = "#6EB5FF"
C_OBSERVE = "#FFD580"
C_BTN = "#6EB5FF"
INSET = 0.05

RULES = (
    "Lance chrono : Démarrer · Reprendre · Passer (phase suivante) · "
    "Save direct : Pause · Passer (fin phase) · Réinitialiser · fin chrono · "
    "Dates save = segment en cours (start…instant du clic)"
)


@dataclass
class TimelineEvent:
    at: float
    button: str
    note: str = ""


@dataclass
class StatsExpectation:
    focus_duration: float
    rest_duration: float
    focus_count: int
    rest_count: int
    sessions_in_db: int = 0


@dataclass
class TestDiagram:
    test_name: str
    title: str
    when: str
    observe_at: float
    events: list[TimelineEvent]
    chrono: list[tuple[str, float]]
    graph: list[tuple[str, float]]
    stats: StatsExpectation
    persisted_graph: list[tuple[str, float]] | None = None

    @property
    def display_graph(self) -> list[tuple[str, float]]:
        return self.graph

    @property
    def db_graph(self) -> list[tuple[str, float]]:
        return self.persisted_graph if self.persisted_graph is not None else self.graph

    @property
    def show_db_section(self) -> bool:
        """Affiche 2a Timeline DB quand persisté est renseigné (même si = affiché)."""

        return self.persisted_graph is not None

    @property
    def has_split_graph(self) -> bool:
        return self.show_db_section and self.persisted_graph != self.graph


def seg(kind: str, *pairs: tuple[str, float]) -> list[tuple[str, float]]:
    return list(pairs)


KIND_COLOR = {"focus": C_FOCUS, "rest": C_REST}
KIND_LABEL = {"focus": "Concentration", "rest": "Pause"}


TESTS: list[TestDiagram] = [
    TestDiagram(
        "testScenarioPassFocus2Seconds",
        "Passer après 2 s de focus",
        "Après Passer · t = 2 s",
        2,
        [TimelineEvent(0, "Démarrer"), TimelineEvent(2, "Passer", "2 s → save")],
        seg("focus", ("focus", 2)),
        seg("focus", ("focus", 2)),
        StatsExpectation(2, 0, 0, 0, 1),
    ),
    TestDiagram(
        "testScenarioPassFocus3SecondsCountsSession",
        "Passer après 3 s — compte 1 phase",
        "Après Passer · t = 3 s",
        3,
        [TimelineEvent(0, "Démarrer"), TimelineEvent(3, "Passer", "3 s → save")],
        seg("focus", ("focus", 3)),
        seg("focus", ("focus", 3)),
        StatsExpectation(3, 0, 1, 0, 1),
    ),
    TestDiagram(
        "testScenarioPassFocus1Second",
        "Passer après 1 s — durée oui, phase non",
        "Après Passer · t = 1 s",
        1,
        [TimelineEvent(0, "Démarrer"), TimelineEvent(1, "Passer", "1 s → save")],
        seg("focus", ("focus", 1)),
        seg("focus", ("focus", 1)),
        StatsExpectation(1, 0, 0, 0, 1),
    ),
    TestDiagram(
        "testScenarioPauseResumeThenPass",
        "Pause chrono → 2 sessions focus",
        "Après Passer · t = 7 s",
        7,
        [
            TimelineEvent(0, "Démarrer"),
            TimelineEvent(2, "Pause", "2 s → save"),
            TimelineEvent(5, "Reprendre", "nouvelle session"),
            TimelineEvent(7, "Passer", "2 s → save"),
        ],
        seg("focus", ("focus", 2), ("focus", 2)),
        seg("focus", ("focus", 2), ("focus", 2)),
        StatsExpectation(4, 0, 0, 0, 2),
    ),
    TestDiagram(
        "testScenarioShortPauseStillShowsGray",
        "Pause courte — 2 sessions focus",
        "Après Passer · t = 5 s",
        5,
        [
            TimelineEvent(0, "Démarrer"),
            TimelineEvent(2, "Pause", "2 s → save"),
            TimelineEvent(3, "Reprendre", "nouvelle session"),
            TimelineEvent(5, "Passer", "2 s → save"),
        ],
        seg("focus", ("focus", 2), ("focus", 2)),
        seg("focus", ("focus", 2), ("focus", 2)),
        StatsExpectation(4, 0, 0, 0, 2),
    ),
    TestDiagram(
        "testScenarioKeepsShortTrailingFocusSegment",
        "Dernier bout de focus 1 s conservé",
        "Après Passer · t = 9 s",
        9,
        [
            TimelineEvent(0, "Démarrer"),
            TimelineEvent(5, "Pause", "5 s → save"),
            TimelineEvent(8, "Reprendre", "nouvelle session"),
            TimelineEvent(9, "Passer", "1 s → save"),
        ],
        seg("focus", ("focus", 5), ("focus", 1)),
        seg("focus", ("focus", 5), ("focus", 1)),
        StatsExpectation(6, 0, 1, 0, 2),
    ),
    TestDiagram(
        "testScenarioWhilePausedLiveGraphFrozen",
        "Pendant la pause : barre figée, pas de gris live",
        "Pendant la pause · t = 32 s (+30 s d’attente)",
        32,
        [
            TimelineEvent(0, "Démarrer"),
            TimelineEvent(2, "Pause", "2 s → save"),
        ],
        seg("focus", ("focus", 2)),
        seg("focus", ("focus", 2)),
        StatsExpectation(2, 0, 0, 0, 1),
    ),
    TestDiagram(
        "testScenarioNaturalCompletionAfterPause",
        "Fin naturelle après pause longue",
        "Fin chrono · t = 15 s",
        15,
        [
            TimelineEvent(0, "Démarrer"),
            TimelineEvent(2, "Pause", "2 s → save"),
            TimelineEvent(12, "Reprendre", "nouvelle session"),
            TimelineEvent(15, "Fin chrono", "3 s → save"),
        ],
        seg("focus", ("focus", 2), ("focus", 3)),
        seg("focus", ("focus", 2), ("focus", 3)),
        StatsExpectation(5, 0, 1, 0, 2),
    ),
    TestDiagram(
        "testScenarioNaturalCompletionSimple",
        "Fin naturelle focus 5 s",
        "Fin chrono · t = 5 s",
        5,
        [TimelineEvent(0, "Démarrer"), TimelineEvent(5, "Fin chrono", "5 s → save")],
        seg("focus", ("focus", 5)),
        seg("focus", ("focus", 5)),
        StatsExpectation(5, 0, 1, 0, 1),
    ),
    TestDiagram(
        "testScenarioReinitWhilePaused",
        "Réinitialiser pendant la pause",
        "Après Réinitialiser · t = 13 s · phase = focus",
        13,
        [
            TimelineEvent(0, "Démarrer"),
            TimelineEvent(3, "Pause", "3 s → save"),
            TimelineEvent(13, "Réinitialiser", "focus déjà save à la Pause"),
        ],
        seg("focus", ("focus", 3)),
        seg("focus", ("focus", 3)),
        StatsExpectation(3, 0, 1, 0, 1),
    ),
    TestDiagram(
        "testScenarioReinitShortFocus",
        "Réinitialiser après 2 s",
        "Après Réinitialiser · t = 2 s",
        2,
        [TimelineEvent(0, "Démarrer"), TimelineEvent(2, "Réinitialiser", "2 s → save")],
        seg("focus", ("focus", 2)),
        seg("focus", ("focus", 2)),
        StatsExpectation(2, 0, 0, 0, 1),
    ),
    TestDiagram(
        "testScenarioReinitAfterPauseResumeKeepsAllSegments",
        "Réinit garde les sessions focus",
        "Après Réinitialiser · t = 9 s",
        9,
        [
            TimelineEvent(0, "Démarrer"),
            TimelineEvent(5, "Pause", "5 s → save"),
            TimelineEvent(8, "Reprendre", "nouvelle session"),
            TimelineEvent(9, "Réinitialiser", "1 s → save"),
        ],
        seg("focus", ("focus", 5), ("focus", 1)),
        seg("focus", ("focus", 5), ("focus", 1)),
        StatsExpectation(6, 0, 1, 0, 2),
    ),
    TestDiagram(
        "testScenarioFocusThenCalmShortRest",
        "Focus puis calm 2 s — calm pas compté",
        "Après 2e Passer · t = 5 s",
        5,
        [
            TimelineEvent(0, "Démarrer"),
            TimelineEvent(3, "Passer", "3 s focus → save"),
            TimelineEvent(5, "Passer", "2 s calm → save"),
        ],
        seg("focus", ("focus", 3), ("rest", 2)),
        seg("focus", ("focus", 3), ("rest", 2)),
        StatsExpectation(3, 2, 1, 0, 2),
        persisted_graph=seg("focus", ("focus", 3), ("rest", 2)),
    ),
    TestDiagram(
        "testScenarioFocusThenCalmBothCount",
        "Focus puis calm 3 s — les deux comptés",
        "Après 2e Passer · t = 6 s",
        6,
        [
            TimelineEvent(0, "Démarrer"),
            TimelineEvent(3, "Passer", "3 s focus → save"),
            TimelineEvent(6, "Passer", "3 s calm → save"),
        ],
        seg("focus", ("focus", 3), ("rest", 3)),
        seg("focus", ("focus", 3), ("rest", 3)),
        StatsExpectation(3, 3, 1, 1, 2),
    ),
    TestDiagram(
        "testScenarioReprendreDoesNotSaveUntilPausePassOrReinit",
        "Reprendre ne save pas — seule la Pause a flush",
        "Après Reprendre · t = 20 s (sans Passer)",
        20,
        [
            TimelineEvent(0, "Démarrer"),
            TimelineEvent(10, "Pause", "10 s → save direct"),
            TimelineEvent(13, "Reprendre", "lance chrono · pas de save"),
        ],
        seg("focus", ("focus", 10), ("focus", 7)),
        seg("focus", ("focus", 10), ("focus", 7)),
        StatsExpectation(17, 0, 1, 0, 1),
        persisted_graph=seg("focus", ("focus", 10)),
    ),
    TestDiagram(
        "testScenarioLiveGraphBeforePass",
        "Pause à 10 s → 1 session save · +15 s live",
        "Sans Passer · t = 28 s",
        28,
        [
            TimelineEvent(0, "Démarrer"),
            TimelineEvent(10, "Pause", "10 s → enregistré"),
            TimelineEvent(13, "Reprendre", "nouvelle session"),
        ],
        seg("focus", ("focus", 10), ("focus", 15)),
        seg("focus", ("focus", 10), ("focus", 15)),
        StatsExpectation(25, 0, 1, 0, 1),
        persisted_graph=seg("focus", ("focus", 10)),
    ),
    TestDiagram(
        "testScenarioLiveGraphAfterPassWithCalmRunning",
        "Après Passer : historique + calm live",
        "Pendant calm · t = 11 s",
        11,
        [
            TimelineEvent(0, "Démarrer"),
            TimelineEvent(3, "Pause", "3 s → save"),
            TimelineEvent(6, "Reprendre", "nouvelle session"),
            TimelineEvent(9, "Passer", "focus 3 s → save · calm live"),
        ],
        seg("focus", ("focus", 3), ("focus", 3), ("rest", 2)),
        seg("focus", ("focus", 3), ("focus", 3), ("rest", 2)),
        StatsExpectation(6, 2, 2, 0, 2),
        persisted_graph=seg("focus", ("focus", 3), ("focus", 3)),
    ),
    TestDiagram(
        "testScenarioPassWithZeroActiveRecordsNothing",
        "Passer sans démarrer",
        "Immédiat · t = 0 s",
        0,
        [TimelineEvent(0, "Passer")],
        [],
        [],
        StatsExpectation(0, 0, 0, 0, 0),
    ),
    TestDiagram(
        "testScenarioResetWithoutProgressRecordsNothing",
        "Réinitialiser sans démarrer",
        "Immédiat · t = 0 s",
        0,
        [TimelineEvent(0, "Réinitialiser")],
        [],
        [],
        StatsExpectation(0, 0, 0, 0, 0),
    ),
]


def segs_to_absolute(specs: list[tuple[str, float]]) -> list[tuple[str, float, float]]:
    out: list[tuple[str, float, float]] = []
    t = 0.0
    for kind, dur in specs:
        if dur <= 0:
            continue
        out.append((kind, t, t + dur))
        t += dur
    return out


def mmss(seconds: float) -> str:
    s = int(seconds)
    return f"{s // 60:02d}:{s % 60:02d}"


def clock_duration(seconds: float) -> str:
    """Comme DurationFormatter.clockDuration — arrondi minute supérieure."""
    total_minutes = max(0, int(-(-seconds / 60)))  # ceil
    return f"{total_minutes // 60:02d}:{total_minutes % 60:02d}"


def graph_range(segments: list[tuple[str, float, float]]) -> tuple[float, float] | None:
    if not segments:
        return None
    return segments[0][1], segments[-1][2]


def section_header(ax: Axes, num: str, title: str, subtitle: str) -> None:
    ax.set_facecolor(C_SECTION)
    ax.axis("off")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.add_patch(
        mpatches.FancyBboxPatch(
            (0, 0),
            1,
            1,
            boxstyle="round,pad=0.01,rounding_size=0.02",
            facecolor=C_SECTION,
            edgecolor="#444",
            linewidth=0.6,
        )
    )
    ax.text(0.02, 0.55, f"{num}. {title}", color=C_TEXT, fontsize=11, fontweight="bold", va="center")
    ax.text(0.02, 0.2, subtitle, color=C_MUTED, fontsize=8.5, va="center")


def graph_diff_note(test: TestDiagram) -> str:
    notes: list[str] = []
    if test.chrono != test.display_graph:
        notes.append("Bandeau §1 = durées actives · trous de pause non enregistrés.")
    if test.show_db_section:
        notes.append("2a = assertTimeline · 2b = assertDisplayTimeline.")
    if test.has_split_graph:
        notes.append("Barre du bas inclut du live non persisté.")
    elif test.show_db_section and test.db_graph == test.display_graph:
        notes.append("Tout est en base (timeline = barre affichée).")
    elif test.stats.rest_duration > 0 and test.display_graph and test.display_graph[-1][0] == "rest":
        if test.db_graph == test.display_graph or not any(k == "rest" for k, _ in test.db_graph):
            notes.append(f"Cumul calm +{test.stats.rest_duration:.0f}s live (phase en cours).")
    elif test.stats.focus_duration > 0 and test.display_graph:
        live_focus = sum(d for k, d in test.display_graph if k == "focus") - sum(
            d for k, d in test.db_graph if k == "focus"
        )
        if live_focus > 0.5:
            persisted = test.stats.focus_duration - live_focus
            notes.append(f"Cumul focus : {persisted:.0f}s base + {live_focus:.0f}s live.")
    return " · ".join(notes)


def specs_equal(a: list[tuple[str, float]], b: list[tuple[str, float]]) -> bool:
    return a == b


# Miroir de TimelineScenarioTests — kinds: focus | rest
SWIFT_EXPECTATIONS: dict[str, dict] = {
    "testScenarioPassFocus2Seconds": {
        "persisted": [("focus", 2)],
        "display": [("focus", 2)],
        "stats": (2, 0, 0, 0, 1),
    },
    "testScenarioPassFocus3SecondsCountsSession": {
        "persisted": [("focus", 3)],
        "display": [("focus", 3)],
        "stats": (3, 0, 1, 0, 1),
    },
    "testScenarioPassFocus1Second": {
        "persisted": [("focus", 1)],
        "display": [("focus", 1)],
        "stats": (1, 0, 0, 0, 1),
    },
    "testScenarioPauseResumeThenPass": {
        "persisted": [("focus", 2), ("focus", 2)],
        "display": [("focus", 2), ("focus", 2)],
        "stats": (4, 0, 0, 0, 2),
    },
    "testScenarioShortPauseStillShowsGray": {
        "persisted": [("focus", 2), ("focus", 2)],
        "display": [("focus", 2), ("focus", 2)],
        "stats": (4, 0, 0, 0, 2),
    },
    "testScenarioKeepsShortTrailingFocusSegment": {
        "persisted": [("focus", 5), ("focus", 1)],
        "display": [("focus", 5), ("focus", 1)],
        "stats": (6, 0, 1, 0, 2),
    },
    "testScenarioWhilePausedLiveGraphFrozen": {
        "persisted": [("focus", 2)],
        "display": [("focus", 2)],
        "stats": (2, 0, 0, 0, 1),
    },
    "testScenarioNaturalCompletionAfterPause": {
        "persisted": [("focus", 2), ("focus", 3)],
        "display": [("focus", 2), ("focus", 3)],
        "stats": (5, 0, 1, 0, 2),
    },
    "testScenarioNaturalCompletionSimple": {
        "persisted": [("focus", 5)],
        "display": [("focus", 5)],
        "stats": (5, 0, 1, 0, 1),
    },
    "testScenarioReinitWhilePaused": {
        "persisted": [("focus", 3)],
        "display": [("focus", 3)],
        "stats": (3, 0, 1, 0, 1),
    },
    "testScenarioReinitShortFocus": {
        "persisted": [("focus", 2)],
        "display": [("focus", 2)],
        "stats": (2, 0, 0, 0, 1),
    },
    "testScenarioReinitAfterPauseResumeKeepsAllSegments": {
        "persisted": [("focus", 5), ("focus", 1)],
        "display": [("focus", 5), ("focus", 1)],
        "stats": (6, 0, 1, 0, 2),
    },
    "testScenarioFocusThenCalmShortRest": {
        "persisted": [("focus", 3), ("rest", 2)],
        "display": [("focus", 3), ("rest", 2)],
        "stats": (3, 2, 1, 0, 2),
    },
    "testScenarioFocusThenCalmBothCount": {
        "persisted": [("focus", 3), ("rest", 3)],
        "display": [("focus", 3), ("rest", 3)],
        "stats": (3, 3, 1, 1, 2),
    },
    "testScenarioReprendreDoesNotSaveUntilPausePassOrReinit": {
        "persisted": [("focus", 10)],
        "display": [("focus", 10), ("focus", 7)],
        "stats": (17, 0, 1, 0, 1),
    },
    "testScenarioLiveGraphBeforePass": {
        "persisted": [("focus", 10)],
        "display": [("focus", 10), ("focus", 15)],
        "stats": (25, 0, 1, 0, 1),
    },
    "testScenarioLiveGraphAfterPassWithCalmRunning": {
        "persisted": [("focus", 3), ("focus", 3)],
        "display": [("focus", 3), ("focus", 3), ("rest", 2)],
        "stats": (6, 2, 2, 0, 2),
    },
    "testScenarioPassWithZeroActiveRecordsNothing": {
        "persisted": [],
        "display": [],
        "stats": (0, 0, 0, 0, 0),
    },
    "testScenarioResetWithoutProgressRecordsNothing": {
        "persisted": [],
        "display": [],
        "stats": (0, 0, 0, 0, 0),
    },
}


def validate_diagrams() -> list[str]:
    errors: list[str] = []
    test_names = {t.test_name for t in TESTS}
    swift_names = set(SWIFT_EXPECTATIONS.keys())

    missing_diagrams = swift_names - test_names
    missing_swift = test_names - swift_names
    if missing_diagrams:
        errors.append(f"TESTS missing PNG for: {sorted(missing_diagrams)}")
    if missing_swift:
        errors.append(f"SWIFT_EXPECTATIONS missing entry for: {sorted(missing_swift)}")

    for test in TESTS:
        exp = SWIFT_EXPECTATIONS.get(test.test_name)
        if exp is None:
            continue
        if not specs_equal(test.db_graph, exp["persisted"]):
            errors.append(f"{test.test_name}: persisted {test.db_graph} != {exp['persisted']}")
        if not specs_equal(test.display_graph, exp["display"]):
            errors.append(f"{test.test_name}: display {test.display_graph} != {exp['display']}")
        s = test.stats
        fd, rd, fc, rc, sc = exp["stats"]
        if (s.focus_duration, s.rest_duration, s.focus_count, s.rest_count, s.sessions_in_db) != (
            fd,
            rd,
            fc,
            rc,
            sc,
        ):
            errors.append(
                f"{test.test_name}: stats mismatch "
                f"got ({s.focus_duration},{s.rest_duration},{s.focus_count},{s.rest_count},{s.sessions_in_db}) "
                f"want {exp['stats']}"
            )
        if test.chrono != test.display_graph and test.test_name != "testScenarioWhilePausedLiveGraphFrozen":
            # chrono = wall clock band; may differ from display only when paused (frozen bar)
            pass
    return errors


def draw_proportional_bar(
    ax: Axes,
    segments: list[tuple[str, float, float]],
    *,
    title: str = "",
    empty_label: str = "Aucune barre (jour vide)",
    note: str = "",
) -> None:
    ax.set_facecolor(C_BG)
    ax.axis("off")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)

    if title:
        ax.text(0.02, 0.96, title, color=C_ACCENT, fontsize=8.5, fontweight="bold", va="top")

    bar_y, bar_h = 0.38, 0.20
    left, right = INSET, 1 - INSET
    width = right - left

    ax.add_patch(mpatches.Rectangle((left, bar_y), width, bar_h, facecolor=C_BAR_BG, edgecolor="none"))

    rng = graph_range(segments)
    if rng is None:
        ax.text(0.5, 0.52, empty_label, ha="center", va="center", color=C_MUTED, fontsize=10)
        return

    start, end = rng
    total = end - start
    if total <= 0:
        return

    for kind, s, e in segments:
        rel_start = (s - start) / total
        rel_w = (e - s) / total
        ax.add_patch(
            mpatches.Rectangle(
                (left + rel_start * width, bar_y),
                max(0.004, rel_w * width),
                bar_h,
                facecolor=KIND_COLOR[kind],
                edgecolor="none",
            )
        )

    ax.text(left, bar_y + bar_h + 0.08, mmss(start), color=C_MUTED, fontsize=9, ha="left", va="bottom")
    ax.text(right, bar_y + bar_h + 0.08, mmss(end), color=C_MUTED, fontsize=9, ha="right", va="bottom")

    legend_x = left
    for kind, s, e in segments:
        dur = e - s
        label = f"{KIND_LABEL[kind]} {dur:.0f}s"
        ax.add_patch(mpatches.Rectangle((legend_x, 0.08), 0.025, 0.06, facecolor=KIND_COLOR[kind]))
        ax.text(legend_x + 0.035, 0.11, label, color=C_TEXT, fontsize=8, va="center")
        legend_x += 0.22

    if note:
        ax.text(0.5, 0.92, note, ha="center", va="top", color=C_OBSERVE, fontsize=8, wrap=True)


def draw_events(ax: Axes, test: TestDiagram) -> None:
    ax.set_facecolor(C_BG)
    ax.axis("off")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)

    t_max = max(test.observe_at, 1)
    track_left, track_right = 0.08, 0.96
    track_w = track_right - track_left
    y_track = 0.72
    h_track = 0.12

    chrono = segs_to_absolute(test.chrono)
    if chrono:
        for kind, s, e in chrono:
            x0 = track_left + (s / t_max) * track_w
            w = max(0.003, ((e - s) / t_max) * track_w)
            ax.add_patch(mpatches.Rectangle((x0, y_track), w, h_track, facecolor=KIND_COLOR[kind], alpha=0.85))
    else:
        ax.add_patch(mpatches.Rectangle((track_left, y_track), track_w, h_track, facecolor=C_BAR_BG))

    ax.plot([track_left, track_right], [y_track - 0.04, y_track - 0.04], color="#555", lw=0.8)
    for tick in range(0, int(t_max) + 1):
        x = track_left + (tick / t_max) * track_w
        ax.plot([x, x], [y_track - 0.05, y_track - 0.03], color="#666", lw=0.6)
        ax.text(x, y_track - 0.08, f"{tick}s", ha="center", va="top", color=C_MUTED, fontsize=7)

    ox = track_left + (test.observe_at / t_max) * track_w
    ax.axvline(ox, ymin=0.05, ymax=0.95, color=C_OBSERVE, ls="--", lw=1.2, alpha=0.9)
    ax.text(ox, 0.04, "observer", ha="center", va="bottom", color=C_OBSERVE, fontsize=8, rotation=90)

    y = 0.48
    for ev in test.events:
        x = track_left + (ev.at / t_max) * track_w
        ax.plot([x, x], [y_track, y + 0.06], color=C_BTN, lw=0.8, alpha=0.5)
        ax.add_patch(
            mpatches.FancyBboxPatch(
                (x - 0.055, y),
                0.11,
                0.11,
                boxstyle="round,pad=0.01,rounding_size=0.015",
                facecolor="#1A3A5C",
                edgecolor=C_BTN,
                linewidth=1,
            )
        )
        ax.text(x, y + 0.055, ev.button, ha="center", va="center", color=C_TEXT, fontsize=7.5, fontweight="bold")
        ax.text(x, y - 0.02, f"t={ev.at:.0f}s", ha="center", va="top", color=C_MUTED, fontsize=7)
        if ev.note:
            ax.text(x, y - 0.08, ev.note, ha="center", va="top", color=C_MUTED, fontsize=6.5, style="italic")
        y -= 0.14 if ev.note else 0.11


def draw_stats_columns(ax: Axes, stats: StatsExpectation) -> None:
    ax.set_facecolor(C_BG)
    ax.axis("off")
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)

    empty = stats.focus_duration == 0 and stats.rest_duration == 0
    if empty:
        ax.text(
            0.5,
            0.5,
            "Colonnes masquées (aucune durée enregistrée)",
            ha="center",
            va="center",
            color=C_MUTED,
            fontsize=10,
        )
        ax.text(
            0.5,
            0.35,
            f"Sessions {stats.focus_count} · Pauses {stats.rest_count}",
            ha="center",
            va="center",
            color=C_MUTED,
            fontsize=9,
        )
        return

    cols = [
        ("Sessions", stats.focus_count, stats.focus_duration, C_FOCUS),
        ("Pauses", stats.rest_count, stats.rest_duration, C_REST),
    ]
    for i, (title, count, duration, color) in enumerate(cols):
        cx = 0.25 + i * 0.5
        ax.text(cx, 0.82, title, ha="center", va="center", color=color, fontsize=12, fontweight="medium")
        ax.text(cx, 0.52, str(count), ha="center", va="center", color=color, fontsize=36, fontweight="medium")
        ax.text(cx, 0.22, clock_duration(duration), ha="center", va="center", color=C_MUTED, fontsize=14)
        ax.text(
            cx,
            0.08,
            f"cumul réel {duration:.0f} s",
            ha="center",
            va="center",
            color=C_MUTED,
            fontsize=8,
        )

    ax.text(
        0.5,
        0.95,
        "Grand chiffre = phases comptées (≥ seuil) · durée = cumul réel sous le chiffre",
        ha="center",
        va="top",
        color=C_MUTED,
        fontsize=7.5,
    )
    if stats.sessions_in_db:
        ax.text(
            0.5,
            -0.12,
            f"{stats.sessions_in_db} session(s) en base",
            ha="center",
            va="top",
            color=C_OBSERVE,
            fontsize=8,
            transform=ax.transAxes,
        )


def render_test_page(test: TestDiagram, path: Path) -> None:
    note = graph_diff_note(test)
    fig_h = 10.2 if test.show_db_section else 9.5
    fig = plt.figure(figsize=(10, fig_h), facecolor=C_BG)

    fig.text(0.05, 0.97, test.title, color="white", fontsize=15, fontweight="bold", va="top")
    fig.text(0.05, 0.935, test.test_name, color=C_ACCENT, fontsize=9, fontfamily="monospace", va="top")
    fig.text(0.05, 0.91, test.when, color=C_OBSERVE, fontsize=10, va="top")

    ax_h1 = fig.add_axes([0.04, 0.86, 0.92, 0.035])
    section_header(ax_h1, "1", "Chronologie des clics", "Bandeau = horloge réelle · pastilles = boutons")

    ax_ev = fig.add_axes([0.04, 0.58, 0.92, 0.26])
    draw_events(ax_ev, test)

    if test.show_db_section:
        ax_h2 = fig.add_axes([0.04, 0.53, 0.92, 0.035])
        subtitle = (
            "Haut = assertTimeline · Bas = assertDisplayTimeline (DayTimelineBar)"
            if test.has_split_graph
            else "Haut = assertTimeline · Bas = identique (tout persisté)"
        )
        section_header(ax_h2, "2", "Timeline — base vs affiché", subtitle)
        db_note = ""
        if test.stats.sessions_in_db == 2 and test.test_name == "testScenarioFocusThenCalmShortRest":
            db_note = "Sessions en base : focus 3 s · calm 2 s"
        ax_db = fig.add_axes([0.04, 0.44, 0.92, 0.085])
        draw_proportional_bar(
            ax_db,
            segs_to_absolute(test.db_graph),
            title="2a · Timeline DB (persisté)",
            note=db_note,
        )
        ax_bar = fig.add_axes([0.04, 0.33, 0.92, 0.085])
        draw_proportional_bar(
            ax_bar,
            segs_to_absolute(test.display_graph),
            title="2b · Barre vue Jour (affiché)",
            note=note,
        )
        leg_y = 0.28
        stats_y = 0.05
        stats_h = 0.20
        h3_y = 0.25
    else:
        ax_h2 = fig.add_axes([0.04, 0.53, 0.92, 0.035])
        section_header(
            ax_h2,
            "2",
            "Barre historique — vue Jour",
            "assertTimeline = assertDisplayTimeline · proportions horloge",
        )
        ax_bar = fig.add_axes([0.04, 0.38, 0.92, 0.13])
        draw_proportional_bar(
            ax_bar,
            segs_to_absolute(test.display_graph),
            title="assertDisplayTimeline",
            note=note,
        )
        leg_y = 0.33
        stats_y = 0.05
        stats_h = 0.20
        h3_y = 0.27

    ax_leg = fig.add_axes([0.04, leg_y, 0.92, 0.04])
    ax_leg.set_facecolor(C_BG)
    ax_leg.axis("off")
    ax_leg.legend(
        handles=[
            mpatches.Patch(facecolor=C_FOCUS, label="Concentration"),
            mpatches.Patch(facecolor=C_REST, label="Pause (phase calm)"),
        ],
        loc="center",
        ncol=2,
        frameon=False,
        labelcolor=C_TEXT,
        fontsize=8,
    )

    ax_h3 = fig.add_axes([0.04, h3_y, 0.92, 0.035])
    section_header(ax_h3, "3", "Colonnes stats — vue Jour", "assertStats + assertSessions")

    ax_stats = fig.add_axes([0.04, stats_y, 0.92, stats_h])
    draw_stats_columns(ax_stats, test.stats)

    fig.text(0.05, 0.015, RULES, color=C_MUTED, fontsize=7.5, va="bottom")

    fig.savefig(path, dpi=150, facecolor=C_BG, bbox_inches="tight", pad_inches=0.2)
    plt.close(fig)


def render_index(path: Path) -> None:
    fig = plt.figure(figsize=(10, 11), facecolor=C_BG)
    ax = fig.add_axes([0, 0, 1, 1])
    ax.set_facecolor(C_BG)
    ax.axis("off")
    ax.text(0.05, 0.98, "Tomate — scénarios timeline", color="white", fontsize=16, fontweight="bold", va="top")
    ax.text(0.05, 0.955, RULES, color=C_MUTED, fontsize=8.5, va="top")
    ax.text(
        0.05,
        0.935,
        "Chaque PNG : ① clics + chrono  ② barre Jour  ③ Sessions / Pauses",
        color=C_MUTED,
        fontsize=8.5,
        va="top",
    )
    y = 0.915
    for i, test in enumerate(TESTS, start=1):
        s = test.stats
        ax.text(0.05, y, f"{i:02d}. {test.title}", color=C_TEXT, fontsize=9, fontweight="bold", va="top")
        ax.text(
            0.05,
            y - 0.022,
            f"     {test.test_name} · {test.when}",
            color=C_ACCENT,
            fontsize=7.5,
            fontfamily="monospace",
            va="top",
        )
        ax.text(
            0.05,
            y - 0.042,
            f"     Stats: Sessions {s.focus_count} ({s.focus_duration:.0f}s) · Pauses {s.rest_count} ({s.rest_duration:.0f}s)",
            color=C_MUTED,
            fontsize=7.5,
            va="top",
        )
        y -= 0.072
    fig.savefig(path, dpi=140, facecolor=C_BG, bbox_inches="tight", pad_inches=0.25)
    plt.close(fig)


def main() -> None:
    errors = validate_diagrams()
    if errors:
        print("VALIDATION FAILED — PNG data ≠ TimelineScenarioTests:")
        for err in errors:
            print(f"  ✗ {err}")
        raise SystemExit(1)
    print(f"Validated {len(TESTS)} diagrams against TimelineScenarioTests ✓")

    if OUT_DIR.exists():
        for old in OUT_DIR.glob("*.png"):
            old.unlink()
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for i, test in enumerate(TESTS, start=1):
        out = OUT_DIR / f"{i:02d}-{test.test_name}.png"
        render_test_page(test, out)
        print(f"Wrote {out}")

    render_index(INDEX_PATH)
    print(f"Wrote {INDEX_PATH}")
    shutil.copy(INDEX_PATH, ROOT / "docs" / "test-timelines.png")
    print(f"Wrote {ROOT / 'docs' / 'test-timelines.png'}")


if __name__ == "__main__":
    main()
