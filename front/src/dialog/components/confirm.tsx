import * as React from 'react';
import { IConfirmDialog } from '../defs';
import { Dialog } from './base';
import { NoButton, YesButton } from './parts';
import { bind } from '../../util/bind';

export interface IPropConfirmDialog extends IConfirmDialog {
  onSelect(result: boolean): void;
}
/**
 * Confirmation Dialog.
 */
export class ConfirmDialog extends React.PureComponent<IPropConfirmDialog, {}> {
  protected yesButton: HTMLButtonElement | null = null;
  public render() {
    const { title, modal, message, yes, no } = this.props;
    return (
      <Dialog
        modal={modal}
        title={title}
        message={message}
        onCancel={this.handleNoClick}
        buttons={() => (
          <>
            <NoButton onClick={this.handleNoClick}>{no}</NoButton>
            <YesButton
              onClick={this.handleYesClick}
              ref={e => (this.yesButton = e)}
            >
              {yes}
            </YesButton>
          </>
        )}
      />
    );
  }
  public componentDidMount() {
    // focus on a yes button
    if (this.yesButton != null) {
      this.yesButton.focus();
    }
  }
  @bind
  protected handleNoClick() {
    this.props.onSelect(false);
  }
  @bind
  protected handleYesClick() {
    this.props.onSelect(true);
  }
}
