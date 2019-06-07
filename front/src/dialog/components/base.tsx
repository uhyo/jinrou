import * as React from 'react';
import Draggable from 'react-draggable';
import styled, { keyframes } from '../../util/styled';
import { WithRandomIds } from '../../util/with-ids';
import { bind } from '../../util/bind';
import { IconProp, FontAwesomeIcon } from '../../util/icon';
import { phone } from '../../common/media';
import { AppStyling } from '../../styles/phone';
import { dialogZIndex } from '../../common/z-index';
import { formLinkColor } from '../../common/color';

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
const DialogWrapper = styled(AppStyling)<IPropDialogWrapper>`
  position: fixed;
  left: 0;
  top: 0;
  width: 100vw;
  height: 100vh;
  z-index: ${dialogZIndex};

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
   * className set to title.
   */
  titleClassName?: string;
  /**
   * Handler of canceling the dialog.
   */
  onCancel?(): void;
  /**
   * Whether wrap the content with a form.
   */
  form?: boolean;
  /**
   * ref for form.
   */
  formRef?: React.Ref<HTMLFormElement>;
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
const CloseButton = styled.span`
  float: right;
  line-height: 0;
  color: #999999;
  cursor: pointer;
  &:hover {
    color: black;
  }
`;
const DialogMain = styled.div`
  margin: 0.8em;
`;
/**
 * Wrapper of buttons in the bottom line of a dialog.
 */
export const Buttons = styled.div`
  margin: 0.5em 6px 0 6px;
  display: flex;
  flex-flow: row nowrap;
  justify-content: flex-end;
`;

/**
 * Base of dialog.
 */
class DialogBaseInner extends React.PureComponent<IPropDialogBase, {}> {
  public render() {
    const {
      className,
      icon,
      title,
      titleClassName,
      children,
      form,
      formRef,
      onSubmit,
      onCancel,
    } = this.props;

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
              <Title id={titleid} className={titleClassName}>
                {icon ? <FontAwesomeIcon icon={icon} /> : null}
                {title}
                <CloseButton onClick={onCancel}>
                  <FontAwesomeIcon icon="times" />
                </CloseButton>
              </Title>
            ) : null}
            <DialogMain id={desc}>
              {form ? (
                <form onSubmit={onSubmit} ref={formRef}>
                  {children}
                </form>
              ) : (
                children
              )}
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
  max-width: 90vw;
  padding: 5px;
  box-shadow: 0 0 6px 4px rgba(0, 0, 0, 0.4);

  background-color: white;
  color: black;
  pointer-events: auto;

  a {
    color: ${formLinkColor};
  }
`;

const DialogMainContents = styled.div`
  max-height: 70vh;
  overflow-y: auto;
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
    message?: string;
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
  formRef,
  onSubmit,
  buttons,
  contents,
  afterButtons,
}: IPropDialog) {
  return (
    <WithRandomIds names={['titleClassName']}>
      {({ titleClassName }) => (
        <DialogWrapper modal={modal}>
          <Draggable bounds="body" handle={`.${titleClassName}`}>
            <DialogBase
              title={title}
              titleClassName={titleClassName}
              icon={icon}
              onCancel={onCancel}
              form={form}
              formRef={formRef}
              onSubmit={onSubmit}
            >
              {message != null ? <p>{message}</p> : null}
              {contents ? (
                <DialogMainContents>{contents()}</DialogMainContents>
              ) : null}
              <Buttons>{buttons()}</Buttons>
              {afterButtons ? afterButtons() : null}
            </DialogBase>
          </Draggable>
        </DialogWrapper>
      )}
    </WithRandomIds>
  );
}
