import * as React from 'react';
import styled, {
    withProps,
} from '../util/styled';

import {
    bind,
} from '../util/bind';
import {
    WithRandomIds,
} from '../util/with-ids';

import {
    IMessageDialog,
    IConfirmDialog,
} from './defs';

interface IPropDialogWrapper {
    modal?: boolean;
}

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
    background-color: ${({modal})=> modal ? 'rgba(0, 0, 0, 0.48)' : 'transparent'};
    pointer-events: ${({modal})=> modal ? 'auto' : 'none'};

    display: flex;
    flex-flow: column nowrap;
    justify-content: center;
    align-items: center;
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
const Buttons = styled.div`
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
`
const YesButton = styled(ButtonBase)`
    background-color: #83f183;
`;
const NoButton = styled(ButtonBase)`
    background-color: #dddddd;
`;
/**
 * Base of dialog.
 */
class DialogBaseInner extends React.PureComponent<IPropDialogBase, {}> {
    public render() {
        const {
            className,
            title,
            children,
        } = this.props;

        return (<WithRandomIds
            names={['title', 'desc']}
        >{
            ({title: titleid, desc})=> (
                <div
                    role='dialog'
                    className={className}
                    aria-labelledby={title ? titleid : undefined}
                    aria-describedby={desc}
                >
                    {title ?
                    <Title id={titleid}>{title}</Title> :
                    null}
                    <DialogMain id={desc}>
                        {children}
                    </DialogMain>
                </div>
                )
            }
            </WithRandomIds>);
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

    padding: 5px;

    @media (min-width: 600px) {
        max-width: 60vh;
    }
`;

export interface IPropMessageDialog extends IMessageDialog {
    onClose(): void;
}

/**
 * Message Dialog.
 */
export class MessageDialog extends React.PureComponent<IPropMessageDialog, {}> {
    protected button: HTMLElement | undefined;
    public render() {
        const {
            title,
            modal,
            message,
            ok,
        } = this.props;

        return (<DialogWrapper
            modal={modal}
        >
            <DialogBase
                title={title}
                onCancel={this.handleClick}
            >
                <p>{message}</p>
                <Buttons>
                    <YesButton
                        onClick={this.handleClick}
                        innerRef={e=> this.button=e}
                    >
                        {ok}
                    </YesButton>
                </Buttons>
            </DialogBase>
        </DialogWrapper>);
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


export interface IPropConfirmDialog extends IConfirmDialog {
    onSelect(result: boolean): void;
}
/**
 * Confirmation Dialog.
 */
export class ConfirmDialog extends React.PureComponent<IPropConfirmDialog, {}> {
    protected yesButton: HTMLButtonElement | undefined;
    public render() {
        const {
            title,
            modal,
            message,
            yes,
            no,
        } = this.props;
        return (<DialogWrapper
            modal={modal}
        >
            <DialogBase
                title={title}
                onCancel={this.handleNoClick}
            >
                <p>{message}</p>
                <Buttons>
                    <NoButton
                        onClick={this.handleNoClick}
                    >
                        {no}
                    </NoButton>
                    <YesButton
                        onClick={this.handleYesClick}
                        innerRef={e=> this.yesButton=e}
                    >
                        {yes}
                    </YesButton>
                </Buttons>
            </DialogBase>
        </DialogWrapper>);
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
