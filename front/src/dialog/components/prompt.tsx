import * as React from 'react';
import { IPromptDialog } from '../defs';
import { Dialog } from './base';
import { NoButton, YesButton, FormControlWrapper, FormInput } from './parts';
import { bind } from '../../util/bind';

export interface IPropPromptDialog extends IPromptDialog {
  onSelect(result: string | null): void;
}
/**
 * Prompt Dialog.
 */
export class PromptDialog extends React.PureComponent<IPropPromptDialog, {}> {
  private inputRef: React.RefObject<HTMLInputElement> = React.createRef();
  public render() {
    const {
      title,
      modal,
      message,
      ok,
      cancel,
      password,
      autocomplete,
    } = this.props;
    return (
      <Dialog
        form={true}
        modal={modal}
        title={title}
        message={message}
        onCancel={this.handleCancel}
        onSubmit={this.handleSubmit}
        contents={() => (
          <FormControlWrapper>
            <FormInput
              ref={this.inputRef}
              type={password ? 'password' : 'text'}
              autoComplete={autocomplete}
              onClick={this.handleInputClick}
            />
          </FormControlWrapper>
        )}
        buttons={() => (
          <>
            <NoButton type="button" onClick={this.handleCancel}>
              {cancel}
            </NoButton>
            <YesButton type="submit">{ok}</YesButton>
          </>
        )}
      />
    );
  }
  public componentDidMount() {
    // focus on the input.
    if (this.inputRef.current != null) {
      this.inputRef.current.focus();
    }
  }
  @bind
  protected handleInputClick() {
    // for Chrome's weird behaviour.
    if (this.inputRef.current != null) {
      this.inputRef.current.focus();
    }
  }
  @bind
  protected handleCancel() {
    this.props.onSelect(null);
  }
  @bind
  protected handleSubmit<T>(e: React.SyntheticEvent<T>) {
    e.preventDefault();
    if (this.inputRef.current == null) {
      this.props.onSelect(null);
    } else {
      this.props.onSelect(this.inputRef.current.value);
    }
  }
}
