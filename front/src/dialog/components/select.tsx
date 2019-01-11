import * as React from 'react';
import { ISelectDialog } from '../defs';
import { Dialog } from './base';
import { NoButton, YesButton, FormSelect, FormControlWrapper } from './parts';
import bind from 'bind-decorator';

export interface IPropSelectDialog extends ISelectDialog {
  onSelect(result: string | null): void;
}

export class SelectDialog extends React.PureComponent<IPropSelectDialog, {}> {
  private selectRef: React.RefObject<HTMLSelectElement> = React.createRef();
  public render() {
    const { modal, title, message, ok, cancel, options } = this.props;

    return (
      <Dialog
        modal={modal}
        title={title}
        message={message}
        onCancel={this.handleCancel}
        buttons={() => (
          <>
            <NoButton onClick={this.handleCancel}>{cancel}</NoButton>
            <YesButton onClick={this.handleYesClick}>{ok}</YesButton>
          </>
        )}
        contents={() => (
          <FormControlWrapper>
            <FormSelect ref={this.selectRef}>
              {options.map(({ label, value }) => (
                <option key={value} value={value} label={label}>
                  {label}
                </option>
              ))}
            </FormSelect>
          </FormControlWrapper>
        )}
      />
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
    this.props.onSelect(sel.value);
  }
}
