import * as React from 'react';
import styled, { keyframes, withProps } from '../../util/styled';
import { WithRandomIds } from '../../util/with-ids';
import { bind } from '../../util/bind';
import { IconProp, FontAwesomeIcon } from '../../util/icon';

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
  icon?: IconProp;
  /**
   * Handler of canceling the dialog.
   */
  onCancel?(): void;
  /**
   * Whether wrap the content with a form.
   */
  form?: boolean;
  /**
   * handler of submission when form is used.
   */
  onSubmit?(e: React.SyntheticEvent<HTMLFormElement>): void;
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

/**
 * Base of dialog.
 */
class DialogBaseInner extends React.PureComponent<IPropDialogBase, {}> {
  public render() {
    const { className, icon, title, children, form, onSubmit } = this.props;

    return (
      <WithRandomIds names={['title', 'desc']}>
        {({ title: titleid, desc }) => (
          <div
            role="dialog"
            className={className}
            aria-labelledby={title ? titleid : undefined}
            aria-describedby={desc}
          >
            {title ? (
              <Title id={titleid}>
                {icon ? <FontAwesomeIcon icon={icon} /> : null}
                {title}
              </Title>
            ) : null}
            <DialogMain id={desc}>
              {form ? <form onSubmit={onSubmit}>{children}</form> : children}
            </DialogMain>
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

  a {
    color: #666666;
  }

  @media (min-width: 600px) {
    max-width: 60vh;
  }
`;

export type IPropDialog = IPropDialogWrapper &
  IPropDialogBase & {
    /**
     * Icon shown at the left of title.
     */
    icon?: IconProp;
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
    /**
     * function to render contents after buttons.
     */
    afterButtons?(): React.ReactNode;
  };
/**
 * commom wrapper of dialog.
 */
export function Dialog({
  modal,
  title,
  icon,
  message,
  onCancel,
  form,
  onSubmit,
  buttons,
  contents,
  afterButtons,
}: IPropDialog) {
  return (
    <DialogWrapper modal={modal}>
      <DialogBase
        title={title}
        icon={icon}
        onCancel={onCancel}
        form={form}
        onSubmit={onSubmit}
      >
        <p>{message}</p>
        {contents ? contents() : null}
        <Buttons>{buttons()}</Buttons>
        {afterButtons ? afterButtons() : null}
      </DialogBase>
    </DialogWrapper>
  );
}
