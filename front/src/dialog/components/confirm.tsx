import * as React from 'react';
import { IConfirmDialog } from '../defs';
import { Dialog, NoButton, YesButton } from './base';
import { bind } from '../../util/bind';

export interface IPropConfirmDialog extends IConfirmDialog {
  onSelect(result: boolean): void;
}
/**
 * Confirmation Dialog.
 */
export class ConfirmDialog extends React.PureComponent<IPropConfirmDialog, {}> {
  protected yesButton: HTMLButtonElement | undefined;
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
              innerRef={e => (this.yesButton = e)}
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
