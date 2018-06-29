import * as React from 'react';
import { IPlayerDialog } from '../defs';
import { bind } from 'bind-decorator';
import { NoButton, Dialog, YesButton, FormTable, FormInput } from './base';
import { UserIcon } from '../../common/user-icon';
import styled from '../../util/styled';

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
  /**
   * Handle a click of icon.
   */
  @bind
  private handleIconClick() {
    // TODO
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
