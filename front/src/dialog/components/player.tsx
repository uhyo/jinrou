import * as React from 'react';
import { IPlayerDialog } from '../defs';
import { bind } from 'bind-decorator';
import { NoButton, Dialog, YesButton, FormTable, FormInput } from './base';

export interface IPropPlayerDialog extends IPlayerDialog {
  onSelect(user: { name: string; icon: string | null } | null): void;
}
/**
 * Player info dialog.
 */
export class PlayerDialog extends React.PureComponent<IPropPlayerDialog, {}> {
  private nameRef: React.RefObject<HTMLInputElement> = React.createRef();
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
            <YesButton onClick={this.handleOk}>{ok}</YesButton>
          </>
        )}
        contents={() => (
          <form onSubmit={this.handleFormSubmit}>
            <FormTable>
              <tbody>
                <tr>
                  <th>名前</th>
                  <td>
                    <FormInput innerRef={this.nameRef} type="text" required />
                  </td>
                </tr>
              </tbody>
            </FormTable>
          </form>
        )}
      />
    );
  }
  public componentDidMount() {
    // focus on input.
    const input = this.nameRef.current;
    if (input != null) {
      input.focus();
    }
  }
  /**
   * Handle a click of cancel button.
   */
  @bind
  private handleCancel() {
    this.props.onSelect(null);
  }
  @bind
  private handleOk() {
    const input = this.nameRef.current;
    if (input == null) {
      return;
    }
    this.props.onSelect({
      name: input.value,
      icon: null,
    });
  }
  /**
   * Handle a submission of form.
   */
  @bind
  private handleFormSubmit<T>(e: React.SyntheticEvent<T>): void {
    e.preventDefault();
    this.handleOk();
  }
}
