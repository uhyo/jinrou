import * as React from 'react';
import { bind } from '../../util/bind';

import { IRoleDescDialog } from '../defs';

import { Dialog } from './base';
import { NoButton } from './parts';
import { I18n } from '../../i18n';
import styled from '../../util/styled';

export interface IPropRoleDescDialog extends IRoleDescDialog {
  onClose(): void;
}

/**
 * Role description dialog.
 */
export class RoleDescDialog extends React.PureComponent<
  IPropRoleDescDialog,
  {}
> {
  protected button: HTMLElement | undefined;
  public render() {
    const { modal, name, role, renderContent } = this.props;

    return (
      <I18n namespace="game_client">
        {t => {
          // name of role.
          const roleName = name != null ? name : t(`roles:jobname.${role}`);
          const title = t('roleDesc.title', {
            role: roleName,
          });
          const close = t('roleDesc.close');
          return (
            <Dialog
              modal={modal}
              title={title}
              onCancel={this.handleClick}
              buttons={() => (
                <NoButton onClick={this.handleClick}>{close}</NoButton>
              )}
              contents={() => (
                <RoleDescContent
                  dangerouslySetInnerHTML={{ __html: renderContent() }}
                />
              )}
            />
          );
        }}
      </I18n>
    );
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

const RoleDescContent = styled.article`
  p {
    margin: 0.4em 0;
  }
`;
