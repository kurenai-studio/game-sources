import { type GameAction } from '@warriorjs/core';
import { Box, Text } from 'ink';
import type React from 'react';
import { useMemo } from 'react';

import { type TurnEvent } from '../../../types.js';
import getUnitAppearance from '../../../utils/getUnitAppearance.js';
import { type PlaybackCursor } from '../../hooks/usePlayback.js';

interface LogAreaProps {
  turns: TurnEvent[][];
  cursor: PlaybackCursor;
  mode: 'playback' | 'review';
  maxLines?: number;
}

interface LogLine {
  type: 'turn' | 'event';
  turnNumber: number;
  eventIndex?: number;
  event?: TurnEvent;
}

interface UnitRef {
  type: 'unit';
  name: string;
  warrior?: boolean;
}

function isUnitRef(value: unknown): value is UnitRef {
  return typeof value === 'object' && value !== null && (value as UnitRef).type === 'unit';
}

function colorizeMessage(
  action: GameAction,
  actor: { name: string; warrior: boolean } | null,
  boldStats: boolean,
): React.ReactNode[] {
  const nodes: React.ReactNode[] = [];
  let key = 0;

  if (actor) {
    const color = getUnitAppearance(actor.name, actor.warrior).color;
    nodes.push(
      <Text key={key++} color={color}>
        {actor.name}
      </Text>,
    );
    nodes.push(<Text key={key++}> </Text>);
  }

  // Split template on {param} placeholders — odd segments are param keys.
  const segments = action.description.split(/\{(\w+)\}/);
  for (let i = 0; i < segments.length; i++) {
    const segment = segments[i]!;
    if (!segment) continue;

    if (i % 2 === 0) {
      nodes.push(<Text key={key++}>{segment}</Text>);
    } else {
      const value = action.params[segment];
      if (value === undefined) {
        nodes.push(<Text key={key++}>{`{${segment}}`}</Text>);
      } else if (isUnitRef(value)) {
        const color = getUnitAppearance(value.name, value.warrior).color;
        nodes.push(
          <Text key={key++} color={color}>
            {value.name}
          </Text>,
        );
      } else if (typeof value === 'number') {
        // Pull trailing label (e.g. " damage", " HP") into the bold span.
        let label = '';
        const next = segments[i + 1];
        if (next) {
          const match = next.match(/^(\s?\w+)/);
          if (match) {
            label = match[1]!;
            segments[i + 1] = next.slice(label.length);
          }
        }
        nodes.push(
          <Text key={key++} bold={boldStats}>
            {String(value) + label}
          </Text>,
        );
      } else {
        nodes.push(<Text key={key++}>{String(value)}</Text>);
      }
    }
  }

  return nodes;
}

export default function LogArea({
  turns,
  cursor,
  mode,
  maxLines = 10,
}: LogAreaProps): React.ReactElement {
  const isReview = mode === 'review';

  // Build a flat list of log lines and determine which are visible.
  const { visibleLines, focusedIndex } = useMemo(() => {
    const lines: LogLine[] = [];
    const lastTurn = isReview ? turns.length - 1 : cursor.turn;

    for (let t = 0; t <= lastTurn; t++) {
      const turnEvents = turns[t]!;
      const maxEvent = !isReview && t === cursor.turn ? cursor.event : turnEvents.length - 1;
      const eventsInRange: { event: TurnEvent; eventIndex: number }[] = [];

      for (let e = 0; e <= maxEvent; e++) {
        const event = turnEvents[e]!;
        if (event.action.description) {
          eventsInRange.push({ event, eventIndex: e });
        }
      }

      if (eventsInRange.length > 0) {
        lines.push({ type: 'turn', turnNumber: t });
        for (const { event, eventIndex } of eventsInRange) {
          lines.push({ type: 'event', turnNumber: t, eventIndex, event });
        }
      }
    }

    // In playback mode, the focused line is always the last one.
    // In review mode, find the line matching the cursor. If not found (e.g. turn 0
    // initial state with no message), focused stays -1 so nothing is highlighted.
    let focused = lines.length - 1;
    if (isReview) {
      focused = lines.findIndex(
        (l) => l.type === 'event' && l.turnNumber === cursor.turn && l.eventIndex === cursor.event,
      );
    }

    // Window the visible lines.
    let visible: LogLine[];
    if (lines.length <= maxLines) {
      visible = lines;
    } else if (isReview) {
      // Center the focused line in the window.
      const half = Math.floor(maxLines / 2);
      let start = focused - half;
      if (start < 0) start = 0;
      if (start + maxLines > lines.length) start = lines.length - maxLines;
      visible = lines.slice(start, start + maxLines);
      focused = focused - start;
    } else {
      // Playback: newest lines at the bottom, oldest scroll off.
      const start = lines.length - maxLines;
      visible = lines.slice(start);
      focused = focused - start;
    }

    return { visibleLines: visible, focusedIndex: focused };
  }, [turns, cursor, maxLines, isReview]);

  return (
    <Box flexDirection="column">
      {visibleLines.map((line, index) => {
        if (line.type === 'turn') {
          return (
            <Text key={`t${line.turnNumber}`} dimColor>
              {`Turn ${line.turnNumber}`}
            </Text>
          );
        }
        const event = line.event!;
        const isCurrent = index === focusedIndex;
        const dim = isReview && !isCurrent;
        return (
          // biome-ignore lint/suspicious/noArrayIndexKey: unique with turnNumber
          <Box key={`e${line.turnNumber}-${index}`} gap={1}>
            <Text dimColor>{'>'}</Text>
            <Text bold={isReview && isCurrent} dimColor={dim}>
              {colorizeMessage(event.action, event.actor, !dim)}
            </Text>
          </Box>
        );
      })}
    </Box>
  );
}
