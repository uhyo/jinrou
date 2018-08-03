import { StringLiteral } from 'babel-types';

/**
 * Base of dialog configs.
 */
export interface IDialogBase {
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
}
/**
 * message dialog.
 */
export interface IMessageDialog extends IDialogBase {
  /**
   * ok button.
   */
  ok: string;
}
/**
 * Standard error dialog.
 */
export type IErrorDialog = Pick<
  IDialogBase,
  Exclude<keyof IDialogBase, 'title'>
>;
/**
 * confirmation dialog.
 */
export interface IConfirmDialog extends IDialogBase {
  /**
   * yes button.
   */
  yes: string;
  /**
   * no button.
   */
  no: string;
}
/**
 * Prompt dialog.
 */
export interface IPromptDialog extends IDialogBase {
  /**
   * Whether required input is a password.
   */
  password?: boolean;
  /**
   * Autocomplete attribute.
   */
  autocomplete?: string;
  /**
   * ok button.
   */
  ok: string;
  /**
   * cancel button.
   */
  cancel: string;
}

/**
 * Player info dialog for blind mode rooms.
 */
export interface IPlayerDialog extends IDialogBase {
  /**
   * ok button.
   */
  ok: string;
  /**
   * cancel button.
   */
  cancel: string;
}

/**
 * Icon select dialog.
 */
export interface IIconSelectDialog {
  modal?: boolean;
}

/**
 * Select from options dialog.
 */
export interface ISelectDialog extends IDialogBase {
  /**
   * Options.
   */
  options: Array<{
    label: string;
    value: string;
  }>;
  /**
   * ok button.
   */
  ok: string;
  /**
   * cancel button.
   */
  cancel: string;
}

/**
 * Kick user from room dialog.
 */
export interface IKickDialog {
  modal?: boolean;
  /**
   * Room ID for kicklist API.
   */
  roomid: number;
  /**
   * Current list of players.
   */
  players: Array<{
    id: string;
    name: string;
  }>;
}

/**
 * checklist dialog.
 */
export interface IChecklistDialog extends IDialogBase {
  /**
   * ok button.
   */
  ok: string;
  /**
   * cancel button.
   */
  cancel: string;
  /**
   * Message shown when the list is empty.
   */
  empty: string;
  /**
   * Promise which resolves to list of options.
   */
  options: Promise<
    Array<{
      id: string;
      label: string;
    }>
  >;
}

/**
 * Login dialog.
 */
export interface ILoginDialog {
  modal?: boolean;
  /**
   * API to login.
   */
  login: (userid: string, password: string) => Promise<boolean>;
}

/**
 * Role description dialog.
 */
export interface IRoleDescDialog {
  modal?: boolean;
  /**
   * ID of role.
   * e.g. "Human", "Werewolf"
   */
  role: string;
  /**
   * Name of role if provided.
   */
  name?: string;
  /**
   * Renderer of raw html content.
   */
  renderContent: () => string;
}

/**
 * Sudden death punishment dialog.
 */
export interface ISuddenDeathPunishDialog {
  modal?: boolean;
  /**
   * Ban time (in minute) per one vote.
   */
  time: number;
  options: Array<{
    id: string;
    label: string;
  }>;
}
