import * as React from 'react';
import { TranslationFunction } from '../../../i18n';
import { PlayerInfo } from '../defs';

/**
 * Speak kind select control.
 */
export const SpeakKindSelect: React.StatelessComponent<{
  /**
   * List of available speak kind.
   */
  kinds: string[];
  /**
   * Currently selected speak kind.
   */
  current: string;
  /**
   * i18n function.
   */
  t: TranslationFunction;
  /**
   * Map from player id to its info.
   */
  playersMap: Map<string, PlayerInfo>;
  /**
   * Callback for change.
   */
  onChange: (kind: string) => void;
}> = ({ kinds, current, playersMap, t, onChange }) => {
  return (
    <select value={current} onChange={e => onChange(e.currentTarget.value)}>
      {kinds.map(value => (
        <option key={value} value={value}>
          {speakKindLabel(t, playersMap, value)}
        </option>
      ))}
    </select>
  );
};

/**
 * speakKindに応じたラベル文字列を返す
 */
export function speakKindLabel(
  t: TranslationFunction,
  playersMap: Map<string, PlayerInfo>,
  kind: string,
): string {
  if (kind.startsWith('gmreply_')) {
    const playerObj = playersMap.get(kind.slice(8));
    return t('game_client:speak.kind.gmreply', {
      target: playerObj != null ? playerObj.name : '',
    });
  } else if (kind.startsWith('helperwhisper_')) {
    return t('game_client:speak.kind.helperwhisper');
  } else {
    return t(`game_client:speak.kind.${kind}`);
  }
}
