import * as React from 'react';
import { IPlayerDialog } from '../defs';
import { bind } from 'bind-decorator';
import { Dialog } from './base';
import { NoButton, YesButton, FormTable, FormInput } from './parts';
import { UserIcon } from '../../common/user-icon';
import styled from '../../util/styled';
import { showIconSelectDialog } from '..';

export interface IPropPlayerDialog extends IPlayerDialog {
  onSelect(user: { name: string; icon: string | null } | null): void;
}
/**
 * Player info dialog.
 */
export class PlayerDialog extends React.PureComponent<
  IPropPlayerDialog,
  {
    /**
     * Currently selected user icon.
     */
    icon: string | null;
  }
> {
  private formRef: React.RefObject<HTMLFormElement> = React.createRef();
  private nameRef: React.RefObject<HTMLInputElement> = React.createRef();
  constructor(props: IPropPlayerDialog) {
    super(props);
    this.state = {
      icon: null,
    };
  }
  public render() {
    const { title, modal, message, ok, cancel } = this.props;
    return (
      <Dialog
        modal={modal}
        title={title}
        icon="user-secret"
        message={message}
        onCancel={this.handleCancel}
        buttons={() => (
          <>
            <NoButton onClick={this.handleCancel}>{cancel}</NoButton>
            <YesButton onClick={this.handleOk}>{ok}</YesButton>
          </>
        )}
        contents={() => (
          <form onSubmit={this.handleFormSubmit} ref={this.formRef}>
            <FormTable>
              <tbody>
                <tr>
                  <th>名前</th>
                  <td>
                    <FormInput ref={this.nameRef} type="text" required />
                  </td>
                </tr>
                <tr>
                  <th>アイコン</th>
                  <td>
                    <IconWrapperButton
                      type="button"
                      onClick={this.handleIconClick}
                    >
                      <UserIcon icon={this.state.icon} />
                    </IconWrapperButton>
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
    if (this.formRef.current && !this.formRef.current.reportValidity()) {
      return;
    }
    this.props.onSelect({
      name: input.value,
      icon: this.state.icon,
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
  /**
   * Handle a click of icon.
   */
  @bind
  private async handleIconClick() {
    const icon = await showIconSelectDialog({
      modal: true,
    });
    this.setState({
      icon,
    });
  }
}

const IconWrapperButton = styled.button`
  cursor: pointer;
  appearance: none;

  width: 48px;
  height: 48px;
  padding: 0;
  border: none;
`;
