/**
 * message dialog.
 */
export interface IMessageDialog {
  /**
   * Title of dialog.
   */
  title?: string;
  /**
   * Whether this is a modal window.
   */
  modal?: boolean;
  /**
   * Message of dialog.
   */
  message: string;
  /**
   * ok button.
   */
  ok: string;
}
/**
 * confirmation dialog.
 */
export interface IConfirmDialog {
  /**
   * Title of dialog.
   */
  title?: string;
  /**
   * Whether this is a modal window.
   */
  modal?: boolean;
  /**
   * Message of dialog.
   */
  message: string;
  /**
   * yes button.
   */
  yes: string;
  /**
   * no button.
   */
  no: string;
}
