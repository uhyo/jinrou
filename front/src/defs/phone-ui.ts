export type PhoneFontSize = 'large' | 'normal' | 'small' | 'very-small';
export type SpeakFormPosition = 'normal' | 'fixed';
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
  /**
   * Position of speak form.
   */
  speakFormPosition: SpeakFormPosition;
}
