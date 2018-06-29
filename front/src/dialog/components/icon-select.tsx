import * as React from 'react';
import { IIconSelectDialog } from '../defs';
import { Dialog, NoButton, YesButton, FormTable, FormInput } from './base';
import bind from 'bind-decorator';
import { I18n } from '../../i18n';
import { UserIcon } from '../../common/user-icon';

export interface IPropIconSelectDialog extends IIconSelectDialog {
  onSelect(icon: string | null): void;
}

/**
 * Icon select dialog.
 */
export class IconSelectDialog extends React.PureComponent<
  IPropIconSelectDialog,
  {
    /**
     * Whether url input is disabled.
     */
    urlDisabled: boolean;
    /**
     * Whether twitter input is disabled.
     */
    twitterDisabled: boolean;
    /**
     * Whether requesting pending.
     */
    requesting: boolean;
  }
> {
  private urlRef = React.createRef<HTMLInputElement>();
  private twitterRef = React.createRef<HTMLInputElement>();
  state = {
    urlDisabled: false,
    twitterDisabled: false,
    requesting: false,
  };
  public render() {
    // TODO
    const { modal } = this.props;
    const { urlDisabled, twitterDisabled } = this.state;
    return (
      <I18n namespace="game_client">
        {t => (
          <Dialog
            modal={modal}
            title={t('iconSelect.title')}
            message={t('iconSelect.message')}
            buttons={() => (
              <>
                <NoButton onClick={this.handleNoClick}>
                  {t('iconSelect.no')}
                </NoButton>
                <YesButton onClick={this.handleYesClick}>
                  {t('iconSelect.save')}
                </YesButton>
              </>
            )}
            contents={() => (
              <FormTable>
                <tbody>
                  <tr>
                    <th>{t('iconSelect.url')}</th>
                    <td>
                      <FormInput
                        innerRef={this.urlRef}
                        disabled={urlDisabled}
                        onChange={this.handleInputChange}
                      />
                    </td>
                  </tr>
                  <tr>
                    <th>{t('iconSelect.twitter')}</th>
                    <td>
                      <FormInput
                        innerRef={this.twitterRef}
                        disabled={twitterDisabled}
                        onChange={this.handleInputChange}
                      />
                    </td>
                  </tr>
                </tbody>
              </FormTable>
            )}
          />
        )}
      </I18n>
    );
  }
  /**
   * Handle a click of no button.
   */
  @bind
  private handleNoClick() {
    this.props.onSelect(null);
  }
  /**
   * Handle a click of yes button.
   */
  @bind
  private handleYesClick() {
    // this.props.onSelect(this.state.icon);
  }
  /**
   * Handle a change of input.
   */
  @bind
  private handleInputChange() {
    const hasUrl = !!(this.urlRef.current && this.urlRef.current.value);
    const hasTwitter = !!(
      this.twitterRef.current && this.twitterRef.current.value
    );

    this.setState({
      urlDisabled: hasTwitter && !hasUrl,
      twitterDisabled: hasUrl,
    });
  }
}
