import * as React from 'react';
import { IIconSelectDialog } from '../defs';
import { Dialog } from './base';
import { NoButton, YesButton, FormTable, FormInput } from './parts';
import bind from 'bind-decorator';
import { I18n, TranslationFunction } from '../../i18n';
import { getTwitterIcon } from '../../api/twitter-icon';
import { showMessageDialog } from '..';

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
        {t => {
          const yesh = this.makeHandleYesClick(t);
          return (
            <Dialog
              modal={modal}
              title={t('iconSelect.title')}
              message={t('iconSelect.message')}
              form
              onSubmit={yesh}
              buttons={() => (
                <>
                  <NoButton type="button" onClick={this.handleNoClick}>
                    {t('iconSelect.no')}
                  </NoButton>
                  <YesButton type="submit">{t('iconSelect.save')}</YesButton>
                </>
              )}
              contents={() => (
                <FormTable>
                  <tbody>
                    <tr>
                      <th>{t('iconSelect.url')}</th>
                      <td>
                        <FormInput
                          ref={this.urlRef}
                          type="text"
                          disabled={urlDisabled}
                          required
                          onChange={this.handleInputChange}
                        />
                      </td>
                    </tr>
                    <tr>
                      <th>{t('iconSelect.twitter')}</th>
                      <td>
                        <FormInput
                          ref={this.twitterRef}
                          type="text"
                          disabled={twitterDisabled}
                          required
                          onChange={this.handleInputChange}
                        />
                      </td>
                    </tr>
                  </tbody>
                </FormTable>
              )}
            />
          );
        }}
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
  private makeHandleYesClick(
    t: TranslationFunction,
  ): ((e: React.SyntheticEvent<any>) => void) {
    return async (e: React.SyntheticEvent<any>) => {
      e.preventDefault();
      const url = this.urlRef.current;
      if (url != null && url.value) {
        this.props.onSelect(url.value);
        return;
      }
      const tw = this.twitterRef.current;
      if (tw == null) {
        // アイコン取得失敗
        return;
      }
      const icon = await getTwitterIcon(tw.value);
      if (icon == null) {
        // could not get icon.
        showMessageDialog({
          modal: true,
          title: t('common:error.error'),
          ok: t('common:messageDialog.close'),
          message: t('iconSelect.apiFail'),
        });
        return;
      }
      this.props.onSelect(icon);
    };
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
