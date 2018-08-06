/**
 * Theme that are provided to styled components.
 */
export interface Theme {
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
