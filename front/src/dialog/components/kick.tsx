import * as React from 'react';
import { IKickDialog } from '../defs';
import {
  Dialog,
  NoButton,
  YesButton,
  FormSelect,
  FormControlWrapper,
  FormTable,
} from './base';
import bind from 'bind-decorator';
import { I18n } from '../../i18n';
import { FontAwesomeIcon } from '../../util/icon';

export interface KickResult {
  /**
   * Id of kicked user.
   */
  id: string;
  /**
   * Whether re-entry is forbidden.
   */
  noentry: boolean;
}
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
                    <FormSelect innerRef={this.selectRef}>
                      {players.map(({ id, name }) => (
                        <option key={id} value={id} label={name} />
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
    const sel = this.selectRef.current;
    if (sel == null) {
      return;
    }
    const noentry = !!(
      this.noentryRef.current && this.noentryRef.current.checked
    );
    this.props.onSelect({
      id: sel.value,
      noentry,
    });
  }
}
