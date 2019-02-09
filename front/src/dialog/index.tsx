import * as React from 'react';
import * as ReactDOM from 'react-dom';

import {
  IMessageDialog,
  IConfirmDialog,
  IPlayerDialog,
  IIconSelectDialog,
  ISelectDialog,
  IKickDialog,
  IChecklistDialog,
  IErrorDialog,
  IPromptDialog,
  ILoginDialog,
  IRoleDescDialog,
  ISuddenDeathPunishDialog,
} from './defs';

import { MessageDialog } from './components/message';
import { ConfirmDialog } from './components/confirm';
import { PlayerDialog } from './components/player';
import { IconSelectDialog } from './components/icon-select';
import { I18nProvider, getI18nFor, i18n } from '../i18n';
import { SelectDialog } from './components/select';
import { KickDialog, KickResult } from './components/kick';
import { ChecklistDialog } from './components/checklist';
import { BoundFunc } from '../util/cached-binder';
import { PromptDialog } from './components/prompt';
import { LoginDialog } from './components/login';
import { RoleDescDialog } from './components/role-desc';

/**
 * ID of area to place dialogs.
 */
const dialogArea = 'dialogs-overlay';

/**
 * Show a message dialog.
 */
export function showMessageDialog(d: IMessageDialog): Promise<void> {
  return showDialog(dialogArea, null, (open, close) => {
    const dialog = <MessageDialog {...d} onClose={() => close(undefined)} />;

    open(dialog);
  });
}

/**
 * Show a standard erorr dialog.
 */
export async function showErrorDialog(d: IErrorDialog): Promise<void> {
  // get i18n instance with system language.
  const i18n = await getI18nFor();
  await showDialog<void>(dialogArea, i18n, (open, close) => {
    const dialog = (
      <MessageDialog
        {...d}
        title={i18n.t('common:errorDialog.title') as string}
        ok={i18n.t('common:errorDialog.close')}
        onClose={close}
      />
    );
    open(dialog);
  });
}
/**
 * Show a prompt dialog.
 */
export function showPromptDialog(d: IPromptDialog): Promise<string | null> {
  return showDialog(dialogArea, null, (open, close) => {
    const dialog = <PromptDialog {...d} onSelect={close} />;
    open(dialog);
  });
}

/**
 * Show a confirmation dialog.
 * Resolves to true if user answered yes.
 */
export function showConfirmDialog(d: IConfirmDialog): Promise<boolean> {
  return showDialog(dialogArea, null, (open, close) => {
    const dialog = <ConfirmDialog {...d} onSelect={close} />;

    open(dialog);
  });
}

/**
 * Show a player information dialog.
 */
export function showPlayerDialog(
  d: IPlayerDialog,
): Promise<{
  name: string;
  icon: string | null;
} | null> {
  return showDialog(dialogArea, null, (open, close) => {
    const dialog = <PlayerDialog {...d} onSelect={close} />;
    open(dialog);
  });
}

/**
 * Show an icon select dialog.
 */
export async function showIconSelectDialog(
  d: IIconSelectDialog,
): Promise<string | null> {
  // get i18n instance with system language.
  const i18n = await getI18nFor();
  return showDialog<string | null>(dialogArea, i18n, (open, close) => {
    const dialog = <IconSelectDialog {...d} onSelect={close} />;
    open(dialog);
  });
}

/**
 * Show a select dialog.
 */
export function showSelectDialog(d: ISelectDialog): Promise<string | null> {
  return showDialog(dialogArea, null, (open, close) => {
    const dialog = <SelectDialog {...d} onSelect={close} />;
    open(dialog);
  });
}

/**
 * Show a kick dialog.
 */
export async function showKickDialog(
  d: IKickDialog,
): Promise<KickResult | null> {
  const i18n = await getI18nFor();
  return showDialog<KickResult | null>(dialogArea, i18n, (open, close) => {
    const dialog = <KickDialog {...d} onSelect={close} />;
    open(dialog);
  });
}

/**
 * Show a select by checklist dialog.
 */
export async function showChecklistDialog(
  d: IChecklistDialog,
): Promise<string[] | null> {
  const i18n = await getI18nFor();
  return showDialog<string[] | null>(dialogArea, i18n, (open, close) => {
    const dialog = <ChecklistDialog {...d} onSelect={close} />;
    open(dialog);
  });
}

/**
 * Show a sudden death punishment dialog.
 */
export async function showSuddenDeathPunishDialog({
  modal,
  time,
  options,
}: ISuddenDeathPunishDialog): Promise<string[] | null> {
  // get i18n instance with system language.
  const i18n = await getI18nFor();
  return showDialog<string[] | null>(dialogArea, i18n, (open, close) => {
    const dialog = (
      <ChecklistDialog
        modal={modal}
        options={Promise.resolve(options)}
        title={i18n.t('game_client:suddenDeathPunish.title') as string}
        message={i18n.t('game_client:suddenDeathPunish.message', {
          count: time,
        })}
        ok={i18n.t('game_client:suddenDeathPunish.ok')}
        cancel={i18n.t('game_client:suddenDeathPunish.cancel')}
        empty=""
        onSelect={close}
      />
    );
    open(dialog);
  });
}
/**
 * Show a login dialog.
 */
export async function showLoginDialog(d: ILoginDialog): Promise<boolean> {
  const i18n = await getI18nFor();
  return showDialog<boolean>(dialogArea, i18n, (open, close) => {
    const dialog = <LoginDialog {...d} onClose={close} />;
    open(dialog);
  });
}

/**
 * Show a role description dialog.
 */
export async function showRoleDescDialog(d: IRoleDescDialog): Promise<void> {
  const i18n = await getI18nFor();
  return showDialog<void>(dialogArea, i18n, (open, close) => {
    const dialog = <RoleDescDialog {...d} onClose={close} />;
    open(dialog);
  });
}

/**
 * Inner function to show a dialog.
 */
function showDialog<T>(
  areaId: string,
  i18n: i18n | null,
  callback: (
    open: ((dialog: React.ReactElement<any>) => void),
    close: BoundFunc<T, void>,
  ) => void,
): Promise<T> {
  return new Promise(resolve => {
    const dialogOverlayArea = document.getElementById(areaId) || document.body;
    // Add an area for showing dialog.
    const area = document.createElement('div');
    dialogOverlayArea.appendChild(area);

    // show a dialog.
    const open = (dialog: React.ReactElement<any>) => {
      // Wrap a dialog with I18nProvider if i18n is provided.
      const dialogElm =
        i18n != null ? (
          <I18nProvider i18n={i18n}>{dialog}</I18nProvider>
        ) : (
          dialog
        );
      ReactDOM.render(dialogElm, area);
    };
    // clean up dialog.
    const close = ((result: T) => {
      ReactDOM.unmountComponentAtNode(area);
      dialogOverlayArea.removeChild(area);
      resolve(result);
    }) as BoundFunc<T, void>;

    callback(open, close);
  });
}
