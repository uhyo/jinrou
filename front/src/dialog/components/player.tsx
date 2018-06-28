import * as React from 'react';
import { IPlayerDialog } from '../defs';
import { bind } from 'bind-decorator';
import { NoButton, Dialog, YesButton } from './base';

export interface IPropPlayerDialog extends IPlayerDialog {
  onSelect(user: { name: string; icon: string | null } | null): void;
}
/**
 * Player info dialog.
 */
export class PlayerDialog extends React.PureComponent<IPropPlayerDialog, {}> {
  public render() {
    const { title, modal, message, ok, cancel } = this.props;
    return (
      <Dialog
        title={title}
        modal={modal}
        message={message}
        onCancel={this.handleCancel}
        buttons={() => (
          <>
            <NoButton onClick={this.handleCancel}>{cancel}</NoButton>
            <YesButton>{ok}</YesButton>
          </>
        )}
      />
    );
  }
  /**
   * Handle a click of cancel button.
   */
  @bind
  private handleCancel() {
    this.props.onSelect(null);
  }
}
