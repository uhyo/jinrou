import { ColorProfile } from '../defs';

/**
 * Theme that are provided to styled components.
 */
export interface UserTheme extends ColorProfile {}

/**
 * Theme object.
 */
export interface Theme {
  /**
   * Theme specified by the user.
   */
  user: UserTheme;
  /**
   * Color of teams.
   */
  teamColors: Record<string, string | undefined>;
}
