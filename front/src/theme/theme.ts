/**
 * Theme that are provided to styled components.
 */
export interface UserTheme {
  /**
   * Color scheme of day.
   */
  day: {
    bg: string;
    color: string;
  };
  /**
   * Color scheme of heaven.
   */
  heaven: {
    bg: string;
    color: string;
  };
  /**
   * Color scheme of night.
   */
  night: {
    bg: string;
    color: string;
  };
}

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
