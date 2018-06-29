import * as React from 'react';
import styled, { keyframes, withProps } from '../../util/styled';
import { WithRandomIds } from '../../util/with-ids';
import { bind } from '../../util/bind';

interface IPropDialogWrapper {
  modal?: boolean;
}

/**
 * Keyframes for dialogs.
 */
const opacityAnimation = keyframes`
    from {
        opacity: 0;
    }
    to {
        opacity: 1;
    }
`;

/**
 * Wrapper of dialog.
 */
const DialogWrapper = withProps<IPropDialogWrapper>()(styled.div)`
    position: fixed;
    left: 0;
    top: 0;
    width: 100vw;
    height: 100vh;

    z-index: 50;
    background-color: ${({ modal }) =>
      modal ? 'rgba(0, 0, 0, 0.48)' : 'transparent'};
    pointer-events: ${({ modal }) => (modal ? 'auto' : 'none')};

    display: flex;
    flex-flow: column nowrap;
    justify-content: center;
    align-items: center;

    animation: ${opacityAnimation} ease-out 0.1s;
`;

interface IPropDialogBase {
  className?: string;
  title?: string;
  /**
   * Handler of canceling the dialog.
   */
  onCancel?(): void;
}

const Title = styled.div`
  border-bottom: 1px solid #666666;
  padding: 2px;
  margin-bottom: 4px;

  font-size: 1.4em;
  font-weight: bold;
`;
const DialogMain = styled.div`
  margin: 0.8em;
`;
/**
 * Wrapper of buttons in the bottom line of a dialog.
 */
export const Buttons = styled.div`
  margin: 1em 6px 0 6px;
  display: flex;
  flex-flow: row nowrap;
  justify-content: flex-end;
`;
const ButtonBase = styled.button`
  appearance: none;

  border: none;
  margin: 6px;
  padding: 0.3em 1em;
  text-align: center;

  font-size: 1.24em;
  font-weight: bold;
`;
/**
 * Button with affirmative impression.
 */
export const YesButton = styled(ButtonBase)`
  background-color: #83f183;
`;
/**
 * Button with negative impression.
 */
export const NoButton = styled(ButtonBase)`
  background-color: #dddddd;
`;

/**
 * Table for use in dialog.
 */
export const FormTable = styled.table`
  margin: 5px;

  th,
  td {
    border: none;
    vertical-align: middle;
  }
`;

/**
 * Input for form in dialog.
 */
export const FormInput = styled.input`
  background-color: white;
  width: 240px;
  padding: 0.4em;
  border: 1px solid #cccccc;

  &:focus {
    border-color: #83f183;
    outline-color: #83f183;
  }
`;

/**
 * Base of dialog.
 */
class DialogBaseInner extends React.PureComponent<IPropDialogBase, {}> {
  public render() {
    const { className, title, children } = this.props;

    return (
      <WithRandomIds names={['title', 'desc']}>
        {({ title: titleid, desc }) => (
          <div
            role="dialog"
            className={className}
            aria-labelledby={title ? titleid : undefined}
            aria-describedby={desc}
          >
            {title ? <Title id={titleid}>{title}</Title> : null}
            <DialogMain id={desc}>{children}</DialogMain>
          </div>
        )}
      </WithRandomIds>
    );
  }
  public componentDidMount() {
    // handle pressing escape key.
    document.addEventListener('keydown', this.keyDownHandler, false);
  }
  public componentWillUnmount() {
    document.removeEventListener('keydown', this.keyDownHandler, false);
  }
  @bind
  protected keyDownHandler(e: KeyboardEvent) {
    // if Escape key is pressed, cancel the dialog.
    if (e.key === 'Escape' && this.props.onCancel) {
      this.props.onCancel();
    }
  }
}

const DialogBase = styled(DialogBaseInner)`
  background-color: white;
  box-shadow: 4px 4px 4px 2px rgba(0, 0, 0, 0.4);
  pointer-events: auto;

  padding: 5px;

  @media (min-width: 600px) {
    max-width: 60vh;
  }
`;

export type IPropDialog = IPropDialogWrapper &
  IPropDialogBase & {
    /**
     * Message to show in a dialog.
     */
    message: string;
    /**
     * function to render buttons.
     */
    buttons(): React.ReactNode;
    /**
     * function to render custom dialog contents.
     */
    contents?(): React.ReactNode;
  };
/**
 * commom wrapper of dialog.
 */
export function Dialog({
  modal,
  title,
  message,
  onCancel,
  buttons,
  contents,
}: IPropDialog) {
  return (
    <DialogWrapper modal={modal}>
      <DialogBase title={title} onCancel={onCancel}>
        <p>{message}</p>
        {contents ? contents() : null}
        <Buttons>{buttons()}</Buttons>
      </DialogBase>
    </DialogWrapper>
  );
}
