import * as React from 'react';
import { bind } from '../../util/bind';

import { IMessageDialog } from '../defs';

import { Dialog, YesButton } from './base';

export interface IPropMessageDialog extends IMessageDialog {
  onClose(): void;
}

/**
 * Message Dialog.
 */
export class MessageDialog extends React.PureComponent<IPropMessageDialog, {}> {
  protected button: HTMLElement | undefined;
  public render() {
    const { title, modal, message, ok } = this.props;

    return (
      <Dialog
        modal={modal}
        title={title}
        onCancel={this.handleClick}
        message={message}
        buttons={() => (
          <YesButton
            onClick={this.handleClick}
            innerRef={e => (this.button = e)}
          >
            {ok}
          </YesButton>
        )}
      />
    );
  }
  public componentDidMount() {
    // focus on a close button
    if (this.button != null) {
      this.button.focus();
    }
  }
  @bind
  protected handleClick() {
    this.props.onClose();
  }
}
