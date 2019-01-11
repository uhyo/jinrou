import * as React from 'react';
import { IKickDialog } from '../defs';
import { Dialog } from './base';
import {
  NoButton,
  YesButton,
  FormSelect,
  FormControlWrapper,
  FormTable,
  FormAsideText,
} from './parts';
import bind from 'bind-decorator';
import { I18n, TranslationFunction } from '../../i18n';
import { FontAwesomeIcon } from '../../util/icon';
import { getKickList } from '../../api/kick-manage';
import { showChecklistDialog } from '..';

export type KickResult =
  | {
      type: 'kick';
      /**
       * Id of kicked user.
       */
      id: string;
      /**
       * Whether re-entry is forbidden.
       */
      noentry: boolean;
    }
  | {
      type: 'list-remove';
      /**
       * List of user ids removed from kick list.
       */
      users: string[];
    };
export interface IPropKickDialog extends IKickDialog {
  onSelect(result: KickResult | null): void;
}

export class KickDialog extends React.PureComponent<IPropKickDialog, {}> {
  private selectRef: React.RefObject<HTMLSelectElement> = React.createRef();
  private noentryRef: React.RefObject<HTMLInputElement> = React.createRef();
  public render() {
    const { modal, players } = this.props;

    return (
      <I18n namespace="game_client">
        {t => {
          return (
            <Dialog
              modal={modal}
              title={t('kick.title')}
              message={t('kick.message')}
              onCancel={this.handleCancel}
              buttons={() => (
                <>
                  <NoButton onClick={this.handleCancel}>
                    {t('kick.cancel')}
                  </NoButton>
                  <YesButton onClick={this.handleYesClick}>
                    {t('kick.ok')}
                  </YesButton>
                </>
              )}
              contents={() => (
                <>
                  <FormControlWrapper>
                    <FormSelect ref={this.selectRef}>
                      {players.map(({ id, name }) => (
                        <option key={id} value={id} label={name}>
                          {name}
                        </option>
                      ))}
                    </FormSelect>
                  </FormControlWrapper>
                  <FormControlWrapper>
                    <label>
                      <FontAwesomeIcon icon="ban" />
                      {t('kick.noentry')}
                      <input ref={this.noentryRef} type="checkbox" />
                    </label>
                  </FormControlWrapper>
                </>
              )}
              afterButtons={() => (
                <FormAsideText>
                  <a
                    href="/"
                    // no-jump class instructs page to ignore click of this link.
                    className="no-jump"
                    onClick={this.handleManagerClick(t)}
                  >
                    {t('kick.manager.title')}…
                  </a>
                </FormAsideText>
              )}
            />
          );
        }}
      </I18n>
    );
  }
  /**
   * Handle cancellation of dialog.
   */
  @bind
  private handleCancel(): void {
    this.props.onSelect(null);
  }
  @bind
  private handleYesClick(): void {
    // Yes button is clicked.
    const sel = this.selectRef.current;
    if (sel == null) {
      return;
    }
    const noentry = !!(
      this.noentryRef.current && this.noentryRef.current.checked
    );
    this.props.onSelect({
      type: 'kick',
      id: sel.value,
      noentry,
    });
  }
  private handleManagerClick<T>(
    t: TranslationFunction,
  ): (e: React.SyntheticEvent<T>) => void {
    return (e: React.SyntheticEvent<T>) => {
      const { modal, roomid, onSelect } = this.props;
      e.preventDefault();
      // Kick manager link is clicked.
      showChecklistDialog({
        modal,
        title: t('kick.manager.title'),
        message: t('kick.manager.message'),
        empty: t('kick.manager.empty'),
        ok: t('kick.ok'),
        cancel: t('kick.cancel'),
        options: getKickList(roomid).then(ids =>
          ids.map(id => ({ id, label: id })),
        ),
      })
        .then(kicked => {
          if (kicked != null) {
            onSelect({
              type: 'list-remove',
              users: kicked,
            });
          }
        })
        .catch(err => {
          // TODO: error handling
          console.error(err);
        });
    };
  }
}
