import * as React from 'react';
import { bind } from '../../util/bind';

import { ILoginDialog } from '../defs';

import { Dialog } from './base';
import {
  YesButton,
  NoButton,
  FormTable,
  FormInput,
  FormControlWrapper,
  FormErrorMessage,
  FormAsideText,
} from './parts';
import { I18n, TranslationFunction } from '../../i18n';
import { LoginFormContents, LoginFormFooter } from '../../common/login-form';

export interface IPropLoginDialog extends ILoginDialog {
  onClose(ok: boolean): void;
}
export interface IStateLoginDialog {
  error: string | null;
}

/**
 * Login Dialog.
 */
export class LoginDialog extends React.PureComponent<
  IPropLoginDialog,
  IStateLoginDialog
> {
  private userIdRef = React.createRef<HTMLInputElement>();
  private passwordRef = React.createRef<HTMLInputElement>();
  state: IStateLoginDialog = {
    error: null,
  };
  public render() {
    const { modal } = this.props;
    const { error } = this.state;

    return (
      <I18n namespace="common">
        {t => {
          const title = t('loginForm.title');
          const ok = t('loginForm.ok');
          const cancel = t('loginForm.cancel');
          return (
            <Dialog
              icon="user"
              modal={modal}
              title={title}
              onCancel={this.handleCancel}
              message=""
              form={true}
              onSubmit={this.handleSubmit(t)}
              contents={() => (
                <>
                  <LoginFormContents
                    userIdRef={this.userIdRef}
                    passwordRef={this.passwordRef}
                  />
                  {error != null ? (
                    <FormErrorMessage>{error}</FormErrorMessage>
                  ) : null}
                </>
              )}
              buttons={() => (
                <>
                  <NoButton type="button" onClick={this.handleCancel}>
                    {cancel}
                  </NoButton>
                  <YesButton>{ok}</YesButton>
                </>
              )}
              afterButtons={() => (
                <LoginFormFooter signup onCancel={this.handleCancel} />
              )}
            />
          );
        }}
      </I18n>
    );
  }
  public componentDidMount() {
    // focus on the userid input
    if (this.userIdRef.current != null) {
      this.userIdRef.current.focus();
    }
  }
  @bind
  protected handleCancel() {
    this.props.onClose(false);
  }
  protected handleSubmit(t: TranslationFunction) {
    return (e: React.SyntheticEvent<any>) => {
      e.preventDefault();
      // Run login api.
      const {
        userIdRef,
        passwordRef,
        props: { login, onClose },
      } = this;
      if (userIdRef.current == null || passwordRef.current == null) {
        return;
      }
      login(userIdRef.current.value, passwordRef.current.value)
        .then(loggedin => {
          if (loggedin) {
            // succeeded to login.
            onClose(true);
          } else {
            this.setState({
              error: t('loginForm.error'),
            });
          }
        })
        .catch(err => {
          this.setState({
            error: String(err),
          });
        });
    };
  }
}
