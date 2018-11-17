import { RoleInfo, GameInfo } from '../defs';
import { GlobalStyleMode } from '../../../theme';

/**
 * Compute global style mode from current game state.
 */
export function styleModeOf(
  roleInfo: RoleInfo | null,
  gameInfo: GameInfo,
): GlobalStyleMode {
  const mode = gameInfo.finished
    ? null
    : gameInfo.status === 'waiting'
      ? 'day'
      : roleInfo != null && roleInfo.dead
        ? 'heaven'
        : gameInfo.night
          ? 'night'
          : 'day';
  return mode;
}
