export type PhoneFontSize = 'large' | 'normal' | 'small';
/**
 * Setting object for smartphone UI.
 * @package
 */
export interface PhoneUISettings {
  /**
   * Whether to use smartphone ui.
   */
  use: boolean;
  /**
   * Size of font.
   */
  fontSize: PhoneFontSize;
}
